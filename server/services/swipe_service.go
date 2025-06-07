package services

import (
	"context"
	"fmt"
	"time"

	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/models"
	"github.com/ponyo877/roudoku/server/repository"
)

// SwipeService defines the interface for swipe business logic
type SwipeService interface {
	CreateSwipeLog(ctx context.Context, userID uuid.UUID, req *models.CreateSwipeLogRequest) (*models.SwipeLog, error)
	GetSwipeLogsByUser(ctx context.Context, userID uuid.UUID) ([]*models.SwipeLog, error)
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
func (s *swipeService) CreateSwipeLog(ctx context.Context, userID uuid.UUID, req *models.CreateSwipeLogRequest) (*models.SwipeLog, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	swipeLog := &models.SwipeLog{
		ID:        uuid.New(),
		UserID:    userID,
		QuoteID:   req.QuoteID,
		Mode:      req.Mode,
		Choice:    req.Choice,
		CreatedAt: time.Now(),
	}

	if err := s.swipeRepo.Create(ctx, swipeLog); err != nil {
		return nil, fmt.Errorf("failed to create swipe log: %w", err)
	}

	return swipeLog, nil
}

// GetSwipeLogsByUser retrieves swipe logs for a user
func (s *swipeService) GetSwipeLogsByUser(ctx context.Context, userID uuid.UUID) ([]*models.SwipeLog, error) {
	swipeLogs, err := s.swipeRepo.GetByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get swipe logs: %w", err)
	}
	return swipeLogs, nil
}