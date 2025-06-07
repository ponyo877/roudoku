#!/bin/bash

# Roudoku Local Development Environment Startup Script
# This script starts the database, server, and mobile app for local development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE_DIR="$PROJECT_ROOT/mobile"
SERVER_DIR="$PROJECT_ROOT/server"

# Configuration
DB_CONTAINER_NAME="roudoku-postgres"
DB_PORT="5432"
DB_NAME="roudoku"
DB_USER="roudoku"
DB_PASSWORD="roudoku_local_password"
SERVER_PORT="8080"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if port is in use
port_in_use() {
    lsof -i ":$1" >/dev/null 2>&1
}

# Function to check Docker container status
container_running() {
    docker ps --format "table {{.Names}}" | grep -q "^$1$"
}

# Function to wait for service to be ready
wait_for_service() {
    local host=$1
    local port=$2
    local service_name=$3
    local max_attempts=30
    local attempt=1

    print_status "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if nc -z "$host" "$port" 2>/dev/null; then
            print_success "$service_name is ready!"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to start within timeout"
    return 1
}

# Function to cleanup processes on exit
cleanup() {
    print_status "Cleaning up..."
    
    # Kill background processes
    if [ ! -z "$SERVER_PID" ]; then
        print_status "Stopping Go server (PID: $SERVER_PID)"
        kill $SERVER_PID 2>/dev/null || true
    fi
    
    if [ ! -z "$FLUTTER_PID" ]; then
        print_status "Stopping Flutter app (PID: $FLUTTER_PID)"
        kill $FLUTTER_PID 2>/dev/null || true
    fi
    
    print_status "Cleanup complete"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT INT TERM

# Main function
main() {
    echo "=============================================="
    echo "🚀 Roudoku Local Development Environment"
    echo "=============================================="
    echo ""

    # Check prerequisites
    print_status "Checking prerequisites..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command_exists go; then
        print_error "Go is not installed. Please install Go first."
        exit 1
    fi
    
    if ! command_exists flutter; then
        print_error "Flutter is not installed. Please install Flutter first."
        exit 1
    fi
    
    if ! command_exists nc; then
        print_warning "netcat (nc) is not installed. Service readiness checks may not work properly."
    fi
    
    print_success "All prerequisites are available"
    echo ""

    # Step 1: Start PostgreSQL Database
    print_status "Step 1: Starting PostgreSQL database..."
    
    if container_running "$DB_CONTAINER_NAME"; then
        print_warning "Database container is already running"
    else
        # Stop existing container if it exists but not running
        docker rm -f "$DB_CONTAINER_NAME" 2>/dev/null || true
        
        print_status "Starting PostgreSQL container..."
        docker run -d \
            --name "$DB_CONTAINER_NAME" \
            -e POSTGRES_DB="$DB_NAME" \
            -e POSTGRES_USER="$DB_USER" \
            -e POSTGRES_PASSWORD="$DB_PASSWORD" \
            -p "${DB_PORT}:5432" \
            -v roudoku_postgres_data:/var/lib/postgresql/data \
            postgres:15-alpine
        
        # Wait for database to be ready
        wait_for_service "localhost" "$DB_PORT" "PostgreSQL database"
        
        # Run database migrations
        print_status "Running database migrations..."
        sleep 5  # Give PostgreSQL a bit more time to fully initialize
        
        if [ -f "$SERVER_DIR/migrations/001_initial_schema.sql" ]; then
            docker exec -i "$DB_CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" < "$SERVER_DIR/migrations/001_initial_schema.sql" || {
                print_warning "Migration failed, but continuing..."
            }
        else
            print_warning "Migration file not found, skipping..."
        fi
    fi
    
    print_success "Database is ready"
    echo ""

    # Step 2: Start Go Server
    print_status "Step 2: Starting Go server..."
    
    if port_in_use "$SERVER_PORT"; then
        print_warning "Port $SERVER_PORT is already in use. Stopping existing process..."
        lsof -ti ":$SERVER_PORT" | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
    
    cd "$SERVER_DIR"
    
    # Set environment variables for server
    export DB_HOST="localhost"
    export DB_PORT="$DB_PORT"
    export DB_NAME="$DB_NAME"
    export DB_USER="$DB_USER"
    export DB_PASSWORD="$DB_PASSWORD"
    export SERVER_PORT="$SERVER_PORT"
    export GIN_MODE="debug"
    
    print_status "Installing Go dependencies..."
    go mod tidy
    
    print_status "Starting Go server on port $SERVER_PORT..."
    go run cmd/server/main.go &
    SERVER_PID=$!
    
    # Wait for server to be ready
    wait_for_service "localhost" "$SERVER_PORT" "Go server"
    
    print_success "Go server is ready"
    echo ""

    # Step 3: Start Flutter Mobile App
    print_status "Step 3: Starting Flutter mobile app..."
    
    cd "$MOBILE_DIR"
    
    # Check if emulator is running
    print_status "Checking for available devices..."
    flutter devices --machine > /tmp/flutter_devices.json
    
    if ! grep -q "\"emulator\"" /tmp/flutter_devices.json && ! grep -q "\"device\"" /tmp/flutter_devices.json; then
        print_warning "No emulator or device detected. Starting Android emulator..."
        
        # Try to start an emulator
        if command_exists emulator; then
            # List available AVDs
            avd_list=$(emulator -list-avds 2>/dev/null | head -1)
            if [ ! -z "$avd_list" ]; then
                print_status "Starting emulator: $avd_list"
                emulator -avd "$avd_list" -no-snapshot-load &
                
                # Wait for emulator to be ready
                print_status "Waiting for emulator to boot..."
                flutter devices --machine | grep -q "\"device\"" || {
                    for i in {1..60}; do
                        if flutter devices --machine | grep -q "\"device\""; then
                            break
                        fi
                        echo -n "."
                        sleep 2
                    done
                }
            else
                print_error "No Android AVDs found. Please create an emulator first."
                print_status "You can create one using: flutter emulators --create"
                exit 1
            fi
        else
            print_error "Android emulator not found. Please install Android SDK and create an emulator."
            exit 1
        fi
    fi
    
    # Install Flutter dependencies
    print_status "Installing Flutter dependencies..."
    flutter pub get
    
    # Generate code if needed
    print_status "Generating code..."
    flutter packages pub run build_runner build --delete-conflicting-outputs || {
        print_warning "Code generation failed, but continuing..."
    }
    
    # Start Flutter app
    print_status "Starting Flutter app..."
    flutter run --debug --hot &
    FLUTTER_PID=$!
    
    print_success "Flutter app is starting..."
    echo ""

    # Step 4: Display information
    echo "=============================================="
    echo "🎉 Local Environment Started Successfully!"
    echo "=============================================="
    echo ""
    echo "📊 Service Information:"
    echo "  Database:     PostgreSQL on localhost:$DB_PORT"
    echo "  Server:       Go API on http://localhost:$SERVER_PORT"
    echo "  Mobile App:   Flutter (check emulator/device)"
    echo ""
    echo "🔗 Useful URLs:"
    echo "  API Health:   http://localhost:$SERVER_PORT/health"
    echo "  API Docs:     http://localhost:$SERVER_PORT/docs (if available)"
    echo ""
    echo "📱 Mobile App Features:"
    echo "  - Authentication (Google Sign-In & Anonymous)"
    echo "  - Book recommendations"
    echo "  - Swipe interface (Tinder & Facemash modes)"
    echo "  - Text-to-Speech playback"
    echo "  - Reading analytics"
    echo "  - Real-time notifications"
    echo ""
    echo "🛠 Development Commands:"
    echo "  View logs:    docker logs $DB_CONTAINER_NAME"
    echo "  DB shell:     docker exec -it $DB_CONTAINER_NAME psql -U $DB_USER -d $DB_NAME"
    echo "  Flutter hot:  Press 'r' in Flutter terminal for hot reload"
    echo "  Flutter rest: Press 'R' in Flutter terminal for hot restart"
    echo ""
    echo "⏹ To stop: Press Ctrl+C"
    echo ""

    # Wait for user interrupt
    print_status "Environment is running. Press Ctrl+C to stop..."
    wait
}

# Run main function
main "$@"