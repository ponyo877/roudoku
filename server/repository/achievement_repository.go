package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/ponyo877/roudoku/server/domain"
)

// Achievement Repository implementation
type postgresAchievementRepository struct {
	db *pgxpool.Pool
}

func NewPostgresAchievementRepository(db *pgxpool.Pool) AchievementRepository {
	return &postgresAchievementRepository{db: db}
}

func (r *postgresAchievementRepository) GetAll(ctx context.Context) ([]*domain.Achievement, error) {
	query := `
		SELECT id, name, description, icon_url, category, requirement_type,
			   requirement_value, points, is_active, created_at
		FROM achievements
		WHERE is_active = true
		ORDER BY category, requirement_value ASC`

	rows, err := r.db.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var achievements []*domain.Achievement
	for rows.Next() {
		var achievement domain.Achievement
		err := rows.Scan(
			&achievement.ID, &achievement.Name, &achievement.Description,
			&achievement.IconURL, &achievement.Category, &achievement.RequirementType,
			&achievement.RequirementValue, &achievement.Points, &achievement.IsActive,
			&achievement.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		achievements = append(achievements, &achievement)
	}

	return achievements, rows.Err()
}

func (r *postgresAchievementRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.Achievement, error) {
	query := `
		SELECT id, name, description, icon_url, category, requirement_type,
			   requirement_value, points, is_active, created_at
		FROM achievements WHERE id = $1`

	var achievement domain.Achievement
	err := r.db.QueryRow(ctx, query, id).Scan(
		&achievement.ID, &achievement.Name, &achievement.Description,
		&achievement.IconURL, &achievement.Category, &achievement.RequirementType,
		&achievement.RequirementValue, &achievement.Points, &achievement.IsActive,
		&achievement.CreatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return &achievement, nil
}

func (r *postgresAchievementRepository) GetByCategory(ctx context.Context, category string) ([]*domain.Achievement, error) {
	query := `
		SELECT id, name, description, icon_url, category, requirement_type,
			   requirement_value, points, is_active, created_at
		FROM achievements
		WHERE category = $1 AND is_active = true
		ORDER BY requirement_value ASC`

	rows, err := r.db.Query(ctx, query, category)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var achievements []*domain.Achievement
	for rows.Next() {
		var achievement domain.Achievement
		err := rows.Scan(
			&achievement.ID, &achievement.Name, &achievement.Description,
			&achievement.IconURL, &achievement.Category, &achievement.RequirementType,
			&achievement.RequirementValue, &achievement.Points, &achievement.IsActive,
			&achievement.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		achievements = append(achievements, &achievement)
	}

	return achievements, rows.Err()
}

// User Achievement Repository implementation
type postgresUserAchievementRepository struct {
	db *pgxpool.Pool
}

func NewPostgresUserAchievementRepository(db *pgxpool.Pool) UserAchievementRepository {
	return &postgresUserAchievementRepository{db: db}
}

func (r *postgresUserAchievementRepository) Create(ctx context.Context, userAchievement *domain.UserAchievement) error {
	query := `
		INSERT INTO user_achievements (
			id, user_id, achievement_id, earned_at, progress, notified
		) VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (user_id, achievement_id) DO UPDATE SET
			progress = EXCLUDED.progress,
			earned_at = CASE WHEN user_achievements.progress < 100 AND EXCLUDED.progress >= 100 
						THEN EXCLUDED.earned_at 
						ELSE user_achievements.earned_at 
						END`

	_, err := r.db.Exec(ctx, query,
		userAchievement.ID, userAchievement.UserID, userAchievement.AchievementID,
		userAchievement.EarnedAt, userAchievement.Progress, userAchievement.Notified,
	)
	return err
}

func (r *postgresUserAchievementRepository) GetByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.UserAchievement, error) {
	query := `
		SELECT ua.id, ua.user_id, ua.achievement_id, ua.earned_at, ua.progress, ua.notified,
			   a.id, a.name, a.description, a.icon_url, a.category, a.requirement_type,
			   a.requirement_value, a.points, a.is_active, a.created_at
		FROM user_achievements ua
		JOIN achievements a ON ua.achievement_id = a.id
		WHERE ua.user_id = $1
		ORDER BY ua.earned_at DESC`

	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var userAchievements []*domain.UserAchievement
	for rows.Next() {
		var userAchievement domain.UserAchievement
		var achievement domain.Achievement
		err := rows.Scan(
			&userAchievement.ID, &userAchievement.UserID, &userAchievement.AchievementID,
			&userAchievement.EarnedAt, &userAchievement.Progress, &userAchievement.Notified,
			&achievement.ID, &achievement.Name, &achievement.Description,
			&achievement.IconURL, &achievement.Category, &achievement.RequirementType,
			&achievement.RequirementValue, &achievement.Points, &achievement.IsActive,
			&achievement.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		userAchievement.Achievement = &achievement
		userAchievements = append(userAchievements, &userAchievement)
	}

	return userAchievements, rows.Err()
}

func (r *postgresUserAchievementRepository) GetByUserIDAndAchievementID(ctx context.Context, userID, achievementID uuid.UUID) (*domain.UserAchievement, error) {
	query := `
		SELECT ua.id, ua.user_id, ua.achievement_id, ua.earned_at, ua.progress, ua.notified,
			   a.id, a.name, a.description, a.icon_url, a.category, a.requirement_type,
			   a.requirement_value, a.points, a.is_active, a.created_at
		FROM user_achievements ua
		JOIN achievements a ON ua.achievement_id = a.id
		WHERE ua.user_id = $1 AND ua.achievement_id = $2`

	var userAchievement domain.UserAchievement
	var achievement domain.Achievement
	err := r.db.QueryRow(ctx, query, userID, achievementID).Scan(
		&userAchievement.ID, &userAchievement.UserID, &userAchievement.AchievementID,
		&userAchievement.EarnedAt, &userAchievement.Progress, &userAchievement.Notified,
		&achievement.ID, &achievement.Name, &achievement.Description,
		&achievement.IconURL, &achievement.Category, &achievement.RequirementType,
		&achievement.RequirementValue, &achievement.Points, &achievement.IsActive,
		&achievement.CreatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	userAchievement.Achievement = &achievement
	return &userAchievement, nil
}

func (r *postgresUserAchievementRepository) Update(ctx context.Context, userAchievement *domain.UserAchievement) error {
	query := `
		UPDATE user_achievements SET
			progress = $3, notified = $4
		WHERE user_id = $1 AND achievement_id = $2`

	_, err := r.db.Exec(ctx, query,
		userAchievement.UserID, userAchievement.AchievementID,
		userAchievement.Progress, userAchievement.Notified,
	)
	return err
}

func (r *postgresUserAchievementRepository) GetUnnotified(ctx context.Context, userID uuid.UUID) ([]*domain.UserAchievement, error) {
	query := `
		SELECT ua.id, ua.user_id, ua.achievement_id, ua.earned_at, ua.progress, ua.notified,
			   a.id, a.name, a.description, a.icon_url, a.category, a.requirement_type,
			   a.requirement_value, a.points, a.is_active, a.created_at
		FROM user_achievements ua
		JOIN achievements a ON ua.achievement_id = a.id
		WHERE ua.user_id = $1 AND ua.notified = false AND ua.progress >= 100
		ORDER BY ua.earned_at ASC`

	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var userAchievements []*domain.UserAchievement
	for rows.Next() {
		var userAchievement domain.UserAchievement
		var achievement domain.Achievement
		err := rows.Scan(
			&userAchievement.ID, &userAchievement.UserID, &userAchievement.AchievementID,
			&userAchievement.EarnedAt, &userAchievement.Progress, &userAchievement.Notified,
			&achievement.ID, &achievement.Name, &achievement.Description,
			&achievement.IconURL, &achievement.Category, &achievement.RequirementType,
			&achievement.RequirementValue, &achievement.Points, &achievement.IsActive,
			&achievement.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		userAchievement.Achievement = &achievement
		userAchievements = append(userAchievements, &userAchievement)
	}

	return userAchievements, rows.Err()
}

func (r *postgresUserAchievementRepository) MarkAsNotified(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE user_achievements SET notified = true WHERE id = $1`
	_, err := r.db.Exec(ctx, query, id)
	return err
}