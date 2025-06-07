package mappers

import (
	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/entities"
)

// RatingMapper handles conversions between rating representations
type RatingMapper struct{}

// NewRatingMapper creates a new rating mapper
func NewRatingMapper() *RatingMapper {
	return &RatingMapper{}
}

// DomainToDTO converts domain rating to DTO response
func (m *RatingMapper) DomainToDTO(rating *domain.Rating) *dto.RatingResponse {
	if rating == nil {
		return nil
	}

	return &dto.RatingResponse{
		UserID:    rating.UserID,
		BookID:    rating.BookID,
		Rating:    rating.Rating,
		Comment:   rating.Comment,
		CreatedAt: rating.CreatedAt,
		UpdatedAt: rating.UpdatedAt,
	}
}

// DomainToDTOSlice converts slice of domain ratings to DTO responses
func (m *RatingMapper) DomainToDTOSlice(ratings []*domain.Rating) []*dto.RatingResponse {
	result := make([]*dto.RatingResponse, len(ratings))
	for i, rating := range ratings {
		result[i] = m.DomainToDTO(rating)
	}
	return result
}

// DomainToEntity converts domain rating to database entity
func (m *RatingMapper) DomainToEntity(rating *domain.Rating) *entities.RatingEntity {
	if rating == nil {
		return nil
	}

	return &entities.RatingEntity{
		UserID:    rating.UserID,
		BookID:    rating.BookID,
		Rating:    rating.Rating,
		Comment:   rating.Comment,
		CreatedAt: rating.CreatedAt,
		UpdatedAt: rating.UpdatedAt,
	}
}

// EntityToDomain converts database entity to domain rating
func (m *RatingMapper) EntityToDomain(entity *entities.RatingEntity) *domain.Rating {
	if entity == nil {
		return nil
	}

	return &domain.Rating{
		UserID:    entity.UserID,
		BookID:    entity.BookID,
		Rating:    entity.Rating,
		Comment:   entity.Comment,
		CreatedAt: entity.CreatedAt,
		UpdatedAt: entity.UpdatedAt,
	}
}

// EntityToDomainSlice converts slice of database entities to domain ratings
func (m *RatingMapper) EntityToDomainSlice(entities []*entities.RatingEntity) []*domain.Rating {
	result := make([]*domain.Rating, len(entities))
	for i, entity := range entities {
		result[i] = m.EntityToDomain(entity)
	}
	return result
}