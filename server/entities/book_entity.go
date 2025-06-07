package entities

import (
	"time"
	
	"github.com/google/uuid"
)

// BookEntity represents a book in the database layer
type BookEntity struct {
	ID                      int64      `db:"id"`
	Title                   string     `db:"title"`
	Author                  string     `db:"author"`
	Epoch                   *string    `db:"epoch"`
	WordCount               int        `db:"word_count"`
	Embedding               []float64  `db:"embedding"`
	ContentURL              *string    `db:"content_url"`
	Summary                 *string    `db:"summary"`
	Genre                   *string    `db:"genre"`
	DifficultyLevel         int        `db:"difficulty_level"`
	EstimatedReadingMinutes int        `db:"estimated_reading_minutes"`
	DownloadCount           int        `db:"download_count"`
	RatingAverage           float64    `db:"rating_average"`
	RatingCount             int        `db:"rating_count"`
	IsPremium               bool       `db:"is_premium"`
	IsActive                bool       `db:"is_active"`
	CreatedAt               time.Time  `db:"created_at"`
	UpdatedAt               time.Time  `db:"updated_at"`
}

// TableName returns the table name for the entity
func (BookEntity) TableName() string {
	return "books"
}

// ChapterEntity represents a chapter in the database layer
type ChapterEntity struct {
	ID        uuid.UUID `db:"id"`
	BookID    int64     `db:"book_id"`
	Title     string    `db:"title"`
	Content   string    `db:"content"`
	Position  int       `db:"position"`
	WordCount int       `db:"word_count"`
	CreatedAt time.Time `db:"created_at"`
}

// TableName returns the table name for the entity
func (ChapterEntity) TableName() string {
	return "chapters"
}