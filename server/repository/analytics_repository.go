package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/ponyo877/roudoku/server/domain"
)

// Analytics Repository Interfaces

type ReadingAnalyticsRepository interface {
	Create(ctx context.Context, analytics *domain.ReadingAnalytics) error
	GetByUserIDAndDate(ctx context.Context, userID uuid.UUID, date time.Time) (*domain.ReadingAnalytics, error)
	GetByUserIDDateRange(ctx context.Context, userID uuid.UUID, startDate, endDate time.Time) ([]*domain.ReadingAnalytics, error)
	Update(ctx context.Context, analytics *domain.ReadingAnalytics) error
	GetAggregatedStats(ctx context.Context, userID uuid.UUID, startDate, endDate time.Time) (*AggregatedStats, error)
}

type ReadingStreakRepository interface {
	Create(ctx context.Context, streak *domain.ReadingStreak) error
	GetByUserID(ctx context.Context, userID uuid.UUID) (*domain.ReadingStreak, error)
	Update(ctx context.Context, streak *domain.ReadingStreak) error
	UpdateStreak(ctx context.Context, userID uuid.UUID, readingDate time.Time) error
}

type ReadingGoalRepository interface {
	Create(ctx context.Context, goal *domain.ReadingGoal) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.ReadingGoal, error)
	GetByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.ReadingGoal, error)
	GetActiveByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.ReadingGoal, error)
	Update(ctx context.Context, goal *domain.ReadingGoal) error
	Delete(ctx context.Context, id uuid.UUID) error
	UpdateProgress(ctx context.Context, goalID uuid.UUID, incrementValue int) error
}

type AchievementRepository interface {
	GetAll(ctx context.Context) ([]*domain.Achievement, error)
	GetByID(ctx context.Context, id uuid.UUID) (*domain.Achievement, error)
	GetByCategory(ctx context.Context, category string) ([]*domain.Achievement, error)
}

type UserAchievementRepository interface {
	Create(ctx context.Context, userAchievement *domain.UserAchievement) error
	GetByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.UserAchievement, error)
	GetByUserIDAndAchievementID(ctx context.Context, userID, achievementID uuid.UUID) (*domain.UserAchievement, error)
	Update(ctx context.Context, userAchievement *domain.UserAchievement) error
	GetUnnotified(ctx context.Context, userID uuid.UUID) ([]*domain.UserAchievement, error)
	MarkAsNotified(ctx context.Context, id uuid.UUID) error
}

type ReadingContextRepository interface {
	Create(ctx context.Context, context *domain.ReadingContext) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.ReadingContext, error)
	GetByUserID(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.ReadingContext, error)
	GetBySessionID(ctx context.Context, sessionID uuid.UUID) (*domain.ReadingContext, error)
	Update(ctx context.Context, context *domain.ReadingContext) error
	Delete(ctx context.Context, id uuid.UUID) error
	GetMostProductiveConditions(ctx context.Context, userID uuid.UUID) (*ProductiveConditions, error)
}

type BookProgressRepository interface {
	Create(ctx context.Context, progress *domain.BookProgress) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.BookProgress, error)
	GetByUserIDAndBookID(ctx context.Context, userID uuid.UUID, bookID int64) (*domain.BookProgress, error)
	GetActiveByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.BookProgress, error)
	GetCompletedByUserID(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.BookProgress, error)
	Update(ctx context.Context, progress *domain.BookProgress) error
	UpdateProgress(ctx context.Context, userID uuid.UUID, bookID int64, position, page int) error
	MarkAsCompleted(ctx context.Context, userID uuid.UUID, bookID int64) error
	MarkAsAbandoned(ctx context.Context, userID uuid.UUID, bookID int64, reason string) error
}

type ReadingInsightRepository interface {
	Create(ctx context.Context, insight *domain.ReadingInsight) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.ReadingInsight, error)
	GetByUserID(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.ReadingInsight, error)
	GetUnreadByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.ReadingInsight, error)
	Update(ctx context.Context, insight *domain.ReadingInsight) error
	MarkAsRead(ctx context.Context, id uuid.UUID) error
	Delete(ctx context.Context, id uuid.UUID) error
	DeleteExpired(ctx context.Context) error
}

