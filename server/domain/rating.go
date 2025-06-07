package domain

import (
	"time"

	"github.com/google/uuid"
)

// Rating represents a user's rating for a book
type Rating struct {
	UserID    uuid.UUID
	BookID    int64
	Rating    int
	Comment   *string
	CreatedAt time.Time
	UpdatedAt time.Time
}

// IsValid checks if the rating value is valid
func (r *Rating) IsValid() bool {
	return r.Rating >= 1 && r.Rating <= 5
}

// NewRating creates a new rating
func NewRating(userID uuid.UUID, bookID int64, rating int) *Rating {
	now := time.Now()
	return &Rating{
		UserID:    userID,
		BookID:    bookID,
		Rating:    rating,
		CreatedAt: now,
		UpdatedAt: now,
	}
}