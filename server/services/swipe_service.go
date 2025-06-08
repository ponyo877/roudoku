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

// SwipeService defines the interface for swipe business logic
type SwipeService interface {
	CreateSwipeLog(ctx context.Context, userID uuid.UUID, req *dto.CreateSwipeLogRequest) (*domain.SwipeLog, error)
	GetSwipeLogsByUser(ctx context.Context, userID uuid.UUID) ([]*domain.SwipeLog, error)
}

// swipeService implements SwipeService
type swipeService struct {
	swipeRepo repository.SwipeRepository
	validator *validator.Validate
}

// NewSwipeService creates a new swipe service
func NewSwipeService(swipeRepo repository.SwipeRepository) SwipeService {
	return &swipeService{
		swipeRepo: swipeRepo,
		validator: validator.New(),
	}
}

// CreateSwipeLog creates a new swipe log
func (s *swipeService) CreateSwipeLog(ctx context.Context, userID uuid.UUID, req *dto.CreateSwipeLogRequest) (*domain.SwipeLog, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	mapper := mappers.NewSwipeMapper()
	swipeLog := mapper.CreateRequestToDomain(userID, req)

	if err := s.swipeRepo.Create(ctx, swipeLog); err != nil {
		return nil, fmt.Errorf("failed to create swipe log: %w", err)
	}

	return swipeLog, nil
}

// GetSwipeLogsByUser retrieves swipe logs for a user
func (s *swipeService) GetSwipeLogsByUser(ctx context.Context, userID uuid.UUID) ([]*domain.SwipeLog, error) {
	swipeLogs, err := s.swipeRepo.GetByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get swipe logs: %w", err)
	}
	return swipeLogs, nil
}