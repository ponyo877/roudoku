package domain

import (
	"time"

	"github.com/google/uuid"
)

// AudioFile represents a TTS-generated audio file
type AudioFile struct {
	ID               uuid.UUID  `json:"id" db:"id"`
	UserID           uuid.UUID  `json:"user_id" db:"user_id"`
	BookID           *int64     `json:"book_id,omitempty" db:"book_id"`
	ChapterID        *uuid.UUID `json:"chapter_id,omitempty" db:"chapter_id"`
	TextContent      string     `json:"text_content" db:"text_content"`
	TextHash         string     `json:"text_hash" db:"text_hash"`
	VoiceConfig      string     `json:"voice_config" db:"voice_config"` // JSONB stored as string
	FilePath         string     `json:"file_path" db:"file_path"`
	FileSizeBytes    int64      `json:"file_size_bytes" db:"file_size_bytes"`
	DurationSeconds  float64    `json:"duration_seconds" db:"duration_seconds"`
	Format           string     `json:"format" db:"format"`
	SampleRate       int        `json:"sample_rate" db:"sample_rate"`
	BitRate          int        `json:"bit_rate" db:"bit_rate"`
	Status           string     `json:"status" db:"status"`
	ErrorMessage     *string    `json:"error_message,omitempty" db:"error_message"`
	PlayCount        int        `json:"play_count" db:"play_count"`
	LastPlayedAt     *time.Time `json:"last_played_at,omitempty" db:"last_played_at"`
	ExpiresAt        *time.Time `json:"expires_at,omitempty" db:"expires_at"`
	CreatedAt        time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at" db:"updated_at"`
}

// AudioPlaybackSession represents a user's audio playback session
type AudioPlaybackSession struct {
	ID              uuid.UUID `json:"id" db:"id"`
	UserID          uuid.UUID `json:"user_id" db:"user_id"`
	AudioFileID     uuid.UUID `json:"audio_file_id" db:"audio_file_id"`
	StartPositionMs int       `json:"start_position_ms" db:"start_position_ms"`
	EndPositionMs   *int      `json:"end_position_ms,omitempty" db:"end_position_ms"`
	DurationMs      int       `json:"duration_ms" db:"duration_ms"`
	PlaybackSpeed   float64   `json:"playback_speed" db:"playback_speed"`
	Completed       bool      `json:"completed" db:"completed"`
	DeviceType      *string   `json:"device_type,omitempty" db:"device_type"`
	CreatedAt       time.Time `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time `json:"updated_at" db:"updated_at"`
}

// NotificationPreferences represents user notification settings
type NotificationPreferences struct {
	UserID                uuid.UUID `json:"user_id" db:"user_id"`
	PushEnabled           bool      `json:"push_enabled" db:"push_enabled"`
	EmailEnabled          bool      `json:"email_enabled" db:"email_enabled"`
	ReadingReminders      bool      `json:"reading_reminders" db:"reading_reminders"`
	ReadingReminderTime   string    `json:"reading_reminder_time" db:"reading_reminder_time"`
	WeeklyProgress        bool      `json:"weekly_progress" db:"weekly_progress"`
	Achievements          bool      `json:"achievements" db:"achievements"`
	Recommendations       bool      `json:"recommendations" db:"recommendations"`
	SilentHoursEnabled    bool      `json:"silent_hours_enabled" db:"silent_hours_enabled"`
	SilentHoursStart      string    `json:"silent_hours_start" db:"silent_hours_start"`
	SilentHoursEnd        string    `json:"silent_hours_end" db:"silent_hours_end"`
	SoundEnabled          bool      `json:"sound_enabled" db:"sound_enabled"`
	VibrationEnabled      bool      `json:"vibration_enabled" db:"vibration_enabled"`
	CreatedAt             time.Time `json:"created_at" db:"created_at"`
	UpdatedAt             time.Time `json:"updated_at" db:"updated_at"`
}

// FCMToken represents a Firebase Cloud Messaging token
type FCMToken struct {
	ID         uuid.UUID `json:"id" db:"id"`
	UserID     uuid.UUID `json:"user_id" db:"user_id"`
	Token      string    `json:"token" db:"token"`
	DeviceType string    `json:"device_type" db:"device_type"`
	DeviceID   string    `json:"device_id" db:"device_id"`
	IsActive   bool      `json:"is_active" db:"is_active"`
	LastUsedAt time.Time `json:"last_used_at" db:"last_used_at"`
	CreatedAt  time.Time `json:"created_at" db:"created_at"`
	UpdatedAt  time.Time `json:"updated_at" db:"updated_at"`
}

// Notification represents a notification sent to a user
type Notification struct {
	ID             uuid.UUID              `json:"id" db:"id"`
	UserID         uuid.UUID              `json:"user_id" db:"user_id"`
	Title          string                 `json:"title" db:"title"`
	Body           string                 `json:"body" db:"body"`
	Data           map[string]interface{} `json:"data,omitempty" db:"data"`
	Type           string                 `json:"type" db:"type"`
	IsRead         bool                   `json:"is_read" db:"is_read"`
	ReadAt         *time.Time             `json:"read_at,omitempty" db:"read_at"`
	SentAt         time.Time              `json:"sent_at" db:"sent_at"`
	ExpiresAt      *time.Time             `json:"expires_at,omitempty" db:"expires_at"`
	FCMMessageID   *string                `json:"fcm_message_id,omitempty" db:"fcm_message_id"`
	DeliveryStatus string                 `json:"delivery_status" db:"delivery_status"`
	ErrorMessage   *string                `json:"error_message,omitempty" db:"error_message"`
	CreatedAt      time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt      time.Time              `json:"updated_at" db:"updated_at"`
}

// ScheduledNotification represents a scheduled or recurring notification
type ScheduledNotification struct {
	ID                     uuid.UUID              `json:"id" db:"id"`
	UserID                 uuid.UUID              `json:"user_id" db:"user_id"`
	Title                  string                 `json:"title" db:"title"`
	Body                   string                 `json:"body" db:"body"`
	Data                   map[string]interface{} `json:"data,omitempty" db:"data"`
	Type                   string                 `json:"type" db:"type"`
	ScheduleAt             time.Time              `json:"schedule_at" db:"schedule_at"`
	IsRecurring            bool                   `json:"is_recurring" db:"is_recurring"`
	RecurringFrequency     *string                `json:"recurring_frequency,omitempty" db:"recurring_frequency"`
	RecurringDaysOfWeek    []int                  `json:"recurring_days_of_week,omitempty" db:"recurring_days_of_week"`
	RecurringTimeOfDay     *string                `json:"recurring_time_of_day,omitempty" db:"recurring_time_of_day"`
	RecurringEndDate       *time.Time             `json:"recurring_end_date,omitempty" db:"recurring_end_date"`
	IsActive               bool                   `json:"is_active" db:"is_active"`
	LastExecutedAt         *time.Time             `json:"last_executed_at,omitempty" db:"last_executed_at"`
	NextExecutionAt        *time.Time             `json:"next_execution_at,omitempty" db:"next_execution_at"`
	ExecutionCount         int                    `json:"execution_count" db:"execution_count"`
	CreatedAt              time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt              time.Time              `json:"updated_at" db:"updated_at"`
}

// TTSConfig represents TTS configuration (kept for backward compatibility)
type TTSConfig struct {
	Language   string  `json:"language"`
	Voice      string  `json:"voice"`
	Speed      float32 `json:"speed"`
	Pitch      float32 `json:"pitch"`
	VolumeGain float32 `json:"volume_gain"`
}