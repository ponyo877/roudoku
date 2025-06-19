package services

import (
	"context"
	"errors"

	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/pkg/logger"
)

// BusinessValidationService provides business rule validation
type BusinessValidationService interface {
	ValidateUserCanRateBook(ctx context.Context, userID uuid.UUID, bookID int64) error
	ValidateReadingSessionConsistency(ctx context.Context, session *domain.ReadingSession) error
	ValidateSwipeLimit(ctx context.Context, userID uuid.UUID) error
}

// businessValidationService implements BusinessValidationService
type businessValidationService struct {
	*BaseService
}

// NewBusinessValidationService creates a new business validation service
func NewBusinessValidationService(logger *logger.Logger) BusinessValidationService {
	return &businessValidationService{
		BaseService: NewBaseService(logger),
	}
}

// ValidateUserCanRateBook validates if a user can rate a specific book
func (s *businessValidationService) ValidateUserCanRateBook(ctx context.Context, userID uuid.UUID, bookID int64) error {
	s.logger.Debug("Validating user can rate book")
	// Simple validation - just check if IDs are valid
	if userID == uuid.Nil {
		return errors.New("invalid user ID")
	}
	if bookID <= 0 {
		return errors.New("invalid book ID")
	}
	return nil
}

// ValidateReadingSessionConsistency validates reading session data consistency
func (s *businessValidationService) ValidateReadingSessionConsistency(ctx context.Context, session *domain.ReadingSession) error {
	s.logger.Debug("Validating reading session consistency")
	
	if session == nil {
		return errors.New("session cannot be nil")
	}
	
	// Basic validations
	if session.UserID == uuid.Nil {
		return errors.New("invalid user ID")
	}
	if session.BookID <= 0 {
		return errors.New("invalid book ID")
	}
	if session.StartPos < 0 {
		return errors.New("start position cannot be negative")
	}
	if session.CurrentPos < 0 {
		return errors.New("current position cannot be negative")
	}
	if session.DurationSec > 24*60*60 {
		return errors.New("reading session duration cannot exceed 24 hours")
	}
	
	return nil
}

// ValidateSwipeLimit validates if user hasn't exceeded daily swipe limits
func (s *businessValidationService) ValidateSwipeLimit(ctx context.Context, userID uuid.UUID) error {
	s.logger.Debug("Validating swipe limits")
	
	if userID == uuid.Nil {
		return errors.New("invalid user ID")
	}
	
	// For now, always allow swipes (can be enhanced later)
	return nil
}