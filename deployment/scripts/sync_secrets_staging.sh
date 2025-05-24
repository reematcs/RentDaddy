#!/bin/bash
# Script to create staging environment secrets from production secrets
# This copies production secrets and allows modification for staging

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="${GITHUB_REPO:-reematcs/RentDaddy}"
STAGING_SUFFIX="_STAGING"

echo -e "${GREEN}GitHub Staging Environment Setup${NC}"
echo "================================="

# Check prerequisites
command -v gh >/dev/null 2>&1 || { echo -e "${RED}Error: GitHub CLI is required but not installed.${NC}" >&2; exit 1; }

# Check if logged in to GitHub CLI
if ! gh auth status >/dev/null 2>&1; then
    echo -e "${RED}Error: Not logged in to GitHub CLI. Run 'gh auth login' first.${NC}"
    exit 1
fi

# Function to copy secret from production to staging
copy_secret_to_staging() {
    local key=$1
    local staging_key="${key}${STAGING_SUFFIX}"
    
    echo -n "Copying $key to $staging_key... "
    
    # Get the production secret value
    prod_value=$(gh secret list --repo "$GITHUB_REPO" --env production --json name,updatedAt | \
        jq -r --arg key "$key" '.[] | select(.name == $key) | .name' || echo "")
    
    if [ -z "$prod_value" ]; then
        echo -e "${YELLOW}Skipped (not found in production)${NC}"
        return
    fi
    
    # For staging, we'll need to get the value from GitHub (which we can't do directly)
    # So we'll prompt for important ones that need to be different
    case $key in
        POSTGRES_HOST|POSTGRES_DB|PG_URL)
            echo -e "${YELLOW}Needs manual configuration for staging database${NC}"
            ;;
        DOMAIN_URL|VITE_BACKEND_URL|VITE_SERVER_URL|APP_DOMAIN)
            echo -e "${YELLOW}Needs manual configuration for staging URLs${NC}"
            ;;
        *)
            echo -e "${GREEN}Use production value or set manually${NC}"
            ;;
    esac
}

# Create staging environment if it doesn't exist
echo -n "Checking if staging environment exists... "
if gh api repos/$GITHUB_REPO/environments/staging >/dev/null 2>&1; then
    echo -e "${GREEN}Already exists${NC}"
else
    echo -e "${YELLOW}Creating staging environment${NC}"
    gh api repos/$GITHUB_REPO/environments/staging --method PUT
fi

# List of secrets that need to be set for staging
SECRETS_TO_COPY=(
    "AWS_ACCESS_KEY_ID"
    "AWS_SECRET_ACCESS_KEY"
    "CLERK_SECRET_KEY"
    "CLERK_WEBHOOK"
    "VITE_CLERK_PUBLISHABLE_KEY"
    "POSTGRES_HOST"
    "POSTGRES_PORT"
    "POSTGRES_USER"
    "POSTGRES_PASSWORD"
    "POSTGRES_DB"
    "PG_URL"
    "SMTP_HOST"
    "SMTP_PORT"
    "SMTP_USER"
    "SMTP_PASSWORD"
    "SMTP_FROM"
    "SMTP_USE_TLS"
    "DOCUMENSO_API_KEY"
    "DOCUMENSO_WEBHOOK_SECRET"
    "DOCUMENSO_API_URL"
    "VITE_DOCUMENSO_PUBLIC_URL"
    "OPENAI_API_KEY"
    "CRON_SECRET_TOKEN"
    "DOMAIN_URL"
    "VITE_BACKEND_URL"
    "VITE_SERVER_URL"
    "APP_DOMAIN"
    "STAGING_APP_URL"
)

echo -e "\n${YELLOW}Setting up staging secrets...${NC}"
echo "For staging, you'll need to configure:"
echo "1. Separate staging database"
echo "2. Staging URLs (e.g., staging.your-domain.com)"
echo "3. Optionally: Separate Clerk staging app"

# Prompt for staging-specific values
read -p $'\nEnter staging domain (e.g., staging.example.com): ' STAGING_DOMAIN

# Set staging-specific secrets
echo -e "\n${GREEN}Setting staging-specific configuration...${NC}"

# Database (assuming separate staging DB)
gh secret set "POSTGRES_HOST_STAGING" -b "staging-postgres" --repo "$GITHUB_REPO" --env staging
gh secret set "POSTGRES_PORT_STAGING" -b "5432" --repo "$GITHUB_REPO" --env staging
gh secret set "POSTGRES_USER_STAGING" -b "appuser" --repo "$GITHUB_REPO" --env staging
gh secret set "POSTGRES_DB_STAGING" -b "appdb_staging" --repo "$GITHUB_REPO" --env staging

