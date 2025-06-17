package repository

import (
	"context"

	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/domain"
)

// BookRepository defines the interface for book data access
type BookRepository interface {
	Create(ctx context.Context, book *domain.Book) error
	GetByID(ctx context.Context, id int64) (*domain.Book, error)
	Update(ctx context.Context, book *domain.Book) error
	Delete(ctx context.Context, id int64) error
	List(ctx context.Context, req *domain.BookSearchRequest) ([]*domain.Book, int, error)

	// Chapter operations
	CreateChapter(ctx context.Context, chapter *domain.Chapter) error
	GetChaptersByBookID(ctx context.Context, bookID int64) ([]*domain.Chapter, error)
	GetChapterByID(ctx context.Context, chapterID string) (*domain.Chapter, error)

	// Quote operations
	CreateQuote(ctx context.Context, quote *domain.Quote) error
	GetRandomQuotes(ctx context.Context, bookID int64, limit int) ([]*domain.Quote, error)
}

// UserRepository defines the interface for user data operations
type UserRepository interface {
	Create(ctx context.Context, user *domain.User) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.User, error)
	GetByFirebaseUID(ctx context.Context, firebaseUID string) (*domain.User, error)
	Update(ctx context.Context, user *domain.User) error
	Delete(ctx context.Context, id uuid.UUID) error
	List(ctx context.Context, limit, offset int) ([]*domain.User, error)
}

// SwipeRepository defines the interface for swipe log data operations
type SwipeRepository interface {
	Create(ctx context.Context, swipeLog *domain.SwipeLog) error
	GetByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.SwipeLog, error)
	GetByQuoteID(ctx context.Context, quoteID uuid.UUID) ([]*domain.SwipeLog, error)
}

// SessionRepository defines the interface for reading session data operations
type SessionRepository interface {
	Create(ctx context.Context, session *domain.ReadingSession) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.ReadingSession, error)
	Update(ctx context.Context, session *domain.ReadingSession) error
	Delete(ctx context.Context, id uuid.UUID) error
	GetByUserID(ctx context.Context, userID uuid.UUID, limit int) ([]*domain.ReadingSession, error)
	GetByBookID(ctx context.Context, bookID int64, limit int) ([]*domain.ReadingSession, error)
}

// RatingRepository defines the interface for rating data operations
type RatingRepository interface {
	Create(ctx context.Context, rating *domain.Rating) error
	GetByUserAndBook(ctx context.Context, userID uuid.UUID, bookID int64) (*domain.Rating, error)
	Update(ctx context.Context, rating *domain.Rating) error
	Delete(ctx context.Context, userID uuid.UUID, bookID int64) error
	GetByUserID(ctx context.Context, userID uuid.UUID, limit int) ([]*domain.Rating, error)
	GetByBookID(ctx context.Context, bookID int64, limit int) ([]*domain.Rating, error)
}
