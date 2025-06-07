package domain

import (
	"time"

	"github.com/google/uuid"
)

// SwipeMode represents the type of swipe interaction
type SwipeMode string

const (
	SwipeModeTinder   SwipeMode = "tinder"
	SwipeModeFacemash SwipeMode = "facemash"
)

// SwipeChoice represents the user's choice
type SwipeChoice int

const (
	SwipeChoiceLeft    SwipeChoice = -1
	SwipeChoiceDislike SwipeChoice = 0
	SwipeChoiceLike    SwipeChoice = 1
)

// SwipeLog represents a user's swipe interaction
type SwipeLog struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	QuoteID   uuid.UUID
	Mode      SwipeMode
	Choice    SwipeChoice
	CreatedAt time.Time
}

// IsPositive returns true if the swipe was positive
func (s *SwipeLog) IsPositive() bool {
	return s.Choice == SwipeChoiceLike
}

// NewSwipeLog creates a new swipe log
func NewSwipeLog(userID, quoteID uuid.UUID, mode SwipeMode, choice SwipeChoice) *SwipeLog {
	return &SwipeLog{
		ID:        uuid.New(),
		UserID:    userID,
		QuoteID:   quoteID,
		Mode:      mode,
		Choice:    choice,
		CreatedAt: time.Now(),
	}
}