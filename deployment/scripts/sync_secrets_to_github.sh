#!/bin/bash
# Script to sync secrets from AWS Secrets Manager to GitHub Actions secrets
# This automates the process of pulling secrets from AWS and setting them in GitHub

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-us-east-2}"
BACKEND_SECRET_NAME="rentdaddy/production/main-app"
DOCUMENSO_SECRET_NAME="rentdaddy/production/documenso"
GITHUB_REPO="${GITHUB_REPO:-reematcs/RentDaddy}"

echo -e "${GREEN}AWS Secrets Manager to GitHub Actions Sync${NC}"
echo "================================================"

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
    local env=${3:-""}
    
    if [ -z "$value" ] || [ "$value" == "null" ]; then
        echo -e "${YELLOW}Warning: Skipping $key (empty value)${NC}"
        return
    fi
    
    if [ -n "$env" ]; then
        echo -n "Setting $key in $env environment... "
        if gh secret set "$key" -b "$value" --repo "$GITHUB_REPO" --env "$env" 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
        fi
    else
        echo -n "Setting $key... "
        if gh secret set "$key" -b "$value" --repo "$GITHUB_REPO" 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
        fi
    fi
}

# Pull main app secrets from AWS Secrets Manager
echo -e "\n${YELLOW}Fetching secrets from AWS Secrets Manager...${NC}"
echo "Region: $AWS_REGION"
echo "Backend Secret: $BACKEND_SECRET_NAME"

# Get the secret value
BACKEND_SECRETS=$(aws secretsmanager get-secret-value \
    --secret-id "$BACKEND_SECRET_NAME" \
    --region "$AWS_REGION" \
    --query 'SecretString' \
    --output text 2>/dev/null) || {
    echo -e "${RED}Error: Failed to retrieve backend secrets from AWS.${NC}"
    echo "Make sure the secret '$BACKEND_SECRET_NAME' exists and you have permissions."
    exit 1
}

# Parse and set each secret from the backend secrets
echo -e "\n${GREEN}Setting GitHub secrets from AWS Secrets Manager...${NC}"

# Core secrets that should be in AWS Secrets Manager
echo "$BACKEND_SECRETS" | jq -r 'to_entries | .[] | "\(.key)=\(.value)"' | while IFS='=' read -r key value; do
    case $key in
        CLERK_SECRET_KEY|CLERK_WEBHOOK|VITE_CLERK_PUBLISHABLE_KEY|ADMIN_CLERK_ID)
            set_github_secret "$key" "$value" "production"
            ;;
        POSTGRES_PASSWORD|PG_URL)
            set_github_secret "$key" "$value" "production"
            ;;
        SMTP_USER|SMTP_PASSWORD)
            set_github_secret "$key" "$value" "production"
            ;;
        DOCUMENSO_API_KEY|DOCUMENSO_WEBHOOK_SECRET)
            set_github_secret "$key" "$value" "production"
            ;;
        OPENAI_API_KEY)
            set_github_secret "$key" "$value" "production"
            ;;
    esac
done

# Try to get Documenso-specific secrets if they exist
echo -e "\n${YELLOW}Checking for Documenso-specific secrets...${NC}"
DOCUMENSO_SECRETS=$(aws secretsmanager get-secret-value \
    --secret-id "$DOCUMENSO_SECRET_NAME" \
    --region "$AWS_REGION" \
    --query 'SecretString' \
    --output text 2>/dev/null) || {
    echo -e "${YELLOW}Warning: Documenso secret not found or not accessible.${NC}"
}

if [ -n "$DOCUMENSO_SECRETS" ] && [ "$DOCUMENSO_SECRETS" != "null" ]; then
    echo "$DOCUMENSO_SECRETS" | jq -r 'to_entries | .[] | "\(.key)=\(.value)"' | while IFS='=' read -r key value; do
        set_github_secret "$key" "$value" "production"
    done
fi

# Set additional secrets that are derived or static
echo -e "\n${GREEN}Setting additional configuration secrets...${NC}"

# Get domain from Terraform or prompt
if [ -f "deployment/simplified_terraform/terraform.tfvars" ]; then
    DOMAIN_NAME=$(grep domain_name deployment/simplified_terraform/terraform.tfvars | cut -d'"' -f2)
