#!/bin/bash
set -e

# ==============================================
# Setup GitHub Deployment Script
# ==============================================
# This script helps you set up GitHub secrets and variables
# for automated deployment to AWS using GitHub Actions
# ==============================================

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Get the repository name
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "🎯 Setting up deployment for repository: $REPO"

# Create production environment if it doesn't exist
echo "📦 Creating/updating production environment..."
gh api -X PUT "/repos/$REPO/environments/production" \
  --field wait_timer=0 \
  --field reviewers='[]' \
  --field deployment_branch_policy='{"protected_branches":false,"custom_branch_policies":true}' \
  || echo "Environment already exists"

# Function to set secret
set_secret() {
    local name=$1
    local value=$2
    local env=${3:-"production"}
    
    if [ -z "$value" ]; then
        echo "⚠️  Skipping $name (no value provided)"
        return
    fi
    
    echo "🔐 Setting secret: $name"
    gh secret set "$name" -b "$value" --env "$env"
}

# Function to set variable
set_variable() {
    local name=$1
    local value=$2
    local env=${3:-"production"}
    
    if [ -z "$value" ]; then
        echo "⚠️  Skipping $name (no value provided)"
        return
    fi
    
    echo "📝 Setting variable: $name"
    gh variable set "$name" -b "$value" --env "$env"
}

echo ""
echo "=== Setting Required Secrets ==="
echo ""

# Get AWS account details
echo -n "Enter your AWS Account ID: "
read AWS_ACCOUNT_ID
set_secret "AWS_ACCOUNT_ID" "$AWS_ACCOUNT_ID"

echo -n "Enter your AWS Region (default: us-east-2): "
read AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-2}
set_secret "AWS_REGION" "$AWS_REGION"

echo -n "Enter your AWS Access Key ID: "
read -s AWS_ACCESS_KEY_ID
echo
set_secret "AWS_ACCESS_KEY_ID" "$AWS_ACCESS_KEY_ID"

echo -n "Enter your AWS Secret Access Key: "
read -s AWS_SECRET_ACCESS_KEY
echo
set_secret "AWS_SECRET_ACCESS_KEY" "$AWS_SECRET_ACCESS_KEY"

# Database and authentication secrets
echo ""
echo "=== Database & Authentication Secrets ==="
echo -n "Enter PostgreSQL password: "
read -s POSTGRES_PASSWORD
echo
set_secret "POSTGRES_PASSWORD" "$POSTGRES_PASSWORD"

echo -n "Enter Clerk Secret Key: "
read -s CLERK_SECRET_KEY
echo
set_secret "CLERK_SECRET_KEY" "$CLERK_SECRET_KEY"

echo -n "Enter Clerk Webhook Secret: "
read -s CLERK_WEBHOOK
echo
set_secret "CLERK_WEBHOOK" "$CLERK_WEBHOOK"

# SMTP configuration
echo ""
echo "=== SMTP Configuration ==="
echo -n "Enter SMTP Username: "
read SMTP_USER
set_secret "SMTP_USER" "$SMTP_USER"

echo -n "Enter SMTP Password: "
read -s SMTP_PASSWORD
echo
set_secret "SMTP_PASSWORD" "$SMTP_PASSWORD"

# Documenso secrets
echo ""
echo "=== Documenso Configuration ==="
echo -n "Enter Documenso API Key: "
read -s DOCUMENSO_API_KEY
echo
set_secret "DOCUMENSO_API_KEY" "$DOCUMENSO_API_KEY"

echo -n "Enter Documenso Webhook Secret: "
read -s DOCUMENSO_WEBHOOK_SECRET
echo
set_secret "DOCUMENSO_WEBHOOK_SECRET" "$DOCUMENSO_WEBHOOK_SECRET"

# S3 Configuration
echo ""
echo "=== S3 Configuration ==="
echo -n "Enter AWS S3 Secret Key: "
read -s awsSecret
echo
set_secret "awsSecret" "$awsSecret"

# Database URL
echo ""
echo -n "Enter PostgreSQL connection string (e.g., postgresql://user:pass@host:5432/db): "
read -s PG_URL
echo
set_secret "PG_URL" "$PG_URL"

echo ""
echo "=== Setting Required Variables ==="
echo ""

# Frontend variables
echo -n "Enter Clerk Publishable Key: "
read VITE_CLERK_PUBLISHABLE_KEY
set_variable "VITE_CLERK_PUBLISHABLE_KEY" "$VITE_CLERK_PUBLISHABLE_KEY"

echo -n "Enter Backend URL (e.g., https://api.curiousdev.net): "
read VITE_BACKEND_URL
set_variable "VITE_BACKEND_URL" "$VITE_BACKEND_URL"