# URLs
gh secret set "DOMAIN_URL_STAGING" -b "https://$STAGING_DOMAIN" --repo "$GITHUB_REPO" --env staging
gh secret set "VITE_BACKEND_URL_STAGING" -b "https://api-$STAGING_DOMAIN" --repo "$GITHUB_REPO" --env staging
gh secret set "VITE_SERVER_URL_STAGING" -b "https://api-$STAGING_DOMAIN" --repo "$GITHUB_REPO" --env staging
gh secret set "APP_DOMAIN_STAGING" -b "$STAGING_DOMAIN" --repo "$GITHUB_REPO" --env staging
gh secret set "STAGING_APP_URL" -b "https://$STAGING_DOMAIN" --repo "$GITHUB_REPO" --env staging

# SMTP (using same SES)
gh secret set "SMTP_HOST_STAGING" -b "email-smtp.us-east-2.amazonaws.com" --repo "$GITHUB_REPO" --env staging
gh secret set "SMTP_PORT_STAGING" -b "587" --repo "$GITHUB_REPO" --env staging
gh secret set "SMTP_FROM_STAGING" -b "staging-ezra@gitfor.ge" --repo "$GITHUB_REPO" --env staging
gh secret set "SMTP_USE_TLS_STAGING" -b "true" --repo "$GITHUB_REPO" --env staging

# Documenso staging
gh secret set "DOCUMENSO_API_URL_STAGING" -b "https://docs-$STAGING_DOMAIN" --repo "$GITHUB_REPO" --env staging
gh secret set "VITE_DOCUMENSO_PUBLIC_URL_STAGING" -b "https://docs-$STAGING_DOMAIN" --repo "$GITHUB_REPO" --env staging

echo -e "\n${YELLOW}Manual configuration required:${NC}"
echo "You need to manually set these staging secrets:"
echo ""
echo "# AWS Credentials for staging (if using separate account)"
echo "gh secret set AWS_ACCESS_KEY_ID_STAGING -b 'your-staging-access-key' --repo $GITHUB_REPO --env staging"
echo "gh secret set AWS_SECRET_ACCESS_KEY_STAGING -b 'your-staging-secret-key' --repo $GITHUB_REPO --env staging"
echo ""
echo "# Database password for staging"
echo "gh secret set POSTGRES_PASSWORD_STAGING -b 'your-staging-db-password' --repo $GITHUB_REPO --env staging"
echo "gh secret set PG_URL_STAGING -b 'postgresql://appuser:your-staging-db-password@staging-postgres:5432/appdb_staging?sslmode=disable' --repo $GITHUB_REPO --env staging"
echo ""
echo "# Clerk staging credentials (if using separate Clerk app)"
echo "gh secret set CLERK_SECRET_KEY_STAGING -b 'your-staging-clerk-secret' --repo $GITHUB_REPO --env staging"
echo "gh secret set CLERK_WEBHOOK_STAGING -b 'your-staging-clerk-webhook' --repo $GITHUB_REPO --env staging"
echo "gh secret set VITE_CLERK_PUBLISHABLE_KEY_STAGING -b 'your-staging-clerk-publishable' --repo $GITHUB_REPO --env staging"
echo ""
echo "# Copy production secrets that can be reused"
echo "gh secret set SMTP_USER_STAGING -b 'your-ses-smtp-user' --repo $GITHUB_REPO --env staging"
echo "gh secret set SMTP_PASSWORD_STAGING -b 'your-ses-smtp-password' --repo $GITHUB_REPO --env staging"
echo "gh secret set DOCUMENSO_API_KEY_STAGING -b 'your-documenso-api-key' --repo $GITHUB_REPO --env staging"
echo "gh secret set DOCUMENSO_WEBHOOK_SECRET_STAGING -b 'your-documenso-webhook-secret' --repo $GITHUB_REPO --env staging"
echo "gh secret set OPENAI_API_KEY_STAGING -b 'your-openai-key' --repo $GITHUB_REPO --env staging"
echo "gh secret set CRON_SECRET_TOKEN_STAGING -b 'your-cron-token' --repo $GITHUB_REPO --env staging"

echo -e "\n${GREEN}✅ Staging environment setup complete!${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Set the manual secrets listed above"
echo "2. Create staging infrastructure in AWS (ECS cluster, services, etc.)"
echo "3. Update staging workflow if needed for your infrastructure"
echo "4. Test a deployment to staging environment"