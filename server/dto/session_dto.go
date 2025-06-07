package dto

import (
	"time"

	"github.com/google/uuid"
)

// ReadingSessionResponse represents a reading session response in the API layer
type ReadingSessionResponse struct {
	ID          uuid.UUID `json:"id"`
	UserID      uuid.UUID `json:"user_id"`
	BookID      int64     `json:"book_id"`
	StartPos    int       `json:"start_pos"`
	CurrentPos  int       `json:"current_pos"`
	DurationSec int       `json:"duration_sec"`
	Mood        *string   `json:"mood"`
	Weather     *string   `json:"weather"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// CreateReadingSessionRequest represents the request to create a reading session
type CreateReadingSessionRequest struct {
	BookID   int64   `json:"book_id" validate:"required"`
	StartPos int     `json:"start_pos" validate:"min=0"`
	Mood     *string `json:"mood" validate:"omitempty,max=100"`
	Weather  *string `json:"weather" validate:"omitempty,max=100"`
}

// UpdateReadingSessionRequest represents the request to update a reading session
type UpdateReadingSessionRequest struct {
	CurrentPos  *int    `json:"current_pos" validate:"omitempty,min=0"`
	DurationSec *int    `json:"duration_sec" validate:"omitempty,min=0"`
	Mood        *string `json:"mood" validate:"omitempty,max=100"`
	Weather     *string `json:"weather" validate:"omitempty,max=100"`
}