package repository

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/ponyo877/roudoku/server/domain"
	ent "github.com/ponyo877/roudoku/server/entities"
	"github.com/ponyo877/roudoku/server/mappers"
)

// postgresUserRepository implements UserRepository using PostgreSQL
type postgresUserRepository struct {
	db     *pgxpool.Pool
	mapper *mappers.UserMapper
}

// NewPostgresUserRepository creates a new PostgreSQL user repository
func NewPostgresUserRepository(db *pgxpool.Pool) UserRepository {
	return &postgresUserRepository{
		db:     db,
		mapper: mappers.NewUserMapper(),
	}
}

// Create creates a new user
func (r *postgresUserRepository) Create(ctx context.Context, user *domain.User) error {
	entity := r.mapper.DomainToEntity(user)
	voicePresetJSON, err := json.Marshal(entity.VoicePreset)
	if err != nil {
		return fmt.Errorf("failed to marshal voice preset: %w", err)
	}

	query := `
		INSERT INTO users (id, display_name, email, voice_preset, subscription_status, subscription_expires_at, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`

	_, err = r.db.Exec(ctx, query,
		entity.ID, entity.DisplayName, entity.Email, voicePresetJSON,
		entity.SubscriptionStatus, entity.SubscriptionExpiresAt,
		entity.CreatedAt, entity.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to create user: %w", err)
	}

	return nil
}

// GetByID retrieves a user by ID
func (r *postgresUserRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.User, error) {
	entity := new(ent.UserEntity)
	var voicePresetJSON []byte

	query := `
		SELECT id, display_name, email, voice_preset, subscription_status, subscription_expires_at, created_at, updated_at
		FROM users WHERE id = $1`

	err := r.db.QueryRow(ctx, query, id).Scan(
		&entity.ID, &entity.DisplayName, &entity.Email, &voicePresetJSON,
		&entity.SubscriptionStatus, &entity.SubscriptionExpiresAt,
		&entity.CreatedAt, &entity.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	if err := json.Unmarshal(voicePresetJSON, &entity.VoicePreset); err != nil {
		return nil, fmt.Errorf("failed to unmarshal voice preset: %w", err)
	}

	return r.mapper.EntityToDomain(entity), nil
}

// Update updates a user
func (r *postgresUserRepository) Update(ctx context.Context, user *domain.User) error {
	entity := r.mapper.DomainToEntity(user)
	voicePresetJSON, err := json.Marshal(entity.VoicePreset)
	if err != nil {
		return fmt.Errorf("failed to marshal voice preset: %w", err)
	}

	query := `
		UPDATE users 
		SET display_name = $2, email = $3, voice_preset = $4, subscription_status = $5, 
		    subscription_expires_at = $6, updated_at = $7
		WHERE id = $1`

	_, err = r.db.Exec(ctx, query,
		entity.ID, entity.DisplayName, entity.Email, voicePresetJSON,
		entity.SubscriptionStatus, entity.SubscriptionExpiresAt, entity.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}

	return nil
}

// Delete deletes a user
func (r *postgresUserRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM users WHERE id = $1`

	_, err := r.db.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete user: %w", err)
	}

	return nil
}

// List retrieves a list of users
func (r *postgresUserRepository) List(ctx context.Context, limit, offset int) ([]*domain.User, error) {
	query := `
		SELECT id, display_name, email, voice_preset, subscription_status, subscription_expires_at, created_at, updated_at
		FROM users 
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2`

	rows, err := r.db.Query(ctx, query, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to list users: %w", err)
	}
	defer rows.Close()

	var entities []*ent.UserEntity
	for rows.Next() {
		entity := new(ent.UserEntity)
		var voicePresetJSON []byte

		err := rows.Scan(
			&entity.ID, &entity.DisplayName, &entity.Email, &voicePresetJSON,
			&entity.SubscriptionStatus, &entity.SubscriptionExpiresAt,
			&entity.CreatedAt, &entity.UpdatedAt)

		if err != nil {
			return nil, fmt.Errorf("failed to scan user row: %w", err)
		}

		if err := json.Unmarshal(voicePresetJSON, &entity.VoicePreset); err != nil {
			return nil, fmt.Errorf("failed to unmarshal voice preset: %w", err)
		}

		entities = append(entities, entity)
	}

	users := r.mapper.EntityToDomainSlice(entities)
	return users, nil
}