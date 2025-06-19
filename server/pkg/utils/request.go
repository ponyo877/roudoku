package utils

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/pkg/errors"
)

func ParseUUIDParam(r *http.Request, paramName string) (uuid.UUID, error) {
	vars := mux.Vars(r)
	idStr, exists := vars[paramName]
	if !exists {
		return uuid.Nil, errors.BadRequest("Missing " + paramName + " parameter", nil)
	}

	id, err := uuid.Parse(idStr)
	if err != nil {
		return uuid.Nil, errors.BadRequest("Invalid " + paramName + " format", err)
	}

	return id, nil
}

func ParseInt64Param(r *http.Request, paramName string) (int64, error) {
	vars := mux.Vars(r)
	valueStr, exists := vars[paramName]
	if !exists {
		return 0, errors.BadRequest("Missing " + paramName + " parameter", nil)
	}

	value, err := strconv.ParseInt(valueStr, 10, 64)
	if err != nil {
		return 0, errors.BadRequest("Invalid " + paramName + " format", err)
	}

	return value, nil
}

func ParseIntParam(r *http.Request, paramName string) (int, error) {
	vars := mux.Vars(r)
	valueStr, exists := vars[paramName]
	if !exists {
		return 0, errors.BadRequest("Missing " + paramName + " parameter", nil)
	}

	value, err := strconv.Atoi(valueStr)
	if err != nil {
		return 0, errors.BadRequest("Invalid " + paramName + " format", err)
	}

	return value, nil
}

func ParseQueryInt(r *http.Request, paramName string, defaultValue int) int {
	valueStr := r.URL.Query().Get(paramName)
	if valueStr == "" {
		return defaultValue
	}

	value, err := strconv.Atoi(valueStr)
	if err != nil {
		return defaultValue
	}

	return value
}

func ParseQueryString(r *http.Request, paramName, defaultValue string) string {
	value := r.URL.Query().Get(paramName)
	if value == "" {
		return defaultValue
	}
	return value
}

func ParsePaginationParams(r *http.Request) (page, perPage int) {
	page = ParseQueryInt(r, "page", 1)
	if page < 1 {
		page = 1
	}

	perPage = ParseQueryInt(r, "per_page", 20)
	if perPage < 1 {
		perPage = 20
	}
	if perPage > 100 {
		perPage = 100
	}

	return page, perPage
}

func DecodeJSON(r *http.Request, dst interface{}) error {
	if r.Header.Get("Content-Type") != "application/json" {
		return errors.BadRequest("Content-Type must be application/json", nil)
	}

	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()

	if err := decoder.Decode(dst); err != nil {
		return errors.BadRequest("Invalid JSON format: " + err.Error(), err)
	}

	return nil
}

func CalculateMeta(page, perPage, totalCount int) *Meta {
	totalPages := (totalCount + perPage - 1) / perPage
	if totalPages < 1 {
		totalPages = 1
	}

	return &Meta{
		Page:       page,
		PerPage:    perPage,
		TotalCount: totalCount,
		TotalPages: totalPages,
	}
}