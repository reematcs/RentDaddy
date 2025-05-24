#!/bin/bash
# Script to pull ALL existing secrets from AWS Secrets Manager and sync to GitHub
# This assumes secrets already exist in AWS and just need to be synced

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-us-east-2}"
GITHUB_REPO="${GITHUB_REPO:-reematcs/RentDaddy}"

echo -e "${GREEN}AWS Secrets Manager to GitHub Actions Complete Sync${NC}"
echo "==================================================="

# Check prerequisites
command -v aws >/dev/null 2>&1 || { echo -e "${RED}Error: AWS CLI is required but not installed.${NC}" >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo -e "${RED}Error: GitHub CLI is required but not installed.${NC}" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo -e "${RED}Error: jq is required but not installed.${NC}" >&2; exit 1; }

# Check if logged in to GitHub CLI
if ! gh auth status >/dev/null 2>&1; then
    echo -e "${RED}Error: Not logged in to GitHub CLI. Run 'gh auth login' first.${NC}"
    exit 1
fi

# Function to set GitHub secret
set_github_secret() {
    local key=$1
    local value=$2
    local env=${3:-"production"}
    
    if [ -z "$value" ] || [ "$value" == "null" ]; then
        echo -e "${YELLOW}Warning: Skipping $key (empty value)${NC}"
        return
    fi
    
    echo -n "Setting $key in $env environment... "
    if gh secret set "$key" -b "$value" --repo "$GITHUB_REPO" --env "$env" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
}

# Get all secrets from AWS Secrets Manager that contain 'rentdaddy'
echo -e "\n${YELLOW}Fetching all RentDaddy secrets from AWS Secrets Manager...${NC}"
echo "Region: $AWS_REGION"

# List all secrets
SECRETS_LIST=$(aws secretsmanager list-secrets \
    --region "$AWS_REGION" \
    --query "SecretList[?contains(Name, 'rentdaddy')].[Name,ARN]" \
    --output json)

echo "$SECRETS_LIST" | jq -r '.[] | @tsv' | while IFS=$'\t' read -r name arn; do
    echo -e "\n${GREEN}Processing secret: $name${NC}"
    
    # Get the secret value
    SECRET_VALUE=$(aws secretsmanager get-secret-value \
        --secret-id "$arn" \
        --region "$AWS_REGION" \
        --query 'SecretString' \
        --output text 2>/dev/null) || {
        echo -e "${RED}Error: Failed to retrieve secret $name${NC}"
        continue
    }
    
    # Try to parse as JSON
    if echo "$SECRET_VALUE" | jq -e . >/dev/null 2>&1; then
        # It's JSON, extract each key-value pair
        echo "$SECRET_VALUE" | jq -r 'to_entries | .[] | "\(.key)=\(.value)"' | while IFS='=' read -r key value; do
            # Set each key as a GitHub secret
            set_github_secret "$key" "$value"
        done
    else
        # It's a plain string, use the secret name as the key
        # Extract a clean key name from the secret path
        KEY_NAME=$(echo "$name" | awk -F'/' '{print $NF}' | tr '[:lower:]' '[:upper:]' | tr '-' '_')
        set_github_secret "$KEY_NAME" "$SECRET_VALUE"
    fi
done

# Get domain configuration from Terraform if available
DOMAIN_NAME=""
if [ -f "deployment/simplified_terraform/terraform.tfvars" ]; then
    DOMAIN_NAME=$(grep domain_name deployment/simplified_terraform/terraform.tfvars | cut -d'"' -f2)
    echo -e "\n${GREEN}Found domain in Terraform config: $DOMAIN_NAME${NC}"
else
    read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
fi

# Set additional configuration that's not in Secrets Manager
echo -e "\n${GREEN}Setting additional configuration secrets...${NC}"

# These are typically hardcoded or derived values
set_github_secret "POSTGRES_HOST" "main-postgres"
set_github_secret "POSTGRES_PORT" "5432"
set_github_secret "POSTGRES_USER" "appuser"
set_github_secret "POSTGRES_DB" "appdb"

