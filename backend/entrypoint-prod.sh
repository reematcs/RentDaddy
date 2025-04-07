#!/bin/sh
set -e

echo "[ENTRYPOINT-PROD] Backend starting..."

# In production, environment variables should be provided by the environment
# (e.g., container platform, Kubernetes, etc.)

echo "[ENTRYPOINT-PROD] POSTGRES_HOST: $POSTGRES_HOST"
echo "[ENTRYPOINT-PROD] POSTGRES_USER: $POSTGRES_USER"
echo "[ENTRYPOINT-PROD] POSTGRES_DB: $POSTGRES_DB"
echo "[ENTRYPOINT-PROD] PORT: $PORT"

# Set up database connection string
export PG_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:5432/${POSTGRES_DB}?sslmode=disable"

# The postgres service in docker-compose already has a healthcheck,
# but we'll add a quick check to make sure our connection works
echo "Verifying PostgreSQL connection..."
attempt=0
max_attempts=30

# First try connecting to postgres default database to ensure the server is up
until PGPASSWORD="$POSTGRES_PASSWORD" psql -h ${POSTGRES_HOST} -U "$POSTGRES_USER" -d "postgres" -c '\q' > /dev/null 2>&1 || [ $attempt -eq $max_attempts ]; do
  attempt=$((attempt+1))
  echo "PostgreSQL connection attempt $attempt/$max_attempts"
  sleep 2
done

if [ $attempt -eq $max_attempts ]; then
  echo "Error: Could not connect to PostgreSQL after multiple attempts"
  exit 1
fi

# Create the database if it doesn't exist
echo "Ensuring database ${POSTGRES_DB} exists..."
PGPASSWORD="$POSTGRES_PASSWORD" psql -h ${POSTGRES_HOST} -U "$POSTGRES_USER" -d postgres -c "SELECT 1 FROM pg_database WHERE datname = '${POSTGRES_DB}'" | grep -q 1 || \
  PGPASSWORD="$POSTGRES_PASSWORD" psql -h ${POSTGRES_HOST} -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE ${POSTGRES_DB}"

# Now connect to the application database to verify it
attempt=0
until PGPASSWORD="$POSTGRES_PASSWORD" psql -h ${POSTGRES_HOST} -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c '\q' > /dev/null 2>&1 || [ $attempt -eq $max_attempts ]; do
  attempt=$((attempt+1))
  echo "Application database connection attempt $attempt/$max_attempts"
  sleep 2
done

if [ $attempt -eq $max_attempts ]; then
  echo "Error: Could not connect to application database after multiple attempts"
  exit 1
fi

echo "Running database migrations..."
cd /app
# Create migrations directory if it doesn't exist
mkdir -p /app/internal/db/migrations

# Run the migrations
set +e

# Check if task command is available
if command -v task >/dev/null 2>&1; then
    echo "Using Task CLI for migrations..."
    # First attempt with Task CLI (preferred method)
    cd /app && task migrate:up
    MIGRATION_STATUS=$?
    
    # If Task failed, try with direct migrate command
    if [ $MIGRATION_STATUS -ne 0 ]; then
        echo "Task migration failed, trying with direct migrate command..."
        PGPASSWORD="$POSTGRES_PASSWORD" migrate -path /app/internal/db/migrations -database "$PG_URL" -verbose up
        MIGRATION_STATUS=$?
    fi
else
    echo "Task command not found, using direct migrate command..."
    # Try direct migrate command first
    PGPASSWORD="$POSTGRES_PASSWORD" migrate -path /app/internal/db/migrations -database "$PG_URL" -verbose up
    MIGRATION_STATUS=$?
    
    # If direct migrate failed and Task not found, install Task
    if [ $MIGRATION_STATUS -ne 0 ]; then
        echo "Direct migration failed, installing Task CLI..."
        
        # Install Task CLI
        wget -O task.tar.gz https://github.com/go-task/task/releases/download/v3.33.1/task_linux_amd64.tar.gz && \
        tar -xzvf task.tar.gz && \
        mv task /usr/local/bin/task && \
        chmod +x /usr/local/bin/task && \
        rm task.tar.gz
        
        # Try migration with Task
        echo "Running migrations with newly installed Task CLI..."
        cd /app && task migrate:up
        MIGRATION_STATUS=$?
    fi
fi

