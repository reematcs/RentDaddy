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

  # Create a fresh builder or reuse existing one depending on flag
  local builder="${name}-builder"
  if [ "$USE_FRESH_BUILDER" = "true" ]; then
    log "Using a fresh builder for $name..."
    docker buildx rm "$builder" >/dev/null 2>&1 || true
    docker buildx create --name "$builder" --use --bootstrap
  else
    log "Checking for existing builder or creating one..."
    docker buildx inspect "$builder" >/dev/null 2>&1 || docker buildx create --name "$builder" --use --bootstrap
    docker buildx use "$builder"
  fi

  # Try to pull the latest image for cache
  if [ "$USE_REGISTRY_CACHE" = "true" ]; then
    log "Pulling latest image for cache: $ECR_BASE/$full_repo:$tag"
    docker pull "$ECR_BASE/$full_repo:$tag" >/dev/null 2>&1 || log "No previous image found for cache, will build from scratch"
  fi

  # Base build command
  local build_cmd=(
    docker buildx build
    --platform linux/amd64
    --builder "$builder"
    --push
    --build-arg BUILDKIT_INLINE_CACHE=1
    --progress=plain
  )
  
  # Add cache-from if using registry cache
  if [ "$USE_REGISTRY_CACHE" = "true" ]; then
    build_cmd+=(--cache-from "$ECR_BASE/$full_repo:$tag")
  fi

  # Add component-specific build args
  if [ "$name" = "frontend" ]; then
    log "Adding frontend-specific build args..."
    
    # Make sure these variables are exported so they're available
    : "${VITE_CLERK_PUBLISHABLE_KEY:?Missing VITE_CLERK_PUBLISHABLE_KEY}"
    : "${VITE_BACKEND_URL:?Missing VITE_BACKEND_URL}"
    
    # Standard frontend-specific build args
    build_cmd+=(
      --build-arg VITE_CLERK_PUBLISHABLE_KEY="$VITE_CLERK_PUBLISHABLE_KEY"
      --build-arg VITE_BACKEND_URL="$VITE_BACKEND_URL"
      --build-arg VITE_ENV="production"
      --build-arg NODE_ENV="production"
    )
    
    # Add VITE_DOCUMENSO_PUBLIC_URL if it exists
    if [ -n "${VITE_DOCUMENSO_PUBLIC_URL:-}" ]; then
      build_cmd+=(--build-arg VITE_DOCUMENSO_PUBLIC_URL="$VITE_DOCUMENSO_PUBLIC_URL")
    else
      # Default value if not set
      build_cmd+=(--build-arg VITE_DOCUMENSO_PUBLIC_URL="https://docs.curiousdev.net")
    fi

    # Add VITE_DOMAIN_URL and VITE_PORT if they exist (to ensure all variables used in apiConfig are set)
    if [ -n "${VITE_DOMAIN_URL:-}" ]; then
      build_cmd+=(--build-arg VITE_DOMAIN_URL="$VITE_DOMAIN_URL")
      log "- VITE_DOMAIN_URL: $VITE_DOMAIN_URL"
    fi
    
    if [ -n "${VITE_PORT:-}" ]; then
      build_cmd+=(--build-arg VITE_PORT="$VITE_PORT")
      log "- VITE_PORT: $VITE_PORT"
    fi
    
    if [ -n "${VITE_SERVER_URL:-}" ]; then
      build_cmd+=(--build-arg VITE_SERVER_URL="$VITE_SERVER_URL")
      log "- VITE_SERVER_URL: $VITE_SERVER_URL"
    fi
    
    # Set no-cache for frontend builds to ensure clean builds each time
    log "Ensuring a clean frontend build without caching issues"
    build_cmd+=(--no-cache)
    
    log "Frontend build env vars:"
    log "- VITE_CLERK_PUBLISHABLE_KEY: ${VITE_CLERK_PUBLISHABLE_KEY:0:5}..."
    log "- VITE_BACKEND_URL: $VITE_BACKEND_URL"
    log "- VITE_DOCUMENSO_PUBLIC_URL: ${VITE_DOCUMENSO_PUBLIC_URL:-https://docs.curiousdev.net}"
    log "- VITE_ENV: production"
    log "- NODE_ENV: production"
  fi

  # Add tag and path to build command
  build_cmd+=(
    -t "$ECR_BASE/$full_repo:$tag"
    -f "$dockerfile"
    "$path"
  )

  # Run the build command
  "${build_cmd[@]}" | tee "$PROJECT_ROOT/deployment/${name}-build.log"

  # Only remove the builder if we're using fresh builders
  if [ "$USE_FRESH_BUILDER" = "true" ]; then
    log "Removing temporary builder: $builder"
    docker buildx rm "$builder" >/dev/null 2>&1 || true
  fi

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
USE_FRESH_BUILDER=true     # Default to using a fresh builder each time
USE_REGISTRY_CACHE=true    # Default to using registry cache

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
      --reuse-builder) USE_FRESH_BUILDER=false; shift ;;
      --fresh-builder) USE_FRESH_BUILDER=true; shift ;;
      --no-cache) USE_REGISTRY_CACHE=false; shift ;;
      --use-cache) USE_REGISTRY_CACHE=true; shift ;;
      -h|--help)
        echo "Usage: $0 [-b|-f|-w|-a] [-t TAG] [--deploy] [--reuse-builder|--fresh-builder] [--use-cache|--no-cache]"
        echo ""
        echo "Build Options:"
        echo "  -b, --backend         Build backend only"
        echo "  -f, --frontend        Build frontend only"
        echo "  -w, --worker          Build worker only"
        echo "  -a, --all             Build all components (default if no component specified)"
        echo ""
        echo "Tag Options:"
        echo "  -t, --tag TAG         Specify tag for all images (defaults: backend=latest, frontend=prod, worker=latest)"
        echo ""
        echo "Deployment Options:"
        echo "  -d, --deploy          Force ECS deployment after build"
        echo ""
        echo "Cache Control Options:"
        echo "  --reuse-builder       Reuse existing Docker builder if available (better local caching)"
        echo "  --fresh-builder       Use a fresh builder for each component (default)"
        echo "  --use-cache           Use registry cache by pulling latest image (default)"
        echo "  --no-cache            Don't use registry cache"
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
  # Clean dist directory before building to prevent stale built files from being included
  log "Cleaning frontend dist directory..."
  rm -rf "$PROJECT_ROOT/frontend/app/dist"
  
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
