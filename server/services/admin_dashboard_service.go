package services

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/repository"
)

// AdminDashboardService provides administrative dashboard functionality
type AdminDashboardService interface {
	// System Overview
	GetSystemOverview(ctx context.Context) (*dto.SystemOverviewResponse, error)
	GetRealtimeMetrics(ctx context.Context) (*dto.RealtimeMetricsResponse, error)
	
	// User Management
	GetUserStatistics(ctx context.Context, req *dto.UserStatisticsRequest) (*dto.UserStatisticsResponse, error)
	GetUserEngagementMetrics(ctx context.Context, timeframe string) (*dto.UserEngagementResponse, error)
	GetUserRetentionAnalysis(ctx context.Context) (*dto.UserRetentionResponse, error)
	
	// Content Management
	GetBookStatistics(ctx context.Context) (*dto.BookStatisticsResponse, error)
	GetContentPerformance(ctx context.Context, req *dto.ContentPerformanceRequest) (*dto.ContentPerformanceResponse, error)
	GetRecommendationEffectiveness(ctx context.Context) (*dto.RecommendationEffectivenessResponse, error)
	
	// Revenue Analytics
	GetRevenueAnalytics(ctx context.Context, req *dto.RevenueAnalyticsRequest) (*dto.RevenueAnalyticsResponse, error)
	GetSubscriptionMetrics(ctx context.Context) (*dto.SubscriptionMetricsResponse, error)
	GetChurnAnalysis(ctx context.Context) (*dto.ChurnAnalysisResponse, error)
	
	// Performance Monitoring
	GetSystemPerformance(ctx context.Context) (*dto.SystemPerformanceResponse, error)
	GetAPIMetrics(ctx context.Context, timeframe string) (*dto.APIMetricsResponse, error)
	GetErrorAnalysis(ctx context.Context) (*dto.ErrorAnalysisResponse, error)
	
	// ML Model Monitoring
	GetModelPerformance(ctx context.Context) (*dto.ModelPerformanceResponse, error)
	GetRecommendationQuality(ctx context.Context) (*dto.RecommendationQualityResponse, error)
	GetABTestSummary(ctx context.Context) (*dto.ABTestSummaryResponse, error)
}

type adminDashboardService struct {
	*BaseService
	userRepo            repository.UserRepository
	bookRepo            repository.BookRepository
	subscriptionRepo    repository.UserSubscriptionRepository
	analyticsRepo       repository.ReadingAnalyticsRepository
	interactionRepo     repository.UserInteractionRepository
	feedbackRepo        repository.RecommendationFeedbackRepository
	abTestingService    ABTestingService
	subscriptionService SubscriptionService
}

// NewAdminDashboardService creates a new admin dashboard service
func NewAdminDashboardService(
	userRepo repository.UserRepository,
	bookRepo repository.BookRepository,
	subscriptionRepo repository.UserSubscriptionRepository,
	analyticsRepo repository.ReadingAnalyticsRepository,
	interactionRepo repository.UserInteractionRepository,
	feedbackRepo repository.RecommendationFeedbackRepository,
	abTestingService ABTestingService,
	subscriptionService SubscriptionService,
	logger *logger.Logger,
) AdminDashboardService {
	return &adminDashboardService{
		BaseService:         NewBaseService(logger),
		userRepo:            userRepo,
		bookRepo:            bookRepo,
		subscriptionRepo:    subscriptionRepo,
		analyticsRepo:       analyticsRepo,
		interactionRepo:     interactionRepo,
		feedbackRepo:        feedbackRepo,
		abTestingService:    abTestingService,
		subscriptionService: subscriptionService,
	}
}

