package repository

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/ponyo877/roudoku/server/domain"
	ent "github.com/ponyo877/roudoku/server/entities"
	"github.com/ponyo877/roudoku/server/mappers"
)

// postgresSwipeRepository implements SwipeRepository using PostgreSQL
type postgresSwipeRepository struct {
	db     *pgxpool.Pool
	mapper *mappers.SwipeMapper
}

// NewPostgresSwipeRepository creates a new PostgreSQL swipe repository
func NewPostgresSwipeRepository(db *pgxpool.Pool) SwipeRepository {
	return &postgresSwipeRepository{
		db:     db,
		mapper: mappers.NewSwipeMapper(),
	}
}

// Create creates a new swipe log
func (r *postgresSwipeRepository) Create(ctx context.Context, swipeLog *domain.SwipeLog) error {
	entity := r.mapper.DomainToEntity(swipeLog)
	query := `
		INSERT INTO swipe_logs (id, user_id, quote_id, mode, choice, created_at)
		VALUES ($1, $2, $3, $4, $5, $6)`

	_, err := r.db.Exec(ctx, query,
		entity.ID, entity.UserID, entity.QuoteID,
		entity.Mode, entity.Choice, entity.CreatedAt)

	if err != nil {
		return fmt.Errorf("failed to create swipe log: %w", err)
	}

	return nil
}

// GetByUserID retrieves swipe logs by user ID
func (r *postgresSwipeRepository) GetByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.SwipeLog, error) {
	query := `
		SELECT id, user_id, quote_id, mode, choice, created_at
		FROM swipe_logs 
		WHERE user_id = $1
		ORDER BY created_at DESC`

	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get swipe logs by user ID: %w", err)
	}
	defer rows.Close()

	var entities []*ent.SwipeLogEntity
	for rows.Next() {
		entity := new(ent.SwipeLogEntity)

		err := rows.Scan(
			&entity.ID, &entity.UserID, &entity.QuoteID,
			&entity.Mode, &entity.Choice, &entity.CreatedAt)

		if err != nil {
			return nil, fmt.Errorf("failed to scan swipe log row: %w", err)
		}

		entities = append(entities, entity)
	}

	swipeLogs := r.mapper.EntityToDomainSlice(entities)
	return swipeLogs, nil
}

// GetByQuoteID retrieves swipe logs by quote ID
func (r *postgresSwipeRepository) GetByQuoteID(ctx context.Context, quoteID uuid.UUID) ([]*domain.SwipeLog, error) {
	query := `
		SELECT id, user_id, quote_id, mode, choice, created_at
		FROM swipe_logs 
		WHERE quote_id = $1
		ORDER BY created_at DESC`

	rows, err := r.db.Query(ctx, query, quoteID)
	if err != nil {
		return nil, fmt.Errorf("failed to get swipe logs by quote ID: %w", err)
	}
	defer rows.Close()

	var entities []*ent.SwipeLogEntity
	for rows.Next() {
		entity := new(ent.SwipeLogEntity)

		err := rows.Scan(
			&entity.ID, &entity.UserID, &entity.QuoteID,
			&entity.Mode, &entity.Choice, &entity.CreatedAt)

		if err != nil {
			return nil, fmt.Errorf("failed to scan swipe log row: %w", err)
		}

		entities = append(entities, entity)
	}

	swipeLogs := r.mapper.EntityToDomainSlice(entities)
	return swipeLogs, nil
}