package services

import (
	"context"
	"fmt"
	"sort"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/logger"
)

// RecommendationService defines the interface for recommendation business logic
type RecommendationService interface {
	GetRecommendations(ctx context.Context, userID uuid.UUID, limit int) ([]*domain.Book, error)
	TrainModel(ctx context.Context, userID uuid.UUID) error
	GetRecommendationStats(ctx context.Context, userID uuid.UUID) (*dto.RecommendationStatsResponse, error)
}

// recommendationService implements RecommendationService
type recommendationService struct {
	*BaseService
	bookService    BookService
	swipeService   SwipeService
	sessionService SessionService
	ratingService  RatingService
}

// NewRecommendationService creates a new recommendation service
func NewRecommendationService(
	bookService BookService,
	swipeService SwipeService,
	sessionService SessionService,
	ratingService RatingService,
	log *logger.Logger,
) RecommendationService {
	return &recommendationService{
		BaseService:    NewBaseService(log),
		bookService:    bookService,
		swipeService:   swipeService,
		sessionService: sessionService,
		ratingService:  ratingService,
	}
}

// UserPreferences represents analyzed user preferences
type UserPreferences struct {
	PreferredGenres    []string
	PreferredAuthors   []string
	PreferredEpochs    []string
	DifficultyRange    []int
	ReadingTimeRange   []int
	InteractionScore   map[int64]float64 // book_id -> score
}

// GetRecommendations generates book recommendations for a user
func (s *recommendationService) GetRecommendations(ctx context.Context, userID uuid.UUID, limit int) ([]*domain.Book, error) {
	if err := s.ValidateLimit(limit); err != nil {
		limit = DefaultLimit
	}
	limit = s.NormalizeLimit(limit)
	s.logger.Info("Generating recommendations", 
		zap.String("user_id", userID.String()),
		zap.Int("limit", limit))

	// Analyze user preferences
	preferences, err := s.analyzeUserPreferences(ctx, userID)
	if err != nil {
		s.logger.Error("Failed to analyze user preferences", zap.Error(err))
		return nil, fmt.Errorf("failed to analyze user preferences: %w", err)
	}

	// Get candidate books
	searchReq := &dto.BookSearchRequest{
		SortBy: string(domain.SortByPopularity),
		Limit:  limit * 3, // Get more candidates for better filtering
		Offset: 0,
	}

	bookListResponse, err := s.bookService.SearchBooks(ctx, searchReq)
	if err != nil {
		s.logger.Error("Failed to get candidate books", zap.Error(err))
		return nil, fmt.Errorf("failed to get candidate books: %w", err)
	}

	// Convert DTO to domain objects
	var candidateBooks []*domain.Book
	for _, bookDTO := range bookListResponse.Books {
		book := s.convertDTOToDomain(bookDTO)
		candidateBooks = append(candidateBooks, book)
	}

	// Score and rank books
	scoredBooks := s.scoreBooks(candidateBooks, preferences)

	// Sort by score (descending)
	sort.Slice(scoredBooks, func(i, j int) bool {
		return scoredBooks[i].Score > scoredBooks[j].Score
	})

	// Return top recommendations
	var recommendations []*domain.Book
	for i, scored := range scoredBooks {
		if i >= limit {
			break
		}
		recommendations = append(recommendations, scored.Book)
	}

	s.logger.Info("Generated recommendations", 
		zap.String("user_id", userID.String()),
		zap.Int("count", len(recommendations)))

	return recommendations, nil
}

// ScoredBook represents a book with its recommendation score
type ScoredBook struct {
	Book  *domain.Book
	Score float64
}

// analyzeUserPreferences analyzes user behavior to determine preferences
func (s *recommendationService) analyzeUserPreferences(ctx context.Context, userID uuid.UUID) (*UserPreferences, error) {
	preferences := &UserPreferences{
		InteractionScore: make(map[int64]float64),
	}

	// Analyze swipe history
	swipes, err := s.swipeService.GetSwipeLogsByUser(ctx, userID)
	if err != nil {
		s.logger.Debug("No swipe history found", zap.String("user_id", userID.String()))
	} else {
		s.analyzeSwipePreferences(swipes, preferences)
	}

	// Analyze reading sessions
	sessions, err := s.sessionService.GetUserReadingSessions(ctx, userID, 100)
	if err != nil {
		s.logger.Debug("No reading sessions found", zap.String("user_id", userID.String()))
	} else {
		s.analyzeSessionPreferences(ctx, sessions, preferences)
	}

	// Analyze ratings
	ratings, err := s.ratingService.GetUserRatings(ctx, userID, 100)
	if err != nil {
		s.logger.Debug("No ratings found", zap.String("user_id", userID.String()))
	} else {
		s.analyzeRatingPreferences(ctx, ratings, preferences)
	}

	return preferences, nil
}

