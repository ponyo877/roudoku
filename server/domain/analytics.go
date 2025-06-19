package domain

import (
	"time"

	"github.com/google/uuid"
)

// ReadingAnalytics represents daily reading statistics
type ReadingAnalytics struct {
	ID                      uuid.UUID `json:"id" db:"id"`
	UserID                  uuid.UUID `json:"user_id" db:"user_id"`
	Date                    time.Time `json:"date" db:"date"`
	TotalReadingTimeMinutes int       `json:"total_reading_time_minutes" db:"total_reading_time_minutes"`
	TotalPagesRead          int       `json:"total_pages_read" db:"total_pages_read"`
	TotalWordsRead          int       `json:"total_words_read" db:"total_words_read"`
	BooksStarted            int       `json:"books_started" db:"books_started"`
	BooksCompleted          int       `json:"books_completed" db:"books_completed"`
	ReadingSessionsCount    int       `json:"reading_sessions_count" db:"reading_sessions_count"`
	LongestSessionMinutes   int       `json:"longest_session_minutes" db:"longest_session_minutes"`
	AverageSessionMinutes   int       `json:"average_session_minutes" db:"average_session_minutes"`
	FavoriteGenre           *string   `json:"favorite_genre,omitempty" db:"favorite_genre"`
	FavoriteTimeOfDay       *string   `json:"favorite_time_of_day,omitempty" db:"favorite_time_of_day"`
	CreatedAt               time.Time `json:"created_at" db:"created_at"`
	UpdatedAt               time.Time `json:"updated_at" db:"updated_at"`
}

// ReadingStreak represents user's reading streak information
type ReadingStreak struct {
	ID                 uuid.UUID  `json:"id" db:"id"`
	UserID             uuid.UUID  `json:"user_id" db:"user_id"`
	CurrentStreakDays  int        `json:"current_streak_days" db:"current_streak_days"`
	LongestStreakDays  int        `json:"longest_streak_days" db:"longest_streak_days"`
	LastReadingDate    *time.Time `json:"last_reading_date,omitempty" db:"last_reading_date"`
	StreakStartDate    *time.Time `json:"streak_start_date,omitempty" db:"streak_start_date"`
	TotalReadingDays   int        `json:"total_reading_days" db:"total_reading_days"`
	CreatedAt          time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt          time.Time  `json:"updated_at" db:"updated_at"`
}

// ReadingGoal represents a user's reading goal
type ReadingGoal struct {
	ID           uuid.UUID  `json:"id" db:"id"`
	UserID       uuid.UUID  `json:"user_id" db:"user_id"`
	GoalType     string     `json:"goal_type" db:"goal_type"`
	TargetValue  int        `json:"target_value" db:"target_value"`
	CurrentValue int        `json:"current_value" db:"current_value"`
	PeriodStart  time.Time  `json:"period_start" db:"period_start"`
	PeriodEnd    time.Time  `json:"period_end" db:"period_end"`
	IsAchieved   bool       `json:"is_achieved" db:"is_achieved"`
	AchievedAt   *time.Time `json:"achieved_at,omitempty" db:"achieved_at"`
	IsActive     bool       `json:"is_active" db:"is_active"`
	CreatedAt    time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at" db:"updated_at"`
}

// Achievement represents a system achievement
type Achievement struct {
	ID               uuid.UUID `json:"id" db:"id"`
	Name             string    `json:"name" db:"name"`
	Description      string    `json:"description" db:"description"`
	IconURL          *string   `json:"icon_url,omitempty" db:"icon_url"`
	Category         string    `json:"category" db:"category"`
	RequirementType  string    `json:"requirement_type" db:"requirement_type"`
	RequirementValue int       `json:"requirement_value" db:"requirement_value"`
	Points           int       `json:"points" db:"points"`
	IsActive         bool      `json:"is_active" db:"is_active"`
	CreatedAt        time.Time `json:"created_at" db:"created_at"`
}

