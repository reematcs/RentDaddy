#!/bin/bash
set -euo pipefail

# ================================================
# RentDaddy Rebuild and Deploy with Rollback Script
# ================================================

PROJECT_ROOT=$(git rev-parse --show-toplevel)
source "$PROJECT_ROOT/deployment/scripts/utils.sh"
init_script "RentDaddy Rebuild and Deploy with Rollback" docker aws

# === Configuration ===
CLUSTER_NAME="rentdaddy-cluster"
APP_SERVICE="rentdaddy-app-service"
DOCUMENSO_SERVICE="rentdaddy-documenso-service"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEPLOY_DIR="$PROJECT_ROOT/deployment/deployment_$TIMESTAMP"
ROLLBACK_DIR="$PROJECT_ROOT/deployment/rollback_$TIMESTAMP"

# === Create directories ===
mkdir -p "$DEPLOY_DIR"
mkdir -p "$ROLLBACK_DIR"

# === Load environment ===
load_env "$PROJECT_ROOT/backend/.env.production.local"
load_env "$PROJECT_ROOT/frontend/app/.env.production.local"

# === Validate required environment ===
: "${AWS_ACCOUNT_ID:?Missing AWS_ACCOUNT_ID}"
: "${AWS_REGION:?Missing AWS_REGION}"

ECR_BASE="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# === Step 1: Create rollback data ===
log "Step 1: Saving current deployment state for rollback..."

# Save current task definitions
aws ecs describe-task-definition --task-definition rentdaddy-app \
  --query 'taskDefinition' > "$ROLLBACK_DIR/app-task-definition.json"
  
aws ecs describe-task-definition --task-definition rentdaddy-documenso \
  --query 'taskDefinition' > "$ROLLBACK_DIR/documenso-task-definition.json"

# Save current service configurations
aws ecs describe-services --cluster $CLUSTER_NAME \
  --services $APP_SERVICE $DOCUMENSO_SERVICE \
  > "$ROLLBACK_DIR/services-current.json"

# Save current image tags
echo "Backend: latest" > "$ROLLBACK_DIR/image-tags.txt"
echo "Frontend: prod" >> "$ROLLBACK_DIR/image-tags.txt"

log "Rollback data saved to: $ROLLBACK_DIR"

# === Step 2: Option to build and push new images ===
BUILD_IMAGES=${1:-"ask"}

if [ "$BUILD_IMAGES" = "ask" ]; then
  read -p "Do you want to build and push new Docker images? (y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    BUILD_IMAGES="yes"
  else
    BUILD_IMAGES="no"
  fi
fi

if [ "$BUILD_IMAGES" = "yes" ]; then
  log "Step 2: Building and pushing new Docker images..."
  
  # Use the existing build script with no-cache flag to ensure fresh builds
  "$PROJECT_ROOT/deployment/scripts/build_and_deploy_latest.sh" -a --no-cache
  
  # Wait for images to be available in ECR
  sleep 10
fi

# === Step 3: Deploy new task definitions ===
log "Step 3: Deploying new task definitions..."

# Force new deployment for both services
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $APP_SERVICE \
  --force-new-deployment \
  > "$DEPLOY_DIR/app-service-update.json"

aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $DOCUMENSO_SERVICE \
  --force-new-deployment \
  > "$DEPLOY_DIR/documenso-service-update.json"

# === Step 4: Monitor deployment ===
log "Step 4: Monitoring deployment (checking every 30 seconds)..."

# Define endpoints to monitor
endpoints=(
  "https://app.curiousdev.net"
  "https://api.curiousdev.net/healthz"
  "https://docs.curiousdev.net"
)

# Monitor for up to 10 minutes
max_checks=20
deployment_success=false

for ((i=1; i<=$max_checks; i++)); do
  log "Health check attempt $i of $max_checks..."
  
  # Wait 30 seconds between checks
  sleep 30
  
  # Check deployment status
  app_status=$(aws ecs describe-services --cluster $CLUSTER_NAME --service $APP_SERVICE \
    --query 'services[0].deployments[0].status' --output text)
  documenso_status=$(aws ecs describe-services --cluster $CLUSTER_NAME --service $DOCUMENSO_SERVICE \
    --query 'services[0].deployments[0].status' --output text)
  
  log "App deployment status: $app_status"
  log "Documenso deployment status: $documenso_status"
  
  # Check if both deployments are completed
  if [ "$app_status" = "PRIMARY" ] && [ "$documenso_status" = "PRIMARY" ]; then
    log "Deployments completed, checking endpoints..."
    
    # Check each endpoint
    all_healthy=true
    for endpoint in "${endpoints[@]}"; do
      status_code=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "$endpoint" || echo "Failed")
      
      if [[ "$status_code" == "2"* ]] || [[ "$status_code" == "3"* ]]; then
        log "✅ $endpoint is healthy (HTTP $status_code)"
      else
        log "❌ $endpoint is not healthy (HTTP $status_code)"
        all_healthy=false
      fi
    done
    
    # If all are healthy, deployment is successful
    if $all_healthy; then
      log "🎉 All services are healthy! Deployment successful."
      deployment_success=true
      break
    fi
  fi
done

# === Step 5: Rollback if needed ===
if [ "$deployment_success" = false ]; then
  log "⚠️ Deployment failed or timed out. Initiating rollback..."
  
  # Create rollback script
  cat > "$ROLLBACK_DIR/execute_rollback.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

ROLLBACK_DIR="$(dirname "$0")"
source "$(dirname "$ROLLBACK_DIR")/scripts/utils.sh"

log "Starting rollback process..."

# Revert task definitions
log "Reverting task definitions..."

# Register previous task definitions
OLD_APP_TASK_DEF=$(cat "$ROLLBACK_DIR/app-task-definition.json" | \
  jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .registeredAt, .registeredBy)')
  
OLD_DOCUMENSO_TASK_DEF=$(cat "$ROLLBACK_DIR/documenso-task-definition.json" | \
  jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .registeredAt, .registeredBy)')

# Register old task definitions
aws ecs register-task-definition --cli-input-json "$OLD_APP_TASK_DEF"
aws ecs register-task-definition --cli-input-json "$OLD_DOCUMENSO_TASK_DEF"

# Update services to use old task definitions
aws ecs update-service \
  --cluster rentdaddy-cluster \
  --service rentdaddy-app-service \
  --task-definition rentdaddy-app \
  --force-new-deployment

aws ecs update-service \
  --cluster rentdaddy-cluster \
  --service rentdaddy-documenso-service \
  --task-definition rentdaddy-documenso \
  --force-new-deployment

log "Rollback initiated. Monitor the services for completion."
EOF

  chmod +x "$ROLLBACK_DIR/execute_rollback.sh"
  
  # Execute rollback
  "$ROLLBACK_DIR/execute_rollback.sh"
  
  log "Rollback script executed. Check AWS console for status."
  log "To manually execute rollback later, run: $ROLLBACK_DIR/execute_rollback.sh"
else
  log "Deployment successful! No rollback needed."
  log "Deployment logs saved to: $DEPLOY_DIR"
fi