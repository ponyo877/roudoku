package entities

import (
	"database/sql/driver"
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// UserEntity represents a user in the database layer
type UserEntity struct {
	ID                    uuid.UUID      `db:"id"`
	DisplayName           string         `db:"display_name"`
	Email                 *string        `db:"email"`
	VoicePreset           VoicePresetDB  `db:"voice_preset"`
	SubscriptionStatus    string         `db:"subscription_status"`
	SubscriptionExpiresAt *time.Time     `db:"subscription_expires_at"`
	CreatedAt             time.Time      `db:"created_at"`
	UpdatedAt             time.Time      `db:"updated_at"`
}

// VoicePresetDB represents voice preset for database storage
type VoicePresetDB struct {
	Gender string  `json:"gender"`
	Pitch  float64 `json:"pitch"`
	Speed  float64 `json:"speed"`
}

// Value implements driver.Valuer interface for database storage
func (vp VoicePresetDB) Value() (driver.Value, error) {
	return json.Marshal(vp)
}

// Scan implements sql.Scanner interface for database retrieval
func (vp *VoicePresetDB) Scan(value interface{}) error {
	if value == nil {
		return nil
	}
	
	switch v := value.(type) {
	case []byte:
		return json.Unmarshal(v, vp)
	case string:
		return json.Unmarshal([]byte(v), vp)
	default:
		return json.Unmarshal([]byte(value.(string)), vp)
	}
}

// TableName returns the table name for the entity
func (UserEntity) TableName() string {
	return "users"
}