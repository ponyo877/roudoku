package mappers

import (
	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/entities"
)

// UserMapper handles conversions between user representations
type UserMapper struct{}

// NewUserMapper creates a new user mapper
func NewUserMapper() *UserMapper {
	return &UserMapper{}
}

// DomainToDTO converts domain user to DTO response
func (m *UserMapper) DomainToDTO(user *domain.User) *dto.UserResponse {
	if user == nil {
		return nil
	}

	return &dto.UserResponse{
		ID:          user.ID,
		DisplayName: user.DisplayName,
		Email:       user.Email,
		VoicePreset: dto.VoicePresetResponse{
			Gender: user.VoicePreset.Gender,
			Pitch:  user.VoicePreset.Pitch,
			Speed:  user.VoicePreset.Speed,
		},
		SubscriptionStatus:    string(user.SubscriptionStatus),
		SubscriptionExpiresAt: user.SubscriptionExpiresAt,
		CreatedAt:             user.CreatedAt,
		UpdatedAt:             user.UpdatedAt,
	}
}

// CreateRequestToDomain converts create request to domain user
func (m *UserMapper) CreateRequestToDomain(req *dto.CreateUserRequest) *domain.User {
	user := domain.NewUser(req.DisplayName, req.Email)
	
	if req.VoicePreset != nil {
		user.VoicePreset = domain.VoicePreset{
			Gender: req.VoicePreset.Gender,
			Pitch:  req.VoicePreset.Pitch,
			Speed:  req.VoicePreset.Speed,
		}
	}
	
	return user
}

// DomainToEntity converts domain user to database entity
func (m *UserMapper) DomainToEntity(user *domain.User) *entities.UserEntity {
	if user == nil {
		return nil
	}

	return &entities.UserEntity{
		ID:          user.ID,
		DisplayName: user.DisplayName,
		Email:       user.Email,
		VoicePreset: entities.VoicePresetDB{
			Gender: user.VoicePreset.Gender,
			Pitch:  user.VoicePreset.Pitch,
			Speed:  user.VoicePreset.Speed,
		},
		SubscriptionStatus:    string(user.SubscriptionStatus),
		SubscriptionExpiresAt: user.SubscriptionExpiresAt,
		CreatedAt:             user.CreatedAt,
		UpdatedAt:             user.UpdatedAt,
	}
}

// EntityToDomain converts database entity to domain user
func (m *UserMapper) EntityToDomain(entity *entities.UserEntity) *domain.User {
	if entity == nil {
		return nil
	}

	return &domain.User{
		ID:          entity.ID,
		DisplayName: entity.DisplayName,
		Email:       entity.Email,
		VoicePreset: domain.VoicePreset{
			Gender: entity.VoicePreset.Gender,
			Pitch:  entity.VoicePreset.Pitch,
			Speed:  entity.VoicePreset.Speed,
		},
		SubscriptionStatus:    domain.SubscriptionStatus(entity.SubscriptionStatus),
		SubscriptionExpiresAt: entity.SubscriptionExpiresAt,
		CreatedAt:             entity.CreatedAt,
		UpdatedAt:             entity.UpdatedAt,
	}
}

// EntityToDomainSlice converts slice of database entities to domain users
func (m *UserMapper) EntityToDomainSlice(entities []*entities.UserEntity) []*domain.User {
	result := make([]*domain.User, len(entities))
	for i, entity := range entities {
		result[i] = m.EntityToDomain(entity)
	}
	return result
}

// UpdateRequestApplyToDomain applies update request to domain user
func (m *UserMapper) UpdateRequestApplyToDomain(user *domain.User, req *dto.UpdateUserRequest) {
	if req.DisplayName != nil {
		user.DisplayName = *req.DisplayName
	}
	if req.Email != nil {
		user.Email = req.Email
	}
	if req.VoicePreset != nil {
		user.VoicePreset = domain.VoicePreset{
			Gender: req.VoicePreset.Gender,
			Pitch:  req.VoicePreset.Pitch,
			Speed:  req.VoicePreset.Speed,
		}
	}
	if req.SubscriptionStatus != nil {
		user.SubscriptionStatus = domain.SubscriptionStatus(*req.SubscriptionStatus)
	}
	if req.SubscriptionExpiresAt != nil {
		user.SubscriptionExpiresAt = req.SubscriptionExpiresAt
	}
}