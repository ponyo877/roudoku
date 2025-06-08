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

// postgresRatingRepository implements RatingRepository using PostgreSQL
type postgresRatingRepository struct {
	db     *pgxpool.Pool
	mapper *mappers.RatingMapper
}

// NewPostgresRatingRepository creates a new PostgreSQL rating repository
func NewPostgresRatingRepository(db *pgxpool.Pool) RatingRepository {
	return &postgresRatingRepository{
		db:     db,
		mapper: mappers.NewRatingMapper(),
	}
}

// Create creates a new rating
func (r *postgresRatingRepository) Create(ctx context.Context, rating *domain.Rating) error {
	entity := r.mapper.DomainToEntity(rating)
	query := `
		INSERT INTO ratings (user_id, book_id, rating, comment, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6)`

	_, err := r.db.Exec(ctx, query,
		entity.UserID, entity.BookID, entity.Rating, entity.Comment,
		entity.CreatedAt, entity.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to create rating: %w", err)
	}

	return nil
}

// GetByUserAndBook retrieves a rating by user and book
func (r *postgresRatingRepository) GetByUserAndBook(ctx context.Context, userID uuid.UUID, bookID int64) (*domain.Rating, error) {
	entity := new(ent.RatingEntity)

	query := `
		SELECT user_id, book_id, rating, comment, created_at, updated_at
		FROM ratings WHERE user_id = $1 AND book_id = $2`

	err := r.db.QueryRow(ctx, query, userID, bookID).Scan(
		&entity.UserID, &entity.BookID, &entity.Rating, &entity.Comment,
		&entity.CreatedAt, &entity.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to get rating: %w", err)
	}

	return r.mapper.EntityToDomain(entity), nil
}

// Update updates a rating
func (r *postgresRatingRepository) Update(ctx context.Context, rating *domain.Rating) error {
	entity := r.mapper.DomainToEntity(rating)
	query := `
		UPDATE ratings 
		SET rating = $3, comment = $4, updated_at = $5
		WHERE user_id = $1 AND book_id = $2`

	_, err := r.db.Exec(ctx, query,
		entity.UserID, entity.BookID, entity.Rating, entity.Comment, entity.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to update rating: %w", err)
	}

	return nil
}

// Delete deletes a rating
func (r *postgresRatingRepository) Delete(ctx context.Context, userID uuid.UUID, bookID int64) error {
	query := `DELETE FROM ratings WHERE user_id = $1 AND book_id = $2`

	_, err := r.db.Exec(ctx, query, userID, bookID)
	if err != nil {
		return fmt.Errorf("failed to delete rating: %w", err)
	}

	return nil
}

// GetByUserID retrieves ratings by user ID
func (r *postgresRatingRepository) GetByUserID(ctx context.Context, userID uuid.UUID, limit int) ([]*domain.Rating, error) {
	query := `
		SELECT user_id, book_id, rating, comment, created_at, updated_at
		FROM ratings 
		WHERE user_id = $1
		ORDER BY updated_at DESC
		LIMIT $2`

	rows, err := r.db.Query(ctx, query, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get ratings by user ID: %w", err)
	}
	defer rows.Close()

	var entities []*ent.RatingEntity
	for rows.Next() {
		entity := new(ent.RatingEntity)

		err := rows.Scan(
			&entity.UserID, &entity.BookID, &entity.Rating, &entity.Comment,
			&entity.CreatedAt, &entity.UpdatedAt)

		if err != nil {
			return nil, fmt.Errorf("failed to scan rating row: %w", err)
		}

		entities = append(entities, entity)
	}

	ratings := r.mapper.EntityToDomainSlice(entities)
	return ratings, nil
}

// GetByBookID retrieves ratings by book ID
func (r *postgresRatingRepository) GetByBookID(ctx context.Context, bookID int64, limit int) ([]*domain.Rating, error) {
	query := `
		SELECT user_id, book_id, rating, comment, created_at, updated_at
		FROM ratings 
		WHERE book_id = $1
		ORDER BY updated_at DESC
		LIMIT $2`

	rows, err := r.db.Query(ctx, query, bookID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get ratings by book ID: %w", err)
	}
	defer rows.Close()

	var entities []*ent.RatingEntity
	for rows.Next() {
		entity := new(ent.RatingEntity)

		err := rows.Scan(
			&entity.UserID, &entity.BookID, &entity.Rating, &entity.Comment,
			&entity.CreatedAt, &entity.UpdatedAt)

		if err != nil {
			return nil, fmt.Errorf("failed to scan rating row: %w", err)
		}

		entities = append(entities, entity)
	}

	ratings := r.mapper.EntityToDomainSlice(entities)
	return ratings, nil
}