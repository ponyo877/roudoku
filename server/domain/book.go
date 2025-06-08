package domain

import (
	"time"

	"github.com/google/uuid"
)

// BookSortBy represents different sorting options for books
type BookSortBy string

const (
	SortByPopularity    BookSortBy = "popularity"
	SortByRating        BookSortBy = "rating"
	SortByPublication   BookSortBy = "publication"
	SortByTitle         BookSortBy = "title"
	SortByAuthor        BookSortBy = "author"
	SortByWordCount     BookSortBy = "word_count"
)

// ToSQLOrderBy converts BookSortBy to SQL ORDER BY clause
func (s BookSortBy) ToSQLOrderBy() string {
	switch s {
	case SortByPopularity:
		return "download_count DESC, rating_average DESC"
	case SortByRating:
		return "rating_average DESC, rating_count DESC"
	case SortByPublication:
		return "created_at DESC"
	case SortByTitle:
		return "title ASC"
	case SortByAuthor:
		return "author ASC"
	case SortByWordCount:
		return "word_count DESC"
	default:
		return "download_count DESC, rating_average DESC"
	}
}

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

// Chapter represents a chapter in the domain layer
type Chapter struct {
	ID        uuid.UUID
	BookID    int64
	Title     string
	Content   string
	Position  int
	WordCount int
	CreatedAt time.Time
}

// NewChapter creates a new chapter
func NewChapter(bookID int64, title, content string, position int) *Chapter {
	return &Chapter{
		ID:        uuid.New(),
		BookID:    bookID,
		Title:     title,
		Content:   content,
		Position:  position,
		WordCount: len(content), // rough estimate
		CreatedAt: time.Now(),
	}
}

// BookSearchRequest represents a search request for books in domain layer
type BookSearchRequest struct {
	Query  string
	Filter *BookFilter
	SortBy BookSortBy
	Limit  int
	Offset int
}

// BookFilter represents filtering options for book queries in domain layer
type BookFilter struct {
	Authors         []string
	Genres          []string
	Epochs          []string
	IsPremium       *bool
	MinWordCount    *int
	MaxWordCount    *int
	MinRating       *float64
	DifficultyLevel *int
	IsActive        *bool
}