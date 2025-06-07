package entities

import (
	"time"

	"github.com/google/uuid"
)

// ReadingSessionEntity represents a reading session in the database layer
type ReadingSessionEntity struct {
	ID          uuid.UUID `db:"id"`
	UserID      uuid.UUID `db:"user_id"`
	BookID      int64     `db:"book_id"`
	StartPos    int       `db:"start_pos"`
	CurrentPos  int       `db:"current_pos"`
	DurationSec int       `db:"duration_sec"`
	Mood        *string   `db:"mood"`
	Weather     *string   `db:"weather"`
	CreatedAt   time.Time `db:"created_at"`
	UpdatedAt   time.Time `db:"updated_at"`
}

// TableName returns the table name for the entity
func (ReadingSessionEntity) TableName() string {
	return "reading_sessions"
}