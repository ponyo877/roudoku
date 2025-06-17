package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"github.com/ponyo877/roudoku/server/services"
)

type RecommendationHandler struct {
	recommendationService services.RecommendationService
}

func NewRecommendationHandler(
	recommendationService services.RecommendationService,
) *RecommendationHandler {
	return &RecommendationHandler{
		recommendationService: recommendationService,
	}
}

// GetRecommendations handles GET /api/v1/users/{user_id}/recommendations
func (h *RecommendationHandler) GetRecommendations(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userIDStr := vars["user_id"]
	
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	ctx := r.Context()

	// Get recommendations from service
	recommendations, err := h.recommendationService.GetRecommendations(ctx, userID, 10)
	if err != nil {
		http.Error(w, "Failed to generate recommendations", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"user_id":         userID,
		"recommendations": recommendations,
		"generated_at":    "now",
	})
}

// TrainModel handles POST /api/v1/users/{user_id}/recommendations/train
func (h *RecommendationHandler) TrainModel(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userIDStr := vars["user_id"]
	
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	ctx := r.Context()

	// Train the model using the service
	err = h.recommendationService.TrainModel(ctx, userID)
	if err != nil {
		http.Error(w, "Failed to train model", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"user_id": userID,
		"status":  "training_completed",
		"message": "Model training completed for user",
	})
}

// GetRecommendationStats handles GET /api/v1/users/{user_id}/recommendations/stats
func (h *RecommendationHandler) GetRecommendationStats(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userIDStr := vars["user_id"]
	
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	ctx := r.Context()

	// Get stats from service
	stats, err := h.recommendationService.GetRecommendationStats(ctx, userID)
	if err != nil {
		http.Error(w, "Failed to get recommendation stats", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(stats)
}

