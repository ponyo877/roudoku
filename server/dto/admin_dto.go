package dto

import (
	"time"

	"github.com/google/uuid"
)

// Admin Dashboard DTOs

// SystemOverviewResponse represents high-level system overview
type SystemOverviewResponse struct {
	TotalUsers               int                    `json:"total_users"`
	ActiveUsers24h           int                    `json:"active_users_24h"`
	ActiveUsers7d            int                    `json:"active_users_7d"`
	TotalBooks               int                    `json:"total_books"`
	TotalReadingSessions     int                    `json:"total_reading_sessions"`
	RecommendationsServed    int                    `json:"recommendations_served"`
	UserGrowth               GrowthMetric           `json:"user_growth"`
	EngagementMetrics        EngagementMetric       `json:"engagement_metrics"`
	RevenueMetrics           RevenueMetric          `json:"revenue_metrics"`
	SystemHealth             SystemHealthMetric     `json:"system_health"`
	TopPerformingBooks       []BookPerformance      `json:"top_performing_books"`
	RecentAlerts             []SystemAlert          `json:"recent_alerts"`
	GeneratedAt              time.Time              `json:"generated_at"`
}

// GrowthMetric represents growth statistics
type GrowthMetric struct {
	Current        int     `json:"current"`
	Previous       int     `json:"previous"`
	GrowthRate     float64 `json:"growth_rate"`
	GrowthAbsolute int     `json:"growth_absolute"`
}

// EngagementMetric represents user engagement statistics
type EngagementMetric struct {
	DailyActiveUsers   int     `json:"daily_active_users"`
	AverageSessionTime float64 `json:"average_session_time"`
	BounceRate         float64 `json:"bounce_rate"`
	RetentionRate      float64 `json:"retention_rate"`
}

// RevenueMetric represents revenue statistics
type RevenueMetric struct {
	TotalRevenue   float64 `json:"total_revenue"`
	MonthlyRevenue float64 `json:"monthly_revenue"`
	AverageARPU    float64 `json:"average_arpu"`
	ConversionRate float64 `json:"conversion_rate"`
}

// SystemHealthMetric represents system health statistics
type SystemHealthMetric struct {
	APIResponseTime     float64 `json:"api_response_time"`
	ErrorRate          float64 `json:"error_rate"`
	CacheHitRate       float64 `json:"cache_hit_rate"`
	DatabaseConnections int     `json:"database_connections"`
}

// BookPerformance represents book performance statistics
type BookPerformance struct {
	BookID       int64   `json:"book_id"`
	Title        string  `json:"title"`
	Author       string  `json:"author"`
	ReadingCount int     `json:"reading_count"`
	Rating       float64 `json:"rating"`
}

// SystemAlert represents a system alert
type SystemAlert struct {
	ID        uuid.UUID `json:"id"`
	Type      string    `json:"type"`
	Message   string    `json:"message"`
	Severity  string    `json:"severity"`
	Timestamp time.Time `json:"timestamp"`
}

// RealtimeMetricsResponse represents real-time system metrics
type RealtimeMetricsResponse struct {
	CurrentActiveUsers  int                `json:"current_active_users"`
	RequestsPerSecond   float64            `json:"requests_per_second"`
	AverageResponseTime float64            `json:"average_response_time"`
	ErrorRate          float64            `json:"error_rate"`
	CacheHitRate       float64            `json:"cache_hit_rate"`
	DatabaseLoad       float64            `json:"database_load"`
	MemoryUsage        float64            `json:"memory_usage"`
	CPUUsage           float64            `json:"cpu_usage"`
	TopEndpoints       []EndpointMetric   `json:"top_endpoints"`
	RecentErrors       []ErrorMetric      `json:"recent_errors"`
	MLModelStatus      []MLModelStatus    `json:"ml_model_status"`
	Timestamp          time.Time          `json:"timestamp"`
}

// EndpointMetric represents API endpoint performance
type EndpointMetric struct {
	Endpoint       string  `json:"endpoint"`
	RequestCount   int     `json:"request_count"`
	AverageLatency float64 `json:"average_latency"`
}

