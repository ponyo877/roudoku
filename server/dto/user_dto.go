package dto

import (
	"time"

	"github.com/google/uuid"
)

// UserResponse represents a user response in the API layer
type UserResponse struct {
	ID                    uuid.UUID           `json:"id"`
	FirebaseUID           string              `json:"firebase_uid"`
	DisplayName           string              `json:"display_name"`
	Email                 *string             `json:"email"`
	VoicePreset           VoicePresetResponse `json:"voice_preset"`
	SubscriptionStatus    string              `json:"subscription_status"`
	SubscriptionExpiresAt *time.Time          `json:"subscription_expires_at"`
	CreatedAt             time.Time           `json:"created_at"`
	UpdatedAt             time.Time           `json:"updated_at"`
}

// VoicePresetResponse represents voice preset in API responses
type VoicePresetResponse struct {
	Gender string  `json:"gender"`
	Pitch  float64 `json:"pitch"`
	Speed  float64 `json:"speed"`
}

// CreateUserRequest represents the request to create a user
type CreateUserRequest struct {
	FirebaseUID string                  `json:"firebase_uid" validate:"required"`
	DisplayName string                  `json:"display_name" validate:"omitempty,min=1,max=100"`
	Email       *string                 `json:"email" validate:"omitempty,email"`
	VoicePreset *VoicePresetRequest     `json:"voice_preset"`
}

// UpdateUserRequest represents the request to update a user
type UpdateUserRequest struct {
	DisplayName           *string             `json:"display_name" validate:"omitempty,min=1,max=100"`
	Email                 *string             `json:"email" validate:"omitempty,email"`
	VoicePreset           *VoicePresetRequest `json:"voice_preset"`
	SubscriptionStatus    *string             `json:"subscription_status" validate:"omitempty,oneof=free premium"`
	SubscriptionExpiresAt *time.Time          `json:"subscription_expires_at"`
}

// VoicePresetRequest represents voice preset in API requests
type VoicePresetRequest struct {
	Gender string  `json:"gender" validate:"required,oneof=male female neutral"`
	Pitch  float64 `json:"pitch" validate:"required,min=0.0,max=1.0"`
	Speed  float64 `json:"speed" validate:"required,min=0.5,max=2.0"`
}