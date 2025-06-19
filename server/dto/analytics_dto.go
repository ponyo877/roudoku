package dto

import (
	"time"

	"github.com/google/uuid"
)

// Analytics DTOs

// ReadingStatsRequest represents request for reading statistics
type ReadingStatsRequest struct {
	Period    string `json:"period" validate:"required,oneof=daily weekly monthly yearly all-time"`
	StartDate string `json:"start_date,omitempty"` // Format: YYYY-MM-DD
	EndDate   string `json:"end_date,omitempty"`   // Format: YYYY-MM-DD
}

// ReadingStatsResponse represents reading statistics response
type ReadingStatsResponse struct {
	Period              string                 `json:"period"`
	StartDate           string                 `json:"start_date"`
	EndDate             string                 `json:"end_date"`
	TotalReadingMinutes int                    `json:"total_reading_minutes"`
	TotalPagesRead      int                    `json:"total_pages_read"`
	TotalWordsRead      int                    `json:"total_words_read"`
	BooksStarted        int                    `json:"books_started"`
	BooksCompleted      int                    `json:"books_completed"`
	AverageSessionTime  int                    `json:"average_session_time_minutes"`
	LongestSessionTime  int                    `json:"longest_session_time_minutes"`
	ReadingStreak       int                    `json:"reading_streak_days"`
	FavoriteGenre       string                 `json:"favorite_genre,omitempty"`
	FavoriteTimeOfDay   string                 `json:"favorite_time_of_day,omitempty"`
	DailyBreakdown      []DailyReadingStats    `json:"daily_breakdown,omitempty"`
	GenreDistribution   map[string]int         `json:"genre_distribution,omitempty"`
	TimeDistribution    map[string]int         `json:"time_distribution,omitempty"`
	ComparisonData      *ComparisonStats       `json:"comparison,omitempty"`
}

// DailyReadingStats represents daily reading statistics
type DailyReadingStats struct {
	Date           string `json:"date"` // Format: YYYY-MM-DD
	ReadingMinutes int    `json:"reading_minutes"`
	PagesRead      int    `json:"pages_read"`
	WordsRead      int    `json:"words_read"`
	SessionsCount  int    `json:"sessions_count"`
}

// ComparisonStats represents comparison with previous period
type ComparisonStats struct {
	ReadingTimeChange   float64 `json:"reading_time_change_percent"`
	PagesReadChange     float64 `json:"pages_read_change_percent"`
	CompletionRateChange float64 `json:"completion_rate_change_percent"`
}

// ReadingStreakResponse represents reading streak information
type ReadingStreakResponse struct {
	CurrentStreak       int       `json:"current_streak_days"`
	LongestStreak       int       `json:"longest_streak_days"`
	TotalReadingDays    int       `json:"total_reading_days"`
	LastReadingDate     string    `json:"last_reading_date"` // Format: YYYY-MM-DD
	StreakStartDate     string    `json:"streak_start_date"` // Format: YYYY-MM-DD
	NextMilestone       int       `json:"next_milestone_days"`
	DaysUntilMilestone  int       `json:"days_until_milestone"`
}

// Goal DTOs

// CreateGoalRequest represents request to create a reading goal
type CreateGoalRequest struct {
	GoalType    string `json:"goal_type" validate:"required,oneof=daily_minutes daily_pages weekly_books monthly_books yearly_books"`
	TargetValue int    `json:"target_value" validate:"required,min=1"`
	StartDate   string `json:"start_date,omitempty"` // Format: YYYY-MM-DD, defaults to today
}

// UpdateGoalRequest represents request to update a reading goal
type UpdateGoalRequest struct {
	TargetValue *int  `json:"target_value,omitempty" validate:"omitempty,min=1"`
	IsActive    *bool `json:"is_active,omitempty"`
}

// GoalResponse represents a reading goal
type GoalResponse struct {
	ID            uuid.UUID `json:"id"`
	GoalType      string    `json:"goal_type"`
	TargetValue   int       `json:"target_value"`
	CurrentValue  int       `json:"current_value"`
	Progress      float64   `json:"progress_percentage"`
	PeriodStart   string    `json:"period_start"` // Format: YYYY-MM-DD
	PeriodEnd     string    `json:"period_end"`   // Format: YYYY-MM-DD
	IsAchieved    bool      `json:"is_achieved"`
	AchievedAt    *string   `json:"achieved_at,omitempty"`
	IsActive      bool      `json:"is_active"`
	DaysRemaining int       `json:"days_remaining"`
	EstimatedDate *string   `json:"estimated_completion_date,omitempty"`
}

// GoalsListResponse represents list of user goals
type GoalsListResponse struct {
	ActiveGoals    []GoalResponse `json:"active_goals"`
	CompletedGoals []GoalResponse `json:"completed_goals"`
	TotalAchieved  int            `json:"total_achieved"`
}

// Achievement DTOs

// AchievementResponse represents an achievement
type AchievementResponse struct {
	ID           uuid.UUID `json:"id"`
	Name         string    `json:"name"`
	Description  string    `json:"description"`
	IconURL      *string   `json:"icon_url,omitempty"`
	Category     string    `json:"category"`
	Points       int       `json:"points"`
	IsEarned     bool      `json:"is_earned"`
	EarnedAt     *string   `json:"earned_at,omitempty"`
	Progress     int       `json:"progress_percentage"`
	Requirements string    `json:"requirements"`
}

