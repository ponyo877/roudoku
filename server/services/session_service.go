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

// SessionService defines the interface for reading session business logic
type SessionService interface {
	CreateReadingSession(ctx context.Context, userID uuid.UUID, req *models.CreateReadingSessionRequest) (*models.ReadingSession, error)
	GetReadingSession(ctx context.Context, sessionID uuid.UUID) (*models.ReadingSession, error)
	UpdateReadingSession(ctx context.Context, sessionID uuid.UUID, req *models.UpdateReadingSessionRequest) (*models.ReadingSession, error)
	GetUserReadingSessions(ctx context.Context, userID uuid.UUID, limit int) ([]*models.ReadingSession, error)
}

// sessionService implements SessionService
type sessionService struct {
	sessionRepo repository.SessionRepository
	validator   *validator.Validate
}

// NewSessionService creates a new session service
func NewSessionService(sessionRepo repository.SessionRepository) SessionService {
	return &sessionService{
		sessionRepo: sessionRepo,
		validator:   validator.New(),
	}
}

// CreateReadingSession creates a new reading session
func (s *sessionService) CreateReadingSession(ctx context.Context, userID uuid.UUID, req *models.CreateReadingSessionRequest) (*models.ReadingSession, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	now := time.Now()
	session := &models.ReadingSession{
		ID:          uuid.New(),
		UserID:      userID,
		BookID:      req.BookID,
		StartPos:    req.StartPos,
		CurrentPos:  req.StartPos,
		DurationSec: 0,
		Mood:        req.Mood,
		Weather:     req.Weather,
		CreatedAt:   now,
		UpdatedAt:   now,
	}

	if err := s.sessionRepo.Create(ctx, session); err != nil {
		return nil, fmt.Errorf("failed to create reading session: %w", err)
	}

	return session, nil
}

// GetReadingSession retrieves a reading session by ID
func (s *sessionService) GetReadingSession(ctx context.Context, sessionID uuid.UUID) (*models.ReadingSession, error) {
	session, err := s.sessionRepo.GetByID(ctx, sessionID)
	if err != nil {
		return nil, fmt.Errorf("failed to get reading session: %w", err)
	}
	return session, nil
}

// UpdateReadingSession updates a reading session
func (s *sessionService) UpdateReadingSession(ctx context.Context, sessionID uuid.UUID, req *models.UpdateReadingSessionRequest) (*models.ReadingSession, error) {
	if err := s.validator.Struct(req); err != nil {
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
func (s *sessionService) GetUserReadingSessions(ctx context.Context, userID uuid.UUID, limit int) ([]*models.ReadingSession, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}

	sessions, err := s.sessionRepo.GetByUserID(ctx, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get user reading sessions: %w", err)
	}
	return sessions, nil
}