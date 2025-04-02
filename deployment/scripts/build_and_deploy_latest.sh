#!/bin/bash
set -e

# Log function for better output
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to load environment variables from a file
load_env() {
  local env_file="$1"
  if [ -f "$env_file" ]; then
    log "Loading environment variables from $env_file"
    set -a # automatically export all variables
    source "$env_file"
    set +a
  else
    log "Warning: Environment file $env_file not found!"
    return 1
  fi
}

# Function to authenticate with AWS ECR
ecr_login() {
  log "Logging in to Amazon ECR..."
  aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
}

# Function to build and push backend
build_backend() {
  local tag="${1:-latest}"
  log "Building backend with tag: $tag"
  
  # Load backend environment variables
  load_env "./backend/.env.production.local"
  
  # Ensure required variables are set
  if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$AWS_REGION" ]; then
    log "Error: AWS_ACCOUNT_ID and AWS_REGION must be set in backend/.env.production.local"
    exit 1
  fi
  
  log "Starting backend build..."
  
  # Record the start time
  local start_time=$(date +%s)
  
  # Build and push backend
  docker buildx build \
    --platform linux/amd64 \
    -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/rentdaddy/backend:$tag \
    -f ./backend/Dockerfile.prod \
    --push \
    ./backend | tee backend-build.log
  
  # Calculate build duration
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  log "Backend build completed in ${duration}s"
  
  log "Backend image pushed to: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/rentdaddy/backend:$tag"
}

# Function to build and push frontend
build_frontend() {
  local tag="${1:-prod}"
  log "Building frontend with tag: $tag"
  
  # Load frontend environment variables
  load_env "./frontend/app/.env.production.local"
  
  # Ensure required variables are set
  if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$AWS_REGION" ]; then
    log "Error: AWS_ACCOUNT_ID and AWS_REGION must be set in frontend/app/.env.production.local"
    exit 1
  fi
  
  if [ -z "$VITE_CLERK_PUBLISHABLE_KEY" ] || [ -z "$VITE_BACKEND_URL" ]; then
    log "Error: VITE_CLERK_PUBLISHABLE_KEY and VITE_BACKEND_URL must be set in frontend/app/.env.production.local"
    exit 1
  fi
  
  log "Starting frontend build..."
  
  # Record the start time
  local start_time=$(date +%s)
  
  # Build and push frontend
  docker buildx build \
    --platform linux/amd64 \
    --progress=plain \
    --build-arg VITE_CLERK_PUBLISHABLE_KEY="$VITE_CLERK_PUBLISHABLE_KEY" \
    --build-arg VITE_BACKEND_URL="$VITE_BACKEND_URL" \
    --build-arg VITE_DOCUMENSO_PUBLIC_URL="${VITE_DOCUMENSO_PUBLIC_URL:-https://docs.curiousdev.net}" \
    --build-arg VITE_ENV="${VITE_ENV:-production}" \
    -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/rentdaddy/frontend:$tag \
    -f ./frontend/app/Dockerfile.prod \
    --push \
    ./frontend/app | tee frontend-build.log
  
  # Calculate build duration
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  log "Frontend build completed in ${duration}s"
  
  log "Frontend image pushed to: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/rentdaddy/frontend:$tag"
}

# Function to force new deployment
force_deployment() {
  log "Forcing new deployment of all services..."
  
  # Ensure AWS credentials are set
  if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$AWS_REGION" ]; then
    log "Loading AWS configuration for deployment..."
    # Try loading from backend env first, then frontend
    if ! load_env "./backend/.env.production.local"; then
      if ! load_env "./frontend/app/.env.production.local"; then
        log "Error: Could not load AWS configuration for deployment"
        exit 1
      fi
    fi
  fi
  
  # Create directory to store deployment info
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local deploy_dir="./deployment/simplified_terraform/ecs_deployment_$timestamp"
  mkdir -p "$deploy_dir"
  
  # Force new deployment for all services
  for svc_arn in $(aws ecs list-services --cluster rentdaddy-cluster --query "serviceArns[]" --output text); do
    local svc_name=$(basename "$svc_arn")
    log "📦 Forcing new deployment for $svc_name..."
    aws ecs update-service \
      --cluster rentdaddy-cluster \
      --service "$svc_name" \
      --force-new-deployment \
      > "$deploy_dir/${svc_name}.json"
  done
  
  log "All deployments have been initiated. Check AWS ECS console for status."
}

# Display help
show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -b, --backend    Build and push backend image only"
  echo "  -f, --frontend   Build and push frontend image only"
  echo "  -a, --all        Build and push both backend and frontend images (default)"
  echo "  -d, --deploy     Force new deployment after building"
  echo "  -t, --tag TAG    Specify a custom tag (default: latest for backend, prod for frontend)"
  echo "  -h, --help       Show this help message"
  echo ""
  echo "Example:"
  echo "  $0 --all --deploy         # Build both and deploy"
  echo "  $0 --backend --tag v1.2.0 # Build backend only with specific tag"
  echo ""
  echo "Note: This script loads environment variables from:"
  echo "  - ./backend/.env.production.local (for backend builds)"
  echo "  - ./frontend/app/.env.production.local (for frontend builds)"
  echo ""
  echo "Required variables in the environment files:"
  echo "  - AWS_ACCOUNT_ID: Your AWS account ID"
  echo "  - AWS_REGION: AWS region (e.g., us-east-2)"
  echo "  - VITE_CLERK_PUBLISHABLE_KEY: Clerk publishable key (for frontend)"
  echo "  - VITE_BACKEND_URL: Backend URL (for frontend)"
}

# Default values
BUILD_BACKEND=false
BUILD_FRONTEND=false
DEPLOY=false
BACKEND_TAG="latest"
FRONTEND_TAG="prod"

# Parse command line arguments
if [ $# -eq 0 ]; then
  # Default behavior if no args: build all
  BUILD_BACKEND=true
  BUILD_FRONTEND=true
else
  while [ $# -gt 0 ]; do
    case "$1" in
      -b|--backend)
        BUILD_BACKEND=true
        shift
        ;;
      -f|--frontend)
        BUILD_FRONTEND=true
        shift
        ;;
      -a|--all)
        BUILD_BACKEND=true
        BUILD_FRONTEND=true
        shift
        ;;
      -d|--deploy)
        DEPLOY=true
        shift
        ;;
      -t|--tag)
        BACKEND_TAG="$2"
        FRONTEND_TAG="$2"
        shift 2
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
fi

# Go to project root directory
cd "$(dirname "$0")/.."
log "Working directory: $(pwd)"

# Login to ECR before building
if [ "$BUILD_BACKEND" = true ] || [ "$BUILD_FRONTEND" = true ]; then
  # We'll load variables and perform login in the build functions
  true
fi

# Build the specified components
if [ "$BUILD_BACKEND" = true ]; then
  build_backend $BACKEND_TAG
fi

if [ "$BUILD_FRONTEND" = true ]; then
  build_frontend $FRONTEND_TAG
fi

# Force deployment if requested
if [ "$DEPLOY" = true ]; then
  force_deployment
fi

log "Build and deployment process completed successfully!"