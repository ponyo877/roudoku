package entities

import (
	"time"

	"github.com/google/uuid"
)

// QuoteEntity represents a quote in the database layer
type QuoteEntity struct {
	ID           uuid.UUID `db:"id"`
	BookID       int64     `db:"book_id"`
	Text         string    `db:"text"`
	Position     int       `db:"position"`
	ChapterTitle *string   `db:"chapter_title"`
	CreatedAt    time.Time `db:"created_at"`
}

// TableName returns the table name for the entity
func (QuoteEntity) TableName() string {
	return "quotes"
}