// ErrorMetric represents error statistics
type ErrorMetric struct {
	Type           string    `json:"type"`
	Count          int       `json:"count"`
	LastOccurrence time.Time `json:"last_occurrence"`
	Endpoint       string    `json:"endpoint"`
}

// MLModelStatus represents ML model status
type MLModelStatus struct {
	ModelName   string    `json:"model_name"`
	Status      string    `json:"status"`
	Accuracy    float64   `json:"accuracy"`
	LastUpdated time.Time `json:"last_updated"`
	Version     string    `json:"version"`
}

// User Analytics DTOs

// UserStatisticsRequest represents request for user statistics
type UserStatisticsRequest struct {
	TimeRange  string `json:"time_range" validate:"required,oneof=24h 7d 30d 90d"`
	UserSegment string `json:"user_segment,omitempty"`
	GroupBy    string `json:"group_by,omitempty"`
}

// UserStatisticsResponse represents user statistics
type UserStatisticsResponse struct {
	TotalUsers       int                    `json:"total_users"`
	NewUsers         int                    `json:"new_users"`
	ActiveUsers      int                    `json:"active_users"`
	ChurnedUsers     int                    `json:"churned_users"`
	UserGrowthTrend  []UserGrowthPoint      `json:"user_growth_trend"`
	DemographicData  UserDemographicData    `json:"demographic_data"`
	GeneratedAt      time.Time              `json:"generated_at"`
}

// UserGrowthPoint represents a point in user growth data
type UserGrowthPoint struct {
	Date      time.Time `json:"date"`
	NewUsers  int       `json:"new_users"`
	TotalUsers int      `json:"total_users"`
	ChurnRate float64   `json:"churn_rate"`
}

// UserDemographicData represents user demographic information
type UserDemographicData struct {
	AgeGroups       []DemographicSegment `json:"age_groups"`
	Locations       []DemographicSegment `json:"locations"`
	DeviceTypes     []DemographicSegment `json:"device_types"`
	SubscriptionTiers []DemographicSegment `json:"subscription_tiers"`
}

// DemographicSegment represents a demographic segment
type DemographicSegment struct {
	Segment    string  `json:"segment"`
	Count      int     `json:"count"`
	Percentage float64 `json:"percentage"`
}

// UserEngagementResponse represents user engagement analysis
type UserEngagementResponse struct {
	Timeframe         string                    `json:"timeframe"`
	OverallEngagement EngagementOverview        `json:"overall_engagement"`
	DailyEngagement   []DailyEngagement         `json:"daily_engagement"`
	UserSegments      []UserSegmentEngagement   `json:"user_segments"`
	FeatureUsage      []FeatureUsageMetric      `json:"feature_usage"`
	GeneratedAt       time.Time                 `json:"generated_at"`
}

// EngagementOverview represents overall engagement metrics
type EngagementOverview struct {
	TotalSessions      int     `json:"total_sessions"`
	AverageSessionTime float64 `json:"average_session_time"`
	PagesPerSession    float64 `json:"pages_per_session"`
	BounceRate         float64 `json:"bounce_rate"`
}

// DailyEngagement represents daily engagement data
type DailyEngagement struct {
	Date        time.Time `json:"date"`
	Sessions    int       `json:"sessions"`
	AverageTime float64   `json:"average_time"`
	UniqueUsers int       `json:"unique_users"`
}

// UserSegmentEngagement represents engagement by user segment
type UserSegmentEngagement struct {
	Segment         string  `json:"segment"`
	UserCount       int     `json:"user_count"`
	EngagementScore float64 `json:"engagement_score"`
	RetentionRate   float64 `json:"retention_rate"`
}

// FeatureUsageMetric represents feature usage statistics
type FeatureUsageMetric struct {
	Feature        string  `json:"feature"`
	UsageCount     int     `json:"usage_count"`
	UserPercentage float64 `json:"user_percentage"`
}

