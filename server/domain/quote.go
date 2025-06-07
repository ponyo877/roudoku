package domain

import (
	"time"

	"github.com/google/uuid"
)

// Quote represents a quote from a book
type Quote struct {
	ID           uuid.UUID
	BookID       int64
	Text         string
	Position     int
	ChapterTitle *string
	CreatedAt    time.Time
}

// NewQuote creates a new quote
func NewQuote(bookID int64, text string, position int) *Quote {
	return &Quote{
		ID:        uuid.New(),
		BookID:    bookID,
		Text:      text,
		Position:  position,
		CreatedAt: time.Now(),
	}
}