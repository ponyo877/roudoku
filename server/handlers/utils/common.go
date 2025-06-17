package utils

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/google/uuid"
)

// ErrorResponse represents a standardized error response
type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Code    string `json:"code,omitempty"`
}

// SuccessResponse wraps successful responses
type SuccessResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Message string      `json:"message,omitempty"`
}

// PaginationParams contains common pagination parameters
type PaginationParams struct {
	Limit  int
	Offset int
}

// WriteJSONError writes a standardized JSON error response
func WriteJSONError(w http.ResponseWriter, message string, code string, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	
	errResp := ErrorResponse{
		Error:   http.StatusText(status),
		Message: message,
		Code:    code,
	}
	
	json.NewEncoder(w).Encode(errResp)
}

// WriteJSONSuccess writes a standardized JSON success response
func WriteJSONSuccess(w http.ResponseWriter, data interface{}, message string, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	
	resp := SuccessResponse{
		Success: true,
		Data:    data,
		Message: message,
	}
	
	json.NewEncoder(w).Encode(resp)
}

// ParseUUIDParam extracts and validates a UUID parameter from the request path
func ParseUUIDParam(r *http.Request, paramName string) (uuid.UUID, error) {
	vars := mux.Vars(r)
	paramStr, ok := vars[paramName]
	if !ok {
		return uuid.Nil, ErrMissingParameter
	}
	
	id, err := uuid.Parse(paramStr)
	if err != nil {
		return uuid.Nil, ErrInvalidUUID
	}
	
	return id, nil
}

// ParseInt64Param extracts and validates an int64 parameter from the request path
func ParseInt64Param(r *http.Request, paramName string) (int64, error) {
	vars := mux.Vars(r)
	paramStr, ok := vars[paramName]
	if !ok {
		return 0, ErrMissingParameter
	}
	
	id, err := strconv.ParseInt(paramStr, 10, 64)
	if err != nil {
		return 0, ErrInvalidID
	}
	
	return id, nil
}

// ParsePaginationParams extracts pagination parameters from query string
func ParsePaginationParams(r *http.Request, defaultLimit int) PaginationParams {
	params := PaginationParams{
		Limit:  defaultLimit,
		Offset: 0,
	}
	
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if limit, err := strconv.Atoi(limitStr); err == nil && limit > 0 {
			params.Limit = limit
		}
	}
	
	if offsetStr := r.URL.Query().Get("offset"); offsetStr != "" {
		if offset, err := strconv.Atoi(offsetStr); err == nil && offset >= 0 {
			params.Offset = offset
		}
	}
	
	return params
}

// DecodeJSONBody decodes the request body into the provided interface
func DecodeJSONBody(r *http.Request, v interface{}) error {
	if err := json.NewDecoder(r.Body).Decode(v); err != nil {
		return ErrInvalidJSON
	}
	return nil
}

// ParseStringParam extracts a string parameter from the request path
func ParseStringParam(r *http.Request, paramName string) (string, error) {
	vars := mux.Vars(r)
	param, ok := vars[paramName]
	if !ok || param == "" {
		return "", ErrMissingParameter
	}
	return param, nil
}