// GetSystemOverview provides high-level system metrics
func (s *adminDashboardService) GetSystemOverview(ctx context.Context) (*dto.SystemOverviewResponse, error) {
	s.logger.Info("Getting system overview")

	// This would typically query multiple data sources
	// For now, returning mock data that represents a real system

	now := time.Now()
	today := now.Truncate(24 * time.Hour)
	_ = today.Add(-24 * time.Hour)  // yesterday - not used yet
	_ = today.Add(-7 * 24 * time.Hour)  // lastWeek - not used yet  
	_ = today.Add(-30 * 24 * time.Hour) // lastMonth - not used yet

	overview := &dto.SystemOverviewResponse{
		TotalUsers:      15420,
		ActiveUsers24h:  2340,
		ActiveUsers7d:   8920,
		TotalBooks:      2450,
		TotalReadingSessions: 45320,
		RecommendationsServed: 123450,
		
		UserGrowth: dto.GrowthMetric{
			Current:        15420,
			Previous:       14890,
			GrowthRate:     3.56,
			GrowthAbsolute: 530,
		},
		
		EngagementMetrics: dto.EngagementMetric{
			DailyActiveUsers:  2340,
			AverageSessionTime: 24.5,
			BounceRate:        12.3,
			RetentionRate:     68.9,
		},
		
		RevenueMetrics: dto.RevenueMetric{
			TotalRevenue:    245678.90,
			MonthlyRevenue:  45678.90,
			AverageARPU:     12.45,
			ConversionRate:  8.9,
		},
		
		SystemHealth: dto.SystemHealthMetric{
			APIResponseTime:     85.6,
			ErrorRate:          0.05,
			CacheHitRate:       94.2,
			DatabaseConnections: 45,
		},
		
		TopPerformingBooks: []dto.BookPerformance{
			{BookID: 1001, Title: "人気小説A", Author: "著名作家", ReadingCount: 1234, Rating: 4.8},
			{BookID: 1002, Title: "話題の本B", Author: "新進作家", ReadingCount: 987, Rating: 4.6},
			{BookID: 1003, Title: "ベストセラーC", Author: "人気作家", ReadingCount: 876, Rating: 4.9},
		},
		
		RecentAlerts: []dto.SystemAlert{
			{
				ID:       uuid.New(),
				Type:     "warning",
				Message:  "API応答時間が閾値を超えています",
				Severity: "medium",
				Timestamp: now.Add(-30 * time.Minute),
			},
			{
				ID:       uuid.New(),
				Type:     "info",
				Message:  "新しいA/Bテストが開始されました",
				Severity: "low",
				Timestamp: now.Add(-2 * time.Hour),
			},
		},
		
		GeneratedAt: now,
	}

	return overview, nil
}

// GetRealtimeMetrics provides real-time system metrics
func (s *adminDashboardService) GetRealtimeMetrics(ctx context.Context) (*dto.RealtimeMetricsResponse, error) {
	s.logger.Info("Getting real-time metrics")

	now := time.Now()

	metrics := &dto.RealtimeMetricsResponse{
		CurrentActiveUsers:    234,
		RequestsPerSecond:     45.6,
		AverageResponseTime:   89.3,
		ErrorRate:            0.12,
		CacheHitRate:         93.8,
		DatabaseLoad:         68.5,
		MemoryUsage:          71.2,
		CPUUsage:             54.3,
		
		TopEndpoints: []dto.EndpointMetric{
			{Endpoint: "/api/v1/recommendations", RequestCount: 1234, AverageLatency: 95.6},
			{Endpoint: "/api/v1/books", RequestCount: 987, AverageLatency: 67.3},
			{Endpoint: "/api/v1/analytics/stats", RequestCount: 654, AverageLatency: 123.4},
		},
		
		RecentErrors: []dto.ErrorMetric{
			{
				Type:      "timeout",
				Count:     12,
				LastOccurrence: now.Add(-5 * time.Minute),
				Endpoint:  "/api/v1/recommendations",
			},
			{
				Type:      "validation",
				Count:     8,
				LastOccurrence: now.Add(-15 * time.Minute),
				Endpoint:  "/api/v1/subscriptions",
			},
		},
		
		MLModelStatus: []dto.MLModelStatus{
			{
				ModelName:    "recommendation_engine",
				Status:       "healthy",
				Accuracy:     94.2,
				LastUpdated:  now.Add(-4 * time.Hour),
				Version:      "v2.1.3",
			},
			{
				ModelName:    "content_similarity",
				Status:       "training",
				Accuracy:     91.8,
				LastUpdated:  now.Add(-1 * time.Hour),
				Version:      "v1.8.2",
			},
		},
		
		Timestamp: now,
	}

	return metrics, nil
}

