#!/bin/bash

# Roudoku Mobile App Test Script
# Tests basic functionality of the mobile app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project configuration
MOBILE_DIR="/Users/ponyo877/Documents/workspace/roudoku/mobile"
SERVER_URL="http://localhost:8080"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
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

# Function to test API endpoint
test_api_endpoint() {
    local endpoint=$1
    local description=$2
    
    print_status "Testing $description..."
    
    if curl -s -f "$SERVER_URL$endpoint" >/dev/null; then
        print_success "$description is accessible"
        return 0
    else
        print_error "$description is not accessible"
        return 1
    fi
}

# Function to test Flutter commands
test_flutter_command() {
    local command=$1
    local description=$2
    
    print_status "Testing $description..."
    
    cd "$MOBILE_DIR"
    if eval "$command" >/dev/null 2>&1; then
        print_success "$description passed"
        return 0
    else
        print_error "$description failed"
        return 1
    fi
}

# Main test function
main() {
    echo "=============================================="
    echo "🧪 Roudoku Mobile App Tests"
    echo "=============================================="
    echo ""
    
    local test_status=0
    
    # Test 1: Flutter Environment
    print_status "Testing Flutter environment..."
    if command -v flutter >/dev/null 2>&1; then
        print_success "Flutter CLI is available"
        
        # Test Flutter doctor
        if flutter doctor --machine >/dev/null 2>&1; then
            print_success "Flutter doctor passed"
        else
            print_warning "Flutter doctor has issues"
        fi
        
        # Test available devices
        device_count=$(flutter devices --machine 2>/dev/null | jq -r '. | length' 2>/dev/null || echo "0")
        if [ "$device_count" -gt 0 ]; then
            print_success "Flutter devices are available ($device_count found)"
        else
            print_warning "No Flutter devices found"
        fi
    else
        print_error "Flutter CLI not found"
        test_status=1
    fi
    echo ""
    
    # Test 2: Project Structure
    print_status "Testing project structure..."
    
    if [ -d "$MOBILE_DIR" ]; then
        print_success "Mobile directory exists"
    else
        print_error "Mobile directory not found"
        test_status=1
    fi
    
    if [ -f "$MOBILE_DIR/pubspec.yaml" ]; then
        print_success "pubspec.yaml found"
    else
        print_error "pubspec.yaml not found"
        test_status=1
    fi
    
    if [ -f "$MOBILE_DIR/lib/main.dart" ]; then
        print_success "main.dart found"
    else
        print_error "main.dart not found"
        test_status=1
    fi
    echo ""
    
    # Test 3: Dependencies
    print_status "Testing Flutter dependencies..."
    cd "$MOBILE_DIR"
    
    if flutter pub get >/dev/null 2>&1; then
        print_success "Flutter pub get succeeded"
    else
        print_error "Flutter pub get failed"
        test_status=1
    fi
    
    # Check for key dependencies
    if grep -q "firebase_core" pubspec.yaml; then
        print_success "Firebase dependency found"
    else
        print_warning "Firebase dependency not found"
    fi
    
    if grep -q "provider" pubspec.yaml; then
        print_success "Provider dependency found"
    else
        print_warning "Provider dependency not found"
    fi
    
    if grep -q "flutter_tts" pubspec.yaml; then
        print_success "TTS dependency found"
    else
        print_warning "TTS dependency not found"
    fi
    echo ""
    
    # Test 4: Code Generation
    print_status "Testing code generation..."
    
    if dart run build_runner build --delete-conflicting-outputs >/dev/null 2>&1; then
        print_success "Code generation succeeded"
    else
        print_warning "Code generation had issues"
    fi
    echo ""
    
    # Test 5: Flutter Analysis
    print_status "Testing Flutter analysis..."
    
    # Run flutter analyze with limited output
    if flutter analyze --no-pub >/dev/null 2>&1; then
        print_success "Flutter analyze passed"
    else
        print_warning "Flutter analyze found issues"
        print_status "Running limited analysis..."
        flutter analyze --no-pub 2>&1 | head -20
    fi
    echo ""
    
    # Test 6: API Connectivity (if server is running)
    print_status "Testing API connectivity..."
    
    if curl -s "$SERVER_URL/api/v1/health" >/dev/null 2>&1; then
        print_success "API server is accessible"
        
        # Test specific endpoints
        test_api_endpoint "/api/v1/health" "Health endpoint"
        
        # Test if we can create a user (this might fail if not implemented)
        if curl -s -X POST -H "Content-Type: application/json" \
           -d '{"email":"test@example.com","display_name":"Test User"}' \
           "$SERVER_URL/api/v1/users" >/dev/null 2>&1; then
            print_success "User creation endpoint is working"
        else
            print_warning "User creation endpoint may not be fully implemented"
        fi
    else
        print_warning "API server is not accessible (this is OK if not running)"
    fi
    echo ""
    
    # Test 7: Build Test (Android APK)
    print_status "Testing Android build..."
    
    if flutter build apk --debug --no-pub >/dev/null 2>&1; then
        print_success "Android debug build succeeded"
    else
        print_warning "Android debug build failed (check Android SDK setup)"
    fi
    echo ""
    
    # Test 8: Firebase Configuration
    print_status "Testing Firebase configuration..."
    
    if [ -f "$MOBILE_DIR/android/app/google-services.json" ]; then
        print_success "Android Firebase config found"
    else
        print_warning "Android Firebase config not found"
    fi
    
    if [ -f "$MOBILE_DIR/ios/Runner/GoogleService-Info.plist" ]; then
        print_success "iOS Firebase config found"
    else
        print_warning "iOS Firebase config not found"
    fi
    echo ""
    
    # Summary
    echo "=============================================="
    if [ $test_status -eq 0 ]; then
        echo -e "${GREEN}🎉 All critical tests passed!${NC}"
        echo ""
        echo "Your mobile app is ready for development and testing."
        echo ""
        echo "Next steps:"
        echo "  1. Start the environment: ./scripts/start-simple.sh"
        echo "  2. Launch an emulator or connect a device"
        echo "  3. Run: cd mobile && flutter run"
    else
        echo -e "${RED}❌ Some tests failed!${NC}"
        echo ""
        echo "Please fix the critical issues before running the app."
    fi
    echo "=============================================="
    echo ""
    
    # Additional Information
    echo "📱 Mobile App Features to Test:"
    echo "  - Authentication (Google Sign-In & Anonymous)"
    echo "  - Home screen with recommendations"
    echo "  - Swipe interface (Tinder & Facemash modes)"
    echo "  - Book player with TTS"
    echo "  - Profile and settings screens"
    echo "  - Reading analytics and goals"
    echo ""
    echo "🐛 If you encounter issues:"
    echo "  - Check 'flutter doctor' output"
    echo "  - Ensure Android SDK/Xcode is properly installed"
    echo "  - Verify Firebase configuration"
    echo "  - Check API server connectivity"
    echo ""
    
    exit $test_status
}

# Run main function
main "$@"