else
    read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
fi

# Set derived URLs
set_github_secret "POSTGRES_HOST" "main-postgres" "production"
set_github_secret "POSTGRES_PORT" "5432" "production"
set_github_secret "POSTGRES_USER" "appuser" "production"
set_github_secret "POSTGRES_DB" "appdb" "production"

set_github_secret "SMTP_HOST" "email-smtp.$AWS_REGION.amazonaws.com" "production"
set_github_secret "SMTP_PORT" "587" "production"
set_github_secret "SMTP_FROM" "ezra@gitfor.ge" "production"
set_github_secret "SMTP_USE_TLS" "true" "production"

set_github_secret "DOCUMENSO_API_URL" "https://docs.$DOMAIN_NAME" "production"
set_github_secret "VITE_DOCUMENSO_PUBLIC_URL" "https://docs.$DOMAIN_NAME" "production"

set_github_secret "DOMAIN_URL" "https://app.$DOMAIN_NAME" "production"
set_github_secret "VITE_BACKEND_URL" "https://api.$DOMAIN_NAME" "production"
set_github_secret "VITE_SERVER_URL" "https://api.$DOMAIN_NAME" "production"
set_github_secret "APP_DOMAIN" "app.$DOMAIN_NAME" "production"

# Generate cron token if not exists
echo -n "Checking CRON_SECRET_TOKEN... "
if ! gh secret list --repo "$GITHUB_REPO" --env production | grep -q CRON_SECRET_TOKEN; then
    CRON_TOKEN=$(openssl rand -hex 32)
    set_github_secret "CRON_SECRET_TOKEN" "$CRON_TOKEN" "production"
    echo -e "${GREEN}Generated new token${NC}"
else
    echo -e "${GREEN}Already exists${NC}"
fi

# AWS credentials need to be set manually
echo -e "\n${YELLOW}Manual steps required:${NC}"
echo "1. Set AWS credentials (these cannot be pulled from AWS):"
echo "   gh secret set AWS_ACCESS_KEY_ID -b 'your-access-key' --repo $GITHUB_REPO --env production"
echo "   gh secret set AWS_SECRET_ACCESS_KEY -b 'your-secret-key' --repo $GITHUB_REPO --env production"

# Optional: Set up test environment secrets
read -p $'\nDo you want to set up test environment secrets for CI? (y/n): ' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${GREEN}Setting up test environment secrets...${NC}"
    
    # Copy specific secrets to test environment with _TEST suffix
    echo "$BACKEND_SECRETS" | jq -r '.CLERK_SECRET_KEY // empty' | { 
        read value; 
        [ -n "$value" ] && set_github_secret "CLERK_SECRET_KEY_TEST" "$value" 
    }
    echo "$BACKEND_SECRETS" | jq -r '.CLERK_WEBHOOK // empty' | { 
        read value; 
        [ -n "$value" ] && set_github_secret "CLERK_WEBHOOK_TEST" "$value" 
    }
    echo "$BACKEND_SECRETS" | jq -r '.VITE_CLERK_PUBLISHABLE_KEY // empty' | { 
        read value; 
        [ -n "$value" ] && set_github_secret "VITE_CLERK_PUBLISHABLE_KEY_TEST" "$value" 
    }
fi

# Optional: Slack webhook
read -p $'\nDo you have a Slack webhook for notifications? (y/n): ' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter Slack webhook URL: " SLACK_WEBHOOK
    set_github_secret "SLACK_WEBHOOK" "$SLACK_WEBHOOK" "production"
fi

echo -e "\n${GREEN}✅ Secret sync complete!${NC}"
echo -e "\n${YELLOW}Summary:${NC}"
gh secret list --repo "$GITHUB_REPO" --env production | grep -E "Updated|Created" | wc -l | xargs echo "- Secrets in production environment:"
echo "- Repository: $GITHUB_REPO"
echo "- AWS Region: $AWS_REGION"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Verify secrets in GitHub: https://github.com/$GITHUB_REPO/settings/secrets/actions"
echo "2. Set AWS credentials manually (see above)"
echo "3. Run a test deployment to verify everything works"