// Helper types

type AggregatedStats struct {
	TotalReadingMinutes int
	TotalPagesRead      int
	TotalWordsRead      int
	BooksStarted        int
	BooksCompleted      int
	AverageSessionTime  int
	LongestSessionTime  int
}

type ProductiveConditions struct {
	MostProductiveMood     *string
	MostProductiveTime     *string
	MostProductiveLocation *string
	AverageWordsPerMood    map[string]int
	AverageWordsPerTime    map[string]int
}

// PostgreSQL implementations

type postgresReadingAnalyticsRepository struct {
	db *pgxpool.Pool
}

func NewPostgresReadingAnalyticsRepository(db *pgxpool.Pool) ReadingAnalyticsRepository {
	return &postgresReadingAnalyticsRepository{db: db}
}

func (r *postgresReadingAnalyticsRepository) Create(ctx context.Context, analytics *domain.ReadingAnalytics) error {
	query := `
		INSERT INTO reading_analytics (
			id, user_id, date, total_reading_time_minutes, total_pages_read,
			total_words_read, books_started, books_completed, reading_sessions_count,
			longest_session_minutes, average_session_minutes, favorite_genre,
			favorite_time_of_day, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)`

	_, err := r.db.Exec(ctx, query,
		analytics.ID, analytics.UserID, analytics.Date,
		analytics.TotalReadingTimeMinutes, analytics.TotalPagesRead,
		analytics.TotalWordsRead, analytics.BooksStarted, analytics.BooksCompleted,
		analytics.ReadingSessionsCount, analytics.LongestSessionMinutes,
		analytics.AverageSessionMinutes, analytics.FavoriteGenre,
		analytics.FavoriteTimeOfDay, analytics.CreatedAt, analytics.UpdatedAt,
	)
	return err
}

