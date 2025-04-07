#!/bin/bash

set -euo pipefail

# ================================================
# RentDaddy Build and Deploy Script
# ================================================

PROJECT_ROOT=$(git rev-parse --show-toplevel)
source "$PROJECT_ROOT/deployment/scripts/utils.sh"
init_script "RentDaddy Build and Deploy" docker aws

# === ENV Loading ===
load_env "$PROJECT_ROOT/backend/.env.production.local"
load_env "$PROJECT_ROOT/frontend/app/.env.production.local"

# === Validate Required ENV ===
: "${AWS_ACCOUNT_ID:?Missing AWS_ACCOUNT_ID}"
: "${AWS_REGION:?Missing AWS_REGION}"

ECR_BASE="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# === Utility ===
ensure_ecr_repo() {
  local repo=$1
  aws ecr describe-repositories --repository-names "$repo" --region "$AWS_REGION" >/dev/null 2>&1 || {
    log "Creating ECR repository: $repo"
    aws ecr create-repository --repository-name "$repo" --region "$AWS_REGION"
  }
}

ecr_login() {
  log "Logging into ECR..."
  aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_BASE"
}

build_component() {
  local name=$1
  local path=$2
  local dockerfile=$3
  local tag=$4
  local full_repo=$5

  log "=== Building $name ==="
  ensure_ecr_repo "$full_repo"
  ecr_login

  local builder="${name}-builder"
  docker buildx rm "$builder" >/dev/null 2>&1 || true
  docker buildx create --name "$builder" --use --bootstrap

  # Base build command
  local build_cmd=(
    docker buildx build
    --platform linux/amd64
    --builder "$builder"
    --push
    --build-arg BUILDKIT_INLINE_CACHE=1
    --progress=plain
  )

  # Add component-specific build args
  if [ "$name" = "frontend" ]; then
    log "Adding frontend-specific build args..."
    
    # Make sure these variables are exported so they're available
    : "${VITE_CLERK_PUBLISHABLE_KEY:?Missing VITE_CLERK_PUBLISHABLE_KEY}"
    : "${VITE_BACKEND_URL:?Missing VITE_BACKEND_URL}"
    
    # Add frontend-specific build args
    build_cmd+=(
      --build-arg VITE_CLERK_PUBLISHABLE_KEY="$VITE_CLERK_PUBLISHABLE_KEY"
      --build-arg VITE_BACKEND_URL="$VITE_BACKEND_URL"
      --build-arg VITE_ENV="production"
    )
    
    # Add VITE_DOCUMENSO_PUBLIC_URL if it exists
    if [ -n "${VITE_DOCUMENSO_PUBLIC_URL:-}" ]; then
      build_cmd+=(--build-arg VITE_DOCUMENSO_PUBLIC_URL="$VITE_DOCUMENSO_PUBLIC_URL")
    else
      # Default value if not set
      build_cmd+=(--build-arg VITE_DOCUMENSO_PUBLIC_URL="https://docs.curiousdev.net")
    fi
    
    log "Frontend build env vars:"
    log "- VITE_CLERK_PUBLISHABLE_KEY: ${VITE_CLERK_PUBLISHABLE_KEY:0:5}..."
    log "- VITE_BACKEND_URL: $VITE_BACKEND_URL"
    log "- VITE_DOCUMENSO_PUBLIC_URL: ${VITE_DOCUMENSO_PUBLIC_URL:-https://docs.curiousdev.net}"
    log "- VITE_ENV: production"
  fi

  # Add tag and path to build command
  build_cmd+=(
    -t "$ECR_BASE/$full_repo:$tag"
    -f "$dockerfile"
    "$path"
  )

  # Run the build command
  "${build_cmd[@]}" | tee "$PROJECT_ROOT/deployment/${name}-build.log"

  docker buildx rm "$builder" >/dev/null 2>&1 || true

  log "✅ $name pushed to: $ECR_BASE/$full_repo:$tag"
}

force_ecs_deploy() {
  log "Forcing new ECS deployments..."
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local deploy_dir="$PROJECT_ROOT/deployment/simplified_terraform/ecs_deployment_$timestamp"
  mkdir -p "$deploy_dir"

  for svc_arn in $(aws ecs list-services --cluster rentdaddy-cluster --query "serviceArns[]" --output text); do
    local svc_name=$(basename "$svc_arn")
    log "📦 Forcing deployment: $svc_name"
    aws ecs update-service \
      --cluster rentdaddy-cluster \
      --service "$svc_name" \
      --force-new-deployment \
      > "$deploy_dir/${svc_name}.json"
  done
}

# === CLI Flags ===
BUILD_BACKEND=false
BUILD_FRONTEND=false
BUILD_WORKER=false
DEPLOY=false
TAG_BACKEND="latest"
TAG_FRONTEND="prod"
TAG_WORKER="latest"

if [ $# -eq 0 ]; then
  BUILD_BACKEND=true
  BUILD_FRONTEND=true
  BUILD_WORKER=true
else
  while [[ $# -gt 0 ]]; do
    case $1 in
      -b|--backend) BUILD_BACKEND=true; shift ;;
      -f|--frontend) BUILD_FRONTEND=true; shift ;;
      -w|--worker) BUILD_WORKER=true; shift ;;
      -a|--all) BUILD_BACKEND=true; BUILD_FRONTEND=true; BUILD_WORKER=true; shift ;;
      -d|--deploy) DEPLOY=true; shift ;;
      -t|--tag)
        TAG_BACKEND="$2"
        TAG_FRONTEND="$2"
        TAG_WORKER="$2"
        shift 2 ;;
      -h|--help)
        echo "Usage: $0 [-b|-f|-w|-a] [-t TAG] [--deploy]"
        exit 0 ;;
      *) echo "Unknown option: $1"; exit 1 ;;
    esac
  done
fi

# === Builds ===
BUILD_SUCCESS=true

$BUILD_BACKEND && {
  if ! build_component "backend" "$PROJECT_ROOT/backend" "$PROJECT_ROOT/backend/Dockerfile.prod" "$TAG_BACKEND" "rentdaddy/backend"; then
    log "❌ Backend build failed"
    BUILD_SUCCESS=false
  fi
}

$BUILD_FRONTEND && {
  if ! build_component "frontend" "$PROJECT_ROOT/frontend/app" "$PROJECT_ROOT/frontend/app/Dockerfile.prod" "$TAG_FRONTEND" "rentdaddy/frontend"; then
    log "❌ Frontend build failed"
    BUILD_SUCCESS=false
  fi
}

$BUILD_WORKER && {
  if ! build_component "documenso-worker" "$PROJECT_ROOT/worker/documenso-worker" "$PROJECT_ROOT/worker/documenso-worker/Dockerfile" "$TAG_WORKER" "rentdaddy/documenso-worker"; then
    log "❌ Worker build failed"
    BUILD_SUCCESS=false
  fi
}

# === Optional Deploy ===
if $DEPLOY && $BUILD_SUCCESS; then
  force_ecs_deploy
elif $DEPLOY && ! $BUILD_SUCCESS; then
  log "❌ Skipping deployment: one or more builds failed"
  exit 1
fi

$BUILD_SUCCESS && log "🎉 All builds and optional deployment completed successfully!"
