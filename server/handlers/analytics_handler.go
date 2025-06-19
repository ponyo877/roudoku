package handlers

import (
	"net/http"

	"github.com/google/uuid"
	"github.com/gorilla/mux"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/errors"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/middleware"
	"github.com/ponyo877/roudoku/server/pkg/utils"
	"github.com/ponyo877/roudoku/server/services"
)

// AnalyticsHandler handles analytics-related HTTP requests
type AnalyticsHandler struct {
	analyticsService services.AnalyticsService
	logger           *logger.Logger
}

// NewAnalyticsHandler creates a new analytics handler
func NewAnalyticsHandler(analyticsService services.AnalyticsService, logger *logger.Logger) *AnalyticsHandler {
	return &AnalyticsHandler{
		analyticsService: analyticsService,
		logger:           logger,
	}
}

// GetReadingStats handles getting reading statistics
func (h *AnalyticsHandler) GetReadingStats(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	// Parse query parameters
	period := r.URL.Query().Get("period")
	if period == "" {
		period = "weekly"
	}

	req := &dto.ReadingStatsRequest{
		Period:    period,
		StartDate: r.URL.Query().Get("start_date"),
		EndDate:   r.URL.Query().Get("end_date"),
	}

	if err := utils.ValidateStruct(req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	stats, err := h.analyticsService.GetReadingStats(r.Context(), userUUID, req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get reading stats", err))
		return
	}

	utils.WriteSuccess(w, stats)
}

// GetReadingStreak handles getting reading streak information
func (h *AnalyticsHandler) GetReadingStreak(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	streak, err := h.analyticsService.GetReadingStreak(r.Context(), userUUID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get reading streak", err))
		return
	}

	utils.WriteSuccess(w, streak)
}

// CreateGoal handles creating a new reading goal
func (h *AnalyticsHandler) CreateGoal(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	var req dto.CreateGoalRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	goal, err := h.analyticsService.CreateGoal(r.Context(), userUUID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to create goal", err))
		return
	}

	utils.WriteCreated(w, goal)
}

// GetGoals handles getting user's reading goals
func (h *AnalyticsHandler) GetGoals(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	goals, err := h.analyticsService.GetGoals(r.Context(), userUUID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get goals", err))
		return
	}

	utils.WriteSuccess(w, goals)
}

// UpdateGoal handles updating a reading goal
func (h *AnalyticsHandler) UpdateGoal(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	goalIDStr := vars["goal_id"]

	goalID, err := uuid.Parse(goalIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid goal ID", err))
		return
	}

	var req dto.UpdateGoalRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	goal, err := h.analyticsService.UpdateGoal(r.Context(), goalID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to update goal", err))
		return
	}

	utils.WriteSuccess(w, goal)
}

// DeleteGoal handles deleting a reading goal
func (h *AnalyticsHandler) DeleteGoal(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	goalIDStr := vars["goal_id"]

	goalID, err := uuid.Parse(goalIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid goal ID", err))
		return
	}

	err = h.analyticsService.DeleteGoal(r.Context(), goalID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to delete goal", err))
		return
	}

	utils.WriteNoContent(w)
}

// GetAchievements handles getting user's achievements
func (h *AnalyticsHandler) GetAchievements(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	achievements, err := h.analyticsService.GetAchievements(r.Context(), userUUID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get achievements", err))
		return
	}

	utils.WriteSuccess(w, achievements)
}

// GetBookProgress handles getting progress for a specific book
func (h *AnalyticsHandler) GetBookProgress(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	bookID, err := utils.ParseInt64Param(r, "book_id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	progress, err := h.analyticsService.GetBookProgress(r.Context(), userUUID, bookID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get book progress", err))
		return
	}

	utils.WriteSuccess(w, progress)
}

// GetCurrentlyReading handles getting currently reading books
func (h *AnalyticsHandler) GetCurrentlyReading(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	currentlyReading, err := h.analyticsService.GetCurrentlyReading(r.Context(), userUUID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get currently reading", err))
		return
	}

	utils.WriteSuccess(w, currentlyReading)
}

// UpdateBookProgress handles updating reading progress
func (h *AnalyticsHandler) UpdateBookProgress(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	var req dto.UpdateProgressRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	err = h.analyticsService.UpdateBookProgress(r.Context(), userUUID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to update book progress", err))
		return
	}

	utils.WriteSuccess(w, map[string]interface{}{
		"success": true,
	})
}

// MarkBookAsCompleted handles marking a book as completed
func (h *AnalyticsHandler) MarkBookAsCompleted(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	bookID, err := utils.ParseInt64Param(r, "book_id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	err = h.analyticsService.MarkBookAsCompleted(r.Context(), userUUID, bookID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to mark book as completed", err))
		return
	}

	utils.WriteSuccess(w, map[string]interface{}{
		"success": true,
	})
}

// RecordReadingContext handles recording reading context
func (h *AnalyticsHandler) RecordReadingContext(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	var req dto.ReadingContextRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	context, err := h.analyticsService.RecordReadingContext(r.Context(), userUUID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to record reading context", err))
		return
	}

	utils.WriteSuccess(w, context)
}

// GetContextInsights handles getting reading context insights
func (h *AnalyticsHandler) GetContextInsights(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	insights, err := h.analyticsService.GetContextInsights(r.Context(), userUUID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get context insights", err))
		return
	}

	utils.WriteSuccess(w, insights)
}

// GetReadingInsights handles getting AI-generated reading insights
func (h *AnalyticsHandler) GetReadingInsights(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	insights, err := h.analyticsService.GetReadingInsights(r.Context(), userUUID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get reading insights", err))
		return
	}

	utils.WriteSuccess(w, insights)
}

// MarkInsightAsRead handles marking an insight as read
func (h *AnalyticsHandler) MarkInsightAsRead(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	insightIDStr := vars["insight_id"]

	insightID, err := uuid.Parse(insightIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid insight ID", err))
		return
	}

	err = h.analyticsService.MarkInsightAsRead(r.Context(), insightID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to mark insight as read", err))
		return
	}

	utils.WriteSuccess(w, map[string]interface{}{
		"success": true,
	})
}