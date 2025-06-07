package repository

import (
	"context"

	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/models"
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

// SwipeRepository defines the interface for swipe log data operations
type SwipeRepository interface {
	Create(ctx context.Context, swipeLog *models.SwipeLog) error
	GetByUserID(ctx context.Context, userID uuid.UUID) ([]*models.SwipeLog, error)
	GetByQuoteID(ctx context.Context, quoteID uuid.UUID) ([]*models.SwipeLog, error)
}

// SessionRepository defines the interface for reading session data operations
type SessionRepository interface {
	Create(ctx context.Context, session *models.ReadingSession) error
	GetByID(ctx context.Context, id uuid.UUID) (*models.ReadingSession, error)
	Update(ctx context.Context, session *models.ReadingSession) error
	Delete(ctx context.Context, id uuid.UUID) error
	GetByUserID(ctx context.Context, userID uuid.UUID, limit int) ([]*models.ReadingSession, error)
	GetByBookID(ctx context.Context, bookID int64, limit int) ([]*models.ReadingSession, error)
}

// RatingRepository defines the interface for rating data operations
type RatingRepository interface {
	Create(ctx context.Context, rating *models.Rating) error
	GetByUserAndBook(ctx context.Context, userID uuid.UUID, bookID int64) (*models.Rating, error)
	Update(ctx context.Context, rating *models.Rating) error
	Delete(ctx context.Context, userID uuid.UUID, bookID int64) error
	GetByUserID(ctx context.Context, userID uuid.UUID, limit int) ([]*models.Rating, error)
	GetByBookID(ctx context.Context, bookID int64, limit int) ([]*models.Rating, error)
}
