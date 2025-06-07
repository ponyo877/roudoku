package services

import (
	"context"
	"fmt"
	"time"

	"github.com/go-playground/validator/v10"

	"github.com/ponyo877/roudoku/server/models"
	"github.com/ponyo877/roudoku/server/repository"
)

// BookService defines the interface for book business logic
type BookService interface {
	CreateBook(ctx context.Context, req *models.CreateBookRequest) (*models.Book, error)
	GetBook(ctx context.Context, id int64) (*models.Book, error)
	SearchBooks(ctx context.Context, req *models.BookSearchRequest) (*models.BookListResponse, error)
	GetRandomQuotes(ctx context.Context, bookID int64, limit int) ([]*models.Quote, error)
}

// bookService implements BookService
type bookService struct {
	bookRepo  repository.BookRepository
	validator *validator.Validate
}

// NewBookService creates a new book service
func NewBookService(bookRepo repository.BookRepository) BookService {
	return &bookService{
		bookRepo:  bookRepo,
		validator: validator.New(),
	}
}

// CreateBook creates a new book
func (s *bookService) CreateBook(ctx context.Context, req *models.CreateBookRequest) (*models.Book, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	now := time.Now()
	book := &models.Book{
		ID:                      req.ID,
		Title:                   req.Title,
		Author:                  req.Author,
		Epoch:                   req.Epoch,
		ContentURL:              req.ContentURL,
		Summary:                 req.Summary,
		Genre:                   req.Genre,
		DifficultyLevel:         getIntValue(req.DifficultyLevel, 1),
		EstimatedReadingMinutes: getIntValue(req.EstimatedReadingMinutes, 0),
		IsPremium:               getBoolValue(req.IsPremium, false),
		IsActive:                true,
		CreatedAt:               now,
		UpdatedAt:               now,
	}

	if err := s.bookRepo.Create(ctx, book); err != nil {
		return nil, fmt.Errorf("failed to create book: %w", err)
	}

	return book, nil
}

// GetBook retrieves a book by ID
func (s *bookService) GetBook(ctx context.Context, id int64) (*models.Book, error) {
	book, err := s.bookRepo.GetByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get book: %w", err)
	}
	return book, nil
}

// SearchBooks searches for books based on criteria
func (s *bookService) SearchBooks(ctx context.Context, req *models.BookSearchRequest) (*models.BookListResponse, error) {
	if req == nil {
		req = &models.BookSearchRequest{
			SortBy: models.SortByPopularity,
			Limit:  20,
			Offset: 0,
		}
	}

	if req.Limit <= 0 || req.Limit > 100 {
		req.Limit = 20
	}
	if req.Offset < 0 {
		req.Offset = 0
	}

	books, total, err := s.bookRepo.List(ctx, req)
	if err != nil {
		return nil, fmt.Errorf("failed to search books: %w", err)
	}

	return &models.BookListResponse{
		Books:   books,
		Total:   total,
		Limit:   req.Limit,
		Offset:  req.Offset,
		HasMore: req.Offset+req.Limit < total,
	}, nil
}

// GetRandomQuotes retrieves random quotes from a book
func (s *bookService) GetRandomQuotes(ctx context.Context, bookID int64, limit int) ([]*models.Quote, error) {
	if limit <= 0 || limit > 50 {
		limit = 10
	}

	quotes, err := s.bookRepo.GetRandomQuotes(ctx, bookID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get random quotes: %w", err)
	}

	return quotes, nil
}

// Helper functions
func getIntValue(ptr *int, defaultVal int) int {
	if ptr == nil {
		return defaultVal
	}
	return *ptr
}

func getBoolValue(ptr *bool, defaultVal bool) bool {
	if ptr == nil {
		return defaultVal
	}
	return *ptr
}
