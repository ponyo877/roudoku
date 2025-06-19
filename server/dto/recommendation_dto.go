package dto

import (
	"time"

	"github.com/google/uuid"
)

// Recommendation DTOs

// RecommendationRequest represents a request for book recommendations
type RecommendationRequest struct {
	RecommendationType string   `json:"recommendation_type" validate:"required,oneof=content_based collaborative hybrid trending similar_users personalized"`
	Count              int      `json:"count" validate:"min=1,max=50"`
	Filters            *RecommendationFilters `json:"filters,omitempty"`
	Context            *RecommendationContext `json:"context,omitempty"`
	ExcludeBookIDs     []int64  `json:"exclude_book_ids,omitempty"`
	IncludeExplanations bool    `json:"include_explanations"`
}

// RecommendationFilters represents filters for recommendations
type RecommendationFilters struct {
	Genres             []string `json:"genres,omitempty"`
	Authors            []string `json:"authors,omitempty"`
	Epochs             []string `json:"epochs,omitempty"`
	MinRating          *float64 `json:"min_rating,omitempty" validate:"omitempty,min=0,max=5"`
	MaxWordCount       *int     `json:"max_word_count,omitempty" validate:"omitempty,min=1"`
	MinWordCount       *int     `json:"min_word_count,omitempty" validate:"omitempty,min=1"`
	DifficultyLevels   []int    `json:"difficulty_levels,omitempty" validate:"omitempty,dive,min=1,max=5"`
	ReadingLength      *string  `json:"reading_length,omitempty" validate:"omitempty,oneof=short medium long"`
	IncludePremium     bool     `json:"include_premium"`
	ExcludeCompleted   bool     `json:"exclude_completed"`
	ExcludeAbandoned   bool     `json:"exclude_abandoned"`
}

// RecommendationContext represents context for recommendations
type RecommendationContext struct {
	Mood               *string `json:"mood,omitempty"`
	TimeOfDay          *string `json:"time_of_day,omitempty"`
	AvailableTime      *int    `json:"available_time_minutes,omitempty"`
	Location           *string `json:"location,omitempty"`
	Device             *string `json:"device,omitempty"`
	Purpose            *string `json:"purpose,omitempty" validate:"omitempty,oneof=entertainment education relaxation learning"`
}

// RecommendationResponse represents a recommendation response
type RecommendationResponse struct {
	Recommendations []BookRecommendation `json:"recommendations"`
	TotalCount      int                  `json:"total_count"`
	AlgorithmUsed   string               `json:"algorithm_used"`
	GeneratedAt     time.Time            `json:"generated_at"`
	ExpiresAt       time.Time            `json:"expires_at"`
	Context         *RecommendationContext `json:"context,omitempty"`
	Explanations    map[string]string    `json:"explanations,omitempty"`
}

// BookRecommendation represents a single book recommendation
type BookRecommendation struct {
	BookID          int64               `json:"book_id"`
	Title           string              `json:"title"`
	Author          string              `json:"author"`
	Genre           *string             `json:"genre,omitempty"`
	Epoch           *string             `json:"epoch,omitempty"`
	WordCount       int                 `json:"word_count"`
	DifficultyLevel int                 `json:"difficulty_level"`
	RatingAverage   float64             `json:"rating_average"`
	RatingCount     int                 `json:"rating_count"`
	IsPremium       bool                `json:"is_premium"`
	Score           float64             `json:"score"` // Recommendation confidence score
	Reasoning       []string            `json:"reasoning,omitempty"`
	SimilarityType  *string             `json:"similarity_type,omitempty"` // content, collaborative, hybrid
	MatchFactors    map[string]float64  `json:"match_factors,omitempty"`   // genre: 0.8, author: 0.6, etc.
}

// User Preferences DTOs

