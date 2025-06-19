package domain

import (
	"time"

	"github.com/google/uuid"
)

// UserPreferences represents user's recommendation preferences
type UserPreferences struct {
	ID                     uuid.UUID `json:"id" db:"id"`
	UserID                 uuid.UUID `json:"user_id" db:"user_id"`
	PreferredGenres        []string  `json:"preferred_genres" db:"preferred_genres"`
	PreferredAuthors       []string  `json:"preferred_authors" db:"preferred_authors"`
	PreferredEpochs        []string  `json:"preferred_epochs" db:"preferred_epochs"`
	PreferredDifficulties  []int     `json:"preferred_difficulty_levels" db:"preferred_difficulty_levels"`
	PreferredReadingLength string    `json:"preferred_reading_length" db:"preferred_reading_length"`
	MinRating              float64   `json:"min_rating" db:"min_rating"`
	MaxWordCount           *int      `json:"max_word_count,omitempty" db:"max_word_count"`
	ExcludeCompleted       bool      `json:"exclude_completed" db:"exclude_completed"`
	ExcludeAbandoned       bool      `json:"exclude_abandoned" db:"exclude_abandoned"`
	DiscoveryMode          string    `json:"discovery_mode" db:"discovery_mode"`
	CreatedAt              time.Time `json:"created_at" db:"created_at"`
	UpdatedAt              time.Time `json:"updated_at" db:"updated_at"`
}

// BookVector represents ML features for a book
type BookVector struct {
	BookID          int64     `json:"book_id" db:"book_id"`
	ContentVector   []float64 `json:"content_vector" db:"content_vector"`
	GenreVector     []float64 `json:"genre_vector" db:"genre_vector"`
	StyleVector     []float64 `json:"style_vector" db:"style_vector"`
	DifficultyScore float64   `json:"difficulty_score" db:"difficulty_score"`
	PopularityScore float64   `json:"popularity_score" db:"popularity_score"`
	QualityScore    float64   `json:"quality_score" db:"quality_score"`
	NoveltyScore    float64   `json:"novelty_score" db:"novelty_score"`
	LastUpdated     time.Time `json:"last_updated" db:"last_updated"`
}

// UserInteraction represents user's interaction with books
type UserInteraction struct {
	ID                   uuid.UUID              `json:"id" db:"id"`
	UserID               uuid.UUID              `json:"user_id" db:"user_id"`
	BookID               int64                  `json:"book_id" db:"book_id"`
	InteractionType      string                 `json:"interaction_type" db:"interaction_type"`
	InteractionValue     *float64               `json:"interaction_value,omitempty" db:"interaction_value"`
	ImplicitScore        float64                `json:"implicit_score" db:"implicit_score"`
	SessionDurationMin   int                    `json:"session_duration_minutes" db:"session_duration_minutes"`
	CompletionPercentage float64                `json:"completion_percentage" db:"completion_percentage"`
	ContextData          map[string]interface{} `json:"context_data,omitempty" db:"context_data"`
	CreatedAt            time.Time              `json:"created_at" db:"created_at"`
}

// UserSimilarity represents similarity between users
type UserSimilarity struct {
	UserAID           uuid.UUID `json:"user_a_id" db:"user_a_id"`
	UserBID           uuid.UUID `json:"user_b_id" db:"user_b_id"`
	SimilarityScore   float64   `json:"similarity_score" db:"similarity_score"`
	SimilarityType    string    `json:"similarity_type" db:"similarity_type"`
	CommonBooksCount  int       `json:"common_books_count" db:"common_books_count"`
	LastCalculated    time.Time `json:"last_calculated" db:"last_calculated"`
}

// RecommendationCache represents cached recommendations
type RecommendationCache struct {
	ID                 uuid.UUID              `json:"id" db:"id"`
	UserID             uuid.UUID              `json:"user_id" db:"user_id"`
	RecommendationType string                 `json:"recommendation_type" db:"recommendation_type"`
	BookIDs            []int64                `json:"book_ids" db:"book_ids"`
	Scores             []float64              `json:"scores" db:"scores"`
	Reasoning          map[string]interface{} `json:"reasoning,omitempty" db:"reasoning"`
	ContextFilters     map[string]interface{} `json:"context_filters,omitempty" db:"context_filters"`
	ExpiresAt          time.Time              `json:"expires_at" db:"expires_at"`
	CreatedAt          time.Time              `json:"created_at" db:"created_at"`
}

