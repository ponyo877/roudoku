package repository

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/ponyo877/roudoku/server/domain"
)

// AudioFileRepository defines the interface for audio file data operations
type AudioFileRepository interface {
	Create(ctx context.Context, audioFile *domain.AudioFile) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.AudioFile, error)
	GetByTextHash(ctx context.Context, userID uuid.UUID, textHash string) (*domain.AudioFile, error)
	GetByUserID(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.AudioFile, error)
	Update(ctx context.Context, audioFile *domain.AudioFile) error
	Delete(ctx context.Context, id uuid.UUID) error
	GetExpiredFiles(ctx context.Context) ([]*domain.AudioFile, error)
	DeleteExpiredFiles(ctx context.Context) error
}

// AudioPlaybackSessionRepository defines the interface for audio playback session operations
type AudioPlaybackSessionRepository interface {
	Create(ctx context.Context, session *domain.AudioPlaybackSession) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.AudioPlaybackSession, error)
	GetByUserID(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.AudioPlaybackSession, error)
	GetByAudioFileID(ctx context.Context, audioFileID uuid.UUID, limit, offset int) ([]*domain.AudioPlaybackSession, error)
	Update(ctx context.Context, session *domain.AudioPlaybackSession) error
	Delete(ctx context.Context, id uuid.UUID) error
}

// NotificationPreferencesRepository defines the interface for notification preferences operations
type NotificationPreferencesRepository interface {
	Create(ctx context.Context, prefs *domain.NotificationPreferences) error
	GetByUserID(ctx context.Context, userID uuid.UUID) (*domain.NotificationPreferences, error)
	Update(ctx context.Context, prefs *domain.NotificationPreferences) error
	Delete(ctx context.Context, userID uuid.UUID) error
}

// FCMTokenRepository defines the interface for FCM token operations
type FCMTokenRepository interface {
	Create(ctx context.Context, token *domain.FCMToken) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.FCMToken, error)
	GetByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.FCMToken, error)
	GetByToken(ctx context.Context, token string) (*domain.FCMToken, error)
	GetActiveTokensByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.FCMToken, error)
	Update(ctx context.Context, token *domain.FCMToken) error
	Delete(ctx context.Context, id uuid.UUID) error
	DeactivateByDeviceID(ctx context.Context, userID uuid.UUID, deviceID string) error
}

// NotificationRepository defines the interface for notification operations
type NotificationRepository interface {
	Create(ctx context.Context, notification *domain.Notification) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.Notification, error)
	GetByUserID(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.Notification, error)
	GetUnreadByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.Notification, error)
	Update(ctx context.Context, notification *domain.Notification) error
	MarkAsRead(ctx context.Context, id uuid.UUID) error
	MarkAllAsRead(ctx context.Context, userID uuid.UUID) error
	Delete(ctx context.Context, id uuid.UUID) error
	DeleteExpiredNotifications(ctx context.Context) error
	GetUnreadCount(ctx context.Context, userID uuid.UUID) (int, error)
}

// ScheduledNotificationRepository defines the interface for scheduled notification operations
type ScheduledNotificationRepository interface {
	Create(ctx context.Context, notification *domain.ScheduledNotification) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.ScheduledNotification, error)
	GetByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.ScheduledNotification, error)
	GetPendingNotifications(ctx context.Context) ([]*domain.ScheduledNotification, error)
	Update(ctx context.Context, notification *domain.ScheduledNotification) error
	Delete(ctx context.Context, id uuid.UUID) error
	UpdateExecutionTime(ctx context.Context, id uuid.UUID) error
}

// PostgreSQL implementations

type postgresAudioFileRepository struct {
	db *pgxpool.Pool
}

func NewPostgresAudioFileRepository(db *pgxpool.Pool) AudioFileRepository {
	return &postgresAudioFileRepository{db: db}
}

func (r *postgresAudioFileRepository) Create(ctx context.Context, audioFile *domain.AudioFile) error {
	query := `
		INSERT INTO audio_files (
			id, user_id, book_id, chapter_id, text_content, text_hash,
			voice_config, file_path, file_size_bytes, duration_seconds,
			format, sample_rate, bit_rate, status, error_message,
			expires_at, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18
		)`

	_, err := r.db.Exec(ctx, query,
		audioFile.ID, audioFile.UserID, audioFile.BookID, audioFile.ChapterID,
		audioFile.TextContent, audioFile.TextHash, audioFile.VoiceConfig,
		audioFile.FilePath, audioFile.FileSizeBytes, audioFile.DurationSeconds,
		audioFile.Format, audioFile.SampleRate, audioFile.BitRate,
		audioFile.Status, audioFile.ErrorMessage, audioFile.ExpiresAt,
		audioFile.CreatedAt, audioFile.UpdatedAt,
	)
	return err
}

