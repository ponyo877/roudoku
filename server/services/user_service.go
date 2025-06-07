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

// UserService defines the interface for user business logic
type UserService interface {
	CreateUser(ctx context.Context, req *models.CreateUserRequest) (*models.User, error)
	GetUser(ctx context.Context, id uuid.UUID) (*models.User, error)
	UpdateUser(ctx context.Context, id uuid.UUID, req *models.UpdateUserRequest) (*models.User, error)
	DeleteUser(ctx context.Context, id uuid.UUID) error
}

// userService implements UserService
type userService struct {
	userRepo  repository.UserRepository
	validator *validator.Validate
}

// NewUserService creates a new user service
func NewUserService(userRepo repository.UserRepository) UserService {
	return &userService{
		userRepo:  userRepo,
		validator: validator.New(),
	}
}

// CreateUser creates a new user
func (s *userService) CreateUser(ctx context.Context, req *models.CreateUserRequest) (*models.User, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	now := time.Now()
	user := &models.User{
		BaseModel: models.BaseModel{
			ID:        uuid.New(),
			CreatedAt: now,
			UpdatedAt: now,
		},
		DisplayName:        req.DisplayName,
		Email:              req.Email,
		VoicePreset:        getVoicePresetValue(req.VoicePreset, models.VoicePreset{Gender: "neutral", Pitch: 0.5, Speed: 1.0}),
		SubscriptionStatus: models.SubscriptionFree,
	}

	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return user, nil
}

// GetUser retrieves a user by ID
func (s *userService) GetUser(ctx context.Context, id uuid.UUID) (*models.User, error) {
	user, err := s.userRepo.GetByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get user: %w", err)
	}
	return user, nil
}

// UpdateUser updates a user
func (s *userService) UpdateUser(ctx context.Context, id uuid.UUID, req *models.UpdateUserRequest) (*models.User, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	user, err := s.userRepo.GetByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	// Update fields if provided
	if req.DisplayName != nil {
		user.DisplayName = *req.DisplayName
	}
	if req.Email != nil {
		user.Email = req.Email
	}
	if req.VoicePreset != nil {
		user.VoicePreset = *req.VoicePreset
	}
	if req.SubscriptionStatus != nil {
		user.SubscriptionStatus = *req.SubscriptionStatus
	}
	if req.SubscriptionExpiresAt != nil {
		user.SubscriptionExpiresAt = req.SubscriptionExpiresAt
	}

	user.UpdatedAt = time.Now()

	if err := s.userRepo.Update(ctx, user); err != nil {
		return nil, fmt.Errorf("failed to update user: %w", err)
	}

	return user, nil
}

// DeleteUser deletes a user
func (s *userService) DeleteUser(ctx context.Context, id uuid.UUID) error {
	if err := s.userRepo.Delete(ctx, id); err != nil {
		return fmt.Errorf("failed to delete user: %w", err)
	}
	return nil
}

// Helper functions
func getVoicePresetValue(ptr *models.VoicePreset, defaultVal models.VoicePreset) models.VoicePreset {
	if ptr == nil {
		return defaultVal
	}
	return *ptr
}