// UserRetentionResponse represents user retention analysis
type UserRetentionResponse struct {
	CohortAnalysis    []CohortRetention    `json:"cohort_analysis"`
	RetentionBySegment []SegmentRetention  `json:"retention_by_segment"`
	ChurnPrediction   []ChurnPrediction    `json:"churn_prediction"`
	GeneratedAt       time.Time            `json:"generated_at"`
}

// CohortRetention represents retention data for a user cohort
type CohortRetention struct {
	CohortMonth      string    `json:"cohort_month"`
	CohortSize       int       `json:"cohort_size"`
	RetentionRates   []float64 `json:"retention_rates"` // Week 1, 2, 3, 4, etc.
}

// SegmentRetention represents retention by user segment
type SegmentRetention struct {
	Segment        string  `json:"segment"`
	Day1Retention  float64 `json:"day1_retention"`
	Day7Retention  float64 `json:"day7_retention"`
	Day30Retention float64 `json:"day30_retention"`
}

// ChurnPrediction represents churn prediction data
type ChurnPrediction struct {
	UserSegment   string  `json:"user_segment"`
	ChurnRisk     string  `json:"churn_risk"` // low, medium, high
	RiskScore     float64 `json:"risk_score"`
	UserCount     int     `json:"user_count"`
	ActionNeeded  string  `json:"action_needed"`
}

// Content Performance DTOs

// BookStatisticsResponse represents book statistics
type BookStatisticsResponse struct {
	TotalBooks           int                    `json:"total_books"`
	ActiveBooks          int                    `json:"active_books"`
	NewBooks             int                    `json:"new_books"`
	TotalReadingSessions int                    `json:"total_reading_sessions"`
	TopPerformingBooks   []BookPerformance      `json:"top_performing_books"`
	GenreDistribution    []GenreDistribution    `json:"genre_distribution"`
	AuthorPerformance    []AuthorPerformance    `json:"author_performance"`
	ContentTrends        []ContentTrend         `json:"content_trends"`
	GeneratedAt          time.Time              `json:"generated_at"`
}

// GenreDistribution represents distribution of books by genre
type GenreDistribution struct {
	Genre      string  `json:"genre"`
	BookCount  int     `json:"book_count"`
	Percentage float64 `json:"percentage"`
	PopularityScore float64 `json:"popularity_score"`
}

// AuthorPerformance represents author performance metrics
type AuthorPerformance struct {
	Author       string  `json:"author"`
	BookCount    int     `json:"book_count"`
	TotalReads   int     `json:"total_reads"`
	AverageRating float64 `json:"average_rating"`
	PopularityRank int    `json:"popularity_rank"`
}

