package services

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/repository"
)

// AnalyticsService defines the interface for analytics operations
type AnalyticsService interface {
	// Stats and Analytics
	GetReadingStats(ctx context.Context, userID uuid.UUID, req *dto.ReadingStatsRequest) (*dto.ReadingStatsResponse, error)
	GetReadingStreak(ctx context.Context, userID uuid.UUID) (*dto.ReadingStreakResponse, error)
	
	// Goals
	CreateGoal(ctx context.Context, userID uuid.UUID, req *dto.CreateGoalRequest) (*dto.GoalResponse, error)
	GetGoals(ctx context.Context, userID uuid.UUID) (*dto.GoalsListResponse, error)
	UpdateGoal(ctx context.Context, goalID uuid.UUID, req *dto.UpdateGoalRequest) (*dto.GoalResponse, error)
	DeleteGoal(ctx context.Context, goalID uuid.UUID) error
	
	// Achievements
	GetAchievements(ctx context.Context, userID uuid.UUID) (*dto.AchievementsListResponse, error)
	CheckAndAwardAchievements(ctx context.Context, userID uuid.UUID) ([]*domain.UserAchievement, error)
	
	// Progress
	GetBookProgress(ctx context.Context, userID uuid.UUID, bookID int64) (*dto.BookProgressResponse, error)
	GetCurrentlyReading(ctx context.Context, userID uuid.UUID) (*dto.CurrentlyReadingResponse, error)
	UpdateBookProgress(ctx context.Context, userID uuid.UUID, req *dto.UpdateProgressRequest) error
	MarkBookAsCompleted(ctx context.Context, userID uuid.UUID, bookID int64) error
	MarkBookAsAbandoned(ctx context.Context, userID uuid.UUID, bookID int64, reason string) error
	
	// Context
	RecordReadingContext(ctx context.Context, userID uuid.UUID, req *dto.ReadingContextRequest) (*dto.ReadingContextResponse, error)
	GetContextInsights(ctx context.Context, userID uuid.UUID) (*dto.ContextInsightsResponse, error)
	
	// Insights
	GetReadingInsights(ctx context.Context, userID uuid.UUID) (*dto.InsightsListResponse, error)
	MarkInsightAsRead(ctx context.Context, insightID uuid.UUID) error
	GenerateInsights(ctx context.Context, userID uuid.UUID) error
}

type analyticsService struct {
	*BaseService
	analyticsRepo     repository.ReadingAnalyticsRepository
	streakRepo        repository.ReadingStreakRepository
	goalRepo          repository.ReadingGoalRepository
	achievementRepo   repository.AchievementRepository
	userAchievementRepo repository.UserAchievementRepository
	progressRepo      repository.BookProgressRepository
	contextRepo       repository.ReadingContextRepository
	insightRepo       repository.ReadingInsightRepository
	bookRepo          repository.BookRepository
}

// NewAnalyticsService creates a new analytics service
func NewAnalyticsService(
	analyticsRepo repository.ReadingAnalyticsRepository,
	streakRepo repository.ReadingStreakRepository,
	goalRepo repository.ReadingGoalRepository,
	achievementRepo repository.AchievementRepository,
	userAchievementRepo repository.UserAchievementRepository,
	progressRepo repository.BookProgressRepository,
	contextRepo repository.ReadingContextRepository,
	insightRepo repository.ReadingInsightRepository,
	bookRepo repository.BookRepository,
	logger *logger.Logger,
) AnalyticsService {
	return &analyticsService{
		BaseService:         NewBaseService(logger),
		analyticsRepo:       analyticsRepo,
		streakRepo:          streakRepo,
		goalRepo:            goalRepo,
		achievementRepo:     achievementRepo,
		userAchievementRepo: userAchievementRepo,
		progressRepo:        progressRepo,
		contextRepo:         contextRepo,
		insightRepo:         insightRepo,
		bookRepo:            bookRepo,
	}
}