// UpdatePreferencesRequest represents request to update user preferences
type UpdatePreferencesRequest struct {
	PreferredGenres        []string `json:"preferred_genres,omitempty"`
	PreferredAuthors       []string `json:"preferred_authors,omitempty"`
	PreferredEpochs        []string `json:"preferred_epochs,omitempty"`
	PreferredDifficulties  []int    `json:"preferred_difficulty_levels,omitempty" validate:"omitempty,dive,min=1,max=5"`
	PreferredReadingLength *string  `json:"preferred_reading_length,omitempty" validate:"omitempty,oneof=short medium long any"`
	MinRating              *float64 `json:"min_rating,omitempty" validate:"omitempty,min=0,max=5"`
	MaxWordCount           *int     `json:"max_word_count,omitempty" validate:"omitempty,min=1"`
	ExcludeCompleted       *bool    `json:"exclude_completed,omitempty"`
	ExcludeAbandoned       *bool    `json:"exclude_abandoned,omitempty"`
	DiscoveryMode          *string  `json:"discovery_mode,omitempty" validate:"omitempty,oneof=conservative balanced adventurous"`
}

// UserPreferencesResponse represents user preferences
type UserPreferencesResponse struct {
	UserID                 uuid.UUID `json:"user_id"`
	PreferredGenres        []string  `json:"preferred_genres"`
	PreferredAuthors       []string  `json:"preferred_authors"`
	PreferredEpochs        []string  `json:"preferred_epochs"`
	PreferredDifficulties  []int     `json:"preferred_difficulty_levels"`
	PreferredReadingLength string    `json:"preferred_reading_length"`
	MinRating              float64   `json:"min_rating"`
	MaxWordCount           *int      `json:"max_word_count,omitempty"`
	ExcludeCompleted       bool      `json:"exclude_completed"`
	ExcludeAbandoned       bool      `json:"exclude_abandoned"`
	DiscoveryMode          string    `json:"discovery_mode"`
	CreatedAt              time.Time `json:"created_at"`
	UpdatedAt              time.Time `json:"updated_at"`
}

// Feedback DTOs

// RecommendationFeedbackRequest represents feedback on recommendations
type RecommendationFeedbackRequest struct {
	BookID             int64                  `json:"book_id" validate:"required"`
	RecommendationID   *uuid.UUID             `json:"recommendation_id,omitempty"`
	FeedbackType       string                 `json:"feedback_type" validate:"required,oneof=click view start complete rate like dislike not_interested already_read"`
	FeedbackValue      *float64               `json:"feedback_value,omitempty" validate:"omitempty,min=-1,max=1"`
	PositionInList     *int                   `json:"position_in_list,omitempty"`
	TimeToActionSec    *int                   `json:"time_to_action_seconds,omitempty"`
	Context            map[string]interface{} `json:"context,omitempty"`
}

// SimilarBooksRequest represents request for similar books
type SimilarBooksRequest struct {
	BookID         int64                  `json:"book_id" validate:"required"`
	Count          int                    `json:"count" validate:"min=1,max=20"`
	SimilarityType string                 `json:"similarity_type" validate:"oneof=content collaborative hybrid"`
	Filters        *RecommendationFilters `json:"filters,omitempty"`
}

// Subscription DTOs

// SubscriptionPlanResponse represents a subscription plan
type SubscriptionPlanResponse struct {
	ID                      uuid.UUID              `json:"id"`
	Name                    string                 `json:"name"`
	Description             string                 `json:"description"`
	PriceMonthly            float64                `json:"price_monthly"`
	PriceYearly             *float64               `json:"price_yearly,omitempty"`
	Features                []string               `json:"features"`
	MaxPremiumBooks         int                    `json:"max_premium_books"` // -1 for unlimited
	MaxTTSMinutesPerDay     int                    `json:"max_tts_minutes_per_day"` // -1 for unlimited
	MaxOfflineDownloads     int                    `json:"max_offline_downloads"` // -1 for unlimited
	HasAdvancedAnalytics    bool                   `json:"has_advanced_analytics"`
	HasAIRecommendations    bool                   `json:"has_ai_recommendations"`
	HasPrioritySupport      bool                   `json:"has_priority_support"`
	IsActive                bool                   `json:"is_active"`
	SortOrder               int                    `json:"sort_order"`
}

