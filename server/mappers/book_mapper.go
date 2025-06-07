package mappers

import (
	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/entities"
)

// BookMapper handles conversions between book representations
type BookMapper struct{}

// NewBookMapper creates a new book mapper
func NewBookMapper() *BookMapper {
	return &BookMapper{}
}

// DomainToDTO converts domain book to DTO response
func (m *BookMapper) DomainToDTO(book *domain.Book) *dto.BookResponse {
	if book == nil {
		return nil
	}

	return &dto.BookResponse{
		ID:                      book.ID,
		Title:                   book.Title,
		Author:                  book.Author,
		Epoch:                   book.Epoch,
		WordCount:               book.WordCount,
		ContentURL:              book.ContentURL,
		Summary:                 book.Summary,
		Genre:                   book.Genre,
		DifficultyLevel:         book.DifficultyLevel,
		EstimatedReadingMinutes: book.EstimatedReadingMinutes,
		DownloadCount:           book.DownloadCount,
		RatingAverage:           book.RatingAverage,
		RatingCount:             book.RatingCount,
		IsPremium:               book.IsPremium,
		IsActive:                book.IsActive,
		CreatedAt:               book.CreatedAt,
		UpdatedAt:               book.UpdatedAt,
	}
}

// DomainToDTOSlice converts slice of domain books to DTO responses
func (m *BookMapper) DomainToDTOSlice(books []*domain.Book) []*dto.BookResponse {
	result := make([]*dto.BookResponse, len(books))
	for i, book := range books {
		result[i] = m.DomainToDTO(book)
	}
	return result
}

// CreateRequestToDomain converts create request to domain book
func (m *BookMapper) CreateRequestToDomain(req *dto.CreateBookRequest) *domain.Book {
	book := domain.NewBook(req.ID, req.Title, req.Author)
	
	book.Epoch = req.Epoch
	book.ContentURL = req.ContentURL
	book.Summary = req.Summary
	book.Genre = req.Genre
	
	if req.DifficultyLevel != nil {
		book.DifficultyLevel = *req.DifficultyLevel
	}
	if req.EstimatedReadingMinutes != nil {
		book.EstimatedReadingMinutes = *req.EstimatedReadingMinutes
	}
	if req.IsPremium != nil {
		book.IsPremium = *req.IsPremium
	}
	
	return book
}

// DomainToEntity converts domain book to database entity
func (m *BookMapper) DomainToEntity(book *domain.Book) *entities.BookEntity {
	if book == nil {
		return nil
	}

	return &entities.BookEntity{
		ID:                      book.ID,
		Title:                   book.Title,
		Author:                  book.Author,
		Epoch:                   book.Epoch,
		WordCount:               book.WordCount,
		Embedding:               book.Embedding,
		ContentURL:              book.ContentURL,
		Summary:                 book.Summary,
		Genre:                   book.Genre,
		DifficultyLevel:         book.DifficultyLevel,
		EstimatedReadingMinutes: book.EstimatedReadingMinutes,
		DownloadCount:           book.DownloadCount,
		RatingAverage:           book.RatingAverage,
		RatingCount:             book.RatingCount,
		IsPremium:               book.IsPremium,
		IsActive:                book.IsActive,
		CreatedAt:               book.CreatedAt,
		UpdatedAt:               book.UpdatedAt,
	}
}

// EntityToDomain converts database entity to domain book
func (m *BookMapper) EntityToDomain(entity *entities.BookEntity) *domain.Book {
	if entity == nil {
		return nil
	}

	return &domain.Book{
		ID:                      entity.ID,
		Title:                   entity.Title,
		Author:                  entity.Author,
		Epoch:                   entity.Epoch,
		WordCount:               entity.WordCount,
		Embedding:               entity.Embedding,
		ContentURL:              entity.ContentURL,
		Summary:                 entity.Summary,
		Genre:                   entity.Genre,
		DifficultyLevel:         entity.DifficultyLevel,
		EstimatedReadingMinutes: entity.EstimatedReadingMinutes,
		DownloadCount:           entity.DownloadCount,
		RatingAverage:           entity.RatingAverage,
		RatingCount:             entity.RatingCount,
		IsPremium:               entity.IsPremium,
		IsActive:                entity.IsActive,
		CreatedAt:               entity.CreatedAt,
		UpdatedAt:               entity.UpdatedAt,
	}
}

// EntityToDomainSlice converts slice of database entities to domain books
func (m *BookMapper) EntityToDomainSlice(entities []*entities.BookEntity) []*domain.Book {
	result := make([]*domain.Book, len(entities))
	for i, entity := range entities {
		result[i] = m.EntityToDomain(entity)
	}
	return result
}