package domain

import (
	"time"

	"github.com/google/uuid"
)

// ReadingSession represents a user's reading session
type ReadingSession struct {
	ID          uuid.UUID
	UserID      uuid.UUID
	BookID      int64
	StartPos    int
	CurrentPos  int
	DurationSec int
	Mood        *string
	Weather     *string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// Progress returns the reading progress as a percentage
func (r *ReadingSession) Progress(totalPositions int) float64 {
	if totalPositions <= 0 {
		return 0
	}
	progress := float64(r.CurrentPos) / float64(totalPositions) * 100
	if progress > 100 {
		return 100
	}
	return progress
}

// IsActive checks if the session is still active (updated within last hour)
func (r *ReadingSession) IsActive() bool {
	return time.Since(r.UpdatedAt) < time.Hour
}

// NewReadingSession creates a new reading session
func NewReadingSession(userID uuid.UUID, bookID int64, startPos int) *ReadingSession {
	now := time.Now()
	return &ReadingSession{
		ID:         uuid.New(),
		UserID:     userID,
		BookID:     bookID,
		StartPos:   startPos,
		CurrentPos: startPos,
		CreatedAt:  now,
		UpdatedAt:  now,
	}
}