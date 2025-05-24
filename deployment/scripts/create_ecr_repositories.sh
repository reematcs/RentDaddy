#!/bin/bash

# Script to create ECR repositories if they don't exist

set -e

AWS_REGION=${AWS_REGION:-us-east-2}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Creating ECR repositories for RentDaddy..."
echo "AWS Account: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION"

# Function to create ECR repository if it doesn't exist
create_ecr_repo() {
    local repo_name=$1
    
    echo "Checking if ECR repository '$repo_name' exists..."
    
    if aws ecr describe-repositories --repository-names "$repo_name" --region "$AWS_REGION" 2>/dev/null; then
        echo "✓ Repository '$repo_name' already exists"
    else
        echo "Creating repository '$repo_name'..."
        aws ecr create-repository \
            --repository-name "$repo_name" \
            --region "$AWS_REGION" \
            --image-scanning-configuration scanOnPush=true \
            --image-tag-mutability MUTABLE
        echo "✓ Repository '$repo_name' created successfully"
    fi
}

# Create repositories
create_ecr_repo "rentdaddy/backend"
create_ecr_repo "rentdaddy/frontend"
create_ecr_repo "rentdaddy-main"

echo ""
echo "ECR repositories setup complete!"
echo ""
echo "Repository URIs:"
echo "Backend:  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/rentdaddy/backend"
echo "Frontend: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/rentdaddy/frontend"
echo "Postgres: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/rentdaddy-main"