// AchievementsListResponse represents list of achievements
type AchievementsListResponse struct {
	Earned     []AchievementResponse `json:"earned"`
	Available  []AchievementResponse `json:"available"`
	TotalPoints int                  `json:"total_points"`
	Level      int                   `json:"level"`
	NextLevel  int                   `json:"points_to_next_level"`
}

// Progress DTOs

// BookProgressResponse represents book reading progress
type BookProgressResponse struct {
	BookID                      int64     `json:"book_id"`
	BookTitle                   string    `json:"book_title"`
	CurrentChapter              *string   `json:"current_chapter,omitempty"`
	CurrentPage                 int       `json:"current_page"`
	TotalPages                  int       `json:"total_pages"`
	ProgressPercentage          float64   `json:"progress_percentage"`
	EstimatedTimeRemaining      int       `json:"estimated_time_remaining_minutes"`
	AverageReadingSpeed         int       `json:"average_reading_speed_wpm"`
	StartedAt                   string    `json:"started_at"`
	LastReadAt                  string    `json:"last_read_at"`
	TotalReadingTime            int       `json:"total_reading_time_minutes"`
	IsCompleted                 bool      `json:"is_completed"`
	CompletedAt                 *string   `json:"completed_at,omitempty"`
}

// CurrentlyReadingResponse represents currently reading books
type CurrentlyReadingResponse struct {
	Books         []BookProgressResponse `json:"books"`
	TotalActive   int                    `json:"total_active"`
	RecentlyRead  []BookProgressResponse `json:"recently_read"`
}

// UpdateProgressRequest represents request to update reading progress
type UpdateProgressRequest struct {
	BookID             int64  `json:"book_id" validate:"required"`
	CurrentPosition    int    `json:"current_position,omitempty"`
	CurrentPage        int    `json:"current_page,omitempty"`
	SessionDurationSec int    `json:"session_duration_seconds,omitempty"`
}

// Context DTOs

// ReadingContextRequest represents reading context information
type ReadingContextRequest struct {
	SessionID          *uuid.UUID `json:"session_id,omitempty"`
	Mood               *string    `json:"mood,omitempty" validate:"omitempty,oneof=happy sad relaxed excited tired focused anxious neutral"`
	Weather            *string    `json:"weather,omitempty" validate:"omitempty,oneof=sunny cloudy rainy snowy windy stormy"`
	LocationType       *string    `json:"location_type,omitempty" validate:"omitempty,oneof=home office cafe library park transit other"`
	TimeOfDay          *string    `json:"time_of_day,omitempty" validate:"omitempty,oneof=early_morning morning afternoon evening night late_night"`
	DeviceType         *string    `json:"device_type,omitempty" validate:"omitempty,oneof=phone tablet e-reader computer"`
	AmbientNoiseLevel  *string    `json:"ambient_noise_level,omitempty" validate:"omitempty,oneof=silent quiet moderate loud"`
	ReadingPosition    *string    `json:"reading_position,omitempty" validate:"omitempty,oneof=sitting lying standing walking"`
	Notes              *string    `json:"notes,omitempty"`
}

// ReadingContextResponse represents reading context
type ReadingContextResponse struct {
	ID                 uuid.UUID  `json:"id"`
	UserID             uuid.UUID  `json:"user_id"`
	SessionID          *uuid.UUID `json:"session_id,omitempty"`
	Mood               *string    `json:"mood,omitempty"`
	Weather            *string    `json:"weather,omitempty"`
	LocationType       *string    `json:"location_type,omitempty"`
	TimeOfDay          *string    `json:"time_of_day,omitempty"`
	DeviceType         *string    `json:"device_type,omitempty"`
	AmbientNoiseLevel  *string    `json:"ambient_noise_level,omitempty"`
	ReadingPosition    *string    `json:"reading_position,omitempty"`
	Notes              *string    `json:"notes,omitempty"`
	CreatedAt          time.Time  `json:"created_at"`
}

// ContextInsightsResponse represents insights based on reading contexts
type ContextInsightsResponse struct {
	MostProductiveMood      *string                `json:"most_productive_mood,omitempty"`
	MostProductiveTime      *string                `json:"most_productive_time,omitempty"`
	MostProductiveLocation  *string                `json:"most_productive_location,omitempty"`
	PreferredConditions     map[string]interface{} `json:"preferred_conditions"`
	ReadingPatterns         []string               `json:"reading_patterns"`
	Recommendations         []string               `json:"recommendations"`
}

// Insight DTOs

// ReadingInsightResponse represents a reading insight
type ReadingInsightResponse struct {
	ID             uuid.UUID              `json:"id"`
	Type           string                 `json:"type"`
	Title          string                 `json:"title"`
	Description    string                 `json:"description"`
	Data           map[string]interface{} `json:"data,omitempty"`
	RelevanceScore float64                `json:"relevance_score"`
	IsRead         bool                   `json:"is_read"`
	CreatedAt      string                 `json:"created_at"`
}

// InsightsListResponse represents list of reading insights
type InsightsListResponse struct {
	Insights      []ReadingInsightResponse `json:"insights"`
	UnreadCount   int                      `json:"unread_count"`
	HasMore       bool                     `json:"has_more"`
}