// GetReadingStats retrieves reading statistics for a user
func (s *analyticsService) GetReadingStats(ctx context.Context, userID uuid.UUID, req *dto.ReadingStatsRequest) (*dto.ReadingStatsResponse, error) {
	s.logger.Info("Getting reading stats for user")

	// Parse date range based on period
	startDate, endDate, err := s.parseDateRange(req.Period, req.StartDate, req.EndDate)
	if err != nil {
		return nil, fmt.Errorf("invalid date range: %w", err)
	}

	// Get aggregated stats
	stats, err := s.analyticsRepo.GetAggregatedStats(ctx, userID, startDate, endDate)
	if err != nil {
		s.logger.Error("Failed to get aggregated stats")
		return nil, fmt.Errorf("failed to get aggregated stats: %w", err)
	}

	// Get streak information
	streak, err := s.streakRepo.GetByUserID(ctx, userID)
	if err != nil {
		s.logger.Error("Failed to get reading streak")
		return nil, fmt.Errorf("failed to get reading streak: %w", err)
	}

	// Get daily breakdown if needed
	var dailyBreakdown []dto.DailyReadingStats
	if req.Period != "all-time" {
		analyticsData, err := s.analyticsRepo.GetByUserIDDateRange(ctx, userID, startDate, endDate)
		if err != nil {
			s.logger.Error("Failed to get daily analytics")
			return nil, fmt.Errorf("failed to get daily analytics: %w", err)
		}

		for _, day := range analyticsData {
			dailyBreakdown = append(dailyBreakdown, dto.DailyReadingStats{
				Date:           day.Date.Format("2006-01-02"),
				ReadingMinutes: day.TotalReadingTimeMinutes,
				PagesRead:      day.TotalPagesRead,
				WordsRead:      day.TotalWordsRead,
				SessionsCount:  day.ReadingSessionsCount,
			})
		}
	}

	response := &dto.ReadingStatsResponse{
		Period:              req.Period,
		StartDate:           startDate.Format("2006-01-02"),
		EndDate:             endDate.Format("2006-01-02"),
		TotalReadingMinutes: stats.TotalReadingMinutes,
		TotalPagesRead:      stats.TotalPagesRead,
		TotalWordsRead:      stats.TotalWordsRead,
		BooksStarted:        stats.BooksStarted,
		BooksCompleted:      stats.BooksCompleted,
		AverageSessionTime:  stats.AverageSessionTime,
		LongestSessionTime:  stats.LongestSessionTime,
		ReadingStreak:       0,
		DailyBreakdown:      dailyBreakdown,
	}

	if streak != nil {
		response.ReadingStreak = streak.CurrentStreakDays
	}

	// TODO: Add genre and time distribution analysis

	return response, nil
}

// GetReadingStreak retrieves reading streak information
func (s *analyticsService) GetReadingStreak(ctx context.Context, userID uuid.UUID) (*dto.ReadingStreakResponse, error) {
	s.logger.Info("Getting reading streak for user")

	streak, err := s.streakRepo.GetByUserID(ctx, userID)
	if err != nil {
		s.logger.Error("Failed to get reading streak")
		return nil, fmt.Errorf("failed to get reading streak: %w", err)
	}

	if streak == nil {
		// No streak yet
		return &dto.ReadingStreakResponse{
			CurrentStreak:      0,
			LongestStreak:      0,
			TotalReadingDays:   0,
			NextMilestone:      7,
			DaysUntilMilestone: 7,
		}, nil
	}

	// Calculate next milestone
	nextMilestone, daysUntil := s.calculateNextMilestone(streak.CurrentStreakDays)

	response := &dto.ReadingStreakResponse{
		CurrentStreak:      streak.CurrentStreakDays,
		LongestStreak:      streak.LongestStreakDays,
		TotalReadingDays:   streak.TotalReadingDays,
		NextMilestone:      nextMilestone,
		DaysUntilMilestone: daysUntil,
	}

	if streak.LastReadingDate != nil {
		response.LastReadingDate = streak.LastReadingDate.Format("2006-01-02")
	}
	if streak.StreakStartDate != nil {
		response.StreakStartDate = streak.StreakStartDate.Format("2006-01-02")
	}

	return response, nil
}

