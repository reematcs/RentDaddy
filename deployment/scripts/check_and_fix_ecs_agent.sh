#!/bin/bash
#
# Check and fix ECS agent connectivity issues
# This script ensures ECS agents are connected before deployment
#

# Load common utilities
source "$(dirname "$0")/utils.sh"

# Initialize script
init_script "ECS Agent Health Check and Fix" aws

# Load AWS configurations
AWS_REGION=$(get_terraform_var "aws_region" || echo "us-east-2")
export AWS_REGION

# Get the ECS cluster name
CLUSTER_NAME="rentdaddy-cluster"

log "Checking ECS container instances in cluster: $CLUSTER_NAME"

# Get all container instances
CONTAINER_INSTANCES=$(aws ecs list-container-instances \
  --cluster $CLUSTER_NAME \
  --region $AWS_REGION \
  --query 'containerInstanceArns[]' \
  --output text)

if [ -z "$CONTAINER_INSTANCES" ]; then
  log "Error: No container instances found in cluster $CLUSTER_NAME"
  exit 1
fi

log "Found container instances: $CONTAINER_INSTANCES"

# Check each instance
DISCONNECTED_INSTANCES=""
for INSTANCE_ARN in $CONTAINER_INSTANCES; do
  # Get instance details
  INSTANCE_DETAILS=$(aws ecs describe-container-instances \
    --cluster $CLUSTER_NAME \
    --container-instances $INSTANCE_ARN \
    --region $AWS_REGION \
    --query 'containerInstances[0]')
  
  # Check agent connectivity
  AGENT_CONNECTED=$(echo $INSTANCE_DETAILS | jq -r '.agentConnected')
  EC2_INSTANCE_ID=$(echo $INSTANCE_DETAILS | jq -r '.ec2InstanceId')
  
  if [ "$AGENT_CONNECTED" != "true" ]; then
    log "Warning: ECS agent disconnected on instance $EC2_INSTANCE_ID"
    DISCONNECTED_INSTANCES="$DISCONNECTED_INSTANCES $EC2_INSTANCE_ID"
  else
    log "✓ ECS agent connected on instance $EC2_INSTANCE_ID"
  fi
done

# If there are disconnected instances, try to fix them
if [ -n "$DISCONNECTED_INSTANCES" ]; then
  log "Found disconnected ECS agents. Attempting to fix..."
  
  for EC2_INSTANCE_ID in $DISCONNECTED_INSTANCES; do
    log "Fixing ECS agent on instance $EC2_INSTANCE_ID..."
    
    # Check if SSM is available
    SSM_STATUS=$(aws ssm describe-instance-information \
      --filters "Key=InstanceIds,Values=$EC2_INSTANCE_ID" \
      --region $AWS_REGION \
      --query 'InstanceInformationList[0].PingStatus' \
      --output text 2>/dev/null)
    
    if [ "$SSM_STATUS" == "Online" ]; then
      log "Using SSM to restart ECS agent on $EC2_INSTANCE_ID..."
      
      # Restart ECS agent via SSM
      COMMAND_ID=$(aws ssm send-command \
        --document-name "AWS-RunShellScript" \
        --targets "Key=instanceids,Values=$EC2_INSTANCE_ID" \
        --parameters "commands=[
          'echo \"Checking ECS agent status...\"',
          'sudo systemctl status ecs',
          'echo \"Restarting ECS agent...\"',
          'sudo systemctl restart ecs',
          'echo \"Waiting for agent to start...\"',
          'sleep 10',
          'echo \"Verifying ECS agent is running...\"',
          'sudo systemctl status ecs',
          'sudo docker ps | grep ecs-agent'
        ]" \
        --region $AWS_REGION \
        --query 'Command.CommandId' \
        --output text)
      
      log "SSM command sent (ID: $COMMAND_ID). Waiting for completion..."
      
      # Wait for command to complete
      sleep 15
      
      # Check command status
      COMMAND_STATUS=$(aws ssm get-command-invocation \
        --command-id $COMMAND_ID \
        --instance-id $EC2_INSTANCE_ID \
        --region $AWS_REGION \
        --query 'Status' \
        --output text 2>/dev/null || echo "Unknown")
      
      log "Command status: $COMMAND_STATUS"
    else
      log "Warning: SSM not available for instance $EC2_INSTANCE_ID. Manual intervention may be required."
      
      # Try to get instance details for manual fix
      INSTANCE_DETAILS=$(aws ec2 describe-instances \
        --instance-ids $EC2_INSTANCE_ID \
        --region $AWS_REGION \
        --query 'Reservations[0].Instances[0]')
      
      PUBLIC_IP=$(echo $INSTANCE_DETAILS | jq -r '.PublicIpAddress')
      PRIVATE_IP=$(echo $INSTANCE_DETAILS | jq -r '.PrivateIpAddress')
      AZ=$(echo $INSTANCE_DETAILS | jq -r '.Placement.AvailabilityZone')
      
      log "Instance details:"
      log "  - Public IP: $PUBLIC_IP"
      log "  - Private IP: $PRIVATE_IP"
      log "  - Availability Zone: $AZ"
      log ""
      log "Manual fix steps:"
      log "1. SSH to the instance: ssh -i <key-file> ec2-user@$PUBLIC_IP"
      log "2. Restart ECS agent: sudo systemctl restart ecs"
      log "3. Check agent logs: sudo docker logs ecs-agent"
    fi
  done
  
  log "Waiting 30 seconds for agents to reconnect..."
  sleep 30
  
  # Re-check agent connectivity
  log "Re-checking agent connectivity..."
  STILL_DISCONNECTED=""
  for EC2_INSTANCE_ID in $DISCONNECTED_INSTANCES; do
    # Get container instance ARN
    INSTANCE_ARN=$(aws ecs list-container-instances \
      --cluster $CLUSTER_NAME \
      --region $AWS_REGION \
      --filter "ec2InstanceId==$EC2_INSTANCE_ID" \
      --query 'containerInstanceArns[0]' \
      --output text 2>/dev/null)
    
    if [ -n "$INSTANCE_ARN" ] && [ "$INSTANCE_ARN" != "None" ]; then
      AGENT_CONNECTED=$(aws ecs describe-container-instances \
        --cluster $CLUSTER_NAME \
        --container-instances $INSTANCE_ARN \
        --region $AWS_REGION \
        --query 'containerInstances[0].agentConnected' \
        --output text)
      
      if [ "$AGENT_CONNECTED" == "true" ]; then
        log "✓ ECS agent reconnected on instance $EC2_INSTANCE_ID"
      else
        log "✗ ECS agent still disconnected on instance $EC2_INSTANCE_ID"
        STILL_DISCONNECTED="$STILL_DISCONNECTED $EC2_INSTANCE_ID"
      fi
    fi
  done
  
  if [ -n "$STILL_DISCONNECTED" ]; then
    log "Error: Some ECS agents are still disconnected: $STILL_DISCONNECTED"
    log "Manual intervention required. Deployment cannot proceed."
    exit 1
  fi
fi

# Final check - ensure we have at least one healthy instance
HEALTHY_INSTANCES=$(aws ecs list-container-instances \
  --cluster $CLUSTER_NAME \
  --status ACTIVE \
  --region $AWS_REGION \
  --query 'containerInstanceArns[]' \
  --output text | wc -w)

if [ "$HEALTHY_INSTANCES" -eq 0 ]; then
  log "Error: No healthy container instances available in cluster"
  exit 1
fi

log "✓ All ECS agents are connected. Cluster has $HEALTHY_INSTANCES healthy instance(s)."
log "Deployment can proceed safely."
exit 0