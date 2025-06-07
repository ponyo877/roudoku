package dto

import (
	"time"
)

// BookResponse represents a book response in the API layer
type BookResponse struct {
	ID                      int64     `json:"id"`
	Title                   string    `json:"title"`
	Author                  string    `json:"author"`
	Epoch                   *string   `json:"epoch"`
	WordCount               int       `json:"word_count"`
	ContentURL              *string   `json:"content_url"`
	Summary                 *string   `json:"summary"`
	Genre                   *string   `json:"genre"`
	DifficultyLevel         int       `json:"difficulty_level"`
	EstimatedReadingMinutes int       `json:"estimated_reading_minutes"`
	DownloadCount           int       `json:"download_count"`
	RatingAverage           float64   `json:"rating_average"`
	RatingCount             int       `json:"rating_count"`
	IsPremium               bool      `json:"is_premium"`
	IsActive                bool      `json:"is_active"`
	CreatedAt               time.Time `json:"created_at"`
	UpdatedAt               time.Time `json:"updated_at"`
}

// CreateBookRequest represents the request to create a book
type CreateBookRequest struct {
	ID                      int64   `json:"id" validate:"required"`
	Title                   string  `json:"title" validate:"required,min=1,max=500"`
	Author                  string  `json:"author" validate:"required,min=1,max=200"`
	Epoch                   *string `json:"epoch" validate:"omitempty,max=50"`
	ContentURL              *string `json:"content_url" validate:"omitempty,url"`
	Summary                 *string `json:"summary" validate:"omitempty,max=2000"`
	Genre                   *string `json:"genre" validate:"omitempty,max=100"`
	DifficultyLevel         *int    `json:"difficulty_level" validate:"omitempty,min=1,max=5"`
	EstimatedReadingMinutes *int    `json:"estimated_reading_minutes" validate:"omitempty,min=0"`
	IsPremium               *bool   `json:"is_premium"`
}

// BookSearchRequest represents a search request for books
type BookSearchRequest struct {
	Query  string       `json:"query,omitempty"`
	Filter *BookFilter  `json:"filter,omitempty"`
	SortBy string       `json:"sort_by,omitempty" validate:"omitempty,oneof=popularity rating publication title author word_count"`
	Limit  int          `json:"limit,omitempty" validate:"omitempty,min=1,max=100"`
	Offset int          `json:"offset,omitempty" validate:"omitempty,min=0"`
}

// BookFilter represents filtering options for book queries
type BookFilter struct {
	Authors         []string `json:"authors,omitempty"`
	Genres          []string `json:"genres,omitempty"`
	Epochs          []string `json:"epochs,omitempty"`
	IsPremium       *bool    `json:"is_premium,omitempty"`
	MinWordCount    *int     `json:"min_word_count,omitempty"`
	MaxWordCount    *int     `json:"max_word_count,omitempty"`
	MinRating       *float64 `json:"min_rating,omitempty"`
	DifficultyLevel *int     `json:"difficulty_level,omitempty"`
	IsActive        *bool    `json:"is_active,omitempty"`
}

// BookListResponse represents a paginated list of books
type BookListResponse struct {
	Books   []*BookResponse `json:"books"`
	Total   int             `json:"total"`
	Limit   int             `json:"limit"`
	Offset  int             `json:"offset"`
	HasMore bool            `json:"has_more"`
}