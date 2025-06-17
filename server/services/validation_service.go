package services

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/ponyo877/roudoku/server/domain"
)

// BusinessValidationService provides business rule validation
type BusinessValidationService interface {
	ValidateUserCanRateBook(ctx context.Context, userID uuid.UUID, bookID int64) error
	ValidateReadingSessionConsistency(ctx context.Context, session *domain.ReadingSession) error
	ValidateSwipeLimit(ctx context.Context, userID uuid.UUID) error
}

// businessValidationService implements BusinessValidationService
type businessValidationService struct {
	BaseService
	userService    UserService
	bookService    BookService
	sessionService SessionService
	swipeService   SwipeService
}

// NewBusinessValidationService creates a new business validation service
func NewBusinessValidationService(
	userService UserService,
	bookService BookService,
	sessionService SessionService,
	swipeService SwipeService,
	logger *zap.Logger,
) BusinessValidationService {
	return &businessValidationService{
		BaseService:    NewBaseService(logger),
		userService:    userService,
		bookService:    bookService,
		sessionService: sessionService,
		swipeService:   swipeService,
	}
}

// ValidateUserCanRateBook validates if a user can rate a specific book
func (s *businessValidationService) ValidateUserCanRateBook(ctx context.Context, userID uuid.UUID, bookID int64) error {
	s.logger.Debug("Validating user can rate book", 
		zap.String("user_id", userID.String()),
		zap.Int64("book_id", bookID))

	// Check if user exists
	_, err := s.userService.GetUser(ctx, userID)
	if err != nil {
		return fmt.Errorf("user not found: %w", err)
	}

	// Check if book exists
	book, err := s.bookService.GetBook(ctx, bookID)
	if err != nil {
		return fmt.Errorf("book not found: %w", err)
	}

	// Check if book is active
	if !book.IsActive {
		return errors.New("cannot rate inactive book")
	}

	// Business rule: User should have at least one reading session for the book
	sessions, err := s.sessionService.GetUserReadingSessions(ctx, userID, 100)
	if err != nil {
		s.logger.Debug("No reading sessions found, allowing rating", zap.Error(err))
		return nil // Allow rating even without sessions for now
	}

	// Check if user has read the book
	hasReadBook := false
	for _, session := range sessions {
		if session.BookID == bookID {
			hasReadBook = true
			break
		}
	}

	if !hasReadBook {
		s.logger.Warn("User attempting to rate book without reading session", 
			zap.String("user_id", userID.String()),
			zap.Int64("book_id", bookID))
		// For now, just log the warning but allow the rating
		// In stricter business rules, this could return an error
	}

	return nil
}

// ValidateReadingSessionConsistency validates reading session data consistency
func (s *businessValidationService) ValidateReadingSessionConsistency(ctx context.Context, session *domain.ReadingSession) error {
	s.logger.Debug("Validating reading session consistency", 
		zap.String("session_id", session.ID.String()))

	// Validate user exists
	_, err := s.userService.GetUser(ctx, session.UserID)
	if err != nil {
		return fmt.Errorf("user not found: %w", err)
	}

	// Validate book exists
	book, err := s.bookService.GetBook(ctx, session.BookID)
	if err != nil {
		return fmt.Errorf("book not found: %w", err)
	}

	// Validate book is active
	if !book.IsActive {
		return errors.New("cannot create session for inactive book")
	}

	// Note: Chapter validation would require chapter management in the domain
	// For now, we'll skip chapter validation since ReadingSession doesn't have ChapterID
	// This could be added later if needed

	// Validate positions are reasonable
	if session.StartPos < 0 {
		return errors.New("start position cannot be negative")
	}
	if session.CurrentPos < 0 {
		return errors.New("current position cannot be negative")
	}

	// Validate duration is reasonable (max 24 hours)
	if session.DurationSec > 24*60*60 {
		return errors.New("reading session duration cannot exceed 24 hours")
	}

	return nil
}

// ValidateSwipeLimit validates if user hasn't exceeded daily swipe limits
func (s *businessValidationService) ValidateSwipeLimit(ctx context.Context, userID uuid.UUID) error {
	s.logger.Debug("Validating swipe limits", zap.String("user_id", userID.String()))

	// Get user's swipe history
	swipes, err := s.swipeService.GetSwipeLogsByUser(ctx, userID)
	if err != nil {
		s.logger.Debug("No swipe history found", zap.Error(err))
		return nil // No history, allow swipe
	}

	// Count swipes in the last 24 hours
	// For now, we'll implement a simple count
	// In production, this would use proper time-based filtering
	const maxSwipesPerDay = 1000
	
	if len(swipes) >= maxSwipesPerDay {
		s.logger.Warn("User exceeded daily swipe limit", 
			zap.String("user_id", userID.String()),
			zap.Int("swipe_count", len(swipes)))
		return fmt.Errorf("daily swipe limit exceeded (%d)", maxSwipesPerDay)
	}

	return nil
}