// GetUserEngagementMetrics provides user engagement analysis
func (s *adminDashboardService) GetUserEngagementMetrics(ctx context.Context, timeframe string) (*dto.UserEngagementResponse, error) {
	s.logger.Info("Getting user engagement metrics")

	// Mock data for demonstration
	engagement := &dto.UserEngagementResponse{
		Timeframe: timeframe,
		
		OverallEngagement: dto.EngagementOverview{
			TotalSessions:      12450,
			AverageSessionTime: 26.8,
			PagesPerSession:    4.2,
			BounceRate:        11.5,
		},
		
		DailyEngagement: []dto.DailyEngagement{
			{Date: time.Now().Add(-6*24*time.Hour), Sessions: 1890, AverageTime: 25.4, UniqueUsers: 1654},
			{Date: time.Now().Add(-5*24*time.Hour), Sessions: 2134, AverageTime: 27.2, UniqueUsers: 1823},
			{Date: time.Now().Add(-4*24*time.Hour), Sessions: 1967, AverageTime: 24.8, UniqueUsers: 1734},
			{Date: time.Now().Add(-3*24*time.Hour), Sessions: 2287, AverageTime: 28.9, UniqueUsers: 1945},
			{Date: time.Now().Add(-2*24*time.Hour), Sessions: 2156, AverageTime: 26.1, UniqueUsers: 1876},
			{Date: time.Now().Add(-1*24*time.Hour), Sessions: 2345, AverageTime: 29.3, UniqueUsers: 2012},
			{Date: time.Now(), Sessions: 1823, AverageTime: 25.7, UniqueUsers: 1598},
		},
		
		UserSegments: []dto.UserSegmentEngagement{
			{Segment: "新規ユーザー", UserCount: 2340, EngagementScore: 72.5, RetentionRate: 45.8},
			{Segment: "アクティブユーザー", UserCount: 8920, EngagementScore: 89.3, RetentionRate: 85.2},
			{Segment: "プレミアムユーザー", UserCount: 1560, EngagementScore: 94.7, RetentionRate: 92.8},
			{Segment: "休眠ユーザー", UserCount: 2600, EngagementScore: 23.1, RetentionRate: 12.5},
		},
		
		FeatureUsage: []dto.FeatureUsageMetric{
			{Feature: "本の検索", UsageCount: 15670, UserPercentage: 78.5},
			{Feature: "推薦機能", UsageCount: 12340, UserPercentage: 61.8},
			{Feature: "読書記録", UsageCount: 9870, UserPercentage: 49.4},
			{Feature: "TTS機能", UsageCount: 6540, UserPercentage: 32.7},
			{Feature: "オフライン読書", UsageCount: 4320, UserPercentage: 21.6},
		},
		
		GeneratedAt: time.Now(),
	}

	return engagement, nil
}