# SMTP configuration for AWS SES
set_github_secret "SMTP_HOST" "email-smtp.$AWS_REGION.amazonaws.com"
set_github_secret "SMTP_PORT" "587"
set_github_secret "SMTP_FROM" "ezra@gitfor.ge"
set_github_secret "SMTP_USE_TLS" "true"

# URLs based on domain
if [ -n "$DOMAIN_NAME" ]; then
    set_github_secret "DOCUMENSO_API_URL" "https://docs.$DOMAIN_NAME"
    set_github_secret "VITE_DOCUMENSO_PUBLIC_URL" "https://docs.$DOMAIN_NAME"
    set_github_secret "DOMAIN_URL" "https://app.$DOMAIN_NAME"
    set_github_secret "VITE_BACKEND_URL" "https://api.$DOMAIN_NAME"
    set_github_secret "VITE_SERVER_URL" "https://api.$DOMAIN_NAME"
    set_github_secret "APP_DOMAIN" "app.$DOMAIN_NAME"
fi

# Generate cron token if not exists
echo -n "Checking CRON_SECRET_TOKEN... "
if ! gh secret list --repo "$GITHUB_REPO" --env production 2>/dev/null | grep -q CRON_SECRET_TOKEN; then
    CRON_TOKEN=$(openssl rand -hex 32)
    set_github_secret "CRON_SECRET_TOKEN" "$CRON_TOKEN"
else
    echo -e "${GREEN}Already exists${NC}"
fi

# List all found secrets for verification
echo -e "\n${YELLOW}Summary of secrets found in AWS:${NC}"
aws secretsmanager list-secrets \
    --region "$AWS_REGION" \
    --query "SecretList[?contains(Name, 'rentdaddy')].[Name,Description,LastChangedDate]" \
    --output table

echo -e "\n${YELLOW}GitHub Secrets Status:${NC}"
gh secret list --repo "$GITHUB_REPO" --env production

echo -e "\n${RED}IMPORTANT: Manual steps required:${NC}"
echo "1. Set AWS credentials in GitHub (these cannot be pulled from AWS):"
echo "   ${YELLOW}gh secret set AWS_ACCESS_KEY_ID -b 'your-access-key' --repo $GITHUB_REPO --env production${NC}"
echo "   ${YELLOW}gh secret set AWS_SECRET_ACCESS_KEY -b 'your-secret-key' --repo $GITHUB_REPO --env production${NC}"

echo -e "\n2. To get these AWS credentials:"
echo "   - For ${GREEN}AWS_ACCESS_KEY_ID${NC} and ${GREEN}AWS_SECRET_ACCESS_KEY${NC}:"
echo "     a) Go to AWS Console → IAM → Users"
echo "     b) Select your user (or create a new CI/CD user)"
echo "     c) Go to 'Security credentials' tab"
echo "     d) Create new access key"
echo "     e) Select 'Application running outside AWS'"
echo "     f) Save both the Access Key ID and Secret Access Key"
echo ""
echo "   ${YELLOW}Make sure the IAM user has these permissions:${NC}"
echo "   - ECS full access (or limited to your cluster)"
echo "   - ECR push/pull access"
echo "   - Secrets Manager read access"
echo "   - CloudWatch Logs access"

# Optional: Set up test environment
echo -e "\n3. For test environment (CI pipeline), also set:"
echo "   ${YELLOW}gh secret set CLERK_SECRET_KEY_TEST -b 'your-clerk-secret'${NC}"
echo "   ${YELLOW}gh secret set CLERK_WEBHOOK_TEST -b 'your-clerk-webhook'${NC}"
echo "   ${YELLOW}gh secret set VITE_CLERK_PUBLISHABLE_KEY_TEST -b 'your-clerk-publishable'${NC}"

echo -e "\n${GREEN}✅ Secret sync complete!${NC}"
echo -e "\nTo verify: https://github.com/$GITHUB_REPO/settings/secrets/actions"