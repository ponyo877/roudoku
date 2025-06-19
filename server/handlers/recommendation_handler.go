package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/google/uuid"
	"github.com/gorilla/mux"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/errors"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/middleware"
	"github.com/ponyo877/roudoku/server/pkg/utils"
	"github.com/ponyo877/roudoku/server/services"
)

type RecommendationHandler struct {
	recommendationService services.RecommendationService
	logger                *logger.Logger
}

func NewRecommendationHandler(recommendationService services.RecommendationService, logger *logger.Logger) *RecommendationHandler {
	return &RecommendationHandler{
		recommendationService: recommendationService,
		logger:                logger,
	}
}

// GetRecommendations handles GET /recommendations
func (h *RecommendationHandler) GetRecommendations(w http.ResponseWriter, r *http.Request) {
	userIDStr, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	// Parse query parameters
	query := r.URL.Query()
	recType := query.Get("type")
	if recType == "" {
		recType = "personalized"
	}

	countStr := query.Get("count")
	count := 10
	if countStr != "" {
		if c, err := strconv.Atoi(countStr); err == nil && c > 0 && c <= 50 {
			count = c
		}
	}

	includeExplanations := query.Get("include_explanations") == "true"

	// Build request
	req := &dto.RecommendationRequest{
		RecommendationType:  recType,
		Count:              count,
		IncludeExplanations: includeExplanations,
	}

	// Parse filters if provided
	if filtersStr := query.Get("filters"); filtersStr != "" {
		var filters dto.RecommendationFilters
		if err := json.Unmarshal([]byte(filtersStr), &filters); err == nil {
			req.Filters = &filters
		}
	}

	// Parse context if provided
	if contextStr := query.Get("context"); contextStr != "" {
		var context dto.RecommendationContext
		if err := json.Unmarshal([]byte(contextStr), &context); err == nil {
			req.Context = &context
		}
	}

	response, err := h.recommendationService.GetRecommendations(r.Context(), userID, req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get recommendations", err))
		return
	}

	utils.WriteSuccess(w, response)
}

// GetSimilarBooks handles GET /recommendations/similar/{bookId}
func (h *RecommendationHandler) GetSimilarBooks(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	bookIDStr, exists := vars["bookId"]
	if !exists {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Book ID is required", nil))
		return
	}

	bookID, err := strconv.ParseInt(bookIDStr, 10, 64)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid book ID", err))
		return
	}

	// Parse query parameters
	query := r.URL.Query()
	countStr := query.Get("count")
	count := 10
	if countStr != "" {
		if c, err := strconv.Atoi(countStr); err == nil && c > 0 && c <= 20 {
			count = c
		}
	}

	similarityType := query.Get("similarity_type")
	if similarityType == "" {
		similarityType = "content"
	}

	req := &dto.SimilarBooksRequest{
		BookID:         bookID,
		Count:          count,
		SimilarityType: similarityType,
	}

	// Parse filters if provided
	if filtersStr := query.Get("filters"); filtersStr != "" {
		var filters dto.RecommendationFilters
		if err := json.Unmarshal([]byte(filtersStr), &filters); err == nil {
			req.Filters = &filters
		}
	}

	response, err := h.recommendationService.GetSimilarBooks(r.Context(), req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get similar books", err))
		return
	}

	utils.WriteSuccess(w, response)
}

// GetUserPreferences handles GET /recommendations/preferences
func (h *RecommendationHandler) GetUserPreferences(w http.ResponseWriter, r *http.Request) {
	userIDStr, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	response, err := h.recommendationService.GetUserPreferences(r.Context(), userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get user preferences", err))
		return
	}

	utils.WriteSuccess(w, response)
}

// UpdateUserPreferences handles PUT /recommendations/preferences
func (h *RecommendationHandler) UpdateUserPreferences(w http.ResponseWriter, r *http.Request) {
	userIDStr, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	var req dto.UpdatePreferencesRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid request body", err))
		return
	}

	response, err := h.recommendationService.UpdateUserPreferences(r.Context(), userID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to update user preferences", err))
		return
	}

	utils.WriteSuccess(w, response)
}

// RecordFeedback handles POST /recommendations/feedback
func (h *RecommendationHandler) RecordFeedback(w http.ResponseWriter, r *http.Request) {
	userIDStr, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	var req dto.RecommendationFeedbackRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid request body", err))
		return
	}

	err = h.recommendationService.RecordFeedback(r.Context(), userID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to record feedback", err))
		return
	}

	utils.WriteSuccess(w, map[string]string{"status": "success"})
}

// GetRecommendationInsights handles GET /recommendations/insights
func (h *RecommendationHandler) GetRecommendationInsights(w http.ResponseWriter, r *http.Request) {
	userIDStr, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	response, err := h.recommendationService.GetRecommendationInsights(r.Context(), userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get recommendation insights", err))
		return
	}

	utils.WriteSuccess(w, response)
}

// RefreshRecommendations handles POST /recommendations/refresh
func (h *RecommendationHandler) RefreshRecommendations(w http.ResponseWriter, r *http.Request) {
	userIDStr, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	// Invalidate user's recommendation cache
	err = h.recommendationService.InvalidateRecommendationCache(r.Context(), userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to refresh recommendations", err))
		return
	}

	// Recalculate user similarities in background
	go func() {
		if err := h.recommendationService.RecalculateUserSimilarities(r.Context(), userID); err != nil {
			h.logger.Error("Failed to recalculate user similarities")
		}
	}()

	utils.WriteSuccess(w, map[string]string{"status": "recommendations refreshed"})
}