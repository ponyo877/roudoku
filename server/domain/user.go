package domain

import (
	"time"

	"github.com/google/uuid"
)

// User represents a user in the domain layer
type User struct {
	ID                    uuid.UUID
	FirebaseUID           string
	DisplayName           string
	Email                 *string
	VoicePreset           VoicePreset
	SubscriptionStatus    SubscriptionStatus
	SubscriptionExpiresAt *time.Time
	CreatedAt             time.Time
	UpdatedAt             time.Time
}

// VoicePreset represents user's voice preferences
type VoicePreset struct {
	Gender string
	Pitch  float64
	Speed  float64
}

// SubscriptionStatus represents user's subscription status
type SubscriptionStatus string

const (
	SubscriptionFree    SubscriptionStatus = "free"
	SubscriptionPremium SubscriptionStatus = "premium"
)

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

// CanAccessPremiumContent checks if user can access premium content
func (u *User) CanAccessPremiumContent() bool {
	return u.HasValidSubscription()
}

// NewUser creates a new user with default values
func NewUser(firebaseUID string, displayName string, email *string) *User {
	now := time.Now()
	return &User{
		ID:          uuid.New(),
		FirebaseUID: firebaseUID,
		DisplayName: displayName,
		Email:       email,
		VoicePreset: VoicePreset{
			Gender: "neutral",
			Pitch:  0.5,
			Speed:  1.0,
		},
		SubscriptionStatus: SubscriptionFree,
		CreatedAt:          now,
		UpdatedAt:          now,
	}
}