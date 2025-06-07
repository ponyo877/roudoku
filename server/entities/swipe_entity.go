package entities

import (
	"time"

	"github.com/google/uuid"
)

// SwipeLogEntity represents a swipe log in the database layer
type SwipeLogEntity struct {
	ID        uuid.UUID `db:"id"`
	UserID    uuid.UUID `db:"user_id"`
	QuoteID   uuid.UUID `db:"quote_id"`
	Mode      string    `db:"mode"`
	Choice    int       `db:"choice"`
	CreatedAt time.Time `db:"created_at"`
}

// TableName returns the table name for the entity
func (SwipeLogEntity) TableName() string {
	return "swipe_logs"
}