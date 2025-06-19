package dto

import (
	"time"

	"github.com/google/uuid"
)

// NotificationPreferences represents user notification preferences
type NotificationPreferences struct {
	UserID                  uuid.UUID `json:"user_id"`
	PushEnabled             bool      `json:"push_enabled"`
	EmailEnabled            bool      `json:"email_enabled"`
	ReadingReminders        bool      `json:"reading_reminders"`
	ReadingReminderTime     string    `json:"reading_reminder_time"` // Format: "HH:MM"
	WeeklyProgress          bool      `json:"weekly_progress"`
	Achievements            bool      `json:"achievements"`
	Recommendations         bool      `json:"recommendations"`
	SilentHoursEnabled      bool      `json:"silent_hours_enabled"`
	SilentHoursStart        string    `json:"silent_hours_start"` // Format: "HH:MM"
	SilentHoursEnd          string    `json:"silent_hours_end"`   // Format: "HH:MM"
	SoundEnabled            bool      `json:"sound_enabled"`
	VibrationEnabled        bool      `json:"vibration_enabled"`
	CreatedAt               time.Time `json:"created_at"`
	UpdatedAt               time.Time `json:"updated_at"`
}

// UpdateNotificationPreferencesRequest represents request to update notification preferences
type UpdateNotificationPreferencesRequest struct {
	PushEnabled          *bool   `json:"push_enabled,omitempty"`
	EmailEnabled         *bool   `json:"email_enabled,omitempty"`
	ReadingReminders     *bool   `json:"reading_reminders,omitempty"`
	ReadingReminderTime  *string `json:"reading_reminder_time,omitempty"`
	WeeklyProgress       *bool   `json:"weekly_progress,omitempty"`
	Achievements         *bool   `json:"achievements,omitempty"`
	Recommendations      *bool   `json:"recommendations,omitempty"`
	SilentHoursEnabled   *bool   `json:"silent_hours_enabled,omitempty"`
	SilentHoursStart     *string `json:"silent_hours_start,omitempty"`
	SilentHoursEnd       *string `json:"silent_hours_end,omitempty"`
	SoundEnabled         *bool   `json:"sound_enabled,omitempty"`
	VibrationEnabled     *bool   `json:"vibration_enabled,omitempty"`
}

// FCMTokenRequest represents FCM token registration request
type FCMTokenRequest struct {
	Token      string `json:"token" validate:"required"`
	DeviceType string `json:"device_type" validate:"required,oneof=ios android web"`
	DeviceID   string `json:"device_id" validate:"required"`
}

// FCMTokenResponse represents FCM token registration response
type FCMTokenResponse struct {
	Success     bool      `json:"success"`
	TokenID     uuid.UUID `json:"token_id"`
	RegisteredAt time.Time `json:"registered_at"`
}

// SendNotificationRequest represents notification send request
type SendNotificationRequest struct {
	UserIDs []uuid.UUID            `json:"user_ids" validate:"required,min=1"`
	Title   string                 `json:"title" validate:"required,min=1,max=100"`
	Body    string                 `json:"body" validate:"required,min=1,max=500"`
	Data    map[string]interface{} `json:"data,omitempty"`
	Type    string                 `json:"type" validate:"required,oneof=reading_reminder achievement weekly_progress recommendation general"`
}

// SendNotificationResponse represents notification send response
type SendNotificationResponse struct {
	Success      bool      `json:"success"`
	SentCount    int       `json:"sent_count"`
	FailedCount  int       `json:"failed_count"`
	NotificationID uuid.UUID `json:"notification_id"`
	SentAt       time.Time `json:"sent_at"`
}

// NotificationHistoryResponse represents notification history
type NotificationHistoryResponse struct {
	Notifications []NotificationHistory `json:"notifications"`
	TotalCount    int                   `json:"total_count"`
	Page          int                   `json:"page"`
	PerPage       int                   `json:"per_page"`
}

// NotificationHistory represents a single notification in history
type NotificationHistory struct {
	ID         uuid.UUID              `json:"id"`
	Title      string                 `json:"title"`
	Body       string                 `json:"body"`
	Data       map[string]interface{} `json:"data"`
	Type       string                 `json:"type"`
	IsRead     bool                   `json:"is_read"`
	ReadAt     *time.Time             `json:"read_at"`
	SentAt     time.Time              `json:"sent_at"`
	ExpiresAt  *time.Time             `json:"expires_at"`
}

// ScheduleNotificationRequest represents scheduled notification request
type ScheduleNotificationRequest struct {
	UserID     uuid.UUID              `json:"user_id" validate:"required"`
	Title      string                 `json:"title" validate:"required,min=1,max=100"`
	Body       string                 `json:"body" validate:"required,min=1,max=500"`
	Data       map[string]interface{} `json:"data,omitempty"`
	Type       string                 `json:"type" validate:"required"`
	ScheduleAt time.Time              `json:"schedule_at" validate:"required"`
	Recurring  *RecurringConfig       `json:"recurring,omitempty"`
}

// RecurringConfig represents recurring notification configuration
type RecurringConfig struct {
	Frequency string `json:"frequency" validate:"required,oneof=daily weekly monthly"`
	DaysOfWeek []int `json:"days_of_week,omitempty"` // 0=Sunday, 1=Monday, etc.
	TimeOfDay  string `json:"time_of_day" validate:"required"` // Format: "HH:MM"
	EndDate    *time.Time `json:"end_date,omitempty"`
}

// ScheduleNotificationResponse represents scheduled notification response
type ScheduleNotificationResponse struct {
	Success        bool      `json:"success"`
	ScheduleID     uuid.UUID `json:"schedule_id"`
	NextExecution  time.Time `json:"next_execution"`
	ScheduledAt    time.Time `json:"scheduled_at"`
}