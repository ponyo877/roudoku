package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/mux"

	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/errors"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/middleware"
	"github.com/ponyo877/roudoku/server/pkg/utils"
	"github.com/ponyo877/roudoku/server/services"
)

type AdvancedRecommendationHandler struct {
	*BaseHandler
	advancedRecommendationService services.AdvancedRecommendationService
}

func NewAdvancedRecommendationHandler(
	advancedRecommendationService services.AdvancedRecommendationService,
	logger *logger.Logger,
) *AdvancedRecommendationHandler {
	return &AdvancedRecommendationHandler{
		BaseHandler:                   NewBaseHandler(logger),
		advancedRecommendationService: advancedRecommendationService,
	}
}

// GetDeepLearningRecommendations handles POST /api/v1/recommendations/advanced/deep-learning
func (h *AdvancedRecommendationHandler) GetDeepLearningRecommendations(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	userIDStr, ok := middleware.GetUserIDFromContext(ctx)
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	var req dto.RecommendationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	recommendations, err := h.advancedRecommendationService.GenerateDeepLearningRecommendations(ctx, userID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, recommendations)
}

// GetContextualRecommendations handles POST /api/v1/recommendations/advanced/contextual
func (h *AdvancedRecommendationHandler) GetContextualRecommendations(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	userIDStr, ok := middleware.GetUserIDFromContext(ctx)
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	var context dto.RecommendationContext
	if err := json.NewDecoder(r.Body).Decode(&context); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	recommendations, err := h.advancedRecommendationService.GenerateContextualRecommendations(ctx, userID, &context)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, recommendations)
}

// GetSequentialRecommendations handles GET /api/v1/recommendations/advanced/sequential/{bookId}
func (h *AdvancedRecommendationHandler) GetSequentialRecommendations(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	userIDStr, ok := middleware.GetUserIDFromContext(ctx)
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	vars := mux.Vars(r)
	bookIDStr := vars["bookId"]
	
	var bookID int64
	if _, err := fmt.Sscanf(bookIDStr, "%d", &bookID); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	recommendations, err := h.advancedRecommendationService.GenerateSequentialRecommendations(ctx, userID, bookID)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, recommendations)
}

// UpdateUserProfileRealtime handles POST /api/v1/recommendations/advanced/profile/update
func (h *AdvancedRecommendationHandler) UpdateUserProfileRealtime(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	userIDStr, ok := middleware.GetUserIDFromContext(ctx)
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	var interaction domain.UserInteraction
	if err := json.NewDecoder(r.Body).Decode(&interaction); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	err = h.advancedRecommendationService.UpdateUserProfileRealtime(ctx, userID, &interaction)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, map[string]string{"status": "updated"})
}

// TriggerRealtimeRecommendationUpdate handles POST /api/v1/recommendations/advanced/refresh
func (h *AdvancedRecommendationHandler) TriggerRealtimeRecommendationUpdate(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	userIDStr, ok := middleware.GetUserIDFromContext(ctx)
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	err = h.advancedRecommendationService.TriggerRealtimeRecommendationUpdate(ctx, userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, map[string]string{"status": "triggered"})
}

// GetRealtimeReadingTrends handles GET /api/v1/recommendations/advanced/trends
func (h *AdvancedRecommendationHandler) GetRealtimeReadingTrends(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	trends, err := h.advancedRecommendationService.GetRealtimeReadingTrends(ctx)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, trends)
}

// GetMultiObjectiveRecommendations handles POST /api/v1/recommendations/advanced/multi-objective
func (h *AdvancedRecommendationHandler) GetMultiObjectiveRecommendations(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	userIDStr, ok := middleware.GetUserIDFromContext(ctx)
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	var request struct {
		Objectives []string `json:"objectives"`
	}
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	recommendations, err := h.advancedRecommendationService.GenerateMultiObjectiveRecommendations(ctx, userID, request.Objectives)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, recommendations)
}

// GetExplorationRecommendations handles GET /api/v1/recommendations/advanced/exploration
func (h *AdvancedRecommendationHandler) GetExplorationRecommendations(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	userIDStr, ok := middleware.GetUserIDFromContext(ctx)
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	recommendations, err := h.advancedRecommendationService.GenerateExplorationRecommendations(ctx, userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, recommendations)
}

// GetSocialRecommendations handles GET /api/v1/recommendations/advanced/social
func (h *AdvancedRecommendationHandler) GetSocialRecommendations(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	userIDStr, ok := middleware.GetUserIDFromContext(ctx)
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	recommendations, err := h.advancedRecommendationService.GetSocialRecommendations(ctx, userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, recommendations)
}

// GetGroupRecommendations handles POST /api/v1/recommendations/advanced/group
func (h *AdvancedRecommendationHandler) GetGroupRecommendations(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var request struct {
		UserIDs []uuid.UUID `json:"user_ids"`
	}
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	recommendations, err := h.advancedRecommendationService.GenerateGroupRecommendations(ctx, request.UserIDs)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, recommendations)
}

// CalculateRecommendationAccuracy handles GET /api/v1/recommendations/advanced/accuracy
func (h *AdvancedRecommendationHandler) CalculateRecommendationAccuracy(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	userIDStr, ok := middleware.GetUserIDFromContext(ctx)
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	timeframeStr := r.URL.Query().Get("timeframe")
	if timeframeStr == "" {
		timeframeStr = "30d"
	}

	timeframe, err := time.ParseDuration(timeframeStr)
	if err != nil {
		// Try parsing as days if duration format fails
		timeframe = 30 * 24 * time.Hour // Default to 30 days
	}

	accuracy, err := h.advancedRecommendationService.CalculateRecommendationAccuracy(ctx, userID, timeframe)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, accuracy)
}

// GetRecommendationPerformanceMetrics handles GET /api/v1/recommendations/advanced/performance
func (h *AdvancedRecommendationHandler) GetRecommendationPerformanceMetrics(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	performance, err := h.advancedRecommendationService.GetRecommendationPerformanceMetrics(ctx)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, performance)
}