# Check final migration status
if [ $MIGRATION_STATUS -ne 0 ]; then
    echo "❌ ERROR: All migration attempts failed!"
    
    # Try to get migration status
    echo "Checking current migration status..."
    PGPASSWORD="$POSTGRES_PASSWORD" migrate -path /app/internal/db/migrations -database "$PG_URL" version
    
    # Check if database is dirty
    DIRTY_STATUS=$(PGPASSWORD="$POSTGRES_PASSWORD" migrate -path /app/internal/db/migrations -database "$PG_URL" version | grep -c "dirty")
    if [ $DIRTY_STATUS -gt 0 ]; then
        echo "Database appears to be in a dirty state. Attempting to fix..."
        PGPASSWORD="$POSTGRES_PASSWORD" migrate -path /app/internal/db/migrations -database "$PG_URL" force 1
        echo "Retrying migrations after force-fixing dirty state..."
        cd /app && task migrate:up
    else
        echo "Database is not in a dirty state, but migrations still failed."
    fi
else
    echo "✅ Database migrations completed successfully."
fi

set -e

# Create config directory if it doesn't exist
mkdir -p /app/config

# Execute the Go application
# Ensure the environment is set up for Go scripts if Go is available
if command -v go >/dev/null 2>&1; then
  echo "Setting up Go environment..."
  export GO111MODULE=on
  export GOPATH="/go"
  export PATH=$PATH:$GOPATH/bin
  
  # Set up symbolic links for module resolution
  echo "Setting up module path structure..."
  mkdir -p $GOPATH/src/github.com/careecodes
  ln -sf /app $GOPATH/src/github.com/careecodes/RentDaddy
  
  # Ensure the vendor directory permissions are correct
  echo "Ensuring vendor directory permissions..."
  chmod -R 755 /app/vendor 2>/dev/null || true
  
  # Set up symlinks to internal packages to ensure they're available for scripts
  echo "Setting up internal packages in vendor directory..."
  mkdir -p /app/vendor/github.com/careecodes/RentDaddy/
  
  # Remove existing directory or symlink if it exists
  echo "Checking for existing internal directory or symlink..."
  if [ -e "/app/vendor/github.com/careecodes/RentDaddy/internal" ]; then
    echo "Found existing internal directory or symlink, removing it..."
    rm -rf /app/vendor/github.com/careecodes/RentDaddy/internal
  fi
  
  # Create symlinks to internal directories
  echo "Creating symlinks for internal packages..."
  ln -sfn /app/internal /app/vendor/github.com/careecodes/RentDaddy/
  
  # Add symlink for pkg directory if it doesn't exist
  if [ ! -e "/app/vendor/github.com/careecodes/RentDaddy/pkg" ]; then
    echo "Setting up pkg package symlink..."
    ln -sfn /app/pkg /app/vendor/github.com/careecodes/RentDaddy/
  fi
  
  # Create symlink for utils package to ensure it's available for scripts
  if [ ! -e "/app/vendor/github.com/careecodes/RentDaddy/internal/utils" ]; then
    echo "Ensuring internal/utils directory exists..."
    mkdir -p /app/internal/utils
  fi
  
  # Verify the symlinks were created correctly
  echo "Verifying symlink creation..."
  if [ -L "/app/vendor/github.com/careecodes/RentDaddy/internal" ] && [ -d "/app/internal/utils" ]; then
    echo "✅ Symlinks created successfully"
    ls -la /app/vendor/github.com/careecodes/RentDaddy/
    ls -la /app/vendor/github.com/careecodes/RentDaddy/internal/
    
    # Check if utils directory is accessible through symlink
    if [ -d "/app/vendor/github.com/careecodes/RentDaddy/internal/utils" ]; then
      echo "✅ internal/utils directory is accessible through symlink"
    else
      echo "❌ internal/utils directory is not accessible through symlink"
      exit 1
    fi
  else
    echo "❌ Failed to create symlinks"
    ls -la /app/vendor/github.com/careecodes/RentDaddy/
    exit 1
  fi
  
  # Ensure vendor directory is consistent
  echo "Ensuring vendor directory is consistent..."
  if [ -d "/app/vendor" ]; then
    # Fix vendor consistency issues by regenerating the vendor directory
    echo "Regenerating vendor directory for consistency..."
    cd /app && go mod vendor
    if [ $? -ne 0 ]; then
      echo "❌ Failed to run go mod vendor, trying to fix..."
      # If vendor fails, try removing vendor directory and recreating
      rm -rf /app/vendor
      go mod vendor
    fi
  else
    echo "Creating vendor directory..."
    cd /app && go mod vendor
  fi
  
  # Install necessary packages for scripts
  echo "Installing dependencies for scripts..."
  go mod download github.com/bxcodec/faker/v4
  go mod download github.com/clerk/clerk-sdk-go/v2
else
  echo "Go not found, skipping module dependencies - continuing with server startup..."
fi

echo "Starting Go server..."
exec /app/server