// GetRecommendationEffectiveness analyzes recommendation system performance
func (s *adminDashboardService) GetRecommendationEffectiveness(ctx context.Context) (*dto.RecommendationEffectivenessResponse, error) {
	s.logger.Info("Getting recommendation effectiveness metrics")

	effectiveness := &dto.RecommendationEffectivenessResponse{
		OverallMetrics: dto.RecommendationOverallMetrics{
			TotalRecommendations:    45670,
			ClickThroughRate:       18.5,
			ConversionRate:         12.3,
			AverageRelevanceScore:  4.2,
			UserSatisfactionScore:  4.6,
		},
		
		AlgorithmPerformance: []dto.AlgorithmPerformance{
			{
				Algorithm:      "hybrid",
				Usage:          45.2,
				ClickRate:      19.8,
				ConversionRate: 14.2,
				AccuracyScore:  4.3,
			},
			{
				Algorithm:      "content_based",
				Usage:          28.7,
				ClickRate:      16.4,
				ConversionRate: 11.8,
				AccuracyScore:  4.1,
			},
			{
				Algorithm:      "collaborative",
				Usage:          20.1,
				ClickRate:      17.9,
				ConversionRate: 10.9,
				AccuracyScore:  3.9,
			},
			{
				Algorithm:      "trending",
				Usage:          6.0,
				ClickRate:      22.3,
				ConversionRate: 8.5,
				AccuracyScore:  3.7,
			},
		},
		
		GenreEffectiveness: []dto.GenreEffectiveness{
			{Genre: "現代小説", RecommendationCount: 8920, ClickRate: 21.3, ConversionRate: 15.7},
			{Genre: "ミステリー", RecommendationCount: 6780, ClickRate: 19.8, ConversionRate: 13.4},
			{Genre: "SF", RecommendationCount: 4560, ClickRate: 17.2, ConversionRate: 11.9},
			{Genre: "古典文学", RecommendationCount: 3240, ClickRate: 14.6, ConversionRate: 9.8},
		},
		
		TimeBasedPerformance: []dto.TimeBasedPerformance{
			{Hour: 9, RecommendationCount: 890, ClickRate: 16.8, ConversionRate: 11.2},
			{Hour: 12, RecommendationCount: 1240, ClickRate: 18.9, ConversionRate: 12.8},
			{Hour: 15, RecommendationCount: 1100, ClickRate: 17.3, ConversionRate: 11.9},
			{Hour: 18, RecommendationCount: 1450, ClickRate: 20.1, ConversionRate: 14.5},
			{Hour: 21, RecommendationCount: 1680, ClickRate: 22.4, ConversionRate: 16.7},
		},
		
		UserSegmentPerformance: []dto.UserSegmentPerformance{
			{Segment: "新規ユーザー", ClickRate: 15.2, ConversionRate: 8.9, SatisfactionScore: 4.1},
			{Segment: "アクティブユーザー", ClickRate: 19.8, ConversionRate: 13.7, SatisfactionScore: 4.5},
			{Segment: "プレミアムユーザー", ClickRate: 24.3, ConversionRate: 18.9, SatisfactionScore: 4.8},
		},
		
		GeneratedAt: time.Now(),
	}

	return effectiveness, nil
}

// Stub implementations for remaining methods

func (s *adminDashboardService) GetUserStatistics(ctx context.Context, req *dto.UserStatisticsRequest) (*dto.UserStatisticsResponse, error) {
	s.logger.Info("Getting user statistics")

	if err := s.ValidateStruct(req); err != nil {
		return nil, err
	}

	// Mock data based on request parameters
	now := time.Now()
	
	// Generate mock data for demonstration
	var totalUsers, newUsers, activeUsers, churnedUsers int
	
	switch req.TimeRange {
	case "24h":
		totalUsers = 15420
		newUsers = 342
		activeUsers = 2340
		churnedUsers = 23
	case "7d":
		totalUsers = 15420
		newUsers = 1890
		activeUsers = 8920
		churnedUsers = 156
	case "30d":
		totalUsers = 15420
		newUsers = 6780
		activeUsers = 12340
		churnedUsers = 567
	case "90d":
		totalUsers = 15420
		newUsers = 14230
		activeUsers = 13890
		churnedUsers = 1234
	default:
		totalUsers = 15420
		newUsers = 342
		activeUsers = 2340
		churnedUsers = 23
	}

	// Generate growth trend data
	var growthTrend []dto.UserGrowthPoint
	for i := 0; i < 7; i++ {
		date := now.AddDate(0, 0, -i)
		growthTrend = append(growthTrend, dto.UserGrowthPoint{
			Date:       date,
			NewUsers:   200 + (i * 50),
			TotalUsers: totalUsers - (i * 100),
			ChurnRate:  2.5 + float64(i)*0.3,
		})
	}

	return &dto.UserStatisticsResponse{
		TotalUsers:      totalUsers,
		NewUsers:        newUsers,
		ActiveUsers:     activeUsers,
		ChurnedUsers:    churnedUsers,
		UserGrowthTrend: growthTrend,
		DemographicData: dto.UserDemographicData{
			AgeGroups: []dto.DemographicSegment{
				{Segment: "18-25", Count: 3084, Percentage: 20.0},
				{Segment: "26-35", Count: 4626, Percentage: 30.0},
				{Segment: "36-45", Count: 3855, Percentage: 25.0},
				{Segment: "46-55", Count: 2313, Percentage: 15.0},
				{Segment: "55+", Count: 1542, Percentage: 10.0},
			},
			Locations: []dto.DemographicSegment{
				{Segment: "Japan", Count: 12336, Percentage: 80.0},
				{Segment: "USA", Count: 1542, Percentage: 10.0},
				{Segment: "Others", Count: 1542, Percentage: 10.0},
			},
			DeviceTypes: []dto.DemographicSegment{
				{Segment: "Mobile", Count: 10794, Percentage: 70.0},
				{Segment: "Desktop", Count: 3084, Percentage: 20.0},
				{Segment: "Tablet", Count: 1542, Percentage: 10.0},
			},
			SubscriptionTiers: []dto.DemographicSegment{
				{Segment: "Free", Count: 12336, Percentage: 80.0},
				{Segment: "Premium", Count: 2313, Percentage: 15.0},
				{Segment: "Pro", Count: 771, Percentage: 5.0},
			},
		},
		GeneratedAt: now,
	}, nil
}

