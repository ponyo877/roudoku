package handlers

import (
	"net/http"

	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/handlers/utils"
	"github.com/ponyo877/roudoku/server/services"
)

// SwipeHandler handles swipe-related HTTP requests
type SwipeHandler struct {
	swipeService services.SwipeService
}

// NewSwipeHandler creates a new swipe handler
func NewSwipeHandler(swipeService services.SwipeService) *SwipeHandler {
	return &SwipeHandler{
		swipeService: swipeService,
	}
}

// CreateSwipeLog handles POST /users/{user_id}/swipes
func (h *SwipeHandler) CreateSwipeLog(w http.ResponseWriter, r *http.Request) {
	userID, err := utils.ParseUUIDParam(r, "user_id")
	if err != nil {
		utils.WriteJSONError(w, "Invalid or missing user ID", utils.CodeInvalidParameter, http.StatusBadRequest)
		return
	}

	var req dto.CreateSwipeLogRequest
	if err := utils.DecodeJSONBody(r, &req); err != nil {
		utils.WriteJSONError(w, "Invalid request body", utils.CodeInvalidFormat, http.StatusBadRequest)
		return
	}

	swipeLog, err := h.swipeService.CreateSwipeLog(r.Context(), userID, &req)
	if err != nil {
		utils.WriteJSONError(w, err.Error(), utils.CodeInternal, http.StatusInternalServerError)
		return
	}

	utils.WriteJSONSuccess(w, swipeLog, "Swipe log created successfully", http.StatusCreated)
}

// GetSwipeLogs handles GET /users/{user_id}/swipes
func (h *SwipeHandler) GetSwipeLogs(w http.ResponseWriter, r *http.Request) {
	userID, err := utils.ParseUUIDParam(r, "user_id")
	if err != nil {
		utils.WriteJSONError(w, "Invalid or missing user ID", utils.CodeInvalidParameter, http.StatusBadRequest)
		return
	}

	swipeLogs, err := h.swipeService.GetSwipeLogsByUser(r.Context(), userID)
	if err != nil {
		utils.WriteJSONError(w, err.Error(), utils.CodeInternal, http.StatusInternalServerError)
		return
	}

	utils.WriteJSONSuccess(w, swipeLogs, "", http.StatusOK)
}

// SwipeLogBatchRequest represents a batch swipe log request
type SwipeLogBatchRequest struct {
	UserID    string                    `json:"userId"`
	SwipeLogs []dto.CreateSwipeLogRequest `json:"swipeLogs"`
	SessionID string                    `json:"sessionId"`
}

// CreateSwipeLogBatch handles POST /swipe/log/batch
func (h *SwipeHandler) CreateSwipeLogBatch(w http.ResponseWriter, r *http.Request) {
	var req SwipeLogBatchRequest
	
	if err := utils.DecodeJSONBody(r, &req); err != nil {
		utils.WriteJSONError(w, "Invalid request body", utils.CodeInvalidFormat, http.StatusBadRequest)
		return
	}

	userID, err := uuid.Parse(req.UserID)
	if err != nil {
		utils.WriteJSONError(w, "Invalid user ID", utils.CodeInvalidParameter, http.StatusBadRequest)
		return
	}

	var results []interface{}
	var errors []string
	for _, swipeReq := range req.SwipeLogs {
		swipeLog, err := h.swipeService.CreateSwipeLog(r.Context(), userID, &swipeReq)
		if err != nil {
			errors = append(errors, err.Error())
			continue
		}
		results = append(results, swipeLog)
	}

	response := map[string]interface{}{
		"success":        len(errors) == 0,
		"processedCount": len(results),
		"failedCount":    len(errors),
		"errors":         errors,
		"results":        results,
	}

	status := http.StatusOK
	if len(errors) > 0 && len(results) == 0 {
		status = http.StatusBadRequest
	} else if len(errors) > 0 {
		status = http.StatusMultiStatus
	}

	utils.WriteJSONSuccess(w, response, "", status)
}

// GetSwipeStats handles GET /swipe/stats/{user_id}
func (h *SwipeHandler) GetSwipeStats(w http.ResponseWriter, r *http.Request) {
	userID, err := utils.ParseUUIDParam(r, "user_id")
	if err != nil {
		utils.WriteJSONError(w, "Invalid or missing user ID", utils.CodeInvalidParameter, http.StatusBadRequest)
		return
	}

	swipeLogs, err := h.swipeService.GetSwipeLogsByUser(r.Context(), userID)
	if err != nil {
		utils.WriteJSONError(w, err.Error(), utils.CodeInternal, http.StatusInternalServerError)
		return
	}

	// Calculate stats from swipe logs
	likeCount := 0
	dislikeCount := 0
	
	// TODO: Implement proper stat calculation based on actual DTO structure
	// For now, provide basic stats structure
	// The actual implementation would depend on the SwipeLog structure
	// which might have fields like Direction, Action, etc.
	
	stats := map[string]interface{}{
		"totalSwipes":   len(swipeLogs),
		"likeCount":     likeCount,
		"dislikeCount":  dislikeCount,
		"likeRatio":     0.0, // Will be calculated once DTO structure is known
	}

	utils.WriteJSONSuccess(w, stats, "", http.StatusOK)
}

// GetSwipeHistory handles GET /swipe/history
func (h *SwipeHandler) GetSwipeHistory(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement proper history retrieval based on user context
	// For now, return empty history
	history := map[string]interface{}{
		"history": []interface{}{},
		"total":   0,
	}
	
	utils.WriteJSONSuccess(w, history, "", http.StatusOK)
}