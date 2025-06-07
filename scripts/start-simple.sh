#!/bin/bash

# Roudoku Simple Local Development Startup Script
# Uses Docker Compose for database and runs server/mobile locally

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
    
    # Stop Docker Compose services
    print_status "Stopping Docker services..."
    cd "$PROJECT_ROOT"
    docker compose -f docker-compose.local.yml stop 2>/dev/null || true
    
    print_status "Cleanup complete"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT INT TERM

# Main function
main() {
    echo "=============================================="
    echo "🚀 Roudoku Simple Local Environment"
    echo "=============================================="
    echo ""

    cd "$PROJECT_ROOT"

    # Step 1: Start Database with Docker Compose
    print_status "Step 1: Starting database with Docker Compose..."
    
    if ! command -v docker compose >/dev/null 2>&1; then
        print_error "docker compose is not installed"
        exit 1
    fi
    
    # Start database
    docker compose -f docker-compose.local.yml up -d postgres
    
    # Wait for database to be healthy
    print_status "Waiting for database to be ready..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if docker compose -f docker-compose.local.yml exec -T postgres pg_isready -U roudoku -d roudoku >/dev/null 2>&1; then
            print_success "Database is ready!"
            break
        fi
        echo -n "."
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        print_error "Database failed to start"
        exit 1
    fi
    
    echo ""

    # Step 2: Start Go Server
    print_status "Step 2: Starting Go server..."
    
    cd "$SERVER_DIR"
    
    # Set environment variables
    export DB_HOST="localhost"
    export DB_PORT="5432"
    export DB_NAME="roudoku"
    export DB_USER="roudoku"
    export DB_PASSWORD="roudoku_local_password"
    export SERVER_PORT="$SERVER_PORT"
    export GIN_MODE="debug"
    
    # Install dependencies and start server
    print_status "Installing Go dependencies..."
    go mod tidy
    
    print_status "Starting Go server on port $SERVER_PORT..."
    go run cmd/server/main.go &
    SERVER_PID=$!
    
    # Wait for server to be ready
    print_status "Waiting for Go server to be ready..."
    timeout=30
    while [ $timeout -gt 0 ]; do
        if curl -s http://localhost:$SERVER_PORT/api/v1/health >/dev/null 2>&1; then
            print_success "Go server is ready!"
            break
        fi
        echo -n "."
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        print_warning "Go server may not be ready yet"
    fi
    
    echo ""

    # Step 3: Start Flutter App
    print_status "Step 3: Preparing Flutter mobile app..."
    
    cd "$MOBILE_DIR"
    
    # Install dependencies
    print_status "Installing Flutter dependencies..."
    flutter pub get
    
    # Generate code
    print_status "Generating code..."
    dart run build_runner build --delete-conflicting-outputs || {
        print_warning "Code generation had issues, but continuing..."
    }
    
    # Check for devices
    print_status "Checking for available devices..."
    device_count=$(flutter devices --machine 2>/dev/null | jq -r '. | length' 2>/dev/null || echo "0")
    
    if [ "$device_count" -eq 0 ]; then
        print_warning "No devices found. Please start an emulator or connect a device."
        print_status "Available emulators:"
        flutter emulators 2>/dev/null || echo "  No emulators found"
        echo ""
        print_status "To create an emulator: flutter emulators --create"
        print_status "To start an emulator: flutter emulators --launch <emulator_id>"
        echo ""
        print_status "You can also run 'flutter run' manually after starting a device"
    else
        print_success "Found $device_count device(s)"
        
        # Start Flutter app
        print_status "Starting Flutter app..."
        flutter run --debug &
        FLUTTER_PID=$!
    fi
    
    echo ""

    # Display status
    echo "=============================================="
    echo "🎉 Development Environment Started!"
    echo "=============================================="
    echo ""
    echo "📊 Services Status:"
    echo "  ✅ Database:     PostgreSQL (Docker)"
    echo "  ✅ API Server:   http://localhost:$SERVER_PORT"
    if [ ! -z "$FLUTTER_PID" ]; then
        echo "  ✅ Mobile App:   Starting on device/emulator"
    else
        echo "  ⚠️  Mobile App:   Ready to start (no device found)"
    fi
    echo ""
    echo "🔗 Useful URLs:"
    echo "  Health Check:   http://localhost:$SERVER_PORT/api/v1/health"
    echo "  Database:       localhost:5432 (roudoku/roudoku)"
    echo ""
    echo "🛠 Commands:"
    echo "  Check health:   ./scripts/health-check.sh"
    echo "  View DB logs:   docker compose -f docker-compose.local.yml logs postgres"
    echo "  DB shell:       docker compose -f docker-compose.local.yml exec postgres psql -U roudoku -d roudoku"
    if [ ! -z "$FLUTTER_PID" ]; then
        echo "  Flutter hot:    Press 'r' in Flutter console for hot reload"
    else
        echo "  Start Flutter:  cd mobile && flutter run"
    fi
    echo ""
    echo "⏹ To stop: Press Ctrl+C"
    echo ""

    # Wait for user interrupt
    print_status "Environment is running. Press Ctrl+C to stop..."
    wait
}

# Run main function
main "$@"