// SubscriptionResponse represents user's subscription
type SubscriptionResponse struct {
	ID                     uuid.UUID                 `json:"id"`
	UserID                 uuid.UUID                 `json:"user_id"`
	Plan                   SubscriptionPlanResponse  `json:"plan"`
	Status                 string                    `json:"status"`
	BillingCycle           string                    `json:"billing_cycle"`
	PricePaid              float64                   `json:"price_paid"`
	Currency               string                    `json:"currency"`
	StartedAt              time.Time                 `json:"started_at"`
	CurrentPeriodStart     time.Time                 `json:"current_period_start"`
	CurrentPeriodEnd       time.Time                 `json:"current_period_end"`
	TrialEnd               *time.Time                `json:"trial_end,omitempty"`
	CanceledAt             *time.Time                `json:"canceled_at,omitempty"`
	CancelReason           *string                   `json:"cancel_reason,omitempty"`
	AutoRenew              bool                      `json:"auto_renew"`
	DaysRemaining          int                       `json:"days_remaining"`
	IsTrialActive          bool                      `json:"is_trial_active"`
	NextBillingDate        *time.Time                `json:"next_billing_date,omitempty"`
}

// CreateSubscriptionRequest represents request to create subscription
type CreateSubscriptionRequest struct {
	PlanID             uuid.UUID `json:"plan_id" validate:"required"`
	BillingCycle       string    `json:"billing_cycle" validate:"required,oneof=monthly yearly"`
	PaymentMethodID    string    `json:"payment_method_id" validate:"required"`
	PromoCode          *string   `json:"promo_code,omitempty"`
	AutoRenew          bool      `json:"auto_renew"`
}

// UpdateSubscriptionRequest represents request to update subscription
type UpdateSubscriptionRequest struct {
	PlanID       *uuid.UUID `json:"plan_id,omitempty"`
	BillingCycle *string    `json:"billing_cycle,omitempty" validate:"omitempty,oneof=monthly yearly"`
	AutoRenew    *bool      `json:"auto_renew,omitempty"`
}

// CancelSubscriptionRequest represents request to cancel subscription
type CancelSubscriptionRequest struct {
	Reason           string `json:"reason" validate:"required"`
	CancelImmediately bool   `json:"cancel_immediately"`
	Feedback         *string `json:"feedback,omitempty"`
}

// UsageStatsResponse represents usage statistics for premium features
type UsageStatsResponse struct {
	CurrentPeriodStart time.Time                  `json:"current_period_start"`
	CurrentPeriodEnd   time.Time                  `json:"current_period_end"`
	TTSMinutesUsed     int                        `json:"tts_minutes_used"`
	TTSMinutesLimit    int                        `json:"tts_minutes_limit"` // -1 for unlimited
	PremiumBooksRead   int                        `json:"premium_books_read"`
	PremiumBooksLimit  int                        `json:"premium_books_limit"` // -1 for unlimited
	OfflineDownloads   int                        `json:"offline_downloads"`
	OfflineDownloadLimit int                      `json:"offline_download_limit"` // -1 for unlimited
	UsageBreakdown     map[string]UsageBreakdown  `json:"usage_breakdown"`
}

// UsageBreakdown represents daily usage breakdown
type UsageBreakdown struct {
	Date  string `json:"date"`
	Count int    `json:"count"`
	Value float64 `json:"value"`
}

// AI Insights DTOs

// RecommendationInsightsResponse represents AI-generated insights about recommendations
type RecommendationInsightsResponse struct {
	UserReadingProfile  UserReadingProfile     `json:"user_reading_profile"`
	TrendingGenres      []TrendingItem         `json:"trending_genres"`
	SimilarUsers        []SimilarUser          `json:"similar_users,omitempty"`
	PersonalizedTips    []string               `json:"personalized_tips"`
	ExplorationSuggestions []ExplorationSuggestion `json:"exploration_suggestions"`
	ReadingGoalSuggestions []string            `json:"reading_goal_suggestions"`
}