// analyzeSwipePreferences analyzes swipe data to extract preferences
func (s *recommendationService) analyzeSwipePreferences(swipes []*domain.SwipeLog, preferences *UserPreferences) {
	genreCount := make(map[string]int)
	authorCount := make(map[string]int)
	epochCount := make(map[string]int)
	bookScores := make(map[int64]float64)

	for _, swipe := range swipes {
		// Get quote to find the book
		// Note: We'd need a quote service to get quotes by ID
		// For now, we'll skip quote-based analysis
		// This is a limitation of the current domain model
		
		score := 0.0
		if swipe.Choice == domain.SwipeChoiceLike {
			score = 1.0
		} else if swipe.Choice == domain.SwipeChoiceLeft || swipe.Choice == domain.SwipeChoiceDislike {
			score = -0.5
		}

		// We can't directly map to books without quote service
		// This is a design issue that should be addressed
		_ = score
	}

	// For now, we'll extract preferences from book scores
	for bookID, score := range bookScores {
		book, err := s.bookService.GetBook(context.Background(), bookID)
		if err != nil {
			continue
		}

		preferences.InteractionScore[book.ID] = score

		if score > 0 {
			if book.Genre != nil {
				genreCount[*book.Genre]++
			}
			authorCount[book.Author]++
			if book.Epoch != nil {
				epochCount[*book.Epoch]++
			}
		}
	}

	// Extract top preferences
	preferences.PreferredGenres = s.getTopKeys(genreCount, 3)
	preferences.PreferredAuthors = s.getTopKeys(authorCount, 5)
	preferences.PreferredEpochs = s.getTopKeys(epochCount, 2)
}

// analyzeSessionPreferences analyzes reading session data
func (s *recommendationService) analyzeSessionPreferences(ctx context.Context, sessions []*domain.ReadingSession, preferences *UserPreferences) {
	var readingTimes []int
	var difficulties []int

	for _, session := range sessions {
		book, err := s.bookService.GetBook(ctx, session.BookID)
		if err != nil {
			continue
		}

		// Longer sessions indicate engagement
		score := float64(session.DurationSec) / 3600.0 // hours
		if existingScore, exists := preferences.InteractionScore[book.ID]; exists {
			preferences.InteractionScore[book.ID] = existingScore + float64(score)
		} else {
			preferences.InteractionScore[book.ID] = float64(score)
		}

		readingTimes = append(readingTimes, book.EstimatedReadingMinutes)
		difficulties = append(difficulties, book.DifficultyLevel)
	}

	// Calculate preferred ranges
	if len(readingTimes) > 0 {
		sort.Ints(readingTimes)
		preferences.ReadingTimeRange = []int{
			readingTimes[len(readingTimes)/4],     // 25th percentile
			readingTimes[3*len(readingTimes)/4],   // 75th percentile
		}
	}

	if len(difficulties) > 0 {
		sort.Ints(difficulties)
		preferences.DifficultyRange = []int{
			difficulties[0],                       // min
			difficulties[len(difficulties)-1],     // max
		}
	}
}

// analyzeRatingPreferences analyzes rating data
func (s *recommendationService) analyzeRatingPreferences(ctx context.Context, ratings []*domain.Rating, preferences *UserPreferences) {
	for _, rating := range ratings {
		// High ratings indicate strong preference
		score := float64(rating.Rating) - 3.0 // Normalize around 3 (neutral)
		if existingScore, exists := preferences.InteractionScore[rating.BookID]; exists {
			preferences.InteractionScore[rating.BookID] = existingScore + score
		} else {
			preferences.InteractionScore[rating.BookID] = score
		}
	}
}

// scoreBooks calculates recommendation scores for candidate books
func (s *recommendationService) scoreBooks(books []*domain.Book, preferences *UserPreferences) []ScoredBook {
	var scoredBooks []ScoredBook

	for _, book := range books {
		score := s.calculateBookScore(book, preferences)
		scoredBooks = append(scoredBooks, ScoredBook{
			Book:  book,
			Score: score,
		})
	}

	return scoredBooks
}

