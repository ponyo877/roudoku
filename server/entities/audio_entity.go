package entities

import (
	"time"

	"github.com/google/uuid"
)

// AudioFileEntity represents audio file data in the database
type AudioFileEntity struct {
	ID          uuid.UUID `db:"id" json:"id"`
	FileName    string    `db:"file_name" json:"file_name"`
	ContentType string    `db:"content_type" json:"content_type"`
	FileSize    int64     `db:"file_size" json:"file_size"`
	StoragePath string    `db:"storage_path" json:"storage_path"`
	DownloadURL *string   `db:"download_url" json:"download_url"`
	UserID      *uuid.UUID `db:"user_id" json:"user_id"`
	BookID      *int64    `db:"book_id" json:"book_id"`
	ChapterID   *string   `db:"chapter_id" json:"chapter_id"`
	TTSConfig   *string   `db:"tts_config" json:"tts_config"` // JSON string of TTS settings
	IsActive    bool      `db:"is_active" json:"is_active"`
	CreatedAt   time.Time `db:"created_at" json:"created_at"`
	UpdatedAt   time.Time `db:"updated_at" json:"updated_at"`
}