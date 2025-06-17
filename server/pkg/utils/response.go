package utils

import (
	"encoding/json"
	"errors"
	"net/http"

	"go.uber.org/zap"

	pkgErrors "github.com/ponyo877/roudoku/server/pkg/errors"
	"github.com/ponyo877/roudoku/server/pkg/logger"
)

type Response struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   *ErrorInfo  `json:"error,omitempty"`
	Meta    *Meta       `json:"meta,omitempty"`
}

type ErrorInfo struct {
	Code      string `json:"code"`
	Message   string `json:"message"`
	RequestID string `json:"request_id,omitempty"`
}

type Meta struct {
	Page       int `json:"page,omitempty"`
	PerPage    int `json:"per_page,omitempty"`
	TotalCount int `json:"total_count,omitempty"`
	TotalPages int `json:"total_pages,omitempty"`
}

func WriteJSON(w http.ResponseWriter, statusCode int, data interface{}) error {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	return json.NewEncoder(w).Encode(data)
}

func WriteSuccess(w http.ResponseWriter, data interface{}) error {
	response := Response{
		Success: true,
		Data:    data,
	}
	return WriteJSON(w, http.StatusOK, response)
}

func WriteSuccessWithMeta(w http.ResponseWriter, data interface{}, meta *Meta) error {
	response := Response{
		Success: true,
		Data:    data,
		Meta:    meta,
	}
	return WriteJSON(w, http.StatusOK, response)
}

func WriteError(w http.ResponseWriter, r *http.Request, log *logger.Logger, err error) {
	var appErr *pkgErrors.AppError
	if !errors.As(err, &appErr) {
		appErr = pkgErrors.InternalServer("An unexpected error occurred", err)
	}

	requestID := ""
	if r != nil {
		if id := r.Context().Value("request_id"); id != nil {
			requestID = id.(string)
		}
	}

	if log != nil {
		logFields := []zap.Field{
			zap.String("error_code", appErr.Code),
			zap.String("error_message", appErr.Message),
			zap.Int("status_code", appErr.StatusCode),
		}

		if requestID != "" {
			logFields = append(logFields, zap.String("request_id", requestID))
		}

		if appErr.Err != nil {
			logFields = append(logFields, zap.Error(appErr.Err))
		}

		if r != nil {
			logFields = append(logFields,
				zap.String("method", r.Method),
				zap.String("path", r.URL.Path),
			)
		}

		if appErr.StatusCode >= 500 {
			log.Error("Server error", logFields...)
		} else {
			log.Warn("Client error", logFields...)
		}
	}

	response := Response{
		Success: false,
		Error: &ErrorInfo{
			Code:      appErr.Code,
			Message:   appErr.Message,
			RequestID: requestID,
		},
	}

	if writeErr := WriteJSON(w, appErr.StatusCode, response); writeErr != nil && log != nil {
		log.Error("Failed to write error response", zap.Error(writeErr))
	}
}

func WriteCreated(w http.ResponseWriter, data interface{}) error {
	response := Response{
		Success: true,
		Data:    data,
	}
	return WriteJSON(w, http.StatusCreated, response)
}

func WriteNoContent(w http.ResponseWriter) {
	w.WriteHeader(http.StatusNoContent)
}