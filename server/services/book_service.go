package services

import (
	"context"
	"fmt"

	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/mappers"
	"github.com/ponyo877/roudoku/server/pkg/errors"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/repository"
)

// BookService defines the interface for book business logic
type BookService interface {
	CreateBook(ctx context.Context, req *dto.CreateBookRequest) (*domain.Book, error)
	GetBook(ctx context.Context, id int64) (*domain.Book, error)
	SearchBooks(ctx context.Context, req *dto.BookSearchRequest) (*dto.BookListResponse, error)
	GetRandomQuotes(ctx context.Context, bookID int64, limit int) ([]*domain.Quote, error)
	GetBookChapters(ctx context.Context, bookID int64) ([]*domain.Chapter, error)
	GetChapterContent(ctx context.Context, bookID int64, chapterID string) (*domain.Chapter, error)
}

// bookService implements BookService
type bookService struct {
	*BaseService
	bookRepo repository.BookRepository
}

// NewBookService creates a new book service
func NewBookService(bookRepo repository.BookRepository, log *logger.Logger) BookService {
	return &bookService{
		BaseService: NewBaseService(log),
		bookRepo:    bookRepo,
	}
}

// CreateBook creates a new book
func (s *bookService) CreateBook(ctx context.Context, req *dto.CreateBookRequest) (*domain.Book, error) {
	if err := s.ValidateStruct(req); err != nil {
		return nil, err
	}

	mapper := mappers.NewBookMapper()
	book := mapper.CreateRequestToDomain(req)

	if err := s.bookRepo.Create(ctx, book); err != nil {
		return nil, errors.InternalServer("Failed to create book", err)
	}

	return book, nil
}

// GetBook retrieves a book by ID
func (s *bookService) GetBook(ctx context.Context, id int64) (*domain.Book, error) {
	s.logger.Debug("Getting book")
	
	book, err := s.bookRepo.GetByID(ctx, id)
	if err != nil {
		s.logger.Error("Failed to get book")
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

	if err := s.ValidateLimit(req.Limit); err != nil {
		req.Limit = DefaultLimit
	}
	if err := s.ValidateOffset(req.Offset); err != nil {
		req.Offset = 0
	}
	req.Limit = s.NormalizeLimit(req.Limit)

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
	if err := s.ValidateLimit(limit); err != nil {
		limit = DefaultLimit
	}
	limit = s.NormalizeLimit(limit)
	s.logger.Debug("Getting random quotes")

	quotes, err := s.bookRepo.GetRandomQuotes(ctx, bookID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get random quotes: %w", err)
	}

	return quotes, nil
}

// GetBookChapters retrieves all chapters for a book
func (s *bookService) GetBookChapters(ctx context.Context, bookID int64) ([]*domain.Chapter, error) {
	chapters, err := s.bookRepo.GetChaptersByBookID(ctx, bookID)
	if err != nil {
		return nil, fmt.Errorf("failed to get book chapters: %w", err)
	}
	return chapters, nil
}

// GetChapterContent retrieves content for a specific chapter
func (s *bookService) GetChapterContent(ctx context.Context, bookID int64, chapterID string) (*domain.Chapter, error) {
	chapter, err := s.bookRepo.GetChapterByID(ctx, chapterID)
	if err != nil {
		return nil, fmt.Errorf("failed to get chapter content: %w", err)
	}
	
	// Verify the chapter belongs to the requested book
	if chapter.BookID != bookID {
		return nil, fmt.Errorf("chapter does not belong to the specified book")
	}
	
	return chapter, nil
}
