package services

import (
	"context"
	"fmt"

	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/mappers"
	"github.com/ponyo877/roudoku/server/repository"
)

// RatingService defines the interface for rating business logic
type RatingService interface {
	CreateOrUpdateRating(ctx context.Context, userID uuid.UUID, req *dto.CreateRatingRequest) (*domain.Rating, error)
	GetRating(ctx context.Context, userID uuid.UUID, bookID int64) (*domain.Rating, error)
	GetUserRatings(ctx context.Context, userID uuid.UUID, limit int) ([]*domain.Rating, error)
	DeleteRating(ctx context.Context, userID uuid.UUID, bookID int64) error
}

// ratingService implements RatingService
type ratingService struct {
	ratingRepo repository.RatingRepository
	validator  *validator.Validate
}

// NewRatingService creates a new rating service
func NewRatingService(ratingRepo repository.RatingRepository) RatingService {
	return &ratingService{
		ratingRepo: ratingRepo,
		validator:  validator.New(),
	}
}

// CreateOrUpdateRating creates or updates a rating
func (s *ratingService) CreateOrUpdateRating(ctx context.Context, userID uuid.UUID, req *dto.CreateRatingRequest) (*domain.Rating, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	mapper := mappers.NewRatingMapper()
	rating := mapper.CreateRequestToDomain(userID, req)

	// Check if rating already exists
	existingRating, err := s.ratingRepo.GetByUserAndBook(ctx, userID, req.BookID)
	if err == nil {
		// Update existing rating
		rating.CreatedAt = existingRating.CreatedAt
		if err := s.ratingRepo.Update(ctx, rating); err != nil {
			return nil, fmt.Errorf("failed to update rating: %w", err)
		}
	} else {
		// Create new rating
		if err := s.ratingRepo.Create(ctx, rating); err != nil {
			return nil, fmt.Errorf("failed to create rating: %w", err)
		}
	}

	return rating, nil
}

// GetRating retrieves a rating by user and book
func (s *ratingService) GetRating(ctx context.Context, userID uuid.UUID, bookID int64) (*domain.Rating, error) {
	rating, err := s.ratingRepo.GetByUserAndBook(ctx, userID, bookID)
	if err != nil {
		return nil, fmt.Errorf("failed to get rating: %w", err)
	}
	return rating, nil
}

// GetUserRatings retrieves ratings for a user
func (s *ratingService) GetUserRatings(ctx context.Context, userID uuid.UUID, limit int) ([]*domain.Rating, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}

	ratings, err := s.ratingRepo.GetByUserID(ctx, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get user ratings: %w", err)
	}
	return ratings, nil
}

// DeleteRating deletes a rating
func (s *ratingService) DeleteRating(ctx context.Context, userID uuid.UUID, bookID int64) error {
	if err := s.ratingRepo.Delete(ctx, userID, bookID); err != nil {
		return fmt.Errorf("failed to delete rating: %w", err)
	}
	return nil
}