// UserAchievement represents an achievement earned by a user
type UserAchievement struct {
	ID            uuid.UUID `json:"id" db:"id"`
	UserID        uuid.UUID `json:"user_id" db:"user_id"`
	AchievementID uuid.UUID `json:"achievement_id" db:"achievement_id"`
	EarnedAt      time.Time `json:"earned_at" db:"earned_at"`
	Progress      int       `json:"progress" db:"progress"`
	Notified      bool      `json:"notified" db:"notified"`
	Achievement   *Achievement `json:"achievement,omitempty"`
}

// ReadingContext represents the context of a reading session
type ReadingContext struct {
	ID                uuid.UUID  `json:"id" db:"id"`
	UserID            uuid.UUID  `json:"user_id" db:"user_id"`
	SessionID         *uuid.UUID `json:"session_id,omitempty" db:"session_id"`
	Mood              *string    `json:"mood,omitempty" db:"mood"`
	Weather           *string    `json:"weather,omitempty" db:"weather"`
	LocationType      *string    `json:"location_type,omitempty" db:"location_type"`
	TimeOfDay         *string    `json:"time_of_day,omitempty" db:"time_of_day"`
	DeviceType        *string    `json:"device_type,omitempty" db:"device_type"`
	AmbientNoiseLevel *string    `json:"ambient_noise_level,omitempty" db:"ambient_noise_level"`
	ReadingPosition   *string    `json:"reading_position,omitempty" db:"reading_position"`
	Notes             *string    `json:"notes,omitempty" db:"notes"`
	CreatedAt         time.Time  `json:"created_at" db:"created_at"`
}

// BookProgress represents detailed progress tracking for a book
type BookProgress struct {
	ID                           uuid.UUID  `json:"id" db:"id"`
	UserID                       uuid.UUID  `json:"user_id" db:"user_id"`
	BookID                       int64      `json:"book_id" db:"book_id"`
	CurrentChapterID             *uuid.UUID `json:"current_chapter_id,omitempty" db:"current_chapter_id"`
	CurrentPosition              int        `json:"current_position" db:"current_position"`
	CurrentPage                  int        `json:"current_page" db:"current_page"`
	TotalPages                   int        `json:"total_pages" db:"total_pages"`
	ProgressPercentage           float64    `json:"progress_percentage" db:"progress_percentage"`
	EstimatedTimeRemainingMinutes *int      `json:"estimated_time_remaining_minutes,omitempty" db:"estimated_time_remaining_minutes"`
	AverageReadingSpeedWPM       *int       `json:"average_reading_speed_wpm,omitempty" db:"average_reading_speed_wpm"`
	StartedAt                    time.Time  `json:"started_at" db:"started_at"`
	LastReadAt                   time.Time  `json:"last_read_at" db:"last_read_at"`
	CompletedAt                  *time.Time `json:"completed_at,omitempty" db:"completed_at"`
	IsCompleted                  bool       `json:"is_completed" db:"is_completed"`
	IsAbandoned                  bool       `json:"is_abandoned" db:"is_abandoned"`
	AbandonedReason              *string    `json:"abandoned_reason,omitempty" db:"abandoned_reason"`
	CreatedAt                    time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt                    time.Time  `json:"updated_at" db:"updated_at"`
	Book                         *Book      `json:"book,omitempty"`
}

// ReadingInsight represents an AI-generated insight
type ReadingInsight struct {
	ID             uuid.UUID              `json:"id" db:"id"`
	UserID         uuid.UUID              `json:"user_id" db:"user_id"`
	InsightType    string                 `json:"insight_type" db:"insight_type"`
	Title          string                 `json:"title" db:"title"`
	Description    string                 `json:"description" db:"description"`
	Data           map[string]interface{} `json:"data,omitempty" db:"data"`
	RelevanceScore float64                `json:"relevance_score" db:"relevance_score"`
	IsRead         bool                   `json:"is_read" db:"is_read"`
	ReadAt         *time.Time             `json:"read_at,omitempty" db:"read_at"`
	ExpiresAt      *time.Time             `json:"expires_at,omitempty" db:"expires_at"`
	CreatedAt      time.Time              `json:"created_at" db:"created_at"`
}