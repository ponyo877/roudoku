package services

import (
	"context"
	"fmt"

	"github.com/go-playground/validator/v10"

	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/mappers"
	"github.com/ponyo877/roudoku/server/repository"
)

// BookService defines the interface for book business logic
type BookService interface {
	CreateBook(ctx context.Context, req *dto.CreateBookRequest) (*domain.Book, error)
	GetBook(ctx context.Context, id int64) (*domain.Book, error)
	SearchBooks(ctx context.Context, req *dto.BookSearchRequest) (*dto.BookListResponse, error)
	GetRandomQuotes(ctx context.Context, bookID int64, limit int) ([]*domain.Quote, error)
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
func (s *bookService) CreateBook(ctx context.Context, req *dto.CreateBookRequest) (*domain.Book, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	mapper := mappers.NewBookMapper()
	book := mapper.CreateRequestToDomain(req)

	// TODO: The repository interface needs to be updated to work with entities
	// For now, this will need to be fixed when the repository layer is updated
	if err := s.bookRepo.Create(ctx, book); err != nil {
		return nil, fmt.Errorf("failed to create book: %w", err)
	}

	return book, nil
}

// GetBook retrieves a book by ID
func (s *bookService) GetBook(ctx context.Context, id int64) (*domain.Book, error) {
	book, err := s.bookRepo.GetByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get book: %w", err)
	}
	return book, nil
}

// SearchBooks searches for books based on criteria
func (s *bookService) SearchBooks(ctx context.Context, req *dto.BookSearchRequest) (*dto.BookListResponse, error) {
	if req == nil {
		req = &dto.BookSearchRequest{
			SortBy: string(domain.SortByPopularity),
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

	// Convert DTO search request to domain search request
	mapper := mappers.NewBookMapper()
	domainReq := mapper.SearchRequestToDomain(req)

	books, total, err := s.bookRepo.List(ctx, domainReq)
	if err != nil {
		return nil, fmt.Errorf("failed to search books: %w", err)
	}

	// Convert domain books to DTO responses
	bookResponses := mapper.DomainToDTOSlice(books)

	return &dto.BookListResponse{
		Books:   bookResponses,
		Total:   total,
		Limit:   req.Limit,
		Offset:  req.Offset,
		HasMore: req.Offset+req.Limit < total,
	}, nil
}

// GetRandomQuotes retrieves random quotes from a book
func (s *bookService) GetRandomQuotes(ctx context.Context, bookID int64, limit int) ([]*domain.Quote, error) {
	if limit <= 0 || limit > 50 {
		limit = 10
	}

	quotes, err := s.bookRepo.GetRandomQuotes(ctx, bookID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get random quotes: %w", err)
	}

	return quotes, nil
}
