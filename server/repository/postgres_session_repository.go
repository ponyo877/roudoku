package repository

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/ponyo877/roudoku/server/models"
)

// postgresSessionRepository implements SessionRepository using PostgreSQL
type postgresSessionRepository struct {
	db *pgxpool.Pool
}

// NewPostgresSessionRepository creates a new PostgreSQL session repository
func NewPostgresSessionRepository(db *pgxpool.Pool) SessionRepository {
	return &postgresSessionRepository{db: db}
}

// Create creates a new reading session
func (r *postgresSessionRepository) Create(ctx context.Context, session *models.ReadingSession) error {
	query := `
		INSERT INTO reading_sessions (id, user_id, book_id, start_pos, current_pos, duration_sec, mood, weather, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`

	_, err := r.db.Exec(ctx, query,
		session.ID, session.UserID, session.BookID, session.StartPos,
		session.CurrentPos, session.DurationSec, session.Mood, session.Weather,
		session.CreatedAt, session.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to create reading session: %w", err)
	}

	return nil
}

// GetByID retrieves a reading session by ID
func (r *postgresSessionRepository) GetByID(ctx context.Context, id uuid.UUID) (*models.ReadingSession, error) {
	var session models.ReadingSession

	query := `
		SELECT id, user_id, book_id, start_pos, current_pos, duration_sec, mood, weather, created_at, updated_at
		FROM reading_sessions WHERE id = $1`

	err := r.db.QueryRow(ctx, query, id).Scan(
		&session.ID, &session.UserID, &session.BookID, &session.StartPos,
		&session.CurrentPos, &session.DurationSec, &session.Mood, &session.Weather,
		&session.CreatedAt, &session.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to get reading session: %w", err)
	}

	return &session, nil
}

// Update updates a reading session
func (r *postgresSessionRepository) Update(ctx context.Context, session *models.ReadingSession) error {
	query := `
		UPDATE reading_sessions 
		SET current_pos = $2, duration_sec = $3, mood = $4, weather = $5, updated_at = $6
		WHERE id = $1`

	_, err := r.db.Exec(ctx, query,
		session.ID, session.CurrentPos, session.DurationSec,
		session.Mood, session.Weather, session.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to update reading session: %w", err)
	}

	return nil
}

// Delete deletes a reading session
func (r *postgresSessionRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM reading_sessions WHERE id = $1`

	_, err := r.db.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete reading session: %w", err)
	}

	return nil
}

// GetByUserID retrieves reading sessions by user ID
func (r *postgresSessionRepository) GetByUserID(ctx context.Context, userID uuid.UUID, limit int) ([]*models.ReadingSession, error) {
	query := `
		SELECT id, user_id, book_id, start_pos, current_pos, duration_sec, mood, weather, created_at, updated_at
		FROM reading_sessions 
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2`

	rows, err := r.db.Query(ctx, query, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get reading sessions by user ID: %w", err)
	}
	defer rows.Close()

	var sessions []*models.ReadingSession
	for rows.Next() {
		var session models.ReadingSession

		err := rows.Scan(
			&session.ID, &session.UserID, &session.BookID, &session.StartPos,
			&session.CurrentPos, &session.DurationSec, &session.Mood, &session.Weather,
			&session.CreatedAt, &session.UpdatedAt)

		if err != nil {
			return nil, fmt.Errorf("failed to scan reading session row: %w", err)
		}

		sessions = append(sessions, &session)
	}

	return sessions, nil
}

// GetByBookID retrieves reading sessions by book ID
func (r *postgresSessionRepository) GetByBookID(ctx context.Context, bookID int64, limit int) ([]*models.ReadingSession, error) {
	query := `
		SELECT id, user_id, book_id, start_pos, current_pos, duration_sec, mood, weather, created_at, updated_at
		FROM reading_sessions 
		WHERE book_id = $1
		ORDER BY created_at DESC
		LIMIT $2`

	rows, err := r.db.Query(ctx, query, bookID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get reading sessions by book ID: %w", err)
	}
	defer rows.Close()

	var sessions []*models.ReadingSession
	for rows.Next() {
		var session models.ReadingSession

		err := rows.Scan(
			&session.ID, &session.UserID, &session.BookID, &session.StartPos,
			&session.CurrentPos, &session.DurationSec, &session.Mood, &session.Weather,
			&session.CreatedAt, &session.UpdatedAt)

		if err != nil {
			return nil, fmt.Errorf("failed to scan reading session row: %w", err)
		}

		sessions = append(sessions, &session)
	}

	return sessions, nil
}