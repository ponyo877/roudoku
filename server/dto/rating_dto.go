package dto

import (
	"time"

	"github.com/google/uuid"
)

// RatingResponse represents a rating response in the API layer
type RatingResponse struct {
	UserID    uuid.UUID `json:"user_id"`
	BookID    int64     `json:"book_id"`
	Rating    int       `json:"rating"`
	Comment   *string   `json:"comment"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// CreateRatingRequest represents the request to create/update a rating
type CreateRatingRequest struct {
	BookID  int64   `json:"book_id" validate:"required"`
	Rating  int     `json:"rating" validate:"required,min=1,max=5"`
	Comment *string `json:"comment" validate:"omitempty,max=1000"`
}