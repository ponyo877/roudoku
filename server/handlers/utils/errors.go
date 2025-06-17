package utils

import "errors"

// Common handler errors
var (
	ErrMissingParameter = errors.New("missing required parameter")
	ErrInvalidUUID      = errors.New("invalid UUID format")
	ErrInvalidID        = errors.New("invalid ID format")
	ErrInvalidJSON      = errors.New("invalid JSON in request body")
	ErrUnauthorized     = errors.New("unauthorized")
	ErrForbidden        = errors.New("forbidden")
	ErrNotFound         = errors.New("resource not found")
	ErrConflict         = errors.New("resource conflict")
	ErrInternal         = errors.New("internal server error")
)

// Error codes for API responses
const (
	CodeInvalidParameter = "INVALID_PARAMETER"
	CodeInvalidFormat    = "INVALID_FORMAT"
	CodeResourceNotFound = "RESOURCE_NOT_FOUND"
	CodeUnauthorized     = "UNAUTHORIZED"
	CodeForbidden        = "FORBIDDEN"
	CodeConflict         = "CONFLICT"
	CodeInternal         = "INTERNAL_ERROR"
)

// GetStatusCode returns the appropriate HTTP status code for an error
func GetStatusCode(err error) int {
	switch {
	case errors.Is(err, ErrMissingParameter),
		errors.Is(err, ErrInvalidUUID),
		errors.Is(err, ErrInvalidID),
		errors.Is(err, ErrInvalidJSON):
		return 400
	case errors.Is(err, ErrUnauthorized):
		return 401
	case errors.Is(err, ErrForbidden):
		return 403
	case errors.Is(err, ErrNotFound):
		return 404
	case errors.Is(err, ErrConflict):
		return 409
	default:
		return 500
	}
}

// GetErrorCode returns the appropriate error code for an error
func GetErrorCode(err error) string {
	switch {
	case errors.Is(err, ErrMissingParameter),
		errors.Is(err, ErrInvalidUUID),
		errors.Is(err, ErrInvalidID):
		return CodeInvalidParameter
	case errors.Is(err, ErrInvalidJSON):
		return CodeInvalidFormat
	case errors.Is(err, ErrUnauthorized):
		return CodeUnauthorized
	case errors.Is(err, ErrForbidden):
		return CodeForbidden
	case errors.Is(err, ErrNotFound):
		return CodeResourceNotFound
	case errors.Is(err, ErrConflict):
		return CodeConflict
	default:
		return CodeInternal
	}
}