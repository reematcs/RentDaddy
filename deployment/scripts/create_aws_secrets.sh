#!/bin/bash
# Script to create initial AWS Secrets Manager secrets
# Run this before sync_secrets_to_github.sh

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

echo -e "${GREEN}AWS Secrets Manager Setup${NC}"
echo "========================="

# Check prerequisites
command -v aws >/dev/null 2>&1 || { echo -e "${RED}Error: AWS CLI is required but not installed.${NC}" >&2; exit 1; }

# Function to prompt for secret value
prompt_secret() {
    local prompt=$1
    local var_name=$2
    local default=$3
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " value
        value=${value:-$default}
    else
        read -p "$prompt: " -s value
        echo
    fi
    
    eval "$var_name='$value'"
}

# Check if secrets already exist
echo -n "Checking if backend secret exists... "
if aws secretsmanager describe-secret --secret-id "$BACKEND_SECRET_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo -e "${YELLOW}Already exists${NC}"
    read -p "Do you want to update the existing secret? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping backend secret creation."
        exit 0
    fi
    UPDATE_BACKEND=true
else
    echo -e "${GREEN}Will create new secret${NC}"
    UPDATE_BACKEND=false
fi

echo -e "\n${YELLOW}Please provide the following values:${NC}"

# Clerk Authentication
echo -e "\n${GREEN}Clerk Authentication:${NC}"
prompt_secret "Clerk Secret Key" CLERK_SECRET_KEY
prompt_secret "Clerk Webhook Secret" CLERK_WEBHOOK
prompt_secret "Clerk Publishable Key" VITE_CLERK_PUBLISHABLE_KEY
prompt_secret "Admin Clerk ID (optional)" ADMIN_CLERK_ID ""

# Database
echo -e "\n${GREEN}Database Configuration:${NC}"
prompt_secret "Database Password" POSTGRES_PASSWORD
PG_URL="postgresql://appuser:${POSTGRES_PASSWORD}@main-postgres:5432/appdb?sslmode=disable"
echo "PG_URL will be: $PG_URL"

# SMTP (AWS SES)
echo -e "\n${GREEN}SMTP Configuration (AWS SES):${NC}"
prompt_secret "SMTP Username" SMTP_USER
prompt_secret "SMTP Password" SMTP_PASSWORD

# Documenso
echo -e "\n${GREEN}Documenso Configuration:${NC}"
prompt_secret "Documenso API Key" DOCUMENSO_API_KEY
prompt_secret "Documenso Webhook Secret" DOCUMENSO_WEBHOOK_SECRET

# OpenAI
echo -e "\n${GREEN}OpenAI Configuration:${NC}"
prompt_secret "OpenAI API Key (optional)" OPENAI_API_KEY ""

# Create the main secret JSON
MAIN_SECRET_JSON=$(cat <<EOF
{
  "CLERK_SECRET_KEY": "$CLERK_SECRET_KEY",
  "CLERK_WEBHOOK": "$CLERK_WEBHOOK",
  "VITE_CLERK_PUBLISHABLE_KEY": "$VITE_CLERK_PUBLISHABLE_KEY",
  "ADMIN_CLERK_ID": "$ADMIN_CLERK_ID",
  "POSTGRES_PASSWORD": "$POSTGRES_PASSWORD",
  "PG_URL": "$PG_URL",
  "SMTP_USER": "$SMTP_USER",
  "SMTP_PASSWORD": "$SMTP_PASSWORD",
  "DOCUMENSO_API_KEY": "$DOCUMENSO_API_KEY",
  "DOCUMENSO_WEBHOOK_SECRET": "$DOCUMENSO_WEBHOOK_SECRET",
  "OPENAI_API_KEY": "$OPENAI_API_KEY"
}
EOF
)

# Create or update the backend secret
echo -e "\n${GREEN}Creating/Updating AWS Secrets Manager secrets...${NC}"

if [ "$UPDATE_BACKEND" = true ]; then
    echo -n "Updating $BACKEND_SECRET_NAME... "
    if aws secretsmanager update-secret \
        --secret-id "$BACKEND_SECRET_NAME" \
        --secret-string "$MAIN_SECRET_JSON" \
        --region "$AWS_REGION" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo "Error updating secret. Check AWS CLI output above."
    fi
else
    echo -n "Creating $BACKEND_SECRET_NAME... "
    if aws secretsmanager create-secret \
        --name "$BACKEND_SECRET_NAME" \
        --description "RentDaddy production backend secrets" \
        --secret-string "$MAIN_SECRET_JSON" \
        --region "$AWS_REGION" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo "Error creating secret. It may already exist or you may lack permissions."
    fi
fi

# Optional: Create Documenso-specific secret
read -p $'\nDo you want to create a separate Documenso secret? (y/n): ' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    DOCUMENSO_SECRET_JSON=$(cat <<EOF
{
  "DOCUMENSO_API_KEY": "$DOCUMENSO_API_KEY",
  "DOCUMENSO_WEBHOOK_SECRET": "$DOCUMENSO_WEBHOOK_SECRET",
  "DOCUMENSO_DATABASE_URL": "postgresql://documenso:documenso@documenso-postgres:5432/documenso"
}
EOF
)
    
    echo -n "Creating $DOCUMENSO_SECRET_NAME... "
    if aws secretsmanager create-secret \
        --name "$DOCUMENSO_SECRET_NAME" \
        --description "RentDaddy Documenso configuration" \
        --secret-string "$DOCUMENSO_SECRET_JSON" \
        --region "$AWS_REGION" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}May already exist or update needed${NC}"
        aws secretsmanager update-secret \
            --secret-id "$DOCUMENSO_SECRET_NAME" \
            --secret-string "$DOCUMENSO_SECRET_JSON" \
            --region "$AWS_REGION" >/dev/null 2>&1
    fi
fi

# Verify secrets
echo -e "\n${GREEN}Verifying secrets...${NC}"
aws secretsmanager list-secrets --region "$AWS_REGION" --query "SecretList[?contains(Name, 'rentdaddy')].[Name,LastChangedDate]" --output table

echo -e "\n${GREEN}✅ AWS Secrets setup complete!${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Note the secret ARNs for your Terraform configuration:"
aws secretsmanager describe-secret --secret-id "$BACKEND_SECRET_NAME" --region "$AWS_REGION" --query 'ARN' --output text
echo ""
echo "2. Run ./sync_secrets_to_github.sh to sync these to GitHub"
echo "3. Manually set AWS credentials in GitHub secrets"

# Clear sensitive variables
unset CLERK_SECRET_KEY CLERK_WEBHOOK POSTGRES_PASSWORD SMTP_PASSWORD DOCUMENSO_API_KEY DOCUMENSO_WEBHOOK_SECRET OPENAI_API_KEY