// RecommendationFeedback represents user feedback on recommendations
type RecommendationFeedback struct {
	ID                 uuid.UUID              `json:"id" db:"id"`
	UserID             uuid.UUID              `json:"user_id" db:"user_id"`
	BookID             int64                  `json:"book_id" db:"book_id"`
	RecommendationID   *uuid.UUID             `json:"recommendation_id,omitempty" db:"recommendation_id"`
	FeedbackType       string                 `json:"feedback_type" db:"feedback_type"`
	FeedbackValue      *float64               `json:"feedback_value,omitempty" db:"feedback_value"`
	PositionInList     *int                   `json:"position_in_list,omitempty" db:"position_in_list"`
	TimeToActionSec    *int                   `json:"time_to_action_seconds,omitempty" db:"time_to_action_seconds"`
	ContextData        map[string]interface{} `json:"context_data,omitempty" db:"context_data"`
	CreatedAt          time.Time              `json:"created_at" db:"created_at"`
}

// Subscription and Premium Feature Domains

// SubscriptionPlan represents a subscription plan
type SubscriptionPlan struct {
	ID                      uuid.UUID              `json:"id" db:"id"`
	Name                    string                 `json:"name" db:"name"`
	Description             string                 `json:"description" db:"description"`
	PriceMonthly            float64                `json:"price_monthly" db:"price_monthly"`
	PriceYearly             *float64               `json:"price_yearly,omitempty" db:"price_yearly"`
	Features                map[string]interface{} `json:"features" db:"features"`
	MaxPremiumBooks         int                    `json:"max_premium_books" db:"max_premium_books"`
	MaxTTSMinutesPerDay     int                    `json:"max_tts_minutes_per_day" db:"max_tts_minutes_per_day"`
	MaxOfflineDownloads     int                    `json:"max_offline_downloads" db:"max_offline_downloads"`
	HasAdvancedAnalytics    bool                   `json:"has_advanced_analytics" db:"has_advanced_analytics"`
	HasAIRecommendations    bool                   `json:"has_ai_recommendations" db:"has_ai_recommendations"`
	HasPrioritySupport      bool                   `json:"has_priority_support" db:"has_priority_support"`
	IsActive                bool                   `json:"is_active" db:"is_active"`
	SortOrder               int                    `json:"sort_order" db:"sort_order"`
	CreatedAt               time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt               time.Time              `json:"updated_at" db:"updated_at"`
}

// UserSubscription represents a user's subscription
type UserSubscription struct {
	ID                     uuid.UUID         `json:"id" db:"id"`
	UserID                 uuid.UUID         `json:"user_id" db:"user_id"`
	PlanID                 uuid.UUID         `json:"plan_id" db:"plan_id"`
	Status                 string            `json:"status" db:"status"`
	BillingCycle           string            `json:"billing_cycle" db:"billing_cycle"`
	PricePaid              float64           `json:"price_paid" db:"price_paid"`
	Currency               string            `json:"currency" db:"currency"`
	StartedAt              time.Time         `json:"started_at" db:"started_at"`
	CurrentPeriodStart     time.Time         `json:"current_period_start" db:"current_period_start"`
	CurrentPeriodEnd       time.Time         `json:"current_period_end" db:"current_period_end"`
	TrialEnd               *time.Time        `json:"trial_end,omitempty" db:"trial_end"`
	CanceledAt             *time.Time        `json:"canceled_at,omitempty" db:"canceled_at"`
	CancelReason           *string           `json:"cancel_reason,omitempty" db:"cancel_reason"`
	ExternalSubscriptionID *string           `json:"external_subscription_id,omitempty" db:"external_subscription_id"`
	PaymentMethodID        *string           `json:"payment_method_id,omitempty" db:"payment_method_id"`
	AutoRenew              bool              `json:"auto_renew" db:"auto_renew"`
	CreatedAt              time.Time         `json:"created_at" db:"created_at"`
	UpdatedAt              time.Time         `json:"updated_at" db:"updated_at"`
	Plan                   *SubscriptionPlan `json:"plan,omitempty"`
}

// IsActive checks if subscription is currently active
func (s *UserSubscription) IsActive() bool {
	now := time.Now()
	return s.Status == "active" && now.Before(s.CurrentPeriodEnd)
}

// IsTrialActive checks if trial is currently active
func (s *UserSubscription) IsTrialActive() bool {
	if s.TrialEnd == nil {
		return false
	}
	now := time.Now()
	return s.Status == "active" && now.Before(*s.TrialEnd)
}

// DaysRemaining returns days remaining in current period
func (s *UserSubscription) DaysRemaining() int {
	now := time.Now()
	if now.After(s.CurrentPeriodEnd) {
		return 0
	}
	return int(s.CurrentPeriodEnd.Sub(now).Hours() / 24)
}

