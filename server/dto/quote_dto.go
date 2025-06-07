package dto

import (
	"time"

	"github.com/google/uuid"
)

// QuoteResponse represents a quote response in the API layer
type QuoteResponse struct {
	ID           uuid.UUID `json:"id"`
	BookID       int64     `json:"book_id"`
	Text         string    `json:"text"`
	Position     int       `json:"position"`
	ChapterTitle *string   `json:"chapter_title"`
	CreatedAt    time.Time `json:"created_at"`
}