// ContentTrend represents content trend data
type ContentTrend struct {
	Category    string    `json:"category"`
	TrendType   string    `json:"trend_type"` // rising, falling, stable
	ChangeRate  float64   `json:"change_rate"`
	TimeFrame   string    `json:"time_frame"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// ContentPerformanceRequest represents request for content performance
type ContentPerformanceRequest struct {
	TimeRange   string `json:"time_range" validate:"required,oneof=24h 7d 30d 90d"`
	ContentType string `json:"content_type,omitempty"`
	Genre       string `json:"genre,omitempty"`
	SortBy      string `json:"sort_by,omitempty"`
	Limit       int    `json:"limit" validate:"min=1,max=100"`
}

// ContentPerformanceResponse represents content performance analysis
type ContentPerformanceResponse struct {
	TimeRange        string                    `json:"time_range"`
	OverallMetrics   ContentOverallMetrics     `json:"overall_metrics"`
	BookPerformance  []DetailedBookPerformance `json:"book_performance"`
	GenrePerformance []GenrePerformanceMetric  `json:"genre_performance"`
	TrendingContent  []TrendingContentItem     `json:"trending_content"`
	GeneratedAt      time.Time                 `json:"generated_at"`
}

// ContentOverallMetrics represents overall content metrics
type ContentOverallMetrics struct {
	TotalViews        int     `json:"total_views"`
	TotalReadingTime  float64 `json:"total_reading_time"`
	AverageRating     float64 `json:"average_rating"`
	CompletionRate    float64 `json:"completion_rate"`
}

// DetailedBookPerformance represents detailed book performance
type DetailedBookPerformance struct {
	BookID          int64   `json:"book_id"`
	Title           string  `json:"title"`
	Author          string  `json:"author"`
	Genre           string  `json:"genre"`
	Views           int     `json:"views"`
	Completions     int     `json:"completions"`
	CompletionRate  float64 `json:"completion_rate"`
	AverageRating   float64 `json:"average_rating"`
	ReadingTime     float64 `json:"reading_time"`
	RecommendationCTR float64 `json:"recommendation_ctr"`
}

// GenrePerformanceMetric represents genre performance metrics
type GenrePerformanceMetric struct {
	Genre          string  `json:"genre"`
	BookCount      int     `json:"book_count"`
	TotalViews     int     `json:"total_views"`
	AverageRating  float64 `json:"average_rating"`
	CompletionRate float64 `json:"completion_rate"`
	GrowthRate     float64 `json:"growth_rate"`
}

// TrendingContentItem represents a trending content item
type TrendingContentItem struct {
	BookID     int64   `json:"book_id"`
	Title      string  `json:"title"`
	Author     string  `json:"author"`
	TrendScore float64 `json:"trend_score"`
	ViewGrowth float64 `json:"view_growth"`
	TimeFrame  string  `json:"time_frame"`
}

// Recommendation Performance DTOs

// RecommendationEffectivenessResponse represents recommendation effectiveness analysis
type RecommendationEffectivenessResponse struct {
	OverallMetrics          RecommendationOverallMetrics    `json:"overall_metrics"`
	AlgorithmPerformance    []AlgorithmPerformance         `json:"algorithm_performance"`
	GenreEffectiveness      []GenreEffectiveness           `json:"genre_effectiveness"`
	TimeBasedPerformance    []TimeBasedPerformance         `json:"time_based_performance"`
	UserSegmentPerformance  []UserSegmentPerformance       `json:"user_segment_performance"`
	GeneratedAt             time.Time                      `json:"generated_at"`
}

// RecommendationOverallMetrics represents overall recommendation metrics
type RecommendationOverallMetrics struct {
	TotalRecommendations   int     `json:"total_recommendations"`
	ClickThroughRate       float64 `json:"click_through_rate"`
	ConversionRate         float64 `json:"conversion_rate"`
	AverageRelevanceScore  float64 `json:"average_relevance_score"`
	UserSatisfactionScore  float64 `json:"user_satisfaction_score"`
}

// AlgorithmPerformance represents performance of recommendation algorithms
type AlgorithmPerformance struct {
	Algorithm      string  `json:"algorithm"`
	Usage          float64 `json:"usage"`
	ClickRate      float64 `json:"click_rate"`
	ConversionRate float64 `json:"conversion_rate"`
	AccuracyScore  float64 `json:"accuracy_score"`
}

// GenreEffectiveness represents recommendation effectiveness by genre
type GenreEffectiveness struct {
	Genre               string  `json:"genre"`
	RecommendationCount int     `json:"recommendation_count"`
	ClickRate           float64 `json:"click_rate"`
	ConversionRate      float64 `json:"conversion_rate"`
}

// TimeBasedPerformance represents time-based recommendation performance
type TimeBasedPerformance struct {
	Hour                int     `json:"hour"`
	RecommendationCount int     `json:"recommendation_count"`
	ClickRate           float64 `json:"click_rate"`
	ConversionRate      float64 `json:"conversion_rate"`
}

// UserSegmentPerformance represents recommendation performance by user segment
type UserSegmentPerformance struct {
	Segment           string  `json:"segment"`
	ClickRate         float64 `json:"click_rate"`
	ConversionRate    float64 `json:"conversion_rate"`
	SatisfactionScore float64 `json:"satisfaction_score"`
}

// Revenue Analytics DTOs

// RevenueAnalyticsRequest represents request for revenue analytics
type RevenueAnalyticsRequest struct {
	TimeRange  string `json:"time_range" validate:"required,oneof=24h 7d 30d 90d 1y"`
	Currency   string `json:"currency,omitempty"`
	BreakdownBy string `json:"breakdown_by,omitempty"`
}

// RevenueAnalyticsResponse represents revenue analytics
type RevenueAnalyticsResponse struct {
	TimeRange           string                    `json:"time_range"`
	TotalRevenue        float64                   `json:"total_revenue"`
	RevenueGrowth       float64                   `json:"revenue_growth"`
	DailyRevenue        []DailyRevenuePoint       `json:"daily_revenue"`
	RevenueBySource     []RevenueSource           `json:"revenue_by_source"`
	SubscriptionMetrics SubscriptionRevenueMetrics `json:"subscription_metrics"`
	GeneratedAt         time.Time                 `json:"generated_at"`
}

// DailyRevenuePoint represents daily revenue data
type DailyRevenuePoint struct {
	Date     time.Time `json:"date"`
	Revenue  float64   `json:"revenue"`
	Subscriptions int  `json:"subscriptions"`
	Cancellations int  `json:"cancellations"`
}

// RevenueSource represents revenue by source
type RevenueSource struct {
	Source     string  `json:"source"`
	Revenue    float64 `json:"revenue"`
	Percentage float64 `json:"percentage"`
	Growth     float64 `json:"growth"`
}

// SubscriptionRevenueMetrics represents subscription revenue metrics
type SubscriptionRevenueMetrics struct {
	MRR              float64 `json:"mrr"` // Monthly Recurring Revenue
	ARR              float64 `json:"arr"` // Annual Recurring Revenue
	ARPU             float64 `json:"arpu"` // Average Revenue Per User
	LTV              float64 `json:"ltv"` // Lifetime Value
	ChurnRate        float64 `json:"churn_rate"`
	NetRevenueRetention float64 `json:"net_revenue_retention"`
}

// SubscriptionMetricsResponse represents subscription metrics
type SubscriptionMetricsResponse struct {
	TotalSubscriptions   int                        `json:"total_subscriptions"`
	ActiveSubscriptions  int                        `json:"active_subscriptions"`
	NewSubscriptions     int                        `json:"new_subscriptions"`
	CancelledSubscriptions int                      `json:"cancelled_subscriptions"`
	SubscriptionsByPlan  []PlanSubscriptionMetric   `json:"subscriptions_by_plan"`
	ChurnAnalysis        ChurnAnalysisData          `json:"churn_analysis"`
	RevenueMetrics       SubscriptionRevenueMetrics `json:"revenue_metrics"`
	GeneratedAt          time.Time                  `json:"generated_at"`
}

// PlanSubscriptionMetric represents subscription metrics by plan
type PlanSubscriptionMetric struct {
	PlanID          uuid.UUID `json:"plan_id"`
	PlanName        string    `json:"plan_name"`
	ActiveCount     int       `json:"active_count"`
	NewCount        int       `json:"new_count"`
	CancelledCount  int       `json:"cancelled_count"`
	Revenue         float64   `json:"revenue"`
	ChurnRate       float64   `json:"churn_rate"`
}

// ChurnAnalysisResponse represents churn analysis
type ChurnAnalysisResponse struct {
	OverallChurnRate    float64              `json:"overall_churn_rate"`
	ChurnByPlan         []PlanChurnMetric    `json:"churn_by_plan"`
	ChurnReasons        []ChurnReason        `json:"churn_reasons"`
	ChurnPrediction     []ChurnPredictionData `json:"churn_prediction"`
	RetentionStrategies []RetentionStrategy  `json:"retention_strategies"`
	GeneratedAt         time.Time            `json:"generated_at"`
}

// ChurnAnalysisData represents churn analysis data
type ChurnAnalysisData struct {
	ChurnRate      float64         `json:"churn_rate"`
	ChurnReasons   []ChurnReason   `json:"churn_reasons"`
	AtRiskUsers    int             `json:"at_risk_users"`
	ChurnTrend     []ChurnTrendPoint `json:"churn_trend"`
}

// PlanChurnMetric represents churn metrics by plan
type PlanChurnMetric struct {
	PlanName    string  `json:"plan_name"`
	ChurnRate   float64 `json:"churn_rate"`
	ChurnCount  int     `json:"churn_count"`
	TotalUsers  int     `json:"total_users"`
}

// ChurnReason represents a reason for churn
type ChurnReason struct {
	Reason     string  `json:"reason"`
	Count      int     `json:"count"`
	Percentage float64 `json:"percentage"`
}

// ChurnPredictionData represents churn prediction data
type ChurnPredictionData struct {
	UserID      uuid.UUID `json:"user_id"`
	ChurnRisk   float64   `json:"churn_risk"`
	RiskLevel   string    `json:"risk_level"`
	Factors     []string  `json:"factors"`
	LastActivity time.Time `json:"last_activity"`
}

// ChurnTrendPoint represents a point in churn trend data
type ChurnTrendPoint struct {
	Date      time.Time `json:"date"`
	ChurnRate float64   `json:"churn_rate"`
	ChurnCount int      `json:"churn_count"`
}

// RetentionStrategy represents a retention strategy
type RetentionStrategy struct {
	Strategy    string  `json:"strategy"`
	TargetSegment string `json:"target_segment"`
	Effectiveness float64 `json:"effectiveness"`
	Implementation string `json:"implementation"`
}

// Performance Monitoring DTOs

// SystemPerformanceResponse represents system performance metrics
type SystemPerformanceResponse struct {
	CPUUsage       float64                 `json:"cpu_usage"`
	MemoryUsage    float64                 `json:"memory_usage"`
	DiskUsage      float64                 `json:"disk_usage"`
	NetworkIO      NetworkIOMetric         `json:"network_io"`
	DatabaseMetrics DatabasePerformanceMetric `json:"database_metrics"`
	CacheMetrics   CachePerformanceMetric  `json:"cache_metrics"`
	APIMetrics     APIPerformanceMetric    `json:"api_metrics"`
	GeneratedAt    time.Time               `json:"generated_at"`
}

// NetworkIOMetric represents network I/O metrics
type NetworkIOMetric struct {
	BytesIn  int64 `json:"bytes_in"`
	BytesOut int64 `json:"bytes_out"`
	PacketsIn int64 `json:"packets_in"`
	PacketsOut int64 `json:"packets_out"`
}

// DatabasePerformanceMetric represents database performance
type DatabasePerformanceMetric struct {
	ConnectionCount    int     `json:"connection_count"`
	AverageQueryTime   float64 `json:"average_query_time"`
	SlowQueriesCount   int     `json:"slow_queries_count"`
	DeadlocksCount     int     `json:"deadlocks_count"`
	CacheHitRate       float64 `json:"cache_hit_rate"`
}

// CachePerformanceMetric represents cache performance
type CachePerformanceMetric struct {
	HitRate       float64 `json:"hit_rate"`
	MissRate      float64 `json:"miss_rate"`
	EvictionRate  float64 `json:"eviction_rate"`
	MemoryUsage   float64 `json:"memory_usage"`
	KeyCount      int     `json:"key_count"`
}

// APIPerformanceMetric represents API performance
type APIPerformanceMetric struct {
	RequestsPerSecond   float64 `json:"requests_per_second"`
	AverageResponseTime float64 `json:"average_response_time"`
	ErrorRate          float64 `json:"error_rate"`
	P95ResponseTime    float64 `json:"p95_response_time"`
	P99ResponseTime    float64 `json:"p99_response_time"`
}

// APIMetricsResponse represents API metrics
type APIMetricsResponse struct {
	Timeframe        string                  `json:"timeframe"`
	OverallMetrics   APIPerformanceMetric    `json:"overall_metrics"`
	EndpointMetrics  []DetailedEndpointMetric `json:"endpoint_metrics"`
	ErrorBreakdown   []ErrorBreakdown        `json:"error_breakdown"`
	TrafficPatterns  []TrafficPattern        `json:"traffic_patterns"`
	GeneratedAt      time.Time               `json:"generated_at"`
}

// DetailedEndpointMetric represents detailed endpoint metrics
type DetailedEndpointMetric struct {
	Endpoint        string  `json:"endpoint"`
	Method          string  `json:"method"`
	RequestCount    int     `json:"request_count"`
	AverageLatency  float64 `json:"average_latency"`
	ErrorCount      int     `json:"error_count"`
	ErrorRate       float64 `json:"error_rate"`
	P95Latency      float64 `json:"p95_latency"`
	ThroughputRPS   float64 `json:"throughput_rps"`
}

// ErrorBreakdown represents error breakdown
type ErrorBreakdown struct {
	StatusCode   int     `json:"status_code"`
	ErrorType    string  `json:"error_type"`
	Count        int     `json:"count"`
	Percentage   float64 `json:"percentage"`
	Trend        string  `json:"trend"`
}

// TrafficPattern represents traffic pattern
type TrafficPattern struct {
	Hour         int     `json:"hour"`
	RequestCount int     `json:"request_count"`
	AverageLoad  float64 `json:"average_load"`
}

// ErrorAnalysisResponse represents error analysis
type ErrorAnalysisResponse struct {
	TotalErrors      int                    `json:"total_errors"`
	ErrorRate        float64                `json:"error_rate"`
	ErrorsByType     []ErrorTypeBreakdown   `json:"errors_by_type"`
	ErrorsByEndpoint []EndpointErrorMetric  `json:"errors_by_endpoint"`
	ErrorTrends      []ErrorTrendPoint      `json:"error_trends"`
	CriticalErrors   []CriticalError        `json:"critical_errors"`
	GeneratedAt      time.Time              `json:"generated_at"`
}

// ErrorTypeBreakdown represents breakdown of errors by type
type ErrorTypeBreakdown struct {
	ErrorType  string  `json:"error_type"`
	Count      int     `json:"count"`
	Percentage float64 `json:"percentage"`
	Impact     string  `json:"impact"`
}

// EndpointErrorMetric represents error metrics by endpoint
type EndpointErrorMetric struct {
	Endpoint   string  `json:"endpoint"`
	ErrorCount int     `json:"error_count"`
	ErrorRate  float64 `json:"error_rate"`
	LastError  time.Time `json:"last_error"`
}

// ErrorTrendPoint represents a point in error trend data
type ErrorTrendPoint struct {
	Time       time.Time `json:"time"`
	ErrorCount int       `json:"error_count"`
	ErrorRate  float64   `json:"error_rate"`
}

// CriticalError represents a critical error
type CriticalError struct {
	ID          uuid.UUID `json:"id"`
	Type        string    `json:"type"`
	Message     string    `json:"message"`
	Endpoint    string    `json:"endpoint"`
	Frequency   int       `json:"frequency"`
	FirstSeen   time.Time `json:"first_seen"`
	LastSeen    time.Time `json:"last_seen"`
	Status      string    `json:"status"`
}

// ML Model Performance DTOs

// ModelPerformanceResponse represents ML model performance
type ModelPerformanceResponse struct {
	Models      []ModelMetric      `json:"models"`
	OverallHealth string           `json:"overall_health"`
	Alerts      []ModelAlert       `json:"alerts"`
	Recommendations []ModelRecommendation `json:"recommendations"`
	GeneratedAt time.Time          `json:"generated_at"`
}

// ModelMetric represents metrics for a specific model
type ModelMetric struct {
	ModelName       string    `json:"model_name"`
	Version         string    `json:"version"`
	Status          string    `json:"status"`
	Accuracy        float64   `json:"accuracy"`
	Precision       float64   `json:"precision"`
	Recall          float64   `json:"recall"`
	F1Score         float64   `json:"f1_score"`
	LastTrained     time.Time `json:"last_trained"`
	PredictionCount int       `json:"prediction_count"`
	ErrorRate       float64   `json:"error_rate"`
}

// ModelAlert represents a model alert
type ModelAlert struct {
	ModelName string    `json:"model_name"`
	AlertType string    `json:"alert_type"`
	Message   string    `json:"message"`
	Severity  string    `json:"severity"`
	Timestamp time.Time `json:"timestamp"`
}

// ModelRecommendation represents a model improvement recommendation
type ModelRecommendation struct {
	ModelName     string `json:"model_name"`
	RecommendationType string `json:"recommendation_type"`
	Description   string `json:"description"`
	Priority      string `json:"priority"`
	EstimatedImpact string `json:"estimated_impact"`
}

// RecommendationQualityResponse represents recommendation quality metrics
type RecommendationQualityResponse struct {
	OverallQuality    float64                    `json:"overall_quality"`
	QualityByAlgorithm []AlgorithmQualityMetric  `json:"quality_by_algorithm"`
	DiversityMetrics  DiversityMetric           `json:"diversity_metrics"`
	NoveltyMetrics    NoveltyMetric             `json:"novelty_metrics"`
	FairnessMetrics   FairnessMetric            `json:"fairness_metrics"`
	GeneratedAt       time.Time                 `json:"generated_at"`
}

// AlgorithmQualityMetric represents quality metrics for an algorithm
type AlgorithmQualityMetric struct {
	Algorithm    string  `json:"algorithm"`
	Accuracy     float64 `json:"accuracy"`
	Relevance    float64 `json:"relevance"`
	Diversity    float64 `json:"diversity"`
	Novelty      float64 `json:"novelty"`
	Coverage     float64 `json:"coverage"`
	Serendipity  float64 `json:"serendipity"`
}

// DiversityMetric represents diversity metrics
type DiversityMetric struct {
	IntraListDiversity float64 `json:"intra_list_diversity"`
	CatalogCoverage    float64 `json:"catalog_coverage"`
	GenreDistribution  float64 `json:"genre_distribution"`
	AuthorDistribution float64 `json:"author_distribution"`
}

// NoveltyMetric represents novelty metrics
type NoveltyMetric struct {
	AveragePopularity float64 `json:"average_popularity"`
	LongTailCoverage  float64 `json:"long_tail_coverage"`
	FreshnessScore    float64 `json:"freshness_score"`
	DiscoveryRate     float64 `json:"discovery_rate"`
}

// FairnessMetric represents fairness metrics
type FairnessMetric struct {
	GenderBalance     float64 `json:"gender_balance"`
	AgeGroupBalance   float64 `json:"age_group_balance"`
	GenreEquity       float64 `json:"genre_equity"`
	AuthorEquity      float64 `json:"author_equity"`
}

// ABTestSummaryResponse represents A/B test summary
type ABTestSummaryResponse struct {
	ActiveExperiments   int                   `json:"active_experiments"`
	CompletedExperiments int                  `json:"completed_experiments"`
	ExperimentSummaries []ExperimentSummary   `json:"experiment_summaries"`
	OverallImpact       ABTestOverallImpact   `json:"overall_impact"`
	GeneratedAt         time.Time             `json:"generated_at"`
}

// ExperimentSummary represents summary of an experiment
type ExperimentSummary struct {
	ExperimentID   uuid.UUID `json:"experiment_id"`
	Name           string    `json:"name"`
	Status         string    `json:"status"`
	StartDate      time.Time `json:"start_date"`
	Participants   int       `json:"participants"`
	ConversionLift float64   `json:"conversion_lift"`
	Significance   bool      `json:"significance"`
	Winner         string    `json:"winner"`
}

// ABTestOverallImpact represents overall impact of A/B tests
type ABTestOverallImpact struct {
	TotalParticipants     int     `json:"total_participants"`
	AverageConversionLift float64 `json:"average_conversion_lift"`
	SignificantTests      int     `json:"significant_tests"`
	TotalTests            int     `json:"total_tests"`
	EstimatedRevenueLift  float64 `json:"estimated_revenue_lift"`
}