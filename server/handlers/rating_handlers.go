package handlers

import (
	"net/http"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/utils"
	"github.com/ponyo877/roudoku/server/services"
)

// RatingHandler handles rating-related HTTP requests
type RatingHandler struct {
	*BaseHandler
	ratingService services.RatingService
}

// NewRatingHandler creates a new rating handler
func NewRatingHandler(ratingService services.RatingService, log *logger.Logger) *RatingHandler {
	return &RatingHandler{
		BaseHandler:   NewBaseHandler(log),
		ratingService: ratingService,
	}
}

// CreateOrUpdateRating handles POST /users/{user_id}/ratings
func (h *RatingHandler) CreateOrUpdateRating(w http.ResponseWriter, r *http.Request) {
	userID, err := utils.ParseUUIDParam(r, "user_id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	var req dto.CreateRatingRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	if err := h.validator.ValidateStruct(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	rating, err := h.ratingService.CreateOrUpdateRating(r.Context(), userID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, rating)
}

// GetUserRatings handles GET /users/{user_id}/ratings
func (h *RatingHandler) GetUserRatings(w http.ResponseWriter, r *http.Request) {
	userID, err := utils.ParseUUIDParam(r, "user_id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	limit := utils.ParseQueryInt(r, "limit", 20)

	ratings, err := h.ratingService.GetUserRatings(r.Context(), userID, limit)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, ratings)
}

// GetRating handles GET /users/{user_id}/ratings/{book_id}
func (h *RatingHandler) GetRating(w http.ResponseWriter, r *http.Request) {
	userID, err := utils.ParseUUIDParam(r, "user_id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	bookID, err := utils.ParseInt64Param(r, "book_id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	rating, err := h.ratingService.GetRating(r.Context(), userID, bookID)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, rating)
}

// DeleteRating handles DELETE /users/{user_id}/ratings/{book_id}
func (h *RatingHandler) DeleteRating(w http.ResponseWriter, r *http.Request) {
	userID, err := utils.ParseUUIDParam(r, "user_id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	bookID, err := utils.ParseInt64Param(r, "book_id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	err = h.ratingService.DeleteRating(r.Context(), userID, bookID)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, map[string]string{"message": "Rating deleted successfully"})
}