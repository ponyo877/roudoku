package services

import (
	"github.com/go-playground/validator/v10"
	"go.uber.org/zap"
)

// BaseService provides common functionality for all services
type BaseService struct {
	validator *validator.Validate
	logger    *zap.Logger
}

// NewBaseService creates a new base service with common dependencies
func NewBaseService(logger *zap.Logger) BaseService {
	if logger == nil {
		// Create a default logger if none provided
		logger, _ = zap.NewProduction()
	}
	
	return BaseService{
		validator: validator.New(),
		logger:    logger,
	}
}

// Validate performs validation on the given struct
func (b *BaseService) Validate(v interface{}) error {
	return b.validator.Struct(v)
}

// Logger returns the service logger
func (b *BaseService) Logger() *zap.Logger {
	return b.logger
}

// Common validation constants
const (
	DefaultLimit    = 20
	MaxLimit        = 100
	DefaultOffset   = 0
	MaxQuotesLimit  = 50
	DefaultQuotesLimit = 10
)

// ValidatePaginationParams validates and normalizes pagination parameters
func ValidatePaginationParams(limit, offset int) (int, int) {
	if limit <= 0 || limit > MaxLimit {
		limit = DefaultLimit
	}
	if offset < 0 {
		offset = DefaultOffset
	}
	return limit, offset
}

// ValidateLimit validates and normalizes a limit parameter
func ValidateLimit(limit int, defaultLimit, maxLimit int) int {
	if limit <= 0 || limit > maxLimit {
		return defaultLimit
	}
	return limit
}