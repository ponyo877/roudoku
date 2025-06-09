package handlers

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/services"
)

type RecommendationHandler struct {
	bookService    services.BookService
	swipeService   services.SwipeService
	sessionService services.SessionService
}

func NewRecommendationHandler(
	bookService services.BookService,
	swipeService services.SwipeService,
	sessionService services.SessionService,
) *RecommendationHandler {
	return &RecommendationHandler{
		bookService:    bookService,
		swipeService:   swipeService,
		sessionService: sessionService,
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

	// Get user's swipe history for preference analysis
	swipes, err := h.swipeService.GetSwipeLogsByUser(ctx, userID)
	if err != nil {
		http.Error(w, "Failed to get user preferences", http.StatusInternalServerError)
		return
	}

	// Get user's reading sessions for context
	sessions, err := h.sessionService.GetUserReadingSessions(ctx, userID, 50)
	if err != nil {
		http.Error(w, "Failed to get reading sessions", http.StatusInternalServerError)
		return
	}

	// Simple recommendation logic (can be enhanced later)
	recommendations, err := h.generateRecommendations(ctx, userID, swipes, sessions)
	if err != nil {
		http.Error(w, "Failed to generate recommendations", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"user_id":         userID,
		"recommendations": recommendations,
		"generated_at":    "now", // Could use time.Now()
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

	// Simple training logic - in production this would trigger ML training
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"user_id": userID,
		"status":  "training_started",
		"message": "Model training initiated for user",
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

	// Get basic stats
	swipes, err := h.swipeService.GetSwipeLogsByUser(ctx, userID)
	if err != nil {
		http.Error(w, "Failed to get swipe data", http.StatusInternalServerError)
		return
	}

	sessions, err := h.sessionService.GetUserReadingSessions(ctx, userID, 100)
	if err != nil {
		http.Error(w, "Failed to get session data", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"user_id":      userID,
		"total_swipes": len(swipes),
		"total_sessions": len(sessions),
		"last_updated": "now",
	})
}

// generateRecommendations - Simple recommendation logic
func (h *RecommendationHandler) generateRecommendations(ctx context.Context, userID uuid.UUID, swipes []*domain.SwipeLog, sessions []*domain.ReadingSession) ([]map[string]interface{}, error) {
	// Use SearchBooks to get books (simplified approach)
	searchReq := &dto.BookSearchRequest{
		SortBy: string(domain.SortByPopularity),
		Limit:  5,
		Offset: 0,
	}
	
	bookListResponse, err := h.bookService.SearchBooks(ctx, searchReq)
	if err != nil {
		return nil, err
	}

	var recommendations []map[string]interface{}
	
	// Simple logic: recommend books from search results
	// In production, this would use ML algorithms
	for i, book := range bookListResponse.Books {
		recommendations = append(recommendations, map[string]interface{}{
			"book_id":    book.ID,
			"title":      book.Title,
			"author":     book.Author,
			"score":      0.8 - float64(i)*0.1, // Decreasing score
			"reason":     "Based on your reading preferences",
		})
	}

	return recommendations, nil
}