# Roudoku Development Scripts

This directory contains scripts to help you set up and run the Roudoku development environment locally.

## 📋 Prerequisites

Before running any scripts, make sure you have the following installed:

- **Docker & Docker Compose**: For running PostgreSQL database
- **Go 1.19+**: For running the backend server
- **Flutter 3.0+**: For running the mobile app
- **Android SDK** or **Xcode**: For mobile app development
- **netcat (nc)**: For port checking (usually pre-installed on macOS/Linux)

## 🚀 Quick Start

### 1. Health Check (Recommended First Step)
```bash
./scripts/health-check.sh
```
This script checks if all prerequisites are installed and properly configured.

### 2. Simple Startup (Recommended)
```bash
./scripts/start-simple.sh
```
Starts the development environment using Docker Compose for the database and runs server/mobile locally.

### 3. Full Startup (Alternative)
```bash
./scripts/start-local-env.sh
```
Comprehensive startup script that manages all services including emulator startup.

### 4. Test Mobile App
```bash
./scripts/test-mobile.sh
```
Tests the mobile app setup and functionality.

## 📄 Script Details

### health-check.sh
**Purpose**: Comprehensive system health check  
**What it does**:
- Verifies all prerequisites are installed
- Checks Docker daemon status
- Tests database connectivity
- Validates Flutter environment
- Checks available devices/emulators
- Verifies project structure
- Tests network connectivity
- Monitors system resources

**Usage**:
```bash
./scripts/health-check.sh
```

**Exit codes**:
- `0`: All checks passed
- `1`: Some checks failed

### start-simple.sh
**Purpose**: Simple development environment startup  
**What it does**:
- Starts PostgreSQL using Docker Compose
- Runs Go server locally (port 8080)
- Prepares Flutter app for development
- Sets up proper environment variables
- Provides development URLs and commands

**Usage**:
```bash
./scripts/start-simple.sh
```

**Services started**:
- PostgreSQL: `localhost:5432`
- Go API Server: `http://localhost:8080`
- Flutter App: Ready to run (requires device/emulator)

**Environment variables set**:
```bash
DB_HOST=localhost
DB_PORT=5432
DB_NAME=roudoku
DB_USER=roudoku
DB_PASSWORD=roudoku_local_password
SERVER_PORT=8080
GIN_MODE=debug
```

### start-local-env.sh
**Purpose**: Comprehensive development environment startup  
**What it does**:
- Starts PostgreSQL database in Docker
- Runs database migrations
- Starts Go server
- Attempts to start Android emulator
- Runs Flutter app automatically
- Provides detailed status information

**Usage**:
```bash
./scripts/start-local-env.sh
```

**Additional features**:
- Automatic emulator detection and startup
- Database migration execution
- Comprehensive error handling
- Detailed logging and status updates

### test-mobile.sh
**Purpose**: Mobile app functionality testing  
**What it does**:
- Tests Flutter environment
- Validates project structure
- Checks dependencies
- Runs code generation
- Performs Flutter analysis
- Tests API connectivity
- Attempts debug build
- Verifies Firebase configuration

**Usage**:
```bash
./scripts/test-mobile.sh
```

**Test categories**:
- Flutter Environment
- Project Structure
- Dependencies
- Code Generation
- Static Analysis
- API Connectivity
- Build Process
- Firebase Setup

## 🗄️ Database Management

### Using Docker Compose
```bash
# Start database only
docker-compose -f docker-compose.local.yml up -d postgres

# View database logs
docker-compose -f docker-compose.local.yml logs postgres

# Access database shell
docker-compose -f docker-compose.local.yml exec postgres psql -U roudoku -d roudoku

# Stop database
docker-compose -f docker-compose.local.yml down
```

### Manual Database Commands
```bash
# Connect to database
docker exec -it roudoku-postgres psql -U roudoku -d roudoku

# Run migration manually
docker exec -i roudoku-postgres psql -U roudoku -d roudoku < server/migrations/001_initial_schema.sql

# Check database status
docker exec roudoku-postgres pg_isready -U roudoku -d roudoku
```

## 📱 Mobile Development

### Device/Emulator Setup
```bash
# List available devices
flutter devices

# List available emulators
flutter emulators

# Create new emulator
flutter emulators --create

# Launch specific emulator
flutter emulators --launch <emulator_id>
```

### Flutter Commands
```bash
# Install dependencies
cd mobile && flutter pub get

# Generate code
cd mobile && dart run build_runner build --delete-conflicting-outputs

# Run app
cd mobile && flutter run

# Hot reload (in Flutter console)
# Press 'r' for hot reload
# Press 'R' for hot restart
# Press 'q' to quit
```

## 🔧 Troubleshooting

### Common Issues

**1. Port already in use**
```bash
# Check what's using port 8080
lsof -i :8080

# Kill process using port
kill -9 $(lsof -ti :8080)
```

**2. Database connection issues**
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Restart database
docker-compose -f docker-compose.local.yml restart postgres

# Check database logs
docker-compose -f docker-compose.local.yml logs postgres
```

**3. Flutter device issues**
```bash
# Check Flutter setup
flutter doctor

# List devices
flutter devices

# Cold boot emulator
emulator -avd <avd_name> -wipe-data
```

**4. Go server issues**
```bash
# Check Go installation
go version

# Check module dependencies
cd server && go mod tidy

# Run with verbose logging
cd server && GIN_MODE=debug go run cmd/server/main.go
```

### Environment Variables

The scripts set these environment variables:

| Variable | Value | Description |
|----------|-------|-------------|
| `DB_HOST` | localhost | Database host |
| `DB_PORT` | 5432 | Database port |
| `DB_NAME` | roudoku | Database name |
| `DB_USER` | roudoku | Database user |
| `DB_PASSWORD` | roudoku_local_password | Database password |
| `SERVER_PORT` | 8080 | API server port |
| `GIN_MODE` | debug | Go Gin framework mode |

## 📊 Health Check URLs

When services are running, you can check these URLs:

- **API Health**: http://localhost:8080/api/v1/health
- **Database**: `localhost:5432` (use database client)

## 🔄 Development Workflow

1. **Initial Setup**:
   ```bash
   ./scripts/health-check.sh
   ./scripts/test-mobile.sh
   ```

2. **Daily Development**:
   ```bash
   ./scripts/start-simple.sh
   # In another terminal:
   cd mobile && flutter run
   ```

3. **Testing Changes**:
   - Use Flutter hot reload (`r` in Flutter console)
   - Restart Go server manually if needed
   - Database persists between restarts

4. **Cleanup**:
   - Press `Ctrl+C` to stop scripts
   - Services will be cleaned up automatically

## 📝 Notes

- Database data persists in Docker volume `roudoku_postgres_data`
- Scripts use colored output for better readability
- All scripts include cleanup handlers for graceful shutdown
- Environment variables are set automatically
- Scripts are tested on macOS but should work on Linux

## 🆘 Getting Help

If you encounter issues:

1. Run `./scripts/health-check.sh` first
2. Check the troubleshooting section above
3. Review the service logs
4. Ensure all prerequisites are properly installed

For additional help, check the main project documentation.