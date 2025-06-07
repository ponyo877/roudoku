#!/bin/bash

# Roudoku Health Check Script
# Verifies that all services are running correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DB_CONTAINER_NAME="roudoku-postgres"
DB_PORT="5432"
SERVER_PORT="8080"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Function to check if port is accessible
check_port() {
    local host=$1
    local port=$2
    local service_name=$3
    
    if nc -z "$host" "$port" 2>/dev/null; then
        print_success "$service_name is accessible on $host:$port"
        return 0
    else
        print_error "$service_name is NOT accessible on $host:$port"
        return 1
    fi
}

# Function to check HTTP endpoint
check_http() {
    local url=$1
    local service_name=$2
    
    if curl -s "$url" >/dev/null 2>&1; then
        print_success "$service_name HTTP endpoint is responding: $url"
        return 0
    else
        print_error "$service_name HTTP endpoint is NOT responding: $url"
        return 1
    fi
}

# Function to check Docker container
check_container() {
    local container_name=$1
    
    if docker ps --format "table {{.Names}}" | grep -q "^$container_name$"; then
        print_success "Docker container '$container_name' is running"
        return 0
    else
        print_error "Docker container '$container_name' is NOT running"
        return 1
    fi
}

# Function to check Flutter devices
check_flutter_devices() {
    local device_count=$(flutter devices --machine 2>/dev/null | jq -r '. | length' 2>/dev/null || echo "0")
    
    if [ "$device_count" -gt 0 ]; then
        print_success "Flutter has $device_count device(s) available"
        flutter devices 2>/dev/null | head -10
        return 0
    else
        print_warning "No Flutter devices found"
        return 1
    fi
}

# Main health check function
main() {
    echo "=============================================="
    echo "🏥 Roudoku Health Check"
    echo "=============================================="
    echo ""
    
    local overall_status=0
    
    # Check 1: Docker
    print_status "Checking Docker..."
    if command -v docker >/dev/null 2>&1; then
        print_success "Docker is installed"
        if docker info >/dev/null 2>&1; then
            print_success "Docker daemon is running"
        else
            print_error "Docker daemon is not running"
            overall_status=1
        fi
    else
        print_error "Docker is not installed"
        overall_status=1
    fi
    echo ""
    
    # Check 2: Database
    print_status "Checking PostgreSQL database..."
    if check_container "$DB_CONTAINER_NAME"; then
        check_port "localhost" "$DB_PORT" "PostgreSQL"
        
        # Test database connection
        if docker exec "$DB_CONTAINER_NAME" pg_isready -U roudoku >/dev/null 2>&1; then
            print_success "Database connection is healthy"
        else
            print_error "Database connection failed"
            overall_status=1
        fi
    else
        overall_status=1
    fi
    echo ""
    
    # Check 3: Go Server
    print_status "Checking Go server..."
    if check_port "localhost" "$SERVER_PORT" "Go server"; then
        # Test health endpoint if it exists
        if check_http "http://localhost:$SERVER_PORT/health" "Go server"; then
            true  # Already printed success
        elif check_http "http://localhost:$SERVER_PORT/" "Go server"; then
            print_warning "Health endpoint not found, but server is responding"
        else
            print_error "Go server is not responding to HTTP requests"
            overall_status=1
        fi
    else
        overall_status=1
    fi
    echo ""
    
    # Check 4: Flutter Environment
    print_status "Checking Flutter environment..."
    if command -v flutter >/dev/null 2>&1; then
        print_success "Flutter is installed"
        
        # Check Flutter doctor
        if flutter doctor --machine >/dev/null 2>&1; then
            print_success "Flutter doctor passed"
        else
            print_warning "Flutter doctor has issues (run 'flutter doctor' for details)"
        fi
        
        # Check available devices
        check_flutter_devices
    else
        print_error "Flutter is not installed"
        overall_status=1
    fi
    echo ""
    
    # Check 5: Go Environment
    print_status "Checking Go environment..."
    if command -v go >/dev/null 2>&1; then
        print_success "Go is installed ($(go version | cut -d' ' -f3))"
        
        # Check Go modules in server directory
        if [ -f "/Users/ponyo877/Documents/workspace/roudoku/server/go.mod" ]; then
            print_success "Go modules configuration found"
        else
            print_warning "Go modules configuration not found"
        fi
    else
        print_error "Go is not installed"
        overall_status=1
    fi
    echo ""
    
    # Check 6: Project Structure
    print_status "Checking project structure..."
    local project_root="/Users/ponyo877/Documents/workspace/roudoku"
    
    if [ -d "$project_root/mobile" ]; then
        print_success "Mobile directory exists"
    else
        print_error "Mobile directory not found"
        overall_status=1
    fi
    
    if [ -d "$project_root/server" ]; then
        print_success "Server directory exists"
    else
        print_error "Server directory not found"
        overall_status=1
    fi
    
    if [ -f "$project_root/mobile/pubspec.yaml" ]; then
        print_success "Flutter pubspec.yaml found"
    else
        print_error "Flutter pubspec.yaml not found"
        overall_status=1
    fi
    
    if [ -f "$project_root/server/go.mod" ]; then
        print_success "Go go.mod found"
    else
        print_error "Go go.mod not found"
        overall_status=1
    fi
    echo ""
    
    # Check 7: Network Connectivity
    print_status "Checking network connectivity..."
    if ping -c 1 google.com >/dev/null 2>&1; then
        print_success "Internet connectivity is available"
    else
        print_warning "Internet connectivity issues (may affect package downloads)"
    fi
    echo ""
    
    # Check 8: System Resources
    print_status "Checking system resources..."
    
    # Check available disk space (minimum 1GB)
    available_space=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$available_space" -gt 1 ]; then
        print_success "Sufficient disk space available (${available_space}GB)"
    else
        print_warning "Low disk space (${available_space}GB available)"
    fi
    
    # Check memory (basic check)
    if command -v free >/dev/null 2>&1; then
        available_memory=$(free -m | awk 'NR==2{printf "%.0f", $7}')
        if [ "$available_memory" -gt 1000 ]; then
            print_success "Sufficient memory available (${available_memory}MB)"
        else
            print_warning "Low memory available (${available_memory}MB)"
        fi
    elif command -v vm_stat >/dev/null 2>&1; then
        # macOS memory check
        free_pages=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        if [ ! -z "$free_pages" ] && [ "$free_pages" -gt 250000 ]; then
            print_success "Sufficient memory available"
        else
            print_warning "Memory may be limited"
        fi
    fi
    echo ""
    
    # Summary
    echo "=============================================="
    if [ $overall_status -eq 0 ]; then
        echo -e "${GREEN}🎉 All health checks passed!${NC}"
        echo ""
        echo "Your Roudoku development environment is ready to use."
        echo "You can start the environment with:"
        echo "  ./scripts/start-local-env.sh"
    else
        echo -e "${RED}❌ Some health checks failed!${NC}"
        echo ""
        echo "Please fix the issues above before starting the environment."
        echo "Common solutions:"
        echo "  - Install missing tools (Docker, Go, Flutter)"
        echo "  - Start Docker daemon"
        echo "  - Check network connectivity"
        echo "  - Free up disk space if needed"
    fi
    echo "=============================================="
    echo ""
    
    exit $overall_status
}

# Run main function
main "$@"