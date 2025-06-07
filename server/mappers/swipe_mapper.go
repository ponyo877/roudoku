package mappers

import (
	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/entities"
)

// SwipeMapper handles conversions between swipe log representations
type SwipeMapper struct{}

// NewSwipeMapper creates a new swipe mapper
func NewSwipeMapper() *SwipeMapper {
	return &SwipeMapper{}
}

// DomainToDTO converts domain swipe log to DTO response
func (m *SwipeMapper) DomainToDTO(swipeLog *domain.SwipeLog) *dto.SwipeLogResponse {
	if swipeLog == nil {
		return nil
	}

	return &dto.SwipeLogResponse{
		ID:        swipeLog.ID,
		UserID:    swipeLog.UserID,
		QuoteID:   swipeLog.QuoteID,
		Mode:      string(swipeLog.Mode),
		Choice:    int(swipeLog.Choice),
		CreatedAt: swipeLog.CreatedAt,
	}
}

// DomainToDTOSlice converts slice of domain swipe logs to DTO responses
func (m *SwipeMapper) DomainToDTOSlice(swipeLogs []*domain.SwipeLog) []*dto.SwipeLogResponse {
	result := make([]*dto.SwipeLogResponse, len(swipeLogs))
	for i, swipeLog := range swipeLogs {
		result[i] = m.DomainToDTO(swipeLog)
	}
	return result
}

// DomainToEntity converts domain swipe log to database entity
func (m *SwipeMapper) DomainToEntity(swipeLog *domain.SwipeLog) *entities.SwipeLogEntity {
	if swipeLog == nil {
		return nil
	}

	return &entities.SwipeLogEntity{
		ID:        swipeLog.ID,
		UserID:    swipeLog.UserID,
		QuoteID:   swipeLog.QuoteID,
		Mode:      string(swipeLog.Mode),
		Choice:    int(swipeLog.Choice),
		CreatedAt: swipeLog.CreatedAt,
	}
}

// EntityToDomain converts database entity to domain swipe log
func (m *SwipeMapper) EntityToDomain(entity *entities.SwipeLogEntity) *domain.SwipeLog {
	if entity == nil {
		return nil
	}

	return &domain.SwipeLog{
		ID:        entity.ID,
		UserID:    entity.UserID,
		QuoteID:   entity.QuoteID,
		Mode:      domain.SwipeMode(entity.Mode),
		Choice:    domain.SwipeChoice(entity.Choice),
		CreatedAt: entity.CreatedAt,
	}
}

// EntityToDomainSlice converts slice of database entities to domain swipe logs
func (m *SwipeMapper) EntityToDomainSlice(entities []*entities.SwipeLogEntity) []*domain.SwipeLog {
	result := make([]*domain.SwipeLog, len(entities))
	for i, entity := range entities {
		result[i] = m.EntityToDomain(entity)
	}
	return result
}