// CreateGoal creates a new reading goal
func (s *analyticsService) CreateGoal(ctx context.Context, userID uuid.UUID, req *dto.CreateGoalRequest) (*dto.GoalResponse, error) {
	s.logger.Info("Creating reading goal")

	if err := s.ValidateStruct(req); err != nil {
		return nil, err
	}

	// Parse start date or use today
	startDate := time.Now()
	if req.StartDate != "" {
		parsedDate, err := time.Parse("2006-01-02", req.StartDate)
		if err != nil {
			return nil, fmt.Errorf("invalid start date format: %w", err)
		}
		startDate = parsedDate
	}

	// Calculate period end based on goal type
	endDate := s.calculateGoalEndDate(startDate, req.GoalType)

	goal := &domain.ReadingGoal{
		ID:           uuid.New(),
		UserID:       userID,
		GoalType:     req.GoalType,
		TargetValue:  req.TargetValue,
		CurrentValue: 0,
		PeriodStart:  startDate,
		PeriodEnd:    endDate,
		IsAchieved:   false,
		IsActive:     true,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	err := s.goalRepo.Create(ctx, goal)
	if err != nil {
		s.logger.Error("Failed to create goal")
		return nil, fmt.Errorf("failed to create goal: %w", err)
	}

	return s.convertGoalToResponse(goal), nil
}

// GetBookProgress retrieves progress for a specific book
func (s *analyticsService) GetBookProgress(ctx context.Context, userID uuid.UUID, bookID int64) (*dto.BookProgressResponse, error) {
	s.logger.Info("Getting book progress")

	progress, err := s.progressRepo.GetByUserIDAndBookID(ctx, userID, bookID)
	if err != nil {
		s.logger.Error("Failed to get book progress")
		return nil, fmt.Errorf("failed to get book progress: %w", err)
	}

	if progress == nil {
		return nil, fmt.Errorf("no progress found for this book")
	}

	response := &dto.BookProgressResponse{
		BookID:                 progress.BookID,
		CurrentPage:            progress.CurrentPage,
		TotalPages:             progress.TotalPages,
		ProgressPercentage:     progress.ProgressPercentage,
		StartedAt:              progress.StartedAt.Format(time.RFC3339),
		LastReadAt:             progress.LastReadAt.Format(time.RFC3339),
		IsCompleted:            progress.IsCompleted,
	}

	if progress.Book != nil {
		response.BookTitle = progress.Book.Title
	}

	if progress.EstimatedTimeRemainingMinutes != nil {
		response.EstimatedTimeRemaining = *progress.EstimatedTimeRemainingMinutes
	}

	if progress.AverageReadingSpeedWPM != nil {
		response.AverageReadingSpeed = *progress.AverageReadingSpeedWPM
	}

	if progress.CompletedAt != nil {
		completedAt := progress.CompletedAt.Format(time.RFC3339)
		response.CompletedAt = &completedAt
	}

	// TODO: Calculate total reading time from sessions

	return response, nil
}

// UpdateBookProgress updates reading progress for a book
func (s *analyticsService) UpdateBookProgress(ctx context.Context, userID uuid.UUID, req *dto.UpdateProgressRequest) error {
	s.logger.Info("Updating book progress")

	if err := s.ValidateStruct(req); err != nil {
		return err
	}

	// Check if progress exists
	progress, err := s.progressRepo.GetByUserIDAndBookID(ctx, userID, req.BookID)
	if err != nil {
		return fmt.Errorf("failed to get existing progress: %w", err)
	}

	if progress == nil {
		// Create new progress
		book, err := s.bookRepo.GetByID(ctx, req.BookID)
		if err != nil || book == nil {
			return fmt.Errorf("book not found")
		}

		// Estimate pages from word count (assuming ~250 words per page)
		estimatedPages := book.WordCount / 250
		if estimatedPages == 0 {
			estimatedPages = 100 // default fallback
		}

		progress = &domain.BookProgress{
			ID:                 uuid.New(),
			UserID:             userID,
			BookID:             req.BookID,
			CurrentPosition:    req.CurrentPosition,
			CurrentPage:        req.CurrentPage,
			TotalPages:         estimatedPages,
			ProgressPercentage: float64(req.CurrentPage) / float64(estimatedPages) * 100,
			StartedAt:          time.Now(),
			LastReadAt:         time.Now(),
			CreatedAt:          time.Now(),
			UpdatedAt:          time.Now(),
		}

		err = s.progressRepo.Create(ctx, progress)
		if err != nil {
			return fmt.Errorf("failed to create progress: %w", err)
		}
	} else {
		// Update existing progress
		err = s.progressRepo.UpdateProgress(ctx, userID, req.BookID, req.CurrentPosition, req.CurrentPage)
		if err != nil {
			return fmt.Errorf("failed to update progress: %w", err)
		}
	}

	// Update goals if applicable
	s.updateGoalProgress(ctx, userID, "daily_pages", req.CurrentPage-progress.CurrentPage)

	return nil
}

// RecordReadingContext records the context of a reading session
func (s *analyticsService) RecordReadingContext(ctx context.Context, userID uuid.UUID, req *dto.ReadingContextRequest) (*dto.ReadingContextResponse, error) {
	s.logger.Info("Recording reading context")

	if err := s.ValidateStruct(req); err != nil {
		return nil, err
	}

	readingContext := &domain.ReadingContext{
		ID:                uuid.New(),
		UserID:            userID,
		SessionID:         req.SessionID,
		Mood:              req.Mood,
		Weather:           req.Weather,
		LocationType:      req.LocationType,
		TimeOfDay:         req.TimeOfDay,
		DeviceType:        req.DeviceType,
		AmbientNoiseLevel: req.AmbientNoiseLevel,
		ReadingPosition:   req.ReadingPosition,
		Notes:             req.Notes,
		CreatedAt:         time.Now(),
	}

	err := s.contextRepo.Create(ctx, readingContext)
	if err != nil {
		s.logger.Error("Failed to record reading context")
		return nil, fmt.Errorf("failed to record reading context: %w", err)
	}

	return &dto.ReadingContextResponse{
		ID:                readingContext.ID,
		UserID:            readingContext.UserID,
		SessionID:         readingContext.SessionID,
		Mood:              readingContext.Mood,
		Weather:           readingContext.Weather,
		LocationType:      readingContext.LocationType,
		TimeOfDay:         readingContext.TimeOfDay,
		DeviceType:        readingContext.DeviceType,
		AmbientNoiseLevel: readingContext.AmbientNoiseLevel,
		ReadingPosition:   readingContext.ReadingPosition,
		Notes:             readingContext.Notes,
		CreatedAt:         readingContext.CreatedAt,
	}, nil
}

// Helper methods

func (s *analyticsService) parseDateRange(period, startDate, endDate string) (time.Time, time.Time, error) {
	now := time.Now()
	
	switch period {
	case "daily":
		return now.Truncate(24 * time.Hour), now, nil
	case "weekly":
		weekStart := now.AddDate(0, 0, -int(now.Weekday()))
		return weekStart.Truncate(24 * time.Hour), now, nil
	case "monthly":
		monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
		return monthStart, now, nil
	case "yearly":
		yearStart := time.Date(now.Year(), 1, 1, 0, 0, 0, 0, now.Location())
		return yearStart, now, nil
	case "all-time":
		// Far past date
		return time.Date(2000, 1, 1, 0, 0, 0, 0, now.Location()), now, nil
	default:
		// Custom date range
		if startDate == "" || endDate == "" {
			return time.Time{}, time.Time{}, fmt.Errorf("start_date and end_date required for custom period")
		}
		
		start, err := time.Parse("2006-01-02", startDate)
		if err != nil {
			return time.Time{}, time.Time{}, err
		}
		
		end, err := time.Parse("2006-01-02", endDate)
		if err != nil {
			return time.Time{}, time.Time{}, err
		}
		
		return start, end, nil
	}
}

func (s *analyticsService) calculateNextMilestone(currentStreak int) (int, int) {
	milestones := []int{7, 14, 30, 60, 90, 180, 365}
	
	for _, milestone := range milestones {
		if currentStreak < milestone {
			return milestone, milestone - currentStreak
		}
	}
	
	// Next milestone is next 100 days
	nextHundred := ((currentStreak / 100) + 1) * 100
	return nextHundred, nextHundred - currentStreak
}

func (s *analyticsService) calculateGoalEndDate(startDate time.Time, goalType string) time.Time {
	switch goalType {
	case "daily_minutes", "daily_pages":
		return startDate.AddDate(0, 0, 1).Add(-time.Second)
	case "weekly_books":
		return startDate.AddDate(0, 0, 7).Add(-time.Second)
	case "monthly_books":
		return startDate.AddDate(0, 1, 0).Add(-time.Second)
	case "yearly_books":
		return startDate.AddDate(1, 0, 0).Add(-time.Second)
	default:
		return startDate.AddDate(0, 0, 1).Add(-time.Second)
	}
}

func (s *analyticsService) convertGoalToResponse(goal *domain.ReadingGoal) *dto.GoalResponse {
	progress := float64(goal.CurrentValue) / float64(goal.TargetValue) * 100
	if progress > 100 {
		progress = 100
	}

	daysRemaining := int(time.Until(goal.PeriodEnd).Hours() / 24)
	if daysRemaining < 0 {
		daysRemaining = 0
	}

	response := &dto.GoalResponse{
		ID:            goal.ID,
		GoalType:      goal.GoalType,
		TargetValue:   goal.TargetValue,
		CurrentValue:  goal.CurrentValue,
		Progress:      progress,
		PeriodStart:   goal.PeriodStart.Format("2006-01-02"),
		PeriodEnd:     goal.PeriodEnd.Format("2006-01-02"),
		IsAchieved:    goal.IsAchieved,
		IsActive:      goal.IsActive,
		DaysRemaining: daysRemaining,
	}

	if goal.AchievedAt != nil {
		achievedAt := goal.AchievedAt.Format(time.RFC3339)
		response.AchievedAt = &achievedAt
	}

	// TODO: Calculate estimated completion date based on current pace

	return response
}

func (s *analyticsService) updateGoalProgress(ctx context.Context, userID uuid.UUID, goalType string, increment int) {
	// This is a background task, don't fail the main operation if it fails
	goals, err := s.goalRepo.GetActiveByUserID(ctx, userID)
	if err != nil {
		s.logger.Warn("Failed to get active goals for progress update")
		return
	}

	for _, goal := range goals {
		if goal.GoalType == goalType {
			err = s.goalRepo.UpdateProgress(ctx, goal.ID, increment)
			if err != nil {
				s.logger.Warn("Failed to update goal progress")
			}
		}
	}
}

// Stub implementations for remaining methods

func (s *analyticsService) GetGoals(ctx context.Context, userID uuid.UUID) (*dto.GoalsListResponse, error) {
	// Implementation needed
	return nil, nil
}

func (s *analyticsService) UpdateGoal(ctx context.Context, goalID uuid.UUID, req *dto.UpdateGoalRequest) (*dto.GoalResponse, error) {
	// Implementation needed
	return nil, nil
}

func (s *analyticsService) DeleteGoal(ctx context.Context, goalID uuid.UUID) error {
	// Implementation needed
	return nil
}

func (s *analyticsService) GetAchievements(ctx context.Context, userID uuid.UUID) (*dto.AchievementsListResponse, error) {
	// Implementation needed
	return nil, nil
}

func (s *analyticsService) CheckAndAwardAchievements(ctx context.Context, userID uuid.UUID) ([]*domain.UserAchievement, error) {
	// Implementation needed
	return nil, nil
}

func (s *analyticsService) GetCurrentlyReading(ctx context.Context, userID uuid.UUID) (*dto.CurrentlyReadingResponse, error) {
	// Implementation needed
	return nil, nil
}

func (s *analyticsService) MarkBookAsCompleted(ctx context.Context, userID uuid.UUID, bookID int64) error {
	// Implementation needed
	return nil
}

func (s *analyticsService) MarkBookAsAbandoned(ctx context.Context, userID uuid.UUID, bookID int64, reason string) error {
	// Implementation needed
	return nil
}

func (s *analyticsService) GetContextInsights(ctx context.Context, userID uuid.UUID) (*dto.ContextInsightsResponse, error) {
	// Implementation needed
	return nil, nil
}

func (s *analyticsService) GetReadingInsights(ctx context.Context, userID uuid.UUID) (*dto.InsightsListResponse, error) {
	// Implementation needed
	return nil, nil
}

func (s *analyticsService) MarkInsightAsRead(ctx context.Context, insightID uuid.UUID) error {
	// Implementation needed
	return nil
}

func (s *analyticsService) GenerateInsights(ctx context.Context, userID uuid.UUID) error {
	// Implementation needed
	return nil
}