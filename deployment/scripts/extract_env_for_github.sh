#!/bin/bash
# Script to extract environment values for GitHub setup
# This reads from local env files and outputs the commands needed

echo "=== GitHub Secrets Required ==="
echo ""
echo "# Run these commands to set up GitHub secrets:"
echo ""

# Backend secrets
if [ -f "backend/.env.production.local" ]; then
  echo "# From backend/.env.production.local:"
  grep -E "^(CLERK_SECRET_KEY|CLERK_WEBHOOK|SMTP_PASSWORD|POSTGRES_PASSWORD|DOCUMENSO_API_KEY|DOCUMENSO_WEBHOOK_SECRET|awsSecret|PG_URL)" backend/.env.production.local | while read line; do
    key=$(echo $line | cut -d= -f1)
    value=$(echo $line | cut -d= -f2-)
    echo "gh secret set $key -b \"$value\" --env production"
  done
fi

echo ""
echo "=== GitHub Variables Required ==="
echo ""

# Frontend variables
if [ -f "frontend/app/.env.production.local" ]; then
  echo "# From frontend/app/.env.production.local:"
  grep -E "^(VITE_CLERK_PUBLISHABLE_KEY|VITE_BACKEND_URL)" frontend/app/.env.production.local | while read line; do
    key=$(echo $line | cut -d= -f1)
    value=$(echo $line | cut -d= -f2-)
    echo "gh variable set $key -b \"$value\" --env production"
  done
fi

# Backend variables
if [ -f "backend/.env.production.local" ]; then
  echo "# From backend/.env.production.local:"
  grep -E "^(PORT|DOMAIN_URL|SMTP_PORT|SMTP_ENDPOINT_ADDRESS|SMTP_FROM|POSTGRES_USER|POSTGRES_DB|ADMIN_FIRST_NAME|ADMIN_LAST_NAME|ADMIN_EMAIL)" backend/.env.production.local | while read line; do
    key=$(echo $line | cut -d= -f1)
    value=$(echo $line | cut -d= -f2-)
    echo "gh variable set $key -b \"$value\" --env production"
  done
fi

echo ""
echo "=== AWS Configuration ==="
echo ""
echo "# From terraform.tfvars:"
if [ -f "deployment/simplified_terraform/terraform.tfvars" ]; then
  grep aws_account_id deployment/simplified_terraform/terraform.tfvars | cut -d= -f2 | tr -d ' "'
  grep aws_region deployment/simplified_terraform/terraform.tfvars | cut -d= -f2 | tr -d ' "'
fi

echo ""
echo "Don't forget to set these manually:"
echo "- AWS_ACCESS_KEY_ID"
echo "- AWS_SECRET_ACCESS_KEY"