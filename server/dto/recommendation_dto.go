package dto

import "time"

// RecommendationStatsResponse represents recommendation statistics for a user
type RecommendationStatsResponse struct {
	TotalInteractions int       `json:"total_interactions"`
	PreferredGenres   []string  `json:"preferred_genres"`
	PreferredAuthors  []string  `json:"preferred_authors"`
	LastUpdated       time.Time `json:"last_updated"`
}