func (s *adminDashboardService) GetUserRetentionAnalysis(ctx context.Context) (*dto.UserRetentionResponse, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *adminDashboardService) GetBookStatistics(ctx context.Context) (*dto.BookStatisticsResponse, error) {
	s.logger.Info("Getting book statistics")

	now := time.Now()

	return &dto.BookStatisticsResponse{
		TotalBooks:           2450,
		ActiveBooks:          2340,
		NewBooks:             89,
		TotalReadingSessions: 45320,
		TopPerformingBooks: []dto.BookPerformance{
			{BookID: 1001, Title: "人気小説A", Author: "著名作家", ReadingCount: 1234, Rating: 4.8},
			{BookID: 1002, Title: "話題の本B", Author: "新進作家", ReadingCount: 987, Rating: 4.6},
			{BookID: 1003, Title: "ベストセラーC", Author: "人気作家", ReadingCount: 876, Rating: 4.9},
			{BookID: 1004, Title: "注目作品D", Author: "新人作家", ReadingCount: 654, Rating: 4.5},
			{BookID: 1005, Title: "話題作E", Author: "ベテラン作家", ReadingCount: 543, Rating: 4.7},
		},
		GenreDistribution: []dto.GenreDistribution{
			{Genre: "現代小説", BookCount: 612, Percentage: 25.0, PopularityScore: 4.6},
			{Genre: "ミステリー", BookCount: 490, Percentage: 20.0, PopularityScore: 4.5},
			{Genre: "SF", BookCount: 367, Percentage: 15.0, PopularityScore: 4.3},
			{Genre: "恋愛", BookCount: 294, Percentage: 12.0, PopularityScore: 4.4},
			{Genre: "古典文学", BookCount: 245, Percentage: 10.0, PopularityScore: 4.2},
			{Genre: "その他", BookCount: 442, Percentage: 18.0, PopularityScore: 4.1},
		},
		AuthorPerformance: []dto.AuthorPerformance{
			{Author: "著名作家", BookCount: 15, TotalReads: 12450, AverageRating: 4.7, PopularityRank: 1},
			{Author: "人気作家", BookCount: 12, TotalReads: 9876, AverageRating: 4.6, PopularityRank: 2},
			{Author: "ベテラン作家", BookCount: 18, TotalReads: 8765, AverageRating: 4.5, PopularityRank: 3},
			{Author: "新進作家", BookCount: 8, TotalReads: 7654, AverageRating: 4.4, PopularityRank: 4},
			{Author: "新人作家", BookCount: 5, TotalReads: 6543, AverageRating: 4.3, PopularityRank: 5},
		},
		ContentTrends: []dto.ContentTrend{
			{Category: "現代小説", TrendType: "rising", ChangeRate: 15.3, TimeFrame: "30d", UpdatedAt: now},
			{Category: "SF", TrendType: "rising", ChangeRate: 12.8, TimeFrame: "30d", UpdatedAt: now},
			{Category: "古典文学", TrendType: "stable", ChangeRate: 2.1, TimeFrame: "30d", UpdatedAt: now},
			{Category: "恋愛", TrendType: "falling", ChangeRate: -5.4, TimeFrame: "30d", UpdatedAt: now},
		},
		GeneratedAt: now,
	}, nil
}

