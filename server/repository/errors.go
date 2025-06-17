package repository

import (
	"github.com/ponyo877/roudoku/server/pkg/errors"
)

var (
	// Repository specific errors
	ErrNotFound      = errors.NotFound("Resource not found")
	ErrDuplicateKey  = errors.New("DUPLICATE_KEY", "Duplicate key constraint violation", 409)
	ErrForeignKey    = errors.New("FOREIGN_KEY", "Foreign key constraint violation", 400)
	ErrCheckViolation = errors.New("CHECK_VIOLATION", "Check constraint violation", 400)
	ErrConnection    = errors.New("CONNECTION_ERROR", "Database connection error", 503)
)

// Common error messages
const (
	ErrMsgBookNotFound    = "Book not found"
	ErrMsgUserNotFound    = "User not found"
	ErrMsgSessionNotFound = "Reading session not found"
	ErrMsgRatingNotFound  = "Rating not found"
	ErrMsgSwipeNotFound   = "Swipe record not found"
)