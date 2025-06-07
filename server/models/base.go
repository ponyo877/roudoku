package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// BaseModel represents common fields for all models
type BaseModel struct {
	ID        uuid.UUID `json:"id" db:"id"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// VoicePreset represents user's voice preferences
type VoicePreset struct {
	Gender string  `json:"gender" validate:"required,oneof=male female neutral"`
	Pitch  float64 `json:"pitch" validate:"required,min=0.0,max=1.0"`
	Speed  float64 `json:"speed" validate:"required,min=0.5,max=2.0"`
}

// SubscriptionStatus represents user's subscription status
type SubscriptionStatus string

const (
	SubscriptionFree    SubscriptionStatus = "free"
	SubscriptionPremium SubscriptionStatus = "premium"
)

// User represents a user in the system
type User struct {
	BaseModel
	DisplayName            string              `json:"display_name" db:"display_name" validate:"omitempty,min=1,max=100"`
	Email                  *string             `json:"email" db:"email" validate:"omitempty,email"`
	VoicePreset            VoicePreset         `json:"voice_preset" db:"voice_preset"`
	SubscriptionStatus     SubscriptionStatus  `json:"subscription_status" db:"subscription_status" validate:"required,oneof=free premium"`
	SubscriptionExpiresAt  *time.Time          `json:"subscription_expires_at" db:"subscription_expires_at"`
}

// CreateUserRequest represents the request body for creating a user
type CreateUserRequest struct {
	DisplayName string       `json:"display_name" validate:"omitempty,min=1,max=100"`
	Email       *string      `json:"email" validate:"omitempty,email"`
	VoicePreset *VoicePreset `json:"voice_preset"`
}

// UpdateUserRequest represents the request body for updating a user
type UpdateUserRequest struct {
	DisplayName            *string             `json:"display_name" validate:"omitempty,min=1,max=100"`
	Email                  *string             `json:"email" validate:"omitempty,email"`
	VoicePreset            *VoicePreset        `json:"voice_preset"`
	SubscriptionStatus     *SubscriptionStatus `json:"subscription_status" validate:"omitempty,oneof=free premium"`
	SubscriptionExpiresAt  *time.Time          `json:"subscription_expires_at"`
}

// ToJSON converts VoicePreset to JSON string for database storage
func (vp VoicePreset) ToJSON() ([]byte, error) {
	return json.Marshal(vp)
}

// FromJSON converts JSON string to VoicePreset from database
func (vp *VoicePreset) FromJSON(data []byte) error {
	return json.Unmarshal(data, vp)
}

// HasValidSubscription checks if user has a valid subscription
func (u *User) HasValidSubscription() bool {
	if u.SubscriptionStatus != SubscriptionPremium {
		return false
	}
	if u.SubscriptionExpiresAt == nil {
		return true // lifetime subscription
	}
	return u.SubscriptionExpiresAt.After(time.Now())
}

// BoolPtr returns a pointer to a boolean value
func BoolPtr(b bool) *bool {
	return &b
}