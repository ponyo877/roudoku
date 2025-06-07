# Roudoku Backend - Clean Architecture

This is the refactored Go backend for the Roudoku application, following Clean Architecture principles.

## Directory Structure

```
server/
├── cmd/server/           # Application entry points
├── models/               # Domain models and business entities
├── repository/           # Data access layer interfaces
├── services/             # Business logic layer
├── handlers/             # HTTP transport layer
├── internal/            # Internal application packages
│   ├── config/          # Configuration management
│   ├── database/        # Database connection
│   └── middleware/      # HTTP middleware
└── migrations/          # Database migrations
```

## Architecture Principles

### Clean Architecture Layers

1. **Models** (`models/`) - Pure domain entities with business rules
2. **Repository** (`repository/`) - Data access interfaces and implementations
3. **Services** (`services/`) - Business logic and use cases
4. **Handlers** (`handlers/`) - HTTP transport layer

### Dependency Rule

Dependencies point inward:
- Handlers depend on Services
- Services depend on Repository interfaces
- Models are independent of all other layers

## Getting Started

### Prerequisites

- Go 1.21+
- PostgreSQL 13+

### Environment Variables

```bash
# Server
PORT=8080

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=roudoku
DB_USER=postgres
DB_PASSWORD=password
DB_SSLMODE=disable
```

### Running the Application

```bash
# Install dependencies
go mod tidy

# Run the server
go run cmd/server/main.go
```

### API Endpoints

- `GET /api/v1/health` - Health check
- `GET /api/v1/books` - Search books
- `POST /api/v1/books` - Create book
- `GET /api/v1/books/{id}` - Get book by ID
- `GET /api/v1/books/{id}/quotes/random` - Get random quotes

## Development

### Adding New Features

1. Define domain models in `models/`
2. Create repository interfaces in `repository/`
3. Implement business logic in `services/`
4. Create HTTP handlers in `handlers/`
5. Wire everything together in `cmd/server/main.go`

### Testing

```bash
# Run tests
go test ./...

# Run tests with coverage
go test -cover ./...
```

## Benefits of This Architecture

- **Testable**: Easy to mock dependencies and test in isolation
- **Maintainable**: Clear separation of concerns
- **Flexible**: Easy to swap implementations (e.g., database providers)
- **Scalable**: Structure supports growth and team development