// calculateBookScore calculates a recommendation score for a book
func (s *recommendationService) calculateBookScore(book *domain.Book, preferences *UserPreferences) float64 {
	score := 0.0

	// Base popularity score
	score += float64(book.DownloadCount) * 0.001
	score += book.RatingAverage * 0.2

	// Genre preference
	if book.Genre != nil {
		for _, genre := range preferences.PreferredGenres {
			if *book.Genre == genre {
				score += 2.0
				break
			}
		}
	}

	// Author preference
	for _, author := range preferences.PreferredAuthors {
		if book.Author == author {
			score += 1.5
			break
		}
	}

	// Epoch preference
	if book.Epoch != nil {
		for _, epoch := range preferences.PreferredEpochs {
			if *book.Epoch == epoch {
				score += 1.0
				break
			}
		}
	}

	// Difficulty preference
	if len(preferences.DifficultyRange) == 2 {
		if book.DifficultyLevel >= preferences.DifficultyRange[0] && 
		   book.DifficultyLevel <= preferences.DifficultyRange[1] {
			score += 1.0
		}
	}

	// Reading time preference
	if len(preferences.ReadingTimeRange) == 2 {
		if book.EstimatedReadingMinutes >= preferences.ReadingTimeRange[0] && 
		   book.EstimatedReadingMinutes <= preferences.ReadingTimeRange[1] {
			score += 1.0
		}
	}

	// Direct interaction score
	if interactionScore, exists := preferences.InteractionScore[book.ID]; exists {
		if interactionScore < 0 {
			score += interactionScore * 2 // Penalty for negative interactions
		} else {
			score += interactionScore
		}
	}

	return score
}

// getTopKeys returns the top N keys by count
func (s *recommendationService) getTopKeys(counts map[string]int, n int) []string {
	type kv struct {
		Key   string
		Value int
	}

	var kvs []kv
	for k, v := range counts {
		kvs = append(kvs, kv{k, v})
	}

	sort.Slice(kvs, func(i, j int) bool {
		return kvs[i].Value > kvs[j].Value
	})

	var result []string
	for i, kv := range kvs {
		if i >= n {
			break
		}
		result = append(result, kv.Key)
	}

	return result
}

// convertDTOToDomain converts a BookResponse DTO to a Book domain object
func (s *recommendationService) convertDTOToDomain(bookDTO *dto.BookResponse) *domain.Book {
	return &domain.Book{
		ID:                      bookDTO.ID,
		Title:                   bookDTO.Title,
		Author:                  bookDTO.Author,
		Epoch:                   bookDTO.Epoch,
		WordCount:               bookDTO.WordCount,
		ContentURL:              bookDTO.ContentURL,
		Summary:                 bookDTO.Summary,
		Genre:                   bookDTO.Genre,
		DifficultyLevel:         bookDTO.DifficultyLevel,
		EstimatedReadingMinutes: bookDTO.EstimatedReadingMinutes,
		DownloadCount:           bookDTO.DownloadCount,
		RatingAverage:           bookDTO.RatingAverage,
		RatingCount:             bookDTO.RatingCount,
		IsPremium:               bookDTO.IsPremium,
		IsActive:                bookDTO.IsActive,
		CreatedAt:               bookDTO.CreatedAt,
		UpdatedAt:               bookDTO.UpdatedAt,
	}
}

// TrainModel trains the recommendation model (placeholder for ML integration)
func (s *recommendationService) TrainModel(ctx context.Context, userID uuid.UUID) error {
	s.logger.Info("Training recommendation model", zap.String("user_id", userID.String()))
	
	// TODO: Implement ML model training
	// This could integrate with external ML services or libraries
	
	return nil
}

// GetRecommendationStats returns statistics about user recommendations
func (s *recommendationService) GetRecommendationStats(ctx context.Context, userID uuid.UUID) (*dto.RecommendationStatsResponse, error) {
	s.logger.Debug("Getting recommendation stats", zap.String("user_id", userID.String()))
	
	preferences, err := s.analyzeUserPreferences(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to analyze user preferences: %w", err)
	}

	// Count interactions
	swipes, _ := s.swipeService.GetSwipeLogsByUser(ctx, userID)
	sessions, _ := s.sessionService.GetUserReadingSessions(ctx, userID, 100)
	ratings, _ := s.ratingService.GetUserRatings(ctx, userID, 100)

	return &dto.RecommendationStatsResponse{
		TotalInteractions: len(swipes) + len(sessions) + len(ratings),
		PreferredGenres:   preferences.PreferredGenres,
		PreferredAuthors:  preferences.PreferredAuthors,
		LastUpdated:       time.Now(),
	}, nil
}