func (s *adminDashboardService) GetContentPerformance(ctx context.Context, req *dto.ContentPerformanceRequest) (*dto.ContentPerformanceResponse, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *adminDashboardService) GetRevenueAnalytics(ctx context.Context, req *dto.RevenueAnalyticsRequest) (*dto.RevenueAnalyticsResponse, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *adminDashboardService) GetSubscriptionMetrics(ctx context.Context) (*dto.SubscriptionMetricsResponse, error) {
	s.logger.Info("Getting subscription metrics")

	now := time.Now()

	return &dto.SubscriptionMetricsResponse{
		TotalSubscriptions:     3142,
		ActiveSubscriptions:    2876,
		NewSubscriptions:       234,
		CancelledSubscriptions: 89,
		SubscriptionsByPlan: []dto.PlanSubscriptionMetric{
			{
				PlanID:         uuid.New(),
				PlanName:       "無料プラン", 
				ActiveCount:    12336,
				NewCount:       156,
				CancelledCount: 23,
				Revenue:        0.0,
				ChurnRate:      1.2,
			},
			{
				PlanID:         uuid.New(),
				PlanName:       "プレミアムプラン",
				ActiveCount:    2313,
				NewCount:       89,
				CancelledCount: 45,
				Revenue:        138780.0,
				ChurnRate:      3.4,
			},
			{
				PlanID:         uuid.New(),
				PlanName:       "プロプラン",
				ActiveCount:    563,
				NewCount:       23,
				CancelledCount: 12,
				Revenue:        56300.0,
				ChurnRate:      2.1,
			},
		},
		ChurnAnalysis: dto.ChurnAnalysisData{
			ChurnRate: 2.8,
			ChurnReasons: []dto.ChurnReason{
				{Reason: "価格が高い", Count: 34, Percentage: 38.2},
				{Reason: "機能が不十分", Count: 23, Percentage: 25.8},
				{Reason: "使用頻度が低い", Count: 18, Percentage: 20.2},
				{Reason: "競合サービスに移行", Count: 14, Percentage: 15.8},
			},
			AtRiskUsers: 234,
			ChurnTrend: []dto.ChurnTrendPoint{
				{Date: now.AddDate(0, 0, -6), ChurnRate: 2.1, ChurnCount: 67},
				{Date: now.AddDate(0, 0, -5), ChurnRate: 2.3, ChurnCount: 73},
				{Date: now.AddDate(0, 0, -4), ChurnRate: 2.6, ChurnCount: 82},
				{Date: now.AddDate(0, 0, -3), ChurnRate: 2.4, ChurnCount: 76},
				{Date: now.AddDate(0, 0, -2), ChurnRate: 2.8, ChurnCount: 89},
				{Date: now.AddDate(0, 0, -1), ChurnRate: 2.5, ChurnCount: 79},
				{Date: now, ChurnRate: 2.8, ChurnCount: 89},
			},
		},
		RevenueMetrics: dto.SubscriptionRevenueMetrics{
			MRR:                 162340.0,
			ARR:                 1948080.0,
			ARPU:                56.45,
			LTV:                 675.80,
			ChurnRate:           2.8,
			NetRevenueRetention: 108.5,
		},
		GeneratedAt: now,
	}, nil
}

func (s *adminDashboardService) GetChurnAnalysis(ctx context.Context) (*dto.ChurnAnalysisResponse, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *adminDashboardService) GetSystemPerformance(ctx context.Context) (*dto.SystemPerformanceResponse, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *adminDashboardService) GetAPIMetrics(ctx context.Context, timeframe string) (*dto.APIMetricsResponse, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *adminDashboardService) GetErrorAnalysis(ctx context.Context) (*dto.ErrorAnalysisResponse, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *adminDashboardService) GetModelPerformance(ctx context.Context) (*dto.ModelPerformanceResponse, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *adminDashboardService) GetRecommendationQuality(ctx context.Context) (*dto.RecommendationQualityResponse, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *adminDashboardService) GetABTestSummary(ctx context.Context) (*dto.ABTestSummaryResponse, error) {
	return nil, fmt.Errorf("not implemented")
}