func (r *postgresAudioFileRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.AudioFile, error) {
	query := `
		SELECT id, user_id, book_id, chapter_id, text_content, text_hash,
			   voice_config, file_path, file_size_bytes, duration_seconds,
			   format, sample_rate, bit_rate, status, error_message,
			   play_count, last_played_at, expires_at, created_at, updated_at
		FROM audio_files WHERE id = $1`

	var audioFile domain.AudioFile
	err := r.db.QueryRow(ctx, query, id).Scan(
		&audioFile.ID, &audioFile.UserID, &audioFile.BookID, &audioFile.ChapterID,
		&audioFile.TextContent, &audioFile.TextHash, &audioFile.VoiceConfig,
		&audioFile.FilePath, &audioFile.FileSizeBytes, &audioFile.DurationSeconds,
		&audioFile.Format, &audioFile.SampleRate, &audioFile.BitRate,
		&audioFile.Status, &audioFile.ErrorMessage, &audioFile.PlayCount,
		&audioFile.LastPlayedAt, &audioFile.ExpiresAt, &audioFile.CreatedAt,
		&audioFile.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return &audioFile, nil
}

func (r *postgresAudioFileRepository) GetByTextHash(ctx context.Context, userID uuid.UUID, textHash string) (*domain.AudioFile, error) {
	query := `
		SELECT id, user_id, book_id, chapter_id, text_content, text_hash,
			   voice_config, file_path, file_size_bytes, duration_seconds,
			   format, sample_rate, bit_rate, status, error_message,
			   play_count, last_played_at, expires_at, created_at, updated_at
		FROM audio_files 
		WHERE user_id = $1 AND text_hash = $2 AND status = 'completed'
		ORDER BY created_at DESC LIMIT 1`

	var audioFile domain.AudioFile
	err := r.db.QueryRow(ctx, query, userID, textHash).Scan(
		&audioFile.ID, &audioFile.UserID, &audioFile.BookID, &audioFile.ChapterID,
		&audioFile.TextContent, &audioFile.TextHash, &audioFile.VoiceConfig,
		&audioFile.FilePath, &audioFile.FileSizeBytes, &audioFile.DurationSeconds,
		&audioFile.Format, &audioFile.SampleRate, &audioFile.BitRate,
		&audioFile.Status, &audioFile.ErrorMessage, &audioFile.PlayCount,
		&audioFile.LastPlayedAt, &audioFile.ExpiresAt, &audioFile.CreatedAt,
		&audioFile.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return &audioFile, nil
}

func (r *postgresAudioFileRepository) GetByUserID(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.AudioFile, error) {
	query := `
		SELECT id, user_id, book_id, chapter_id, text_content, text_hash,
			   voice_config, file_path, file_size_bytes, duration_seconds,
			   format, sample_rate, bit_rate, status, error_message,
			   play_count, last_played_at, expires_at, created_at, updated_at
		FROM audio_files 
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3`

	rows, err := r.db.Query(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var audioFiles []*domain.AudioFile
	for rows.Next() {
		var audioFile domain.AudioFile
		err := rows.Scan(
			&audioFile.ID, &audioFile.UserID, &audioFile.BookID, &audioFile.ChapterID,
			&audioFile.TextContent, &audioFile.TextHash, &audioFile.VoiceConfig,
			&audioFile.FilePath, &audioFile.FileSizeBytes, &audioFile.DurationSeconds,
			&audioFile.Format, &audioFile.SampleRate, &audioFile.BitRate,
			&audioFile.Status, &audioFile.ErrorMessage, &audioFile.PlayCount,
			&audioFile.LastPlayedAt, &audioFile.ExpiresAt, &audioFile.CreatedAt,
			&audioFile.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		audioFiles = append(audioFiles, &audioFile)
	}

	return audioFiles, rows.Err()
}

func (r *postgresAudioFileRepository) Update(ctx context.Context, audioFile *domain.AudioFile) error {
	query := `
		UPDATE audio_files SET
			file_path = $2, file_size_bytes = $3, duration_seconds = $4,
			format = $5, sample_rate = $6, bit_rate = $7, status = $8,
			error_message = $9, expires_at = $10, updated_at = $11
		WHERE id = $1`

	_, err := r.db.Exec(ctx, query,
		audioFile.ID, audioFile.FilePath, audioFile.FileSizeBytes,
		audioFile.DurationSeconds, audioFile.Format, audioFile.SampleRate,
		audioFile.BitRate, audioFile.Status, audioFile.ErrorMessage,
		audioFile.ExpiresAt, audioFile.UpdatedAt,
	)
	return err
}

func (r *postgresAudioFileRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM audio_files WHERE id = $1`
	_, err := r.db.Exec(ctx, query, id)
	return err
}

func (r *postgresAudioFileRepository) GetExpiredFiles(ctx context.Context) ([]*domain.AudioFile, error) {
	query := `
		SELECT id, user_id, book_id, chapter_id, text_content, text_hash,
			   voice_config, file_path, file_size_bytes, duration_seconds,
			   format, sample_rate, bit_rate, status, error_message,
			   play_count, last_played_at, expires_at, created_at, updated_at
		FROM audio_files 
		WHERE expires_at IS NOT NULL AND expires_at < NOW()`

	rows, err := r.db.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var audioFiles []*domain.AudioFile
	for rows.Next() {
		var audioFile domain.AudioFile
		err := rows.Scan(
			&audioFile.ID, &audioFile.UserID, &audioFile.BookID, &audioFile.ChapterID,
			&audioFile.TextContent, &audioFile.TextHash, &audioFile.VoiceConfig,
			&audioFile.FilePath, &audioFile.FileSizeBytes, &audioFile.DurationSeconds,
			&audioFile.Format, &audioFile.SampleRate, &audioFile.BitRate,
			&audioFile.Status, &audioFile.ErrorMessage, &audioFile.PlayCount,
			&audioFile.LastPlayedAt, &audioFile.ExpiresAt, &audioFile.CreatedAt,
			&audioFile.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		audioFiles = append(audioFiles, &audioFile)
	}

	return audioFiles, rows.Err()
}

func (r *postgresAudioFileRepository) DeleteExpiredFiles(ctx context.Context) error {
	query := `DELETE FROM audio_files WHERE expires_at IS NOT NULL AND expires_at < NOW()`
	_, err := r.db.Exec(ctx, query)
	return err
}

// FCM Token Repository implementation
type postgresFCMTokenRepository struct {
	db *pgxpool.Pool
}

func NewPostgresFCMTokenRepository(db *pgxpool.Pool) FCMTokenRepository {
	return &postgresFCMTokenRepository{db: db}
}

func (r *postgresFCMTokenRepository) Create(ctx context.Context, token *domain.FCMToken) error {
	query := `
		INSERT INTO fcm_tokens (id, user_id, token, device_type, device_id, is_active, last_used_at, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (token) DO UPDATE SET
			user_id = EXCLUDED.user_id,
			device_type = EXCLUDED.device_type,
			device_id = EXCLUDED.device_id,
			is_active = EXCLUDED.is_active,
			last_used_at = EXCLUDED.last_used_at,
			updated_at = EXCLUDED.updated_at`

	_, err := r.db.Exec(ctx, query,
		token.ID, token.UserID, token.Token, token.DeviceType,
		token.DeviceID, token.IsActive, token.LastUsedAt,
		token.CreatedAt, token.UpdatedAt,
	)
	return err
}

func (r *postgresFCMTokenRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.FCMToken, error) {
	query := `
		SELECT id, user_id, token, device_type, device_id, is_active, last_used_at, created_at, updated_at
		FROM fcm_tokens WHERE id = $1`

	var token domain.FCMToken
	err := r.db.QueryRow(ctx, query, id).Scan(
		&token.ID, &token.UserID, &token.Token, &token.DeviceType,
		&token.DeviceID, &token.IsActive, &token.LastUsedAt,
		&token.CreatedAt, &token.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return &token, nil
}

func (r *postgresFCMTokenRepository) GetByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.FCMToken, error) {
	query := `
		SELECT id, user_id, token, device_type, device_id, is_active, last_used_at, created_at, updated_at
		FROM fcm_tokens WHERE user_id = $1 ORDER BY created_at DESC`

	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tokens []*domain.FCMToken
	for rows.Next() {
		var token domain.FCMToken
		err := rows.Scan(
			&token.ID, &token.UserID, &token.Token, &token.DeviceType,
			&token.DeviceID, &token.IsActive, &token.LastUsedAt,
			&token.CreatedAt, &token.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		tokens = append(tokens, &token)
	}

	return tokens, rows.Err()
}

func (r *postgresFCMTokenRepository) GetByToken(ctx context.Context, tokenStr string) (*domain.FCMToken, error) {
	query := `
		SELECT id, user_id, token, device_type, device_id, is_active, last_used_at, created_at, updated_at
		FROM fcm_tokens WHERE token = $1`

	var token domain.FCMToken
	err := r.db.QueryRow(ctx, query, tokenStr).Scan(
		&token.ID, &token.UserID, &token.Token, &token.DeviceType,
		&token.DeviceID, &token.IsActive, &token.LastUsedAt,
		&token.CreatedAt, &token.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return &token, nil
}

func (r *postgresFCMTokenRepository) GetActiveTokensByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.FCMToken, error) {
	query := `
		SELECT id, user_id, token, device_type, device_id, is_active, last_used_at, created_at, updated_at
		FROM fcm_tokens WHERE user_id = $1 AND is_active = true ORDER BY last_used_at DESC`

	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tokens []*domain.FCMToken
	for rows.Next() {
		var token domain.FCMToken
		err := rows.Scan(
			&token.ID, &token.UserID, &token.Token, &token.DeviceType,
			&token.DeviceID, &token.IsActive, &token.LastUsedAt,
			&token.CreatedAt, &token.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		tokens = append(tokens, &token)
	}

	return tokens, rows.Err()
}

func (r *postgresFCMTokenRepository) Update(ctx context.Context, token *domain.FCMToken) error {
	query := `
		UPDATE fcm_tokens SET
			device_type = $2, device_id = $3, is_active = $4,
			last_used_at = $5, updated_at = $6
		WHERE id = $1`

	_, err := r.db.Exec(ctx, query,
		token.ID, token.DeviceType, token.DeviceID,
		token.IsActive, token.LastUsedAt, token.UpdatedAt,
	)
	return err
}

func (r *postgresFCMTokenRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM fcm_tokens WHERE id = $1`
	_, err := r.db.Exec(ctx, query, id)
	return err
}

func (r *postgresFCMTokenRepository) DeactivateByDeviceID(ctx context.Context, userID uuid.UUID, deviceID string) error {
	query := `UPDATE fcm_tokens SET is_active = false WHERE user_id = $1 AND device_id = $2`
	_, err := r.db.Exec(ctx, query, userID, deviceID)
	return err
}

// Notification Repository implementation
type postgresNotificationRepository struct {
	db *pgxpool.Pool
}

func NewPostgresNotificationRepository(db *pgxpool.Pool) NotificationRepository {
	return &postgresNotificationRepository{db: db}
}

func (r *postgresNotificationRepository) Create(ctx context.Context, notification *domain.Notification) error {
	dataJSON, err := json.Marshal(notification.Data)
	if err != nil {
		return fmt.Errorf("failed to marshal notification data: %w", err)
	}

	query := `
		INSERT INTO notifications (
			id, user_id, title, body, data, type, is_read, sent_at,
			expires_at, fcm_message_id, delivery_status, error_message,
			created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)`

	_, err = r.db.Exec(ctx, query,
		notification.ID, notification.UserID, notification.Title,
		notification.Body, dataJSON, notification.Type, notification.IsRead,
		notification.SentAt, notification.ExpiresAt, notification.FCMMessageID,
		notification.DeliveryStatus, notification.ErrorMessage,
		notification.CreatedAt, notification.UpdatedAt,
	)
	return err
}

func (r *postgresNotificationRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.Notification, error) {
	query := `
		SELECT id, user_id, title, body, data, type, is_read, read_at,
			   sent_at, expires_at, fcm_message_id, delivery_status,
			   error_message, created_at, updated_at
		FROM notifications WHERE id = $1`

	var notification domain.Notification
	var dataJSON []byte
	err := r.db.QueryRow(ctx, query, id).Scan(
		&notification.ID, &notification.UserID, &notification.Title,
		&notification.Body, &dataJSON, &notification.Type,
		&notification.IsRead, &notification.ReadAt, &notification.SentAt,
		&notification.ExpiresAt, &notification.FCMMessageID,
		&notification.DeliveryStatus, &notification.ErrorMessage,
		&notification.CreatedAt, &notification.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	if len(dataJSON) > 0 {
		err = json.Unmarshal(dataJSON, &notification.Data)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal notification data: %w", err)
		}
	}

	return &notification, nil
}

func (r *postgresNotificationRepository) GetByUserID(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*domain.Notification, error) {
	query := `
		SELECT id, user_id, title, body, data, type, is_read, read_at,
			   sent_at, expires_at, fcm_message_id, delivery_status,
			   error_message, created_at, updated_at
		FROM notifications 
		WHERE user_id = $1
		ORDER BY sent_at DESC
		LIMIT $2 OFFSET $3`

	rows, err := r.db.Query(ctx, query, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var notifications []*domain.Notification
	for rows.Next() {
		var notification domain.Notification
		var dataJSON []byte
		err := rows.Scan(
			&notification.ID, &notification.UserID, &notification.Title,
			&notification.Body, &dataJSON, &notification.Type,
			&notification.IsRead, &notification.ReadAt, &notification.SentAt,
			&notification.ExpiresAt, &notification.FCMMessageID,
			&notification.DeliveryStatus, &notification.ErrorMessage,
			&notification.CreatedAt, &notification.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}

		if len(dataJSON) > 0 {
			err = json.Unmarshal(dataJSON, &notification.Data)
			if err != nil {
				return nil, fmt.Errorf("failed to unmarshal notification data: %w", err)
			}
		}

		notifications = append(notifications, &notification)
	}

	return notifications, rows.Err()
}

func (r *postgresNotificationRepository) GetUnreadByUserID(ctx context.Context, userID uuid.UUID) ([]*domain.Notification, error) {
	query := `
		SELECT id, user_id, title, body, data, type, is_read, read_at,
			   sent_at, expires_at, fcm_message_id, delivery_status,
			   error_message, created_at, updated_at
		FROM notifications 
		WHERE user_id = $1 AND is_read = false
		ORDER BY sent_at DESC`

	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var notifications []*domain.Notification
	for rows.Next() {
		var notification domain.Notification
		var dataJSON []byte
		err := rows.Scan(
			&notification.ID, &notification.UserID, &notification.Title,
			&notification.Body, &dataJSON, &notification.Type,
			&notification.IsRead, &notification.ReadAt, &notification.SentAt,
			&notification.ExpiresAt, &notification.FCMMessageID,
			&notification.DeliveryStatus, &notification.ErrorMessage,
			&notification.CreatedAt, &notification.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}

		if len(dataJSON) > 0 {
			err = json.Unmarshal(dataJSON, &notification.Data)
			if err != nil {
				return nil, fmt.Errorf("failed to unmarshal notification data: %w", err)
			}
		}

		notifications = append(notifications, &notification)
	}

	return notifications, rows.Err()
}

func (r *postgresNotificationRepository) Update(ctx context.Context, notification *domain.Notification) error {
	dataJSON, err := json.Marshal(notification.Data)
	if err != nil {
		return fmt.Errorf("failed to marshal notification data: %w", err)
	}

	query := `
		UPDATE notifications SET
			title = $2, body = $3, data = $4, type = $5, is_read = $6,
			read_at = $7, expires_at = $8, fcm_message_id = $9,
			delivery_status = $10, error_message = $11, updated_at = $12
		WHERE id = $1`

	_, err = r.db.Exec(ctx, query,
		notification.ID, notification.Title, notification.Body,
		dataJSON, notification.Type, notification.IsRead,
		notification.ReadAt, notification.ExpiresAt,
		notification.FCMMessageID, notification.DeliveryStatus,
		notification.ErrorMessage, notification.UpdatedAt,
	)
	return err
}

func (r *postgresNotificationRepository) MarkAsRead(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE notifications SET is_read = true, read_at = NOW(), updated_at = NOW() WHERE id = $1`
	_, err := r.db.Exec(ctx, query, id)
	return err
}

func (r *postgresNotificationRepository) MarkAllAsRead(ctx context.Context, userID uuid.UUID) error {
	query := `UPDATE notifications SET is_read = true, read_at = NOW(), updated_at = NOW() WHERE user_id = $1 AND is_read = false`
	_, err := r.db.Exec(ctx, query, userID)
	return err
}

func (r *postgresNotificationRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM notifications WHERE id = $1`
	_, err := r.db.Exec(ctx, query, id)
	return err
}

func (r *postgresNotificationRepository) DeleteExpiredNotifications(ctx context.Context) error {
	query := `DELETE FROM notifications WHERE expires_at IS NOT NULL AND expires_at < NOW()`
	_, err := r.db.Exec(ctx, query)
	return err
}

func (r *postgresNotificationRepository) GetUnreadCount(ctx context.Context, userID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = false`
	var count int
	err := r.db.QueryRow(ctx, query, userID).Scan(&count)
	return count, err
}