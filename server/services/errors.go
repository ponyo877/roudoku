package services

import "errors"

// Common service errors
var (
	ErrBookNotFound    = errors.New("book not found")
	ErrChapterNotFound = errors.New("chapter not found")
	ErrUserNotFound    = errors.New("user not found")
	ErrSessionNotFound = errors.New("reading session not found")
	ErrRatingNotFound  = errors.New("rating not found")
	
	ErrInvalidInput     = errors.New("invalid input")
	ErrDuplicateEntry   = errors.New("duplicate entry")
	ErrUnauthorized     = errors.New("unauthorized")
	ErrForbidden        = errors.New("forbidden")
	ErrInternalError    = errors.New("internal error")
)