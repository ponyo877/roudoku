package errors

import (
	"errors"
	"fmt"
	"net/http"
)

type AppError struct {
	Code       string `json:"code"`
	Message    string `json:"message"`
	StatusCode int    `json:"-"`
	Err        error  `json:"-"`
}

func (e *AppError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%s: %v", e.Message, e.Err)
	}
	return e.Message
}

func (e *AppError) Unwrap() error {
	return e.Err
}

var (
	ErrNotFound           = &AppError{Code: "NOT_FOUND", Message: "Resource not found", StatusCode: http.StatusNotFound}
	ErrBadRequest         = &AppError{Code: "BAD_REQUEST", Message: "Invalid request", StatusCode: http.StatusBadRequest}
	ErrUnauthorized       = &AppError{Code: "UNAUTHORIZED", Message: "Unauthorized", StatusCode: http.StatusUnauthorized}
	ErrForbidden          = &AppError{Code: "FORBIDDEN", Message: "Forbidden", StatusCode: http.StatusForbidden}
	ErrConflict           = &AppError{Code: "CONFLICT", Message: "Resource conflict", StatusCode: http.StatusConflict}
	ErrInternalServer     = &AppError{Code: "INTERNAL_SERVER_ERROR", Message: "Internal server error", StatusCode: http.StatusInternalServerError}
	ErrValidation         = &AppError{Code: "VALIDATION_ERROR", Message: "Validation failed", StatusCode: http.StatusBadRequest}
	ErrTooManyRequests    = &AppError{Code: "TOO_MANY_REQUESTS", Message: "Too many requests", StatusCode: http.StatusTooManyRequests}
	ErrServiceUnavailable = &AppError{Code: "SERVICE_UNAVAILABLE", Message: "Service unavailable", StatusCode: http.StatusServiceUnavailable}
)

func New(code, message string, statusCode int) *AppError {
	return &AppError{
		Code:       code,
		Message:    message,
		StatusCode: statusCode,
	}
}

func NewWithError(code, message string, statusCode int, err error) *AppError {
	return &AppError{
		Code:       code,
		Message:    message,
		StatusCode: statusCode,
		Err:        err,
	}
}

func Wrap(err error, code, message string, statusCode int) *AppError {
	return &AppError{
		Code:       code,
		Message:    message,
		StatusCode: statusCode,
		Err:        err,
	}
}

func NotFound(message string) *AppError {
	return &AppError{
		Code:       ErrNotFound.Code,
		Message:    message,
		StatusCode: ErrNotFound.StatusCode,
	}
}

func BadRequest(message string, err error) *AppError {
	return &AppError{
		Code:       ErrBadRequest.Code,
		Message:    message,
		StatusCode: ErrBadRequest.StatusCode,
		Err:        err,
	}
}

func Unauthorized(message string, err error) *AppError {
	return &AppError{
		Code:       ErrUnauthorized.Code,
		Message:    message,
		StatusCode: ErrUnauthorized.StatusCode,
		Err:        err,
	}
}

func InternalServerError(message string, err error) *AppError {
	return &AppError{
		Code:       ErrInternalServer.Code,
		Message:    message,
		StatusCode: ErrInternalServer.StatusCode,
		Err:        err,
	}
}

func Validation(message string) *AppError {
	return &AppError{
		Code:       ErrValidation.Code,
		Message:    message,
		StatusCode: ErrValidation.StatusCode,
	}
}

func InternalServer(message string, err error) *AppError {
	return &AppError{
		Code:       ErrInternalServer.Code,
		Message:    message,
		StatusCode: ErrInternalServer.StatusCode,
		Err:        err,
	}
}

func GetStatusCode(err error) int {
	var appErr *AppError
	if errors.As(err, &appErr) {
		return appErr.StatusCode
	}
	return http.StatusInternalServerError
}