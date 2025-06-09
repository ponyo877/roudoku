#!/bin/bash
# Database setup and migration script for Aozora StoryWalk

set -e

# Configuration
PROJECT_ID="${PROJECT_ID:-gke-test-287910}"
REGION="${REGION:-asia-northeast1}"
DB_INSTANCE="${DB_INSTANCE:-roudoku-db}"
DB_NAME="${DB_NAME:-roudoku}"
DB_USER="${DB_USER:-roudoku-user}"

echo "Setting up database for Aozora StoryWalk..."

# Check if Cloud SQL Admin API is enabled
if ! gcloud services list --enabled | grep -q sqladmin.googleapis.com; then
    echo "Enabling Cloud SQL Admin API..."
    gcloud services enable sqladmin.googleapis.com
fi

# Get the database instance connection name
CONNECTION_NAME=$(gcloud sql instances describe $DB_INSTANCE \
    --project=$PROJECT_ID \
    --format="value(connectionName)" 2>/dev/null || echo "")

if [ -z "$CONNECTION_NAME" ]; then
    echo "Error: Database instance $DB_INSTANCE not found"
    echo "Please run Terraform first to create the infrastructure"
    exit 1
fi

echo "Database instance found: $CONNECTION_NAME"

# Install migrate tool if not present
if ! command -v migrate &> /dev/null; then
    echo "Installing golang-migrate..."
    curl -L https://github.com/golang-migrate/migrate/releases/download/v4.16.2/migrate.darwin.amd64.tar.gz | tar xvz
    sudo mv migrate /usr/local/bin/
fi

# Get database password from Secret Manager
DB_PASS=$(gcloud secrets versions access latest --secret="roudoku-db-pass" --project=$PROJECT_ID 2>/dev/null || echo "")

if [ -z "$DB_PASS" ]; then
    echo "Error: Database password not found in Secret Manager"
    echo "Please ensure Terraform has been applied successfully"
    exit 1
fi

# Start Cloud SQL Proxy
echo "Starting Cloud SQL Proxy..."
cloud_sql_proxy -instances=$CONNECTION_NAME=tcp:5432 &
PROXY_PID=$!

# Wait for proxy to start
sleep 5

# Run migrations
echo "Running database migrations..."
migrate -path ../server/migrations \
    -database "postgres://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME?sslmode=disable" \
    up

# Create pgvector extension
echo "Creating pgvector extension..."
PGPASSWORD=$DB_PASS psql -h localhost -U $DB_USER -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Stop Cloud SQL Proxy
kill $PROXY_PID

echo "Database setup complete!"
echo ""
echo "Database connection details:"
echo "  Instance: $CONNECTION_NAME"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: Stored in Secret Manager (roudoku-db-pass)"