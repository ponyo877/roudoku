package handlers

import (
	"net/http"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/utils"
	"github.com/ponyo877/roudoku/server/services"
)

// SwipeHandler handles swipe-related HTTP requests
type SwipeHandler struct {
	*BaseHandler
	swipeService services.SwipeService
}

// NewSwipeHandler creates a new swipe handler
func NewSwipeHandler(swipeService services.SwipeService, log *logger.Logger) *SwipeHandler {
	return &SwipeHandler{
		BaseHandler:  NewBaseHandler(log),
		swipeService: swipeService,
	}
}

// CreateSwipeLog handles POST /users/{user_id}/swipes and POST /swipe/log
func (h *SwipeHandler) CreateSwipeLog(w http.ResponseWriter, r *http.Request) {
	userID, err := utils.ParseUUIDParam(r, "user_id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	var req dto.CreateSwipeLogRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	if err := h.validator.ValidateStruct(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	swipeLog, err := h.swipeService.CreateSwipeLog(r.Context(), userID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, swipeLog)
}

// GetSwipeLogsByUser handles GET /users/{user_id}/swipes
func (h *SwipeHandler) GetSwipeLogs(w http.ResponseWriter, r *http.Request) {
	userID, err := utils.ParseUUIDParam(r, "user_id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	swipeLogs, err := h.swipeService.GetSwipeLogsByUser(r.Context(), userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, swipeLogs)
}

// CreateSwipeLogBatch handles POST /swipe/log/batch
func (h *SwipeHandler) CreateSwipeLogBatch(w http.ResponseWriter, r *http.Request) {
	// This endpoint would need a userID parameter or batch requests structure
	// For now, return a simple message indicating batch processing is not implemented
	utils.WriteSuccess(w, map[string]string{
		"message": "Batch swipe log creation not yet implemented",
	})
}

// GetSwipeStats handles GET /swipe/stats/{user_id}
func (h *SwipeHandler) GetSwipeStats(w http.ResponseWriter, r *http.Request) {
	userID, err := utils.ParseUUIDParam(r, "user_id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	swipeLogs, err := h.swipeService.GetSwipeLogsByUser(r.Context(), userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	// Calculate basic stats
	stats := map[string]any{
		"total_swipes": len(swipeLogs),
		"user_id":      userID.String(),
	}

	utils.WriteSuccess(w, stats)
}

// GetSwipeHistory handles GET /swipe/history
func (h *SwipeHandler) GetSwipeHistory(w http.ResponseWriter, r *http.Request) {
	// For now, return empty history - this would need proper implementation
	// based on query parameters for filtering
	history := []any{}
	utils.WriteSuccess(w, history)
}