package domain

import (
	"time"
)

// Book represents a book in the domain layer
type Book struct {
	ID                      int64
	Title                   string
	Author                  string
	Epoch                   *string
	WordCount               int
	Embedding               []float64
	ContentURL              *string
	Summary                 *string
	Genre                   *string
	DifficultyLevel         int
	EstimatedReadingMinutes int
	DownloadCount           int
	RatingAverage           float64
	RatingCount             int
	IsPremium               bool
	IsActive                bool
	CreatedAt               time.Time
	UpdatedAt               time.Time
}

// IsAccessibleByUser checks if a book is accessible by a user
func (b *Book) IsAccessibleByUser(user *User) bool {
	if !b.IsActive {
		return false
	}
	if b.IsPremium && !user.CanAccessPremiumContent() {
		return false
	}
	return true
}

// CalculateReadingTime estimates reading time based on average reading speed
func (b *Book) CalculateReadingTime(wordsPerMinute int) int {
	if wordsPerMinute <= 0 {
		wordsPerMinute = 250 // average reading speed
	}
	return b.WordCount / wordsPerMinute
}

// NewBook creates a new book
func NewBook(id int64, title, author string) *Book {
	now := time.Now()
	return &Book{
		ID:              id,
		Title:           title,
		Author:          author,
		DifficultyLevel: 1,
		IsActive:        true,
		CreatedAt:       now,
		UpdatedAt:       now,
	}
}