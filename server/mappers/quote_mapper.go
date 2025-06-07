package mappers

import (
	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/entities"
)

// QuoteMapper handles conversions between quote representations
type QuoteMapper struct{}

// NewQuoteMapper creates a new quote mapper
func NewQuoteMapper() *QuoteMapper {
	return &QuoteMapper{}
}

// DomainToDTO converts domain quote to DTO response
func (m *QuoteMapper) DomainToDTO(quote *domain.Quote) *dto.QuoteResponse {
	if quote == nil {
		return nil
	}

	return &dto.QuoteResponse{
		ID:           quote.ID,
		BookID:       quote.BookID,
		Text:         quote.Text,
		Position:     quote.Position,
		ChapterTitle: quote.ChapterTitle,
		CreatedAt:    quote.CreatedAt,
	}
}

// DomainToDTOSlice converts slice of domain quotes to DTO responses
func (m *QuoteMapper) DomainToDTOSlice(quotes []*domain.Quote) []*dto.QuoteResponse {
	result := make([]*dto.QuoteResponse, len(quotes))
	for i, quote := range quotes {
		result[i] = m.DomainToDTO(quote)
	}
	return result
}

// DomainToEntity converts domain quote to database entity
func (m *QuoteMapper) DomainToEntity(quote *domain.Quote) *entities.QuoteEntity {
	if quote == nil {
		return nil
	}

	return &entities.QuoteEntity{
		ID:           quote.ID,
		BookID:       quote.BookID,
		Text:         quote.Text,
		Position:     quote.Position,
		ChapterTitle: quote.ChapterTitle,
		CreatedAt:    quote.CreatedAt,
	}
}

// EntityToDomain converts database entity to domain quote
func (m *QuoteMapper) EntityToDomain(entity *entities.QuoteEntity) *domain.Quote {
	if entity == nil {
		return nil
	}

	return &domain.Quote{
		ID:           entity.ID,
		BookID:       entity.BookID,
		Text:         entity.Text,
		Position:     entity.Position,
		ChapterTitle: entity.ChapterTitle,
		CreatedAt:    entity.CreatedAt,
	}
}

// EntityToDomainSlice converts slice of database entities to domain quotes
func (m *QuoteMapper) EntityToDomainSlice(entities []*entities.QuoteEntity) []*domain.Quote {
	result := make([]*domain.Quote, len(entities))
	for i, entity := range entities {
		result[i] = m.EntityToDomain(entity)
	}
	return result
}