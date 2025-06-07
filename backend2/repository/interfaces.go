package repository

import (
	"context"

	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/backend2/models"
)

// BookRepository defines the interface for book data access
type BookRepository interface {
	Create(ctx context.Context, book *models.Book) error
	GetByID(ctx context.Context, id int64) (*models.Book, error)
	Update(ctx context.Context, book *models.Book) error
	Delete(ctx context.Context, id int64) error
	List(ctx context.Context, req *models.BookSearchRequest) ([]*models.Book, int, error)
	
	// Chapter operations
	CreateChapter(ctx context.Context, chapter *models.Chapter) error
	GetChaptersByBookID(ctx context.Context, bookID int64) ([]*models.Chapter, error)
	
	// Quote operations
	CreateQuote(ctx context.Context, quote *models.Quote) error
	GetRandomQuotes(ctx context.Context, bookID int64, limit int) ([]*models.Quote, error)
}

// UserRepository defines the interface for user data operations
type UserRepository interface {
	Create(ctx context.Context, user *models.User) error
	GetByID(ctx context.Context, id uuid.UUID) (*models.User, error)
	Update(ctx context.Context, user *models.User) error
	Delete(ctx context.Context, id uuid.UUID) error
	List(ctx context.Context, limit, offset int) ([]*models.User, error)
}