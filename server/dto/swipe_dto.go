package dto

import (
	"time"

	"github.com/google/uuid"
)

// SwipeLogResponse represents a swipe log response in the API layer
type SwipeLogResponse struct {
	ID        uuid.UUID `json:"id"`
	UserID    uuid.UUID `json:"user_id"`
	QuoteID   uuid.UUID `json:"quote_id"`
	Mode      string    `json:"mode"`
	Choice    int       `json:"choice"`
	CreatedAt time.Time `json:"created_at"`
}

// CreateSwipeLogRequest represents the request to create a swipe log
type CreateSwipeLogRequest struct {
	QuoteID uuid.UUID `json:"quote_id" validate:"required"`
	Mode    string    `json:"mode" validate:"required,oneof=tinder facemash"`
	Choice  int       `json:"choice" validate:"required,oneof=-1 0 1"`
}