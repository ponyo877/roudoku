package mappers

import (
	"time"

	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/entities"
)

// SessionMapper handles conversions between reading session representations
type SessionMapper struct{}

// NewSessionMapper creates a new session mapper
func NewSessionMapper() *SessionMapper {
	return &SessionMapper{}
}

// DomainToDTO converts domain reading session to DTO response
func (m *SessionMapper) DomainToDTO(session *domain.ReadingSession) *dto.ReadingSessionResponse {
	if session == nil {
		return nil
	}

	return &dto.ReadingSessionResponse{
		ID:          session.ID,
		UserID:      session.UserID,
		BookID:      session.BookID,
		StartPos:    session.StartPos,
		CurrentPos:  session.CurrentPos,
		DurationSec: session.DurationSec,
		Mood:        session.Mood,
		Weather:     session.Weather,
		CreatedAt:   session.CreatedAt,
		UpdatedAt:   session.UpdatedAt,
	}
}

// DomainToDTOSlice converts slice of domain reading sessions to DTO responses
func (m *SessionMapper) DomainToDTOSlice(sessions []*domain.ReadingSession) []*dto.ReadingSessionResponse {
	result := make([]*dto.ReadingSessionResponse, len(sessions))
	for i, session := range sessions {
		result[i] = m.DomainToDTO(session)
	}
	return result
}

// DomainToEntity converts domain reading session to database entity
func (m *SessionMapper) DomainToEntity(session *domain.ReadingSession) *entities.ReadingSessionEntity {
	if session == nil {
		return nil
	}

	return &entities.ReadingSessionEntity{
		ID:          session.ID,
		UserID:      session.UserID,
		BookID:      session.BookID,
		StartPos:    session.StartPos,
		CurrentPos:  session.CurrentPos,
		DurationSec: session.DurationSec,
		Mood:        session.Mood,
		Weather:     session.Weather,
		CreatedAt:   session.CreatedAt,
		UpdatedAt:   session.UpdatedAt,
	}
}

// EntityToDomain converts database entity to domain reading session
func (m *SessionMapper) EntityToDomain(entity *entities.ReadingSessionEntity) *domain.ReadingSession {
	if entity == nil {
		return nil
	}

	return &domain.ReadingSession{
		ID:          entity.ID,
		UserID:      entity.UserID,
		BookID:      entity.BookID,
		StartPos:    entity.StartPos,
		CurrentPos:  entity.CurrentPos,
		DurationSec: entity.DurationSec,
		Mood:        entity.Mood,
		Weather:     entity.Weather,
		CreatedAt:   entity.CreatedAt,
		UpdatedAt:   entity.UpdatedAt,
	}
}

// EntityToDomainSlice converts slice of database entities to domain reading sessions
func (m *SessionMapper) EntityToDomainSlice(entities []*entities.ReadingSessionEntity) []*domain.ReadingSession {
	result := make([]*domain.ReadingSession, len(entities))
	for i, entity := range entities {
		result[i] = m.EntityToDomain(entity)
	}
	return result
}

// CreateRequestToDomain converts create request to domain reading session
func (m *SessionMapper) CreateRequestToDomain(userID uuid.UUID, req *dto.CreateReadingSessionRequest) *domain.ReadingSession {
	now := time.Now()
	return &domain.ReadingSession{
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
}