// UserReadingProfile represents user's reading profile analysis
type UserReadingProfile struct {
	DominantGenres      []string  `json:"dominant_genres"`
	PreferredDifficulty string    `json:"preferred_difficulty"`
	TypicalReadingLength string   `json:"typical_reading_length"`
	ReadingPace         string    `json:"reading_pace"` // fast, medium, slow
	ExplorationLevel    string    `json:"exploration_level"` // conservative, balanced, adventurous
	Consistency         float64   `json:"consistency"` // 0.0-1.0
	DiversityScore      float64   `json:"diversity_score"` // 0.0-1.0
}

// TrendingItem represents trending content
type TrendingItem struct {
	Name        string  `json:"name"`
	Score       float64 `json:"score"`
	Growth      float64 `json:"growth_percentage"`
	BookCount   int     `json:"book_count"`
}

// SimilarUser represents a user with similar taste
type SimilarUser struct {
	SimilarityScore   float64  `json:"similarity_score"`
	CommonGenres      []string `json:"common_genres"`
	CommonBooks       int      `json:"common_books"`
	RecommendedBy     int      `json:"recommended_by"` // how many books this similar user liked
}

// ExplorationSuggestion represents suggestion to try new content
type ExplorationSuggestion struct {
	Type        string  `json:"type"` // genre, author, epoch
	Value       string  `json:"value"`
	Reason      string  `json:"reason"`
	Confidence  float64 `json:"confidence"`
	BookCount   int     `json:"book_count"`
}

// Additional DTOs for services

// SubscriptionPlansResponse represents list of subscription plans
type SubscriptionPlansResponse struct {
	Plans []SubscriptionPlanResponse `json:"plans"`
}

// FeatureAccessResponse represents feature access check result
type FeatureAccessResponse struct {
	CanAccess bool   `json:"can_access"`
	Reason    string `json:"reason"`
}

// Advanced Recommendation DTOs

// ReadingTrendsResponse represents real-time reading trends
type ReadingTrendsResponse struct {
	TrendingGenres   []TrendingItem `json:"trending_genres"`
	TrendingAuthors  []TrendingItem `json:"trending_authors"`
	EmergingBooks    []BookTrend    `json:"emerging_books"`
	PeakReadingHours []TimeSlot     `json:"peak_reading_hours"`
	UpdatedAt        time.Time      `json:"updated_at"`
}

// BookTrend represents a trending book
type BookTrend struct {
	BookID      int64   `json:"book_id"`
	Title       string  `json:"title"`
	Author      string  `json:"author"`
	GrowthRate  float64 `json:"growth_rate"`
	ReadingRate float64 `json:"reading_rate"`
}

// TimeSlot represents activity at a specific hour
type TimeSlot struct {
	Hour     int     `json:"hour"`
	Activity float64 `json:"activity"`
}

// SocialRecommendationResponse represents social recommendations
type SocialRecommendationResponse struct {
	FriendRecommendations []FriendRecommendation `json:"friend_recommendations"`
	CommunityTrending     []BookRecommendation   `json:"community_trending"`
	ReadingGroups         []ReadingGroup         `json:"reading_groups"`
	DiscussionTopics      []DiscussionTopic      `json:"discussion_topics"`
}

// FriendRecommendation represents a recommendation from a friend
type FriendRecommendation struct {
	BookID     int64  `json:"book_id"`
	Title      string `json:"title"`
	Author     string `json:"author"`
	FriendName string `json:"friend_name"`
	FriendID   string `json:"friend_id"`
	Comment    string `json:"comment,omitempty"`
	SharedAt   time.Time `json:"shared_at"`
}

// ReadingGroup represents a reading group
type ReadingGroup struct {
	GroupID     string   `json:"group_id"`
	Name        string   `json:"name"`
	Description string   `json:"description"`
	MemberCount int      `json:"member_count"`
	CurrentBook BookTrend `json:"current_book"`
}

// DiscussionTopic represents a discussion topic
type DiscussionTopic struct {
	TopicID      string    `json:"topic_id"`
	Title        string    `json:"title"`
	BookID       int64     `json:"book_id"`
	BookTitle    string    `json:"book_title"`
	MessageCount int       `json:"message_count"`
	LastActivity time.Time `json:"last_activity"`
}

