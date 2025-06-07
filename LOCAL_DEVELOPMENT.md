# 🚀 Roudoku Local Development Setup

Complete guide for setting up and running the Roudoku project locally for development and testing.

## 📋 Prerequisites

### Required Software
- **Docker & Docker Compose**: For PostgreSQL database
- **Go 1.24+**: Backend API server
- **Flutter 3.32+**: Mobile app development
- **Android Studio** or **Xcode**: Mobile development tools

### System Requirements
- **macOS/Linux/Windows**: Scripts optimized for macOS/Linux
- **RAM**: 8GB+ recommended
- **Disk**: 5GB+ free space
- **Network**: Internet connection for dependencies

## ⚡ Quick Start (Recommended)

### 1. Clone and Navigate
```bash
cd /Users/ponyo877/Documents/workspace/roudoku
```

### 2. Health Check
```bash
./scripts/health-check.sh
```
**Fix any issues before proceeding.**

### 3. Start Development Environment
```bash
./scripts/start-simple.sh
```

### 4. In Another Terminal - Start Mobile App
```bash
cd mobile
flutter run
```

## 🏗️ What Gets Started

### Database (PostgreSQL)
- **Container**: `roudoku-postgres`
- **Port**: `5432`
- **Database**: `roudoku`
- **User/Password**: `roudoku/roudoku_local_password`
- **Data**: Persisted in Docker volume

### API Server (Go)
- **Port**: `8080`
- **Health Check**: http://localhost:8080/api/v1/health
- **Auto-reload**: Manual restart required
- **Environment**: Debug mode enabled

### Mobile App (Flutter)
- **Platform**: Android/iOS emulator or device
- **Hot Reload**: Press `r` in terminal
- **Hot Restart**: Press `R` in terminal
- **Features**: All app features available

## 🧪 Testing the Setup

### 1. Test Mobile App Features
```bash
./scripts/test-mobile.sh
```

### 2. Manual Testing Checklist

#### Authentication
- [ ] Google Sign-In works
- [ ] Anonymous login works
- [ ] User profile displays correctly

#### Core Features
- [ ] Home screen loads recommendations
- [ ] Swipe mode (Tinder-style) works
- [ ] Compare mode (Facemash-style) works
- [ ] Book player opens and plays TTS
- [ ] Settings screens are accessible

#### Integration
- [ ] API calls succeed (check network logs)
- [ ] Database stores user data
- [ ] Real-time features work
- [ ] Offline mode gracefully handles no connection

### 3. API Testing
```bash
# Test health endpoint
curl http://localhost:8080/api/v1/health

# Test user creation (may return error if validation strict)
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","display_name":"Test User"}'
```

## 🔧 Development Workflow

### Daily Development
1. **Start environment**: `./scripts/start-simple.sh`
2. **Start mobile app**: `cd mobile && flutter run`
3. **Develop with hot reload**: Press `r` in Flutter console
4. **API changes**: Restart Go server manually
5. **Database changes**: Modify migrations and restart

### Making Changes

#### Backend (Go)
```bash
# Edit files in server/
# Restart server (Ctrl+C in terminal, then restart)
cd server && go run cmd/server/main.go
```

#### Mobile (Flutter)
```bash
# Edit files in mobile/lib/
# Use hot reload: Press 'r' in Flutter console
# For major changes: Press 'R' for hot restart
```

#### Database Schema
```bash
# Edit: server/migrations/001_initial_schema.sql
# Restart database container:
docker-compose -f docker-compose.local.yml restart postgres
```

### Code Generation
```bash
# When you modify models with JSON annotations
cd mobile
dart run build_runner build --delete-conflicting-outputs
```

## 🛠️ Useful Commands

### Database Management
```bash
# Access database shell
docker-compose -f docker-compose.local.yml exec postgres psql -U roudoku -d roudoku

# View database logs
docker-compose -f docker-compose.local.yml logs postgres

# Restart database
docker-compose -f docker-compose.local.yml restart postgres

# Stop all services
docker-compose -f docker-compose.local.yml down
```

