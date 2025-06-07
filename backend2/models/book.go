package models

import (
	"time"

	"github.com/google/uuid"
)

// SortBy represents different sorting options for books
type SortBy string

const (
	SortByPopularity      SortBy = "popularity"      // download_count DESC
	SortByRating          SortBy = "rating"          // rating_average DESC
	SortByPublicationDate SortBy = "publication"    // created_at DESC
	SortByCreatedAt       SortBy = "created_at"      // created_at DESC  
	SortByTitle           SortBy = "title"           // title ASC
	SortByAuthor          SortBy = "author"          // author ASC
	SortByWordCount       SortBy = "word_count"      // word_count ASC
)

// Book represents a book from Aozora Bunko
type Book struct {
	ID                      int64     `json:"id" db:"id"`
	Title                   string    `json:"title" db:"title"`
	Author                  string    `json:"author" db:"author"`
	Epoch                   *string   `json:"epoch" db:"epoch"`
	WordCount               int       `json:"word_count" db:"word_count"`
	Embedding               []float64 `json:"embedding,omitempty" db:"embedding"`
	ContentURL              *string   `json:"content_url" db:"content_url"`
	Summary                 *string   `json:"summary" db:"summary"`
	Genre                   *string   `json:"genre" db:"genre"`
	DifficultyLevel         int       `json:"difficulty_level" db:"difficulty_level"`
	EstimatedReadingMinutes int       `json:"estimated_reading_minutes" db:"estimated_reading_minutes"`
	DownloadCount           int       `json:"download_count" db:"download_count"`
	RatingAverage           float64   `json:"rating_average" db:"rating_average"`
	RatingCount             int       `json:"rating_count" db:"rating_count"`
	IsPremium               bool      `json:"is_premium" db:"is_premium"`
	IsActive                bool      `json:"is_active" db:"is_active"`
	CreatedAt               time.Time `json:"created_at" db:"created_at"`
	UpdatedAt               time.Time `json:"updated_at" db:"updated_at"`
}

// Chapter represents a chapter within a book
type Chapter struct {
	ID        uuid.UUID `json:"id" db:"id"`
	BookID    int64     `json:"book_id" db:"book_id"`
	Title     string    `json:"title" db:"title"`
	Content   string    `json:"content" db:"content"`
	Position  int       `json:"position" db:"position"`
	WordCount int       `json:"word_count" db:"word_count"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// Quote represents a quote from a book for recommendation system
type Quote struct {
	ID           uuid.UUID `json:"id" db:"id"`
	BookID       int64     `json:"book_id" db:"book_id"`
	Text         string    `json:"text" db:"text"`
	Position     int       `json:"position" db:"position"`
	ChapterTitle *string   `json:"chapter_title" db:"chapter_title"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
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

// BookSearchRequest represents a search request for books
type BookSearchRequest struct {
	Query  string      `json:"query,omitempty"`
	Filter *BookFilter `json:"filter,omitempty"`
	SortBy SortBy      `json:"sort_by,omitempty" validate:"omitempty,oneof=popularity rating publication title author word_count"`
	Limit  int         `json:"limit,omitempty" validate:"omitempty,min=1,max=100"`
	Offset int         `json:"offset,omitempty" validate:"omitempty,min=0"`
}

// BookListResponse represents a paginated list of books
type BookListResponse struct {
	Books   []*Book `json:"books"`
	Total   int     `json:"total"`
	Limit   int     `json:"limit"`
	Offset  int     `json:"offset"`
	HasMore bool    `json:"has_more"`
}

// CreateBookRequest represents the request body for creating a book
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

// ToSQLOrderBy converts SortBy to SQL ORDER BY clause
func (s SortBy) ToSQLOrderBy() string {
	switch s {
	case SortByPopularity:
		return "download_count DESC, rating_average DESC"
	case SortByRating:
		return "rating_average DESC, rating_count DESC"
	case SortByPublicationDate:
		return "created_at DESC"
	case SortByTitle:
		return "title ASC"
	case SortByAuthor:
		return "author ASC, title ASC"
	case SortByWordCount:
		return "word_count ASC"
	default:
		return "download_count DESC, rating_average DESC"
	}
}