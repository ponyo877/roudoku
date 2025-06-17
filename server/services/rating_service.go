package services

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"go.uber.org/zap"

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
	BaseService
	ratingRepo       repository.RatingRepository
	validationService BusinessValidationService
}

// NewRatingService creates a new rating service
func NewRatingService(ratingRepo repository.RatingRepository, validationService BusinessValidationService, logger *zap.Logger) RatingService {
	return &ratingService{
		BaseService:       NewBaseService(logger),
		ratingRepo:        ratingRepo,
		validationService: validationService,
	}
}

// CreateOrUpdateRating creates or updates a rating
func (s *ratingService) CreateOrUpdateRating(ctx context.Context, userID uuid.UUID, req *dto.CreateRatingRequest) (*domain.Rating, error) {
	s.logger.Info("Creating or updating rating", 
		zap.String("user_id", userID.String()), 
		zap.Int64("book_id", req.BookID),
		zap.Int("rating", req.Rating))
	
	if err := s.Validate(req); err != nil {
		s.logger.Error("Validation failed", zap.Error(err))
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	// Business validation
	if s.validationService != nil {
		if err := s.validationService.ValidateUserCanRateBook(ctx, userID, req.BookID); err != nil {
			s.logger.Error("Business validation failed", zap.Error(err))
			return nil, fmt.Errorf("business validation failed: %w", err)
		}
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
	limit = ValidateLimit(limit, DefaultLimit, MaxLimit)
	s.logger.Debug("Getting user ratings", zap.String("user_id", userID.String()), zap.Int("limit", limit))

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