// CanAccessFeature checks if user can access a premium feature
func (s *UserSubscription) CanAccessFeature(feature string) bool {
	if !s.IsActive() {
		return false
	}
	
	if s.Plan == nil {
		return false
	}
	
	// Check specific features
	switch feature {
	case "premium_books":
		return s.Plan.MaxPremiumBooks == -1 || s.Plan.MaxPremiumBooks > 0
	case "unlimited_tts":
		return s.Plan.MaxTTSMinutesPerDay == -1
	case "advanced_analytics":
		return s.Plan.HasAdvancedAnalytics
	case "ai_recommendations":
		return s.Plan.HasAIRecommendations
	case "priority_support":
		return s.Plan.HasPrioritySupport
	default:
		return false
	}
}

// UsageTracking represents usage of premium features
type UsageTracking struct {
	ID          uuid.UUID              `json:"id" db:"id"`
	UserID      uuid.UUID              `json:"user_id" db:"user_id"`
	FeatureType string                 `json:"feature_type" db:"feature_type"`
	UsageDate   time.Time              `json:"usage_date" db:"usage_date"`
	UsageCount  int                    `json:"usage_count" db:"usage_count"`
	UsageValue  float64                `json:"usage_value" db:"usage_value"`
	Metadata    map[string]interface{} `json:"metadata,omitempty" db:"metadata"`
	CreatedAt   time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time              `json:"updated_at" db:"updated_at"`
}

// RecommendationExperiment represents A/B testing for recommendation algorithms
type RecommendationExperiment struct {
	ID               uuid.UUID              `json:"id" db:"id"`
	Name             string                 `json:"name" db:"name"`
	Description      string                 `json:"description" db:"description"`
	AlgorithmType    string                 `json:"algorithm_type" db:"algorithm_type"`
	Parameters       map[string]interface{} `json:"parameters" db:"parameters"`
	TargetPercentage float64                `json:"target_percentage" db:"target_percentage"`
	IsActive         bool                   `json:"is_active" db:"is_active"`
	StartDate        *time.Time             `json:"start_date,omitempty" db:"start_date"`
	EndDate          *time.Time             `json:"end_date,omitempty" db:"end_date"`
	SuccessMetrics   map[string]interface{} `json:"success_metrics,omitempty" db:"success_metrics"`
	CreatedAt        time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time              `json:"updated_at" db:"updated_at"`
}

// UserExperimentAssignment represents user assignment to A/B test
type UserExperimentAssignment struct {
	UserID       uuid.UUID `json:"user_id" db:"user_id"`
	ExperimentID uuid.UUID `json:"experiment_id" db:"experiment_id"`
	Variant      string    `json:"variant" db:"variant"`
	AssignedAt   time.Time `json:"assigned_at" db:"assigned_at"`
}

// ExperimentInteraction represents user interaction within an A/B test
type ExperimentInteraction struct {
	ID               uuid.UUID              `json:"id" db:"id"`
	UserID           uuid.UUID              `json:"user_id" db:"user_id"`
	ExperimentID     uuid.UUID              `json:"experiment_id" db:"experiment_id"`
	Variant          string                 `json:"variant" db:"variant"`
	InteractionType  string                 `json:"interaction_type" db:"interaction_type"`
	InteractionValue *float64               `json:"interaction_value,omitempty" db:"interaction_value"`
	BookID           *int64                 `json:"book_id,omitempty" db:"book_id"`
	Metadata         map[string]interface{} `json:"metadata,omitempty" db:"metadata"`
	Timestamp        time.Time              `json:"timestamp" db:"timestamp"`
}

// Recommendation Algorithm Interfaces and Types

// RecommendationAlgorithm represents the interface for recommendation algorithms
type RecommendationAlgorithm interface {
	GenerateRecommendations(userID uuid.UUID, count int, filters map[string]interface{}) ([]*BookRecommendation, error)
	GetAlgorithmName() string
	SupportsRealtime() bool
}

// BookRecommendation represents a recommended book with score and reasoning
type BookRecommendation struct {
	Book           *Book              `json:"book"`
	Score          float64            `json:"score"`
	Reasoning      []string           `json:"reasoning"`
	SimilarityType string             `json:"similarity_type"`
	MatchFactors   map[string]float64 `json:"match_factors"`
	Confidence     float64            `json:"confidence"`
}

// RecommendationConfig represents configuration for recommendation generation
type RecommendationConfig struct {
	ContentWeight      float64 `json:"content_weight"`
	CollaborativeWeight float64 `json:"collaborative_weight"`
	PopularityWeight   float64 `json:"popularity_weight"`
	NoveltyWeight      float64 `json:"novelty_weight"`
	DiversityThreshold float64 `json:"diversity_threshold"`
	MinScore           float64 `json:"min_score"`
	UseRealtime        bool    `json:"use_realtime"`
	CacheEnabled       bool    `json:"cache_enabled"`
	CacheTTLHours      int     `json:"cache_ttl_hours"`
}