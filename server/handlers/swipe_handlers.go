package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/dto"
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
	vars := mux.Vars(r)
	userIDStr, ok := vars["user_id"]
	if !ok {
		http.Error(w, "Missing user ID", http.StatusBadRequest)
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	var req dto.CreateSwipeLogRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	swipeLog, err := h.swipeService.CreateSwipeLog(r.Context(), userID, &req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(swipeLog)
}

// GetSwipeLogs handles GET /users/{user_id}/swipes
func (h *SwipeHandler) GetSwipeLogs(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userIDStr, ok := vars["user_id"]
	if !ok {
		http.Error(w, "Missing user ID", http.StatusBadRequest)
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	swipeLogs, err := h.swipeService.GetSwipeLogsByUser(r.Context(), userID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(swipeLogs)
}