// AccuracyMetrics represents recommendation accuracy metrics
type AccuracyMetrics struct {
	UserID                uuid.UUID `json:"user_id"`
	TimeframeDays         int       `json:"timeframe_days"`
	TotalRecommendations  int       `json:"total_recommendations"`
	ClickedRecommendations int      `json:"clicked_recommendations"`
	CompletedRecommendations int    `json:"completed_recommendations"`
	ClickThroughRate      float64   `json:"click_through_rate"`
	CompletionRate        float64   `json:"completion_rate"`
	AverageRating         float64   `json:"average_rating"`
	AccuracyScore         float64   `json:"accuracy_score"`
	CalculatedAt          time.Time `json:"calculated_at"`
}

// PerformanceMetrics represents system-wide recommendation performance
type PerformanceMetrics struct {
	OverallAccuracy       float64                `json:"overall_accuracy"`
	AlgorithmPerformance  map[string]float64     `json:"algorithm_performance"`
	UserSatisfaction      float64                `json:"user_satisfaction"`
	RecommendationLatency time.Duration          `json:"recommendation_latency"`
	CacheHitRate          float64                `json:"cache_hit_rate"`
	DiversityScore        float64                `json:"diversity_score"`
	NoveltyScore          float64                `json:"novelty_score"`
	MetricsByGenre        map[string]float64     `json:"metrics_by_genre"`
	TrendingTopics        []string               `json:"trending_topics"`
	CalculatedAt          time.Time              `json:"calculated_at"`
}

// A/B Testing DTOs

// CreateExperimentRequest represents request to create A/B test experiment
type CreateExperimentRequest struct {
	Name             string                 `json:"name" validate:"required"`
	Description      string                 `json:"description" validate:"required"`
	AlgorithmType    string                 `json:"algorithm_type" validate:"required"`
	Parameters       map[string]interface{} `json:"parameters"`
	TargetPercentage float64                `json:"target_percentage" validate:"min=0,max=100"`
	StartDate        *time.Time             `json:"start_date,omitempty"`
	EndDate          *time.Time             `json:"end_date,omitempty"`
	SuccessMetrics   map[string]interface{} `json:"success_metrics"`
}

// UpdateExperimentRequest represents request to update A/B test experiment
type UpdateExperimentRequest struct {
	Name             *string                `json:"name,omitempty"`
	Description      *string                `json:"description,omitempty"`
	TargetPercentage *float64               `json:"target_percentage,omitempty" validate:"omitempty,min=0,max=100"`
	EndDate          *time.Time             `json:"end_date,omitempty"`
	SuccessMetrics   map[string]interface{} `json:"success_metrics,omitempty"`
}

// ExperimentResponse represents A/B test experiment
type ExperimentResponse struct {
	ID               uuid.UUID              `json:"id"`
	Name             string                 `json:"name"`
	Description      string                 `json:"description"`
	AlgorithmType    string                 `json:"algorithm_type"`
	Parameters       map[string]interface{} `json:"parameters"`
	TargetPercentage float64                `json:"target_percentage"`
	IsActive         bool                   `json:"is_active"`
	StartDate        *time.Time             `json:"start_date,omitempty"`
	EndDate          *time.Time             `json:"end_date,omitempty"`
	SuccessMetrics   map[string]interface{} `json:"success_metrics"`
	CreatedAt        time.Time              `json:"created_at"`
	UpdatedAt        time.Time              `json:"updated_at"`
}

// ListExperimentsRequest represents request to list experiments
type ListExperimentsRequest struct {
	IsActive   *bool  `json:"is_active,omitempty"`
	Limit      int    `json:"limit" validate:"min=1,max=100"`
	Offset     int    `json:"offset" validate:"min=0"`
	SortBy     string `json:"sort_by,omitempty"`
	SortOrder  string `json:"sort_order,omitempty" validate:"omitempty,oneof=asc desc"`
}

// ExperimentListResponse represents list of experiments
type ExperimentListResponse struct {
	Experiments []ExperimentResponse `json:"experiments"`
	TotalCount  int                  `json:"total_count"`
	Limit       int                  `json:"limit"`
	Offset      int                  `json:"offset"`
}