echo -n "Enter Frontend Domain URL (e.g., https://app.curiousdev.net): "
read VITE_DOMAIN_URL
set_variable "VITE_DOMAIN_URL" "$VITE_DOMAIN_URL"

echo -n "Enter Documenso Public URL (e.g., https://docs.curiousdev.net): "
read VITE_DOCUMENSO_PUBLIC_URL
set_variable "VITE_DOCUMENSO_PUBLIC_URL" "$VITE_DOCUMENSO_PUBLIC_URL"

# Backend variables
echo -n "Enter Backend Port (default: 8080): "
read PORT
PORT=${PORT:-8080}
set_variable "PORT" "$PORT"

echo -n "Enter Backend Domain URL (e.g., https://api.curiousdev.net): "
read DOMAIN_URL
set_variable "DOMAIN_URL" "$DOMAIN_URL"

# SMTP variables
echo ""
echo "=== SMTP Variables ==="
echo -n "Enter SMTP Port (default: 587): "
read SMTP_PORT
SMTP_PORT=${SMTP_PORT:-587}
set_variable "SMTP_PORT" "$SMTP_PORT"

echo -n "Enter SMTP Endpoint Address: "
read SMTP_ENDPOINT_ADDRESS
set_variable "SMTP_ENDPOINT_ADDRESS" "$SMTP_ENDPOINT_ADDRESS"

echo -n "Enter SMTP From Email: "
read SMTP_FROM
set_variable "SMTP_FROM" "$SMTP_FROM"

echo -n "Enter SMTP TLS Mode (starttls/tls): "
read SMTP_TLS_MODE
set_variable "SMTP_TLS_MODE" "$SMTP_TLS_MODE"

# S3 variables
echo ""
echo "=== S3 Variables ==="
echo -n "Enter S3 Bucket Name: "
read s3Bucket
set_variable "s3Bucket" "$s3Bucket"

echo -n "Enter AWS Access ID for S3: "
read awsAccessID
set_variable "awsAccessID" "$awsAccessID"

# Database variables
echo ""
echo "=== Database Variables ==="
echo -n "Enter PostgreSQL Username (default: appuser): "
read POSTGRES_USER
POSTGRES_USER=${POSTGRES_USER:-appuser}
set_variable "POSTGRES_USER" "$POSTGRES_USER"

echo -n "Enter PostgreSQL Database Name (default: appdb): "
read POSTGRES_DB
POSTGRES_DB=${POSTGRES_DB:-appdb}
set_variable "POSTGRES_DB" "$POSTGRES_DB"

# Admin configuration
echo ""
echo "=== Admin Configuration ==="
echo -n "Enter Admin First Name: "
read ADMIN_FIRST_NAME
set_variable "ADMIN_FIRST_NAME" "$ADMIN_FIRST_NAME"

echo -n "Enter Admin Last Name: "
read ADMIN_LAST_NAME
set_variable "ADMIN_LAST_NAME" "$ADMIN_LAST_NAME"

echo -n "Enter Admin Email: "
read ADMIN_EMAIL
set_variable "ADMIN_EMAIL" "$ADMIN_EMAIL"

# Set default variables
echo ""
echo "=== Setting Default Variables ==="
set_variable "VITE_PORT" "8080"
set_variable "VITE_SERVER_URL" "$VITE_BACKEND_URL"
set_variable "VITE_ENV" "production"
set_variable "TEMP_DIR" "/app/temp"
set_variable "POSTGRES_PORT" "5432"
set_variable "FRONTEND_PORT" "5173"
set_variable "CLERK_SIGN_IN_URL" "/sign-in/*"
set_variable "CLERK_SIGN_IN_FALLBACK_REDIRECT_URL" "/"
set_variable "CLERK_SIGN_UP_FALLBACK_REDIRECT_URL" "/"
set_variable "s3Region" "$AWS_REGION"
set_variable "s3BaseURL" "https://s3.$AWS_REGION.amazonaws.com"
set_variable "DOCUMENSO_HOST" "$(echo $VITE_DOCUMENSO_PUBLIC_URL | sed 's|https://||')"
set_variable "DOCUMENSO_PORT" "3000"
set_variable "ENV" "production"

echo ""
echo "✅ GitHub deployment setup complete!"
echo ""
echo "Next steps:"
echo "1. Run terraform apply in deployment/simplified_terraform to set up AWS infrastructure"
echo "2. Push to main branch to trigger deployment"
echo "3. Monitor the Actions tab in GitHub for deployment status"
echo ""
echo "To deploy manually, run:"
echo "  gh workflow run aws-deploy.yml"