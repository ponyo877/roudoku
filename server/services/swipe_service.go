package services

import (
	"context"
	"fmt"

	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/mappers"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/repository"
)

// SwipeService defines the interface for swipe business logic
type SwipeService interface {
	CreateSwipeLog(ctx context.Context, userID uuid.UUID, req *dto.CreateSwipeLogRequest) (*domain.SwipeLog, error)
	GetSwipeLogsByUser(ctx context.Context, userID uuid.UUID) ([]*domain.SwipeLog, error)
}

// swipeService implements SwipeService
type swipeService struct {
	*BaseService
	swipeRepo         repository.SwipeRepository
	validationService BusinessValidationService
}

// NewSwipeService creates a new swipe service
func NewSwipeService(swipeRepo repository.SwipeRepository, validationService BusinessValidationService, logger *logger.Logger) SwipeService {
	return &swipeService{
		BaseService:       NewBaseService(logger),
		swipeRepo:         swipeRepo,
		validationService: validationService,
	}
}

// CreateSwipeLog creates a new swipe log
func (s *swipeService) CreateSwipeLog(ctx context.Context, userID uuid.UUID, req *dto.CreateSwipeLogRequest) (*domain.SwipeLog, error) {
	s.logger.Info("Creating swipe log")
	
	if err := s.ValidateStruct(req); err != nil {
		s.logger.Error("Validation failed")
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	// Business validation
	if s.validationService != nil {
		if err := s.validationService.ValidateSwipeLimit(ctx, userID); err != nil {
			s.logger.Error("Business validation failed")
			return nil, fmt.Errorf("business validation failed: %w", err)
		}
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