// ExperimentAssignment represents user assignment to experiment
type ExperimentAssignment struct {
	UserID       uuid.UUID `json:"user_id"`
	ExperimentID uuid.UUID `json:"experiment_id"`
	Variant      string    `json:"variant"`
	AssignedAt   time.Time `json:"assigned_at"`
}

// ExperimentInteraction represents user interaction in experiment
type ExperimentInteraction struct {
	InteractionType  string                 `json:"interaction_type" validate:"required"`
	InteractionValue *float64               `json:"interaction_value,omitempty"`
	BookID           *int64                 `json:"book_id,omitempty"`
	Metadata         map[string]interface{} `json:"metadata,omitempty"`
}

// ExperimentResults represents results of A/B test experiment
type ExperimentResults struct {
	ExperimentID      uuid.UUID              `json:"experiment_id"`
	ExperimentName    string                 `json:"experiment_name"`
	StartDate         *time.Time             `json:"start_date,omitempty"`
	EndDate           *time.Time             `json:"end_date,omitempty"`
	TotalParticipants int                    `json:"total_participants"`
	VariantResults    []VariantResult        `json:"variant_results"`
	OverallMetrics    map[string]float64     `json:"overall_metrics"`
	CalculatedAt      time.Time              `json:"calculated_at"`
}

// VariantResult represents results for a specific experiment variant
type VariantResult struct {
	Variant          string             `json:"variant"`
	ParticipantCount int                `json:"participant_count"`
	InteractionCount int                `json:"interaction_count"`
	ConversionCount  int                `json:"conversion_count"`
	ConversionRate   float64            `json:"conversion_rate"`
	AverageValue     float64            `json:"average_value"`
	Metrics          map[string]float64 `json:"metrics"`
}

// ExperimentStatistics represents detailed statistics for experiment
type ExperimentStatistics struct {
	ExperimentID     uuid.UUID              `json:"experiment_id"`
	DurationDays     int                    `json:"duration_days"`
	VariantStats     []VariantStatistics    `json:"variant_stats"`
	TimeSeriesData   []TimeSeriesPoint      `json:"time_series_data"`
	SegmentAnalysis  []SegmentAnalysis      `json:"segment_analysis"`
	CalculatedAt     time.Time              `json:"calculated_at"`
}

// VariantStatistics represents detailed statistics for a variant
type VariantStatistics struct {
	Variant              string  `json:"variant"`
	ParticipantCount     int     `json:"participant_count"`
	ConversionRate       float64 `json:"conversion_rate"`
	ConversionRateCI     [2]float64 `json:"conversion_rate_ci"` // 95% confidence interval
	AverageSessionTime   float64 `json:"average_session_time"`
	BounceRate          float64 `json:"bounce_rate"`
	RevenuePerUser      float64 `json:"revenue_per_user"`
	LifetimeValue       float64 `json:"lifetime_value"`
}

// TimeSeriesPoint represents a point in time series data
type TimeSeriesPoint struct {
	Date             time.Time          `json:"date"`
	VariantMetrics   map[string]float64 `json:"variant_metrics"`
}

// SegmentAnalysis represents analysis by user segment
type SegmentAnalysis struct {
	Segment          string             `json:"segment"`
	SegmentSize      int                `json:"segment_size"`
	VariantResults   []VariantResult    `json:"variant_results"`
}

// SignificanceTest represents statistical significance test results
type SignificanceTest struct {
	ExperimentID        uuid.UUID `json:"experiment_id"`
	ControlVariant      string    `json:"control_variant"`
	TreatmentVariant    string    `json:"treatment_variant"`
	ZScore              float64   `json:"z_score"`
	PValue              float64   `json:"p_value"`
	ConfidenceLevel     float64   `json:"confidence_level"`
	IsSignificant       bool      `json:"is_significant"`
	Effect              string    `json:"effect"` // positive, negative, neutral
	SampleSizeControl   int       `json:"sample_size_control"`
	SampleSizeTreatment int       `json:"sample_size_treatment"`
	CalculatedAt        time.Time `json:"calculated_at"`
}