func (r *postgresReadingAnalyticsRepository) GetByUserIDAndDate(ctx context.Context, userID uuid.UUID, date time.Time) (*domain.ReadingAnalytics, error) {
	query := `
		SELECT id, user_id, date, total_reading_time_minutes, total_pages_read,
			   total_words_read, books_started, books_completed, reading_sessions_count,
			   longest_session_minutes, average_session_minutes, favorite_genre,
			   favorite_time_of_day, created_at, updated_at
		FROM reading_analytics
		WHERE user_id = $1 AND date = $2`

	var analytics domain.ReadingAnalytics
	err := r.db.QueryRow(ctx, query, userID, date.Format("2006-01-02")).Scan(
		&analytics.ID, &analytics.UserID, &analytics.Date,
		&analytics.TotalReadingTimeMinutes, &analytics.TotalPagesRead,
		&analytics.TotalWordsRead, &analytics.BooksStarted, &analytics.BooksCompleted,
		&analytics.ReadingSessionsCount, &analytics.LongestSessionMinutes,
		&analytics.AverageSessionMinutes, &analytics.FavoriteGenre,
		&analytics.FavoriteTimeOfDay, &analytics.CreatedAt, &analytics.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return &analytics, nil
}

func (r *postgresReadingAnalyticsRepository) GetByUserIDDateRange(ctx context.Context, userID uuid.UUID, startDate, endDate time.Time) ([]*domain.ReadingAnalytics, error) {
	query := `
		SELECT id, user_id, date, total_reading_time_minutes, total_pages_read,
			   total_words_read, books_started, books_completed, reading_sessions_count,
			   longest_session_minutes, average_session_minutes, favorite_genre,
			   favorite_time_of_day, created_at, updated_at
		FROM reading_analytics
		WHERE user_id = $1 AND date >= $2 AND date <= $3
		ORDER BY date ASC`

	rows, err := r.db.Query(ctx, query, userID, startDate, endDate)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var analytics []*domain.ReadingAnalytics
	for rows.Next() {
		var a domain.ReadingAnalytics
		err := rows.Scan(
			&a.ID, &a.UserID, &a.Date,
			&a.TotalReadingTimeMinutes, &a.TotalPagesRead,
			&a.TotalWordsRead, &a.BooksStarted, &a.BooksCompleted,
			&a.ReadingSessionsCount, &a.LongestSessionMinutes,
			&a.AverageSessionMinutes, &a.FavoriteGenre,
			&a.FavoriteTimeOfDay, &a.CreatedAt, &a.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		analytics = append(analytics, &a)
	}

	return analytics, rows.Err()
}

func (r *postgresReadingAnalyticsRepository) Update(ctx context.Context, analytics *domain.ReadingAnalytics) error {
	query := `
		UPDATE reading_analytics SET
			total_reading_time_minutes = $3, total_pages_read = $4,
			total_words_read = $5, books_started = $6, books_completed = $7,
			reading_sessions_count = $8, longest_session_minutes = $9,
			average_session_minutes = $10, favorite_genre = $11,
			favorite_time_of_day = $12, updated_at = $13
		WHERE id = $1 AND user_id = $2`

	_, err := r.db.Exec(ctx, query,
		analytics.ID, analytics.UserID,
		analytics.TotalReadingTimeMinutes, analytics.TotalPagesRead,
		analytics.TotalWordsRead, analytics.BooksStarted, analytics.BooksCompleted,
		analytics.ReadingSessionsCount, analytics.LongestSessionMinutes,
		analytics.AverageSessionMinutes, analytics.FavoriteGenre,
		analytics.FavoriteTimeOfDay, analytics.UpdatedAt,
	)
	return err
}

func (r *postgresReadingAnalyticsRepository) GetAggregatedStats(ctx context.Context, userID uuid.UUID, startDate, endDate time.Time) (*AggregatedStats, error) {
	query := `
		SELECT 
			COALESCE(SUM(total_reading_time_minutes), 0) as total_reading_minutes,
			COALESCE(SUM(total_pages_read), 0) as total_pages,
			COALESCE(SUM(total_words_read), 0) as total_words,
			COALESCE(SUM(books_started), 0) as books_started,
			COALESCE(SUM(books_completed), 0) as books_completed,
			COALESCE(AVG(average_session_minutes), 0) as avg_session,
			COALESCE(MAX(longest_session_minutes), 0) as longest_session
		FROM reading_analytics
		WHERE user_id = $1 AND date >= $2 AND date <= $3`

	var stats AggregatedStats
	err := r.db.QueryRow(ctx, query, userID, startDate, endDate).Scan(
		&stats.TotalReadingMinutes,
		&stats.TotalPagesRead,
		&stats.TotalWordsRead,
		&stats.BooksStarted,
		&stats.BooksCompleted,
		&stats.AverageSessionTime,
		&stats.LongestSessionTime,
	)

	if err != nil {
		return nil, err
	}

	return &stats, nil
}

// Reading Streak Repository

type postgresReadingStreakRepository struct {
	db *pgxpool.Pool
}

func NewPostgresReadingStreakRepository(db *pgxpool.Pool) ReadingStreakRepository {
	return &postgresReadingStreakRepository{db: db}
}

func (r *postgresReadingStreakRepository) Create(ctx context.Context, streak *domain.ReadingStreak) error {
	query := `
		INSERT INTO reading_streaks (
			id, user_id, current_streak_days, longest_streak_days,
			last_reading_date, streak_start_date, total_reading_days,
			created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`

	_, err := r.db.Exec(ctx, query,
		streak.ID, streak.UserID, streak.CurrentStreakDays,
		streak.LongestStreakDays, streak.LastReadingDate,
		streak.StreakStartDate, streak.TotalReadingDays,
		streak.CreatedAt, streak.UpdatedAt,
	)
	return err
}

func (r *postgresReadingStreakRepository) GetByUserID(ctx context.Context, userID uuid.UUID) (*domain.ReadingStreak, error) {
	query := `
		SELECT id, user_id, current_streak_days, longest_streak_days,
			   last_reading_date, streak_start_date, total_reading_days,
			   created_at, updated_at
		FROM reading_streaks
		WHERE user_id = $1`

	var streak domain.ReadingStreak
	err := r.db.QueryRow(ctx, query, userID).Scan(
		&streak.ID, &streak.UserID, &streak.CurrentStreakDays,
		&streak.LongestStreakDays, &streak.LastReadingDate,
		&streak.StreakStartDate, &streak.TotalReadingDays,
		&streak.CreatedAt, &streak.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return &streak, nil
}

func (r *postgresReadingStreakRepository) Update(ctx context.Context, streak *domain.ReadingStreak) error {
	query := `
		UPDATE reading_streaks SET
			current_streak_days = $2, longest_streak_days = $3,
			last_reading_date = $4, streak_start_date = $5,
			total_reading_days = $6, updated_at = $7
		WHERE user_id = $1`

	_, err := r.db.Exec(ctx, query,
		streak.UserID, streak.CurrentStreakDays,
		streak.LongestStreakDays, streak.LastReadingDate,
		streak.StreakStartDate, streak.TotalReadingDays,
		streak.UpdatedAt,
	)
	return err
}

func (r *postgresReadingStreakRepository) UpdateStreak(ctx context.Context, userID uuid.UUID, readingDate time.Time) error {
	// This will be handled by the database trigger, but we can call it explicitly if needed
	query := `SELECT update_reading_streak($1, $2)`
	_, err := r.db.Exec(ctx, query, userID, readingDate)
	return err
}

// Book Progress Repository

type postgresBookProgressRepository struct {
	db *pgxpool.Pool
}

func NewPostgresBookProgressRepository(db *pgxpool.Pool) BookProgressRepository {
	return &postgresBookProgressRepository{db: db}
}

func (r *postgresBookProgressRepository) Create(ctx context.Context, progress *domain.BookProgress) error {
	query := `
		INSERT INTO book_progress (
			id, user_id, book_id, current_chapter_id, current_position,
			current_page, total_pages, progress_percentage, estimated_time_remaining_minutes,
			average_reading_speed_wpm, started_at, last_read_at, is_completed,
			is_abandoned, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)`

	_, err := r.db.Exec(ctx, query,
		progress.ID, progress.UserID, progress.BookID, progress.CurrentChapterID,
		progress.CurrentPosition, progress.CurrentPage, progress.TotalPages,
		progress.ProgressPercentage, progress.EstimatedTimeRemainingMinutes,
		progress.AverageReadingSpeedWPM, progress.StartedAt, progress.LastReadAt,
		progress.IsCompleted, progress.IsAbandoned, progress.CreatedAt, progress.UpdatedAt,
	)
	return err
}

func (r *postgresBookProgressRepository) GetByUserIDAndBookID(ctx context.Context, userID uuid.UUID, bookID int64) (*domain.BookProgress, error) {
	query := `
		SELECT bp.id, bp.user_id, bp.book_id, bp.current_chapter_id, bp.current_position,
			   bp.current_page, bp.total_pages, bp.progress_percentage, 
			   bp.estimated_time_remaining_minutes, bp.average_reading_speed_wpm,
			   bp.started_at, bp.last_read_at, bp.completed_at, bp.is_completed,
			   bp.is_abandoned, bp.abandoned_reason, bp.created_at, bp.updated_at,
			   b.id, b.title, b.author, b.genre
		FROM book_progress bp
		LEFT JOIN books b ON bp.book_id = b.id
		WHERE bp.user_id = $1 AND bp.book_id = $2`

	var progress domain.BookProgress
	var book domain.Book
	err := r.db.QueryRow(ctx, query, userID, bookID).Scan(
		&progress.ID, &progress.UserID, &progress.BookID, &progress.CurrentChapterID,
		&progress.CurrentPosition, &progress.CurrentPage, &progress.TotalPages,
		&progress.ProgressPercentage, &progress.EstimatedTimeRemainingMinutes,
		&progress.AverageReadingSpeedWPM, &progress.StartedAt, &progress.LastReadAt,
		&progress.CompletedAt, &progress.IsCompleted, &progress.IsAbandoned,
		&progress.AbandonedReason, &progress.CreatedAt, &progress.UpdatedAt,
		&book.ID, &book.Title, &book.Author, &book.Genre,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	progress.Book = &book
	return &progress, nil
}

func (r *postgresBookProgressRepository) GetActiveByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.BookProgress, error) {
	query := `
		SELECT bp.id, bp.user_id, bp.book_id, bp.current_chapter_id, bp.current_position,
			   bp.current_page, bp.total_pages, bp.progress_percentage, 
			   bp.estimated_time_remaining_minutes, bp.average_reading_speed_wpm,
			   bp.started_at, bp.last_read_at, bp.is_completed,
			   bp.is_abandoned, bp.created_at, bp.updated_at,
			   b.id, b.title, b.author, b.genre
		FROM book_progress bp
		LEFT JOIN books b ON bp.book_id = b.id
		WHERE bp.user_id = $1 AND bp.is_completed = false AND bp.is_abandoned = false
		ORDER BY bp.last_read_at DESC`

	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var progressList []*domain.BookProgress
	for rows.Next() {
		var progress domain.BookProgress
		var book domain.Book
		err := rows.Scan(
			&progress.ID, &progress.UserID, &progress.BookID, &progress.CurrentChapterID,
			&progress.CurrentPosition, &progress.CurrentPage, &progress.TotalPages,
			&progress.ProgressPercentage, &progress.EstimatedTimeRemainingMinutes,
			&progress.AverageReadingSpeedWPM, &progress.StartedAt, &progress.LastReadAt,
			&progress.IsCompleted, &progress.IsAbandoned, &progress.CreatedAt, &progress.UpdatedAt,
			&book.ID, &book.Title, &book.Author, &book.Genre,
		)
		if err != nil {
			return nil, err
		}
		progress.Book = &book
		progressList = append(progressList, &progress)
	}

	return progressList, rows.Err()
}

func (r *postgresBookProgressRepository) UpdateProgress(ctx context.Context, userID uuid.UUID, bookID int64, position, page int) error {
	query := `
		UPDATE book_progress SET
			current_position = $3,
			current_page = $4,
			progress_percentage = ($4::float / total_pages * 100),
			last_read_at = NOW(),
			updated_at = NOW()
		WHERE user_id = $1 AND book_id = $2`

	_, err := r.db.Exec(ctx, query, userID, bookID, position, page)
	return err
}

func (r *postgresBookProgressRepository) MarkAsCompleted(ctx context.Context, userID uuid.UUID, bookID int64) error {
	query := `
		UPDATE book_progress SET
			is_completed = true,
			completed_at = NOW(),
			progress_percentage = 100,
			updated_at = NOW()
		WHERE user_id = $1 AND book_id = $2`

	_, err := r.db.Exec(ctx, query, userID, bookID)
	return err
}

// Reading Context Repository

type postgresReadingContextRepository struct {
	db *pgxpool.Pool
}

func NewPostgresReadingContextRepository(db *pgxpool.Pool) ReadingContextRepository {
	return &postgresReadingContextRepository{db: db}
}

func (r *postgresReadingContextRepository) Create(ctx context.Context, context *domain.ReadingContext) error {
	query := `
		INSERT INTO reading_contexts (
			id, user_id, session_id, mood, weather, location_type,
			time_of_day, device_type, ambient_noise_level, reading_position,
			notes, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`

	_, err := r.db.Exec(ctx, query,
		context.ID, context.UserID, context.SessionID, context.Mood,
		context.Weather, context.LocationType, context.TimeOfDay,
		context.DeviceType, context.AmbientNoiseLevel, context.ReadingPosition,
		context.Notes, context.CreatedAt,
	)
	return err
}

func (r *postgresReadingContextRepository) GetByUserID(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.ReadingContext, error) {
	query := `
		SELECT id, user_id, session_id, mood, weather, location_type,
			   time_of_day, device_type, ambient_noise_level, reading_position,
			   notes, created_at
		FROM reading_contexts
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3`

	rows, err := r.db.Query(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var contexts []*domain.ReadingContext
	for rows.Next() {
		var c domain.ReadingContext
		err := rows.Scan(
			&c.ID, &c.UserID, &c.SessionID, &c.Mood, &c.Weather,
			&c.LocationType, &c.TimeOfDay, &c.DeviceType,
			&c.AmbientNoiseLevel, &c.ReadingPosition, &c.Notes, &c.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		contexts = append(contexts, &c)
	}

	return contexts, rows.Err()
}

// Reading Insight Repository

type postgresReadingInsightRepository struct {
	db *pgxpool.Pool
}

func NewPostgresReadingInsightRepository(db *pgxpool.Pool) ReadingInsightRepository {
	return &postgresReadingInsightRepository{db: db}
}

func (r *postgresReadingInsightRepository) Create(ctx context.Context, insight *domain.ReadingInsight) error {
	dataJSON, err := json.Marshal(insight.Data)
	if err != nil {
		return fmt.Errorf("failed to marshal insight data: %w", err)
	}

	query := `
		INSERT INTO reading_insights (
			id, user_id, insight_type, title, description, data,
			relevance_score, is_read, expires_at, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`

	_, err = r.db.Exec(ctx, query,
		insight.ID, insight.UserID, insight.InsightType, insight.Title,
		insight.Description, dataJSON, insight.RelevanceScore,
		insight.IsRead, insight.ExpiresAt, insight.CreatedAt,
	)
	return err
}

func (r *postgresReadingInsightRepository) GetUnreadByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.ReadingInsight, error) {
	query := `
		SELECT id, user_id, insight_type, title, description, data,
			   relevance_score, is_read, read_at, expires_at, created_at
		FROM reading_insights
		WHERE user_id = $1 AND is_read = false 
		AND (expires_at IS NULL OR expires_at > NOW())
		ORDER BY relevance_score DESC, created_at DESC`

	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var insights []*domain.ReadingInsight
	for rows.Next() {
		var insight domain.ReadingInsight
		var dataJSON []byte
		err := rows.Scan(
			&insight.ID, &insight.UserID, &insight.InsightType,
			&insight.Title, &insight.Description, &dataJSON,
			&insight.RelevanceScore, &insight.IsRead, &insight.ReadAt,
			&insight.ExpiresAt, &insight.CreatedAt,
		)
		if err != nil {
			return nil, err
		}

		if len(dataJSON) > 0 {
			err = json.Unmarshal(dataJSON, &insight.Data)
			if err != nil {
				return nil, fmt.Errorf("failed to unmarshal insight data: %w", err)
			}
		}

		insights = append(insights, &insight)
	}

	return insights, rows.Err()
}

func (r *postgresReadingInsightRepository) MarkAsRead(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE reading_insights SET is_read = true, read_at = NOW() WHERE id = $1`
	_, err := r.db.Exec(ctx, query, id)
	return err
}

// Stub implementations for remaining methods
func (r *postgresBookProgressRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.BookProgress, error) {
	// Implementation needed
	return nil, nil
}

func (r *postgresBookProgressRepository) GetCompletedByUserID(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.BookProgress, error) {
	// Implementation needed
	return nil, nil
}

func (r *postgresBookProgressRepository) Update(ctx context.Context, progress *domain.BookProgress) error {
	// Implementation needed
	return nil
}

func (r *postgresBookProgressRepository) MarkAsAbandoned(ctx context.Context, userID uuid.UUID, bookID int64, reason string) error {
	// Implementation needed
	return nil
}

func (r *postgresReadingContextRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.ReadingContext, error) {
	// Implementation needed
	return nil, nil
}

func (r *postgresReadingContextRepository) GetBySessionID(ctx context.Context, sessionID uuid.UUID) (*domain.ReadingContext, error) {
	// Implementation needed
	return nil, nil
}

func (r *postgresReadingContextRepository) Update(ctx context.Context, context *domain.ReadingContext) error {
	// Implementation needed
	return nil
}

func (r *postgresReadingContextRepository) Delete(ctx context.Context, id uuid.UUID) error {
	// Implementation needed
	return nil
}

func (r *postgresReadingContextRepository) GetMostProductiveConditions(ctx context.Context, userID uuid.UUID) (*ProductiveConditions, error) {
	// Implementation needed
	return nil, nil
}

func (r *postgresReadingInsightRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.ReadingInsight, error) {
	// Implementation needed
	return nil, nil
}

func (r *postgresReadingInsightRepository) GetByUserID(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.ReadingInsight, error) {
	// Implementation needed
	return nil, nil
}

func (r *postgresReadingInsightRepository) Update(ctx context.Context, insight *domain.ReadingInsight) error {
	// Implementation needed
	return nil
}

func (r *postgresReadingInsightRepository) Delete(ctx context.Context, id uuid.UUID) error {
	// Implementation needed
	return nil
}

func (r *postgresReadingInsightRepository) DeleteExpired(ctx context.Context) error {
	// Implementation needed
	return nil
}