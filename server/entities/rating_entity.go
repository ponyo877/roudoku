package entities

import (
	"time"

	"github.com/google/uuid"
)

// RatingEntity represents a rating in the database layer
type RatingEntity struct {
	UserID    uuid.UUID `db:"user_id"`
	BookID    int64     `db:"book_id"`
	Rating    int       `db:"rating"`
	Comment   *string   `db:"comment"`
	CreatedAt time.Time `db:"created_at"`
	UpdatedAt time.Time `db:"updated_at"`
}

// TableName returns the table name for the entity
func (RatingEntity) TableName() string {
	return "ratings"
}