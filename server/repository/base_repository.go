package repository

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/ponyo877/roudoku/server/pkg/errors"
)

// BaseRepository provides common database operations
type BaseRepository struct {
	db *pgxpool.Pool
}

// NewBaseRepository creates a new base repository
func NewBaseRepository(db *pgxpool.Pool) *BaseRepository {
	return &BaseRepository{db: db}
}

// HandleError converts database errors to application errors
func (r *BaseRepository) HandleError(err error, operation string) error {
	if err == nil {
		return nil
	}

	switch {
	case err == pgx.ErrNoRows || err == sql.ErrNoRows:
		return errors.NotFound("Resource not found")
	case err.Error() == "duplicate key value violates unique constraint":
		return errors.New("DUPLICATE_ENTRY", "Resource already exists", 409)
	default:
		return errors.InternalServer(fmt.Sprintf("Database %s failed", operation), err)
	}
}

// Transaction executes a function within a database transaction
func (r *BaseRepository) Transaction(ctx context.Context, fn func(tx pgx.Tx) error) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return r.HandleError(err, "transaction begin")
	}
	defer tx.Rollback(ctx)

	if err := fn(tx); err != nil {
		return err
	}

	if err := tx.Commit(ctx); err != nil {
		return r.HandleError(err, "transaction commit")
	}

	return nil
}

// GetConnection returns the database connection pool
func (r *BaseRepository) GetConnection() *pgxpool.Pool {
	return r.db
}

// Ping checks database connectivity
func (r *BaseRepository) Ping(ctx context.Context) error {
	if err := r.db.Ping(ctx); err != nil {
		return r.HandleError(err, "ping")
	}
	return nil
}