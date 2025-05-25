#!/bin/bash
# Script to import existing AWS resources into Terraform state

set -e

echo "=== Importing existing AWS resources into Terraform state ==="
echo "This script will import resources that already exist in AWS."
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../simplified_terraform"

cd "$TERRAFORM_DIR"

# Check if we're using the GitHub Actions terraform file
if [ -f "main-github-actions.tf" ]; then
    echo "Using main-github-actions.tf configuration"
    
    # Rename main.tf to main.tf.backup if it exists
    if [ -f "main.tf" ]; then
        mv main.tf main.tf.backup
    fi
    
    # Copy main-github-actions.tf to main.tf for Terraform to use
    cp main-github-actions.tf main.tf
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init -upgrade

# Function to safely import resources
import_resource() {
    local resource_type=$1
    local resource_name=$2
    local resource_id=$3
    
    echo ""
    echo "Importing ${resource_type}.${resource_name}..."
    
    # Check if resource already exists in state
    if terraform state show "${resource_type}.${resource_name}" &>/dev/null; then
        echo "  Resource already exists in state, skipping..."
    else
        # Try to import the resource
        if terraform import "${resource_type}.${resource_name}" "$resource_id" 2>/dev/null; then
            echo "  ✓ Successfully imported"
        else
            echo "  ✗ Failed to import (resource might not exist in AWS)"
        fi
    fi
}

# Import Load Balancer
echo ""
echo "=== Importing Load Balancer ==="
ALB_ARN=$(aws elbv2 describe-load-balancers --names rentdaddy-alb --region us-east-2 --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "")
if [ "$ALB_ARN" != "" ] && [ "$ALB_ARN" != "None" ]; then
    import_resource "aws_lb" "main" "$ALB_ARN"
else
    echo "  Load Balancer 'rentdaddy-alb' not found in AWS"
fi

# Import Target Groups
echo ""
echo "=== Importing Target Groups ==="
BACKEND_TG_ARN=$(aws elbv2 describe-target-groups --names backend-tg --region us-east-2 --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
if [ "$BACKEND_TG_ARN" != "" ] && [ "$BACKEND_TG_ARN" != "None" ]; then
    import_resource "aws_lb_target_group" "backend" "$BACKEND_TG_ARN"
else
    echo "  Target Group 'backend-tg' not found in AWS"
fi

DOCUMENSO_TG_ARN=$(aws elbv2 describe-target-groups --names documenso-tg --region us-east-2 --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
if [ "$DOCUMENSO_TG_ARN" != "" ] && [ "$DOCUMENSO_TG_ARN" != "None" ]; then
    import_resource "aws_lb_target_group" "documenso" "$DOCUMENSO_TG_ARN"
else
    echo "  Target Group 'documenso-tg' not found in AWS"
fi

# Import ECS Cluster
echo ""
echo "=== Importing ECS Cluster ==="
ECS_CLUSTER=$(aws ecs describe-clusters --clusters rentdaddy-cluster --region us-east-2 --query 'clusters[0].clusterArn' --output text 2>/dev/null || echo "")
if [ "$ECS_CLUSTER" != "" ] && [ "$ECS_CLUSTER" != "None" ]; then
    import_resource "aws_ecs_cluster" "main" "rentdaddy-cluster"
else
    echo "  ECS Cluster 'rentdaddy-cluster' not found in AWS"
fi

# Import IAM Roles
echo ""
echo "=== Importing IAM Roles ==="
if aws iam get-role --role-name rentdaddy-ecs-task-execution-role &>/dev/null; then
    import_resource "aws_iam_role" "ecs_task_execution" "rentdaddy-ecs-task-execution-role"
else
    echo "  IAM Role 'rentdaddy-ecs-task-execution-role' not found in AWS"
fi

if aws iam get-role --role-name rentdaddy-ecs-task-role &>/dev/null; then
    import_resource "aws_iam_role" "ecs_task" "rentdaddy-ecs-task-role"
else
    echo "  IAM Role 'rentdaddy-ecs-task-role' not found in AWS"
fi

if aws iam get-role --role-name rentdaddy-ecs-instance-role &>/dev/null; then
    import_resource "aws_iam_role" "ecs_instance" "rentdaddy-ecs-instance-role"
else
    echo "  IAM Role 'rentdaddy-ecs-instance-role' not found in AWS"
fi

# Import CloudWatch Log Groups
echo ""
echo "=== Importing CloudWatch Log Groups ==="
if aws logs describe-log-groups --log-group-name-prefix /ecs/rentdaddy-backend --region us-east-2 --query "logGroups[?logGroupName=='/ecs/rentdaddy-backend'].logGroupName" --output text | grep -q rentdaddy-backend; then
    import_resource "aws_cloudwatch_log_group" "backend_logs" "/ecs/rentdaddy-backend"
else
    echo "  Log Group '/ecs/rentdaddy-backend' not found in AWS"
fi

if aws logs describe-log-groups --log-group-name-prefix /ecs/rentdaddy-frontend --region us-east-2 --query "logGroups[?logGroupName=='/ecs/rentdaddy-frontend'].logGroupName" --output text | grep -q rentdaddy-frontend; then
    import_resource "aws_cloudwatch_log_group" "frontend_logs" "/ecs/rentdaddy-frontend"
else
    echo "  Log Group '/ecs/rentdaddy-frontend' not found in AWS"
fi

if aws logs describe-log-groups --log-group-name-prefix /ecs/rentdaddy-documenso --region us-east-2 --query "logGroups[?logGroupName=='/ecs/rentdaddy-documenso'].logGroupName" --output text | grep -q rentdaddy-documenso; then
    import_resource "aws_cloudwatch_log_group" "documenso_logs" "/ecs/rentdaddy-documenso"
else
    echo "  Log Group '/ecs/rentdaddy-documenso' not found in AWS"
fi

echo ""
echo "=== Import Summary ==="
echo "Import process complete!"
echo ""
echo "Next steps:"
echo "1. Run 'terraform plan' to see what changes Terraform wants to make"
echo "2. Review the plan carefully - imported resources might need configuration adjustments"
echo "3. If the plan looks good, run 'terraform apply' to update the infrastructure"
echo ""
echo "If you see errors about resources already existing, you may need to:"
echo "- Delete the resources from AWS and run terraform apply to recreate them"
echo "- Or adjust the Terraform configuration to match the existing resources"