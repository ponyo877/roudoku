package services

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/mappers"
	"github.com/ponyo877/roudoku/server/repository"
)

// SessionService defines the interface for reading session business logic
type SessionService interface {
	CreateReadingSession(ctx context.Context, userID uuid.UUID, req *dto.CreateReadingSessionRequest) (*domain.ReadingSession, error)
	GetReadingSession(ctx context.Context, sessionID uuid.UUID) (*domain.ReadingSession, error)
	UpdateReadingSession(ctx context.Context, sessionID uuid.UUID, req *dto.UpdateReadingSessionRequest) (*domain.ReadingSession, error)
	GetUserReadingSessions(ctx context.Context, userID uuid.UUID, limit int) ([]*domain.ReadingSession, error)
}

// sessionService implements SessionService
type sessionService struct {
	BaseService
	sessionRepo       repository.SessionRepository
	validationService BusinessValidationService
}

// NewSessionService creates a new session service
func NewSessionService(sessionRepo repository.SessionRepository, validationService BusinessValidationService, logger *zap.Logger) SessionService {
	return &sessionService{
		BaseService:       NewBaseService(logger),
		sessionRepo:       sessionRepo,
		validationService: validationService,
	}
}

// CreateReadingSession creates a new reading session
func (s *sessionService) CreateReadingSession(ctx context.Context, userID uuid.UUID, req *dto.CreateReadingSessionRequest) (*domain.ReadingSession, error) {
	s.logger.Info("Creating reading session", 
		zap.String("user_id", userID.String()), 
		zap.Int64("book_id", req.BookID),
		zap.Int("start_pos", req.StartPos))
	
	if err := s.Validate(req); err != nil {
		s.logger.Error("Validation failed", zap.Error(err))
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	mapper := mappers.NewSessionMapper()
	session := mapper.CreateRequestToDomain(userID, req)

	// Business validation
	if s.validationService != nil {
		if err := s.validationService.ValidateReadingSessionConsistency(ctx, session); err != nil {
			s.logger.Error("Business validation failed", zap.Error(err))
			return nil, fmt.Errorf("business validation failed: %w", err)
		}
	}

	if err := s.sessionRepo.Create(ctx, session); err != nil {
		return nil, fmt.Errorf("failed to create reading session: %w", err)
	}

	return session, nil
}

// GetReadingSession retrieves a reading session by ID
func (s *sessionService) GetReadingSession(ctx context.Context, sessionID uuid.UUID) (*domain.ReadingSession, error) {
	session, err := s.sessionRepo.GetByID(ctx, sessionID)
	if err != nil {
		return nil, fmt.Errorf("failed to get reading session: %w", err)
	}
	return session, nil
}

// UpdateReadingSession updates a reading session
func (s *sessionService) UpdateReadingSession(ctx context.Context, sessionID uuid.UUID, req *dto.UpdateReadingSessionRequest) (*domain.ReadingSession, error) {
	s.logger.Info("Updating reading session", zap.String("session_id", sessionID.String()))
	
	if err := s.Validate(req); err != nil {
		s.logger.Error("Validation failed", zap.Error(err))
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	session, err := s.sessionRepo.GetByID(ctx, sessionID)
	if err != nil {
		return nil, fmt.Errorf("failed to get reading session: %w", err)
	}

	// Update fields if provided
	if req.CurrentPos != nil {
		session.CurrentPos = *req.CurrentPos
	}
	if req.DurationSec != nil {
		session.DurationSec = *req.DurationSec
	}
	if req.Mood != nil {
		session.Mood = req.Mood
	}
	if req.Weather != nil {
		session.Weather = req.Weather
	}

	session.UpdatedAt = time.Now()

	if err := s.sessionRepo.Update(ctx, session); err != nil {
		return nil, fmt.Errorf("failed to update reading session: %w", err)
	}

	return session, nil
}

// GetUserReadingSessions retrieves reading sessions for a user
func (s *sessionService) GetUserReadingSessions(ctx context.Context, userID uuid.UUID, limit int) ([]*domain.ReadingSession, error) {
	if err := s.ValidateLimit(limit); err != nil {
		limit = DefaultLimit
	}
	limit = s.NormalizeLimit(limit)
	s.logger.Debug("Getting user reading sessions", zap.String("user_id", userID.String()), zap.Int("limit", limit))

	sessions, err := s.sessionRepo.GetByUserID(ctx, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get user reading sessions: %w", err)
	}
	return sessions, nil
}