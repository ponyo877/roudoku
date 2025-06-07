package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/models"
	"github.com/ponyo877/roudoku/server/services"
)

// RatingHandler handles rating-related HTTP requests
type RatingHandler struct {
	ratingService services.RatingService
}

// NewRatingHandler creates a new rating handler
func NewRatingHandler(ratingService services.RatingService) *RatingHandler {
	return &RatingHandler{
		ratingService: ratingService,
	}
}

// CreateOrUpdateRating handles POST /users/{user_id}/ratings
func (h *RatingHandler) CreateOrUpdateRating(w http.ResponseWriter, r *http.Request) {
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

	var req models.CreateRatingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	rating, err := h.ratingService.CreateOrUpdateRating(r.Context(), userID, &req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(rating)
}

// GetRating handles GET /users/{user_id}/ratings/{book_id}
func (h *RatingHandler) GetRating(w http.ResponseWriter, r *http.Request) {
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

	bookIDStr, ok := vars["book_id"]
	if !ok {
		http.Error(w, "Missing book ID", http.StatusBadRequest)
		return
	}

	bookID, err := strconv.ParseInt(bookIDStr, 10, 64)
	if err != nil {
		http.Error(w, "Invalid book ID", http.StatusBadRequest)
		return
	}

	rating, err := h.ratingService.GetRating(r.Context(), userID, bookID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(rating)
}

// GetUserRatings handles GET /users/{user_id}/ratings
func (h *RatingHandler) GetUserRatings(w http.ResponseWriter, r *http.Request) {
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

	limit := 50
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil {
			limit = l
		}
	}

	ratings, err := h.ratingService.GetUserRatings(r.Context(), userID, limit)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(ratings)
}

// DeleteRating handles DELETE /users/{user_id}/ratings/{book_id}
func (h *RatingHandler) DeleteRating(w http.ResponseWriter, r *http.Request) {
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

	bookIDStr, ok := vars["book_id"]
	if !ok {
		http.Error(w, "Missing book ID", http.StatusBadRequest)
		return
	}

	bookID, err := strconv.ParseInt(bookIDStr, 10, 64)
	if err != nil {
		http.Error(w, "Invalid book ID", http.StatusBadRequest)
		return
	}

	err = h.ratingService.DeleteRating(r.Context(), userID, bookID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}