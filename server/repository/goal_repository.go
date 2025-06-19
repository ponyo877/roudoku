package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/ponyo877/roudoku/server/domain"
)

// ReadingGoalRepository implementation
type postgresReadingGoalRepository struct {
	db *pgxpool.Pool
}

func NewPostgresReadingGoalRepository(db *pgxpool.Pool) ReadingGoalRepository {
	return &postgresReadingGoalRepository{db: db}
}

func (r *postgresReadingGoalRepository) Create(ctx context.Context, goal *domain.ReadingGoal) error {
	query := `
		INSERT INTO reading_goals (
			id, user_id, goal_type, target_value, current_value,
			period_start, period_end, is_achieved, achieved_at,
			is_active, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`

	_, err := r.db.Exec(ctx, query,
		goal.ID, goal.UserID, goal.GoalType, goal.TargetValue,
		goal.CurrentValue, goal.PeriodStart, goal.PeriodEnd,
		goal.IsAchieved, goal.AchievedAt, goal.IsActive,
		goal.CreatedAt, goal.UpdatedAt,
	)
	return err
}

func (r *postgresReadingGoalRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.ReadingGoal, error) {
	query := `
		SELECT id, user_id, goal_type, target_value, current_value,
			   period_start, period_end, is_achieved, achieved_at,
			   is_active, created_at, updated_at
		FROM reading_goals WHERE id = $1`

	var goal domain.ReadingGoal
	err := r.db.QueryRow(ctx, query, id).Scan(
		&goal.ID, &goal.UserID, &goal.GoalType, &goal.TargetValue,
		&goal.CurrentValue, &goal.PeriodStart, &goal.PeriodEnd,
		&goal.IsAchieved, &goal.AchievedAt, &goal.IsActive,
		&goal.CreatedAt, &goal.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return &goal, nil
}

func (r *postgresReadingGoalRepository) GetByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.ReadingGoal, error) {
	query := `
		SELECT id, user_id, goal_type, target_value, current_value,
			   period_start, period_end, is_achieved, achieved_at,
			   is_active, created_at, updated_at
		FROM reading_goals 
		WHERE user_id = $1
		ORDER BY created_at DESC`

	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var goals []*domain.ReadingGoal
	for rows.Next() {
		var goal domain.ReadingGoal
		err := rows.Scan(
			&goal.ID, &goal.UserID, &goal.GoalType, &goal.TargetValue,
			&goal.CurrentValue, &goal.PeriodStart, &goal.PeriodEnd,
			&goal.IsAchieved, &goal.AchievedAt, &goal.IsActive,
			&goal.CreatedAt, &goal.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		goals = append(goals, &goal)
	}

	return goals, rows.Err()
}

func (r *postgresReadingGoalRepository) GetActiveByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.ReadingGoal, error) {
	query := `
		SELECT id, user_id, goal_type, target_value, current_value,
			   period_start, period_end, is_achieved, achieved_at,
			   is_active, created_at, updated_at
		FROM reading_goals 
		WHERE user_id = $1 AND is_active = true
		ORDER BY created_at DESC`

	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var goals []*domain.ReadingGoal
	for rows.Next() {
		var goal domain.ReadingGoal
		err := rows.Scan(
			&goal.ID, &goal.UserID, &goal.GoalType, &goal.TargetValue,
			&goal.CurrentValue, &goal.PeriodStart, &goal.PeriodEnd,
			&goal.IsAchieved, &goal.AchievedAt, &goal.IsActive,
			&goal.CreatedAt, &goal.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		goals = append(goals, &goal)
	}

	return goals, rows.Err()
}

func (r *postgresReadingGoalRepository) Update(ctx context.Context, goal *domain.ReadingGoal) error {
	query := `
		UPDATE reading_goals SET
			target_value = $2, current_value = $3, is_achieved = $4,
			achieved_at = $5, is_active = $6, updated_at = $7
		WHERE id = $1`

	_, err := r.db.Exec(ctx, query,
		goal.ID, goal.TargetValue, goal.CurrentValue,
		goal.IsAchieved, goal.AchievedAt, goal.IsActive, goal.UpdatedAt,
	)
	return err
}

func (r *postgresReadingGoalRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM reading_goals WHERE id = $1`
	_, err := r.db.Exec(ctx, query, id)
	return err
}

func (r *postgresReadingGoalRepository) UpdateProgress(ctx context.Context, goalID uuid.UUID, incrementValue int) error {
	query := `
		UPDATE reading_goals SET
			current_value = current_value + $2,
			updated_at = NOW()
		WHERE id = $1`

	_, err := r.db.Exec(ctx, query, goalID, incrementValue)
	return err
}