### Flutter Development
```bash
# Check Flutter setup
flutter doctor

# List available devices
flutter devices

# Start emulator
flutter emulators --launch <emulator_name>

# Clean and rebuild
flutter clean && flutter pub get

# Run with specific device
flutter run -d <device_id>
```

### Go Development
```bash
# Run server with live reload (install air first: go install github.com/cosmtrek/air@latest)
cd server && air

# Manual server restart
cd server && go run cmd/server/main.go

# Run tests
cd server && go test ./...

# Update dependencies
cd server && go mod tidy
```

## 🐛 Troubleshooting

### Common Issues

#### "Port 8080 already in use"
```bash
# Find and kill the process
lsof -ti :8080 | xargs kill -9
```

#### "No devices found" (Flutter)
```bash
# Check available emulators
flutter emulators

# Create new emulator
flutter emulators --create

# Start specific emulator
flutter emulators --launch <emulator_name>
```

#### "Database connection failed"
```bash
# Check if PostgreSQL container is running
docker ps | grep postgres

# Restart database
docker-compose -f docker-compose.local.yml restart postgres

# Check logs
docker-compose -f docker-compose.local.yml logs postgres
```

#### "Go dependencies issues"
```bash
cd server
go mod download
go mod tidy
```

#### "Flutter build issues"
```bash
cd mobile
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Performance Issues

#### Slow Flutter Hot Reload
- Use smaller device resolution
- Close unnecessary apps
- Use physical device instead of emulator

#### Database Slow Queries
- Check database logs for slow queries
- Consider adding indexes (modify migrations)
- Monitor with: `docker stats roudoku-postgres`

#### High Memory Usage
- Close unused applications
- Use lighter emulator (no Google Play services)
- Increase swap space if needed

## 📊 Monitoring and Logs

### Application Logs
```bash
# Flutter app logs
# Check Flutter console where you ran `flutter run`

# Go server logs
# Check terminal where you ran the server

# Database logs
docker-compose -f docker-compose.local.yml logs postgres
```

### Health Monitoring
```bash
# Run comprehensive health check
./scripts/health-check.sh

# Check API health
curl http://localhost:8080/api/v1/health

# Check database health
docker exec roudoku-postgres pg_isready -U roudoku -d roudoku
```

### Resource Usage
```bash
# Docker container stats
docker stats

# System resource usage
top # or htop if installed
```

## 🚦 Environment Status

After running `./scripts/start-simple.sh`, you should see:

```
🎉 Development Environment Started!
==============================================

📊 Services Status:
  ✅ Database:     PostgreSQL (Docker)
  ✅ API Server:   http://localhost:8080
  ✅ Mobile App:   Starting on device/emulator

🔗 Useful URLs:
  Health Check:   http://localhost:8080/api/v1/health
  Database:       localhost:5432 (roudoku/roudoku)

🛠 Commands:
  Check health:   ./scripts/health-check.sh
  View DB logs:   docker-compose -f docker-compose.local.yml logs postgres
  DB shell:       docker-compose -f docker-compose.local.yml exec postgres psql -U roudoku -d roudoku
  Flutter hot:    Press 'r' in Flutter console for hot reload

⏹ To stop: Press Ctrl+C
```

## 🎯 Development Goals

This setup enables you to:
- ✅ Develop and test all mobile app features
- ✅ Modify backend API and see changes immediately
- ✅ Test database interactions and schema changes
- ✅ Debug authentication flows
- ✅ Test real-time features
- ✅ Validate offline functionality
- ✅ Test performance and optimization

## 📞 Getting Help

1. **Run health check**: `./scripts/health-check.sh`
2. **Check logs**: Review application and Docker logs
3. **Restart services**: Use cleanup and restart commands
4. **Check documentation**: Review scripts/README.md
5. **Verify setup**: Ensure all prerequisites are installed correctly

Happy coding! 🎉