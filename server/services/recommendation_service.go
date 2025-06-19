package services

import (
	"context"
	"fmt"
	"math"
	"sort"
	"time"

	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/repository"
)

// RecommendationService defines the interface for recommendation operations
type RecommendationService interface {
	// Recommendations
	GetRecommendations(ctx context.Context, userID uuid.UUID, req *dto.RecommendationRequest) (*dto.RecommendationResponse, error)
	GetSimilarBooks(ctx context.Context, req *dto.SimilarBooksRequest) (*dto.RecommendationResponse, error)
	
	// User Preferences
	GetUserPreferences(ctx context.Context, userID uuid.UUID) (*dto.UserPreferencesResponse, error)
	UpdateUserPreferences(ctx context.Context, userID uuid.UUID, req *dto.UpdatePreferencesRequest) (*dto.UserPreferencesResponse, error)
	
	// Feedback
	RecordFeedback(ctx context.Context, userID uuid.UUID, req *dto.RecommendationFeedbackRequest) error
	
	// Insights
	GetRecommendationInsights(ctx context.Context, userID uuid.UUID) (*dto.RecommendationInsightsResponse, error)
	
	// Background tasks
	RecalculateUserSimilarities(ctx context.Context, userID uuid.UUID) error
	UpdateBookVectors(ctx context.Context, bookID int64) error
	InvalidateRecommendationCache(ctx context.Context, userID uuid.UUID) error
}

type recommendationService struct {
	*BaseService
	preferencesRepo     repository.UserPreferencesRepository
	interactionRepo     repository.UserInteractionRepository
	similarityRepo      repository.UserSimilarityRepository
	cacheRepo           repository.RecommendationCacheRepository
	feedbackRepo        repository.RecommendationFeedbackRepository
	vectorRepo          repository.BookVectorRepository
	bookRepo            repository.BookRepository
	progressRepo        repository.BookProgressRepository
	config              *domain.RecommendationConfig
}

// NewRecommendationService creates a new recommendation service
func NewRecommendationService(
	preferencesRepo repository.UserPreferencesRepository,
	interactionRepo repository.UserInteractionRepository,
	similarityRepo repository.UserSimilarityRepository,
	cacheRepo repository.RecommendationCacheRepository,
	feedbackRepo repository.RecommendationFeedbackRepository,
	vectorRepo repository.BookVectorRepository,
	bookRepo repository.BookRepository,
	progressRepo repository.BookProgressRepository,
	logger *logger.Logger,
) RecommendationService {
	config := &domain.RecommendationConfig{
		ContentWeight:       0.4,
		CollaborativeWeight: 0.3,
		PopularityWeight:    0.2,
		NoveltyWeight:       0.1,
		DiversityThreshold:  0.8,
		MinScore:           0.1,
		UseRealtime:        true,
		CacheEnabled:       true,
		CacheTTLHours:      24,
	}

	return &recommendationService{
		BaseService:     NewBaseService(logger),
		preferencesRepo: preferencesRepo,
		interactionRepo: interactionRepo,
		similarityRepo:  similarityRepo,
		cacheRepo:       cacheRepo,
		feedbackRepo:    feedbackRepo,
		vectorRepo:      vectorRepo,
		bookRepo:        bookRepo,
		progressRepo:    progressRepo,
		config:          config,
	}
}

// GetRecommendations generates personalized book recommendations
func (s *recommendationService) GetRecommendations(ctx context.Context, userID uuid.UUID, req *dto.RecommendationRequest) (*dto.RecommendationResponse, error) {
	s.logger.Info("Generating recommendations for user")

	if err := s.ValidateStruct(req); err != nil {
		return nil, err
	}

	// Set defaults
	if req.Count == 0 {
		req.Count = 10
	}

	// Check cache first
	if s.config.CacheEnabled {
		cached, err := s.getCachedRecommendations(ctx, userID, req.RecommendationType)
		if err == nil && cached != nil {
			return s.convertCacheToResponse(cached, req), nil
		}
	}

	// Generate recommendations based on type
	var recommendations []*domain.BookRecommendation
	var algorithmUsed string
	var err error

	switch req.RecommendationType {
	case "content_based":
		recommendations, err = s.generateContentBasedRecommendations(ctx, userID, req)
		algorithmUsed = "content_based"
	case "collaborative":
		recommendations, err = s.generateCollaborativeRecommendations(ctx, userID, req)
		algorithmUsed = "collaborative_filtering"
	case "hybrid":
		recommendations, err = s.generateHybridRecommendations(ctx, userID, req)
		algorithmUsed = "hybrid"
	case "trending":
		recommendations, err = s.generateTrendingRecommendations(ctx, userID, req)
		algorithmUsed = "trending"
	case "personalized":
		recommendations, err = s.generatePersonalizedRecommendations(ctx, userID, req)
		algorithmUsed = "personalized_hybrid"
	default:
		return nil, fmt.Errorf("unsupported recommendation type: %s", req.RecommendationType)
	}

	if err != nil {
		s.logger.Error("Failed to generate recommendations")
		return nil, fmt.Errorf("failed to generate recommendations: %w", err)
	}

	// Apply filters and ranking
	recommendations = s.applyFilters(recommendations, req.Filters)
	recommendations = s.ensureDiversity(recommendations)
	recommendations = s.rankRecommendations(recommendations)

	// Limit results
	if len(recommendations) > req.Count {
		recommendations = recommendations[:req.Count]
	}

	// Cache results
	if s.config.CacheEnabled {
		s.cacheRecommendations(ctx, userID, req.RecommendationType, recommendations, req)
	}

	// Convert to response
	response := &dto.RecommendationResponse{
		Recommendations: s.convertToBookRecommendations(recommendations),
		TotalCount:      len(recommendations),
		AlgorithmUsed:   algorithmUsed,
		GeneratedAt:     time.Now(),
		ExpiresAt:       time.Now().Add(time.Duration(s.config.CacheTTLHours) * time.Hour),
		Context:         req.Context,
	}

	if req.IncludeExplanations {
		response.Explanations = s.generateExplanations(recommendations, algorithmUsed)
	}

	return response, nil
}

// GetUserPreferences retrieves user's recommendation preferences
func (s *recommendationService) GetUserPreferences(ctx context.Context, userID uuid.UUID) (*dto.UserPreferencesResponse, error) {
	s.logger.Info("Getting user preferences")

	prefs, err := s.preferencesRepo.GetByUserID(ctx, userID)
	if err != nil {
		s.logger.Error("Failed to get user preferences")
		return nil, fmt.Errorf("failed to get user preferences: %w", err)
	}

	// Create default preferences if none exist
	if prefs == nil {
		prefs, err = s.createDefaultPreferences(ctx, userID)
		if err != nil {
			return nil, fmt.Errorf("failed to create default preferences: %w", err)
		}
	}

	return &dto.UserPreferencesResponse{
		UserID:                 prefs.UserID,
		PreferredGenres:        prefs.PreferredGenres,
		PreferredAuthors:       prefs.PreferredAuthors,
		PreferredEpochs:        prefs.PreferredEpochs,
		PreferredDifficulties:  prefs.PreferredDifficulties,
		PreferredReadingLength: prefs.PreferredReadingLength,
		MinRating:              prefs.MinRating,
		MaxWordCount:           prefs.MaxWordCount,
		ExcludeCompleted:       prefs.ExcludeCompleted,
		ExcludeAbandoned:       prefs.ExcludeAbandoned,
		DiscoveryMode:          prefs.DiscoveryMode,
		CreatedAt:              prefs.CreatedAt,
		UpdatedAt:              prefs.UpdatedAt,
	}, nil
}

// UpdateUserPreferences updates user's recommendation preferences
func (s *recommendationService) UpdateUserPreferences(ctx context.Context, userID uuid.UUID, req *dto.UpdatePreferencesRequest) (*dto.UserPreferencesResponse, error) {
	s.logger.Info("Updating user preferences")

	if err := s.ValidateStruct(req); err != nil {
		return nil, err
	}

	// Get existing preferences
	prefs, err := s.preferencesRepo.GetByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get existing preferences: %w", err)
	}

	if prefs == nil {
		prefs, err = s.createDefaultPreferences(ctx, userID)
		if err != nil {
			return nil, fmt.Errorf("failed to create default preferences: %w", err)
		}
	}

	// Update fields that are provided
	if req.PreferredGenres != nil {
		prefs.PreferredGenres = req.PreferredGenres
	}
	if req.PreferredAuthors != nil {
		prefs.PreferredAuthors = req.PreferredAuthors
	}
	if req.PreferredEpochs != nil {
		prefs.PreferredEpochs = req.PreferredEpochs
	}
	if req.PreferredDifficulties != nil {
		prefs.PreferredDifficulties = req.PreferredDifficulties
	}
	if req.PreferredReadingLength != nil {
		prefs.PreferredReadingLength = *req.PreferredReadingLength
	}
	if req.MinRating != nil {
		prefs.MinRating = *req.MinRating
	}
	if req.MaxWordCount != nil {
		prefs.MaxWordCount = req.MaxWordCount
	}
	if req.ExcludeCompleted != nil {
		prefs.ExcludeCompleted = *req.ExcludeCompleted
	}
	if req.ExcludeAbandoned != nil {
		prefs.ExcludeAbandoned = *req.ExcludeAbandoned
	}
	if req.DiscoveryMode != nil {
		prefs.DiscoveryMode = *req.DiscoveryMode
	}

	prefs.UpdatedAt = time.Now()

	// Save updated preferences
	err = s.preferencesRepo.Update(ctx, prefs)
	if err != nil {
		s.logger.Error("Failed to update user preferences")
		return nil, fmt.Errorf("failed to update user preferences: %w", err)
	}

	// Invalidate recommendation cache
	s.InvalidateRecommendationCache(ctx, userID)

	return s.GetUserPreferences(ctx, userID)
}

// RecordFeedback records user feedback on recommendations
func (s *recommendationService) RecordFeedback(ctx context.Context, userID uuid.UUID, req *dto.RecommendationFeedbackRequest) error {
	s.logger.Info("Recording recommendation feedback")

	if err := s.ValidateStruct(req); err != nil {
		return err
	}

	feedback := &domain.RecommendationFeedback{
		ID:                uuid.New(),
		UserID:            userID,
		BookID:            req.BookID,
		RecommendationID:  req.RecommendationID,
		FeedbackType:      req.FeedbackType,
		FeedbackValue:     req.FeedbackValue,
		PositionInList:    req.PositionInList,
		TimeToActionSec:   req.TimeToActionSec,
		ContextData:       req.Context,
		CreatedAt:         time.Now(),
	}

	err := s.feedbackRepo.Create(ctx, feedback)
	if err != nil {
		s.logger.Error("Failed to record feedback")
		return fmt.Errorf("failed to record feedback: %w", err)
	}

	// Record as user interaction as well
	s.recordInteractionFromFeedback(ctx, userID, req)

	return nil
}

// Private helper methods

func (s *recommendationService) generateContentBasedRecommendations(ctx context.Context, userID uuid.UUID, req *dto.RecommendationRequest) ([]*domain.BookRecommendation, error) {
	// Get user's reading history and preferences
	interactions, err := s.interactionRepo.GetMostInteractedBooks(ctx, userID, 20)
	if err != nil {
		return nil, err
	}

	if len(interactions) == 0 {
		// New user - return popular books
		return s.generateTrendingRecommendations(ctx, userID, req)
	}

	var recommendations []*domain.BookRecommendation

	// For each highly-rated book, find similar books
	for _, interaction := range interactions[:min(5, len(interactions))] {
		if interaction.Score > 0.7 { // Only use books user liked
			similarBooks, err := s.vectorRepo.GetSimilarBooks(ctx, interaction.BookID, 5, "content")
			if err != nil {
				continue
			}

			for _, similar := range similarBooks {
				book, err := s.bookRepo.GetByID(ctx, similar.BookID)
				if err != nil || book == nil {
					continue
				}

				score := similar.Similarity * interaction.Score * s.config.ContentWeight
				
				recommendation := &domain.BookRecommendation{
					Book:           book,
					Score:          score,
					Reasoning:      []string{fmt.Sprintf("Similar to %s which you enjoyed", getBookTitle(interaction.BookID))},
					SimilarityType: "content",
					MatchFactors:   map[string]float64{"content_similarity": similar.Similarity, "user_rating": interaction.Score},
					Confidence:     score,
				}

				recommendations = append(recommendations, recommendation)
			}
		}
	}

	return recommendations, nil
}

func (s *recommendationService) generateCollaborativeRecommendations(ctx context.Context, userID uuid.UUID, req *dto.RecommendationRequest) ([]*domain.BookRecommendation, error) {
	// Get similar users
	similarUsers, err := s.similarityRepo.GetSimilarUsers(ctx, userID, 10)
	if err != nil {
		return nil, err
	}

	if len(similarUsers) == 0 {
		// No similar users found - fall back to content-based
		return s.generateContentBasedRecommendations(ctx, userID, req)
	}

	var recommendations []*domain.BookRecommendation
	bookScores := make(map[int64]float64)
	bookCounts := make(map[int64]int)

	// Aggregate recommendations from similar users
	for _, similarUser := range similarUsers {
		interactions, err := s.interactionRepo.GetMostInteractedBooks(ctx, similarUser.UserAID, 10)
		if err != nil {
			continue
		}

		for _, interaction := range interactions {
			if interaction.Score > 0.6 { // Only consider books they liked
				weight := similarUser.SimilarityScore * s.config.CollaborativeWeight
				bookScores[interaction.BookID] += interaction.Score * weight
				bookCounts[interaction.BookID]++
			}
		}
	}

	// Convert to recommendations
	for bookID, score := range bookScores {
		if bookCounts[bookID] >= 2 { // At least 2 similar users liked it
			book, err := s.bookRepo.GetByID(ctx, bookID)
			if err != nil || book == nil {
				continue
			}

			avgScore := score / float64(bookCounts[bookID])
			
			recommendation := &domain.BookRecommendation{
				Book:           book,
				Score:          avgScore,
				Reasoning:      []string{fmt.Sprintf("Recommended by %d users with similar taste", bookCounts[bookID])},
				SimilarityType: "collaborative",
				MatchFactors:   map[string]float64{"collaborative_score": avgScore, "recommender_count": float64(bookCounts[bookID])},
				Confidence:     avgScore,
			}

			recommendations = append(recommendations, recommendation)
		}
	}

	return recommendations, nil
}

func (s *recommendationService) generateHybridRecommendations(ctx context.Context, userID uuid.UUID, req *dto.RecommendationRequest) ([]*domain.BookRecommendation, error) {
	// Get both content-based and collaborative recommendations
	contentRecs, err := s.generateContentBasedRecommendations(ctx, userID, req)
	if err != nil {
		contentRecs = []*domain.BookRecommendation{}
	}

	collabRecs, err := s.generateCollaborativeRecommendations(ctx, userID, req)
	if err != nil {
		collabRecs = []*domain.BookRecommendation{}
	}

	// Combine and rerank
	combinedRecs := make(map[int64]*domain.BookRecommendation)

	// Add content-based recommendations
	for _, rec := range contentRecs {
		combinedRecs[rec.Book.ID] = rec
	}

	// Merge collaborative recommendations
	for _, rec := range collabRecs {
		if existing, exists := combinedRecs[rec.Book.ID]; exists {
			// Combine scores
			existing.Score = (existing.Score + rec.Score) / 2
			existing.Reasoning = append(existing.Reasoning, rec.Reasoning...)
			existing.SimilarityType = "hybrid"
		} else {
			combinedRecs[rec.Book.ID] = rec
		}
	}

	// Convert back to slice
	var recommendations []*domain.BookRecommendation
	for _, rec := range combinedRecs {
		recommendations = append(recommendations, rec)
	}

	return recommendations, nil
}

func (s *recommendationService) generateTrendingRecommendations(ctx context.Context, userID uuid.UUID, req *dto.RecommendationRequest) ([]*domain.BookRecommendation, error) {
	// For now, return highly-rated popular books
	// In a real system, this would use time-weighted popularity metrics
	
	filter := &domain.BookFilter{
		MinRating: floatPtr(4.0),
		IsActive:  boolPtr(true),
	}

	searchReq := &domain.BookSearchRequest{
		Filter: filter,
		SortBy: domain.SortByPopularity,
		Limit:  req.Count * 2, // Get more to allow for filtering
		Offset: 0,
	}

	books, _, err := s.bookRepo.List(context.Background(), searchReq)
	if err != nil {
		return nil, err
	}

	var recommendations []*domain.BookRecommendation
	for _, book := range books {
		score := s.calculatePopularityScore(book)
		
		recommendation := &domain.BookRecommendation{
			Book:           book,
			Score:          score,
			Reasoning:      []string{"Popular and highly-rated"},
			SimilarityType: "trending",
			MatchFactors:   map[string]float64{"popularity": float64(book.DownloadCount), "rating": book.RatingAverage},
			Confidence:     score,
		}

		recommendations = append(recommendations, recommendation)
	}

	return recommendations, nil
}

func (s *recommendationService) generatePersonalizedRecommendations(ctx context.Context, userID uuid.UUID, req *dto.RecommendationRequest) ([]*domain.BookRecommendation, error) {
	// Get user preferences
	prefs, err := s.preferencesRepo.GetByUserID(ctx, userID)
	if err != nil {
		return nil, err
	}

	// Adjust algorithm weights based on user's discovery mode
	config := *s.config // Copy
	if prefs != nil {
		switch prefs.DiscoveryMode {
		case "conservative":
			config.ContentWeight = 0.6
			config.CollaborativeWeight = 0.3
			config.NoveltyWeight = 0.05
			config.PopularityWeight = 0.05
		case "adventurous":
			config.ContentWeight = 0.2
			config.CollaborativeWeight = 0.2
			config.NoveltyWeight = 0.4
			config.PopularityWeight = 0.2
		default: // balanced
			// Use default weights
		}
	}

	// Generate hybrid recommendations with personalized weights
	originalConfig := s.config
	s.config = &config
	defer func() { s.config = originalConfig }()

	return s.generateHybridRecommendations(ctx, userID, req)
}

func (s *recommendationService) applyFilters(recommendations []*domain.BookRecommendation, filters *dto.RecommendationFilters) []*domain.BookRecommendation {
	if filters == nil {
		return recommendations
	}

	var filtered []*domain.BookRecommendation
	for _, rec := range recommendations {
		if s.passesFilters(rec.Book, filters) {
			filtered = append(filtered, rec)
		}
	}

	return filtered
}

func (s *recommendationService) passesFilters(book *domain.Book, filters *dto.RecommendationFilters) bool {
	// Check genres
	if len(filters.Genres) > 0 && book.Genre != nil {
		found := false
		for _, genre := range filters.Genres {
			if *book.Genre == genre {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}

	// Check minimum rating
	if filters.MinRating != nil && book.RatingAverage < *filters.MinRating {
		return false
	}

	// Check word count limits
	if filters.MinWordCount != nil && book.WordCount < *filters.MinWordCount {
		return false
	}
	if filters.MaxWordCount != nil && book.WordCount > *filters.MaxWordCount {
		return false
	}

	// Check difficulty levels
	if len(filters.DifficultyLevels) > 0 {
		found := false
		for _, level := range filters.DifficultyLevels {
			if book.DifficultyLevel == level {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}

	// Check premium status
	if !filters.IncludePremium && book.IsPremium {
		return false
	}

	return true
}

func (s *recommendationService) ensureDiversity(recommendations []*domain.BookRecommendation) []*domain.BookRecommendation {
	if len(recommendations) <= 1 {
		return recommendations
	}

	var diverse []*domain.BookRecommendation
	genreCounts := make(map[string]int)
	authorCounts := make(map[string]int)

	// Sort by score first
	sort.Slice(recommendations, func(i, j int) bool {
		return recommendations[i].Score > recommendations[j].Score
	})

	for _, rec := range recommendations {
		genre := "unknown"
		if rec.Book.Genre != nil {
			genre = *rec.Book.Genre
		}

		// Apply diversity constraints
		if genreCounts[genre] >= 3 { // Max 3 books per genre
			continue
		}
		if authorCounts[rec.Book.Author] >= 2 { // Max 2 books per author
			continue
		}

		diverse = append(diverse, rec)
		genreCounts[genre]++
		authorCounts[rec.Book.Author]++
	}

	return diverse
}

func (s *recommendationService) rankRecommendations(recommendations []*domain.BookRecommendation) []*domain.BookRecommendation {
	// Final ranking combining score with other factors
	for _, rec := range recommendations {
		finalScore := rec.Score
		
		// Boost newer books slightly
		daysSinceCreation := time.Since(rec.Book.CreatedAt).Hours() / 24
		if daysSinceCreation < 30 { // Books newer than 30 days
			finalScore *= 1.1
		}

		// Boost books with more ratings (reliability)
		if rec.Book.RatingCount > 10 {
			finalScore *= 1.05
		}

		rec.Score = finalScore
	}

	// Sort by final score
	sort.Slice(recommendations, func(i, j int) bool {
		return recommendations[i].Score > recommendations[j].Score
	})

	return recommendations
}

func (s *recommendationService) calculatePopularityScore(book *domain.Book) float64 {
	// Combine download count and rating
	downloadScore := math.Log(float64(book.DownloadCount + 1)) / 10.0 // Log scale
	ratingScore := book.RatingAverage / 5.0
	
	return (downloadScore + ratingScore) / 2.0
}

func (s *recommendationService) createDefaultPreferences(ctx context.Context, userID uuid.UUID) (*domain.UserPreferences, error) {
	now := time.Now()
	prefs := &domain.UserPreferences{
		ID:                     uuid.New(),
		UserID:                 userID,
		PreferredGenres:        []string{},
		PreferredAuthors:       []string{},
		PreferredEpochs:        []string{},
		PreferredDifficulties:  []int{1, 2, 3},
		PreferredReadingLength: "any",
		MinRating:              0.0,
		ExcludeCompleted:       true,
		ExcludeAbandoned:       true,
		DiscoveryMode:          "balanced",
		CreatedAt:              now,
		UpdatedAt:              now,
	}

	err := s.preferencesRepo.Create(ctx, prefs)
	if err != nil {
		return nil, err
	}

	return prefs, nil
}

func (s *recommendationService) convertToBookRecommendations(recommendations []*domain.BookRecommendation) []dto.BookRecommendation {
	var result []dto.BookRecommendation
	for _, rec := range recommendations {
		result = append(result, dto.BookRecommendation{
			BookID:          rec.Book.ID,
			Title:           rec.Book.Title,
			Author:          rec.Book.Author,
			Genre:           rec.Book.Genre,
			Epoch:           rec.Book.Epoch,
			WordCount:       rec.Book.WordCount,
			DifficultyLevel: rec.Book.DifficultyLevel,
			RatingAverage:   rec.Book.RatingAverage,
			RatingCount:     rec.Book.RatingCount,
			IsPremium:       rec.Book.IsPremium,
			Score:           rec.Score,
			Reasoning:       rec.Reasoning,
			SimilarityType:  &rec.SimilarityType,
			MatchFactors:    rec.MatchFactors,
		})
	}
	return result
}

func (s *recommendationService) recordInteractionFromFeedback(ctx context.Context, userID uuid.UUID, req *dto.RecommendationFeedbackRequest) {
	// Convert feedback to interaction score
	var score float64
	switch req.FeedbackType {
	case "like":
		score = 0.8
	case "dislike":
		score = 0.2
	case "click":
		score = 0.3
	case "view":
		score = 0.1
	case "start":
		score = 0.4
	case "complete":
		score = 0.9
	case "rate":
		if req.FeedbackValue != nil {
			score = (*req.FeedbackValue + 1.0) / 2.0 // Convert -1,1 to 0,1
		} else {
			score = 0.5
		}
	default:
		score = 0.1
	}

	interaction := &domain.UserInteraction{
		ID:              uuid.New(),
		UserID:          userID,
		BookID:          req.BookID,
		InteractionType: req.FeedbackType,
		InteractionValue: &score,
		ContextData:     req.Context,
		CreatedAt:       time.Now(),
	}

	s.interactionRepo.Create(ctx, interaction)
}

// Utility functions
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func floatPtr(f float64) *float64 {
	return &f
}

func boolPtr(b bool) *bool {
	return &b
}

func getBookTitle(bookID int64) string {
	// In a real implementation, this would look up the book title
	return fmt.Sprintf("Book #%d", bookID)
}

// Stub implementations for remaining methods

func (s *recommendationService) GetSimilarBooks(ctx context.Context, req *dto.SimilarBooksRequest) (*dto.RecommendationResponse, error) {
	s.logger.Info("Getting similar books")

	if err := s.ValidateStruct(req); err != nil {
		return nil, err
	}

	// Get similar books using vector repository
	similarBooks, err := s.vectorRepo.GetSimilarBooks(ctx, req.BookID, req.Count, req.SimilarityType)
	if err != nil {
		return nil, fmt.Errorf("failed to get similar books: %w", err)
	}

	var recommendations []*domain.BookRecommendation
	for _, similar := range similarBooks {
		book, err := s.bookRepo.GetByID(ctx, similar.BookID)
		if err != nil || book == nil {
			continue
		}

		recommendation := &domain.BookRecommendation{
			Book:           book,
			Score:          similar.Similarity,
			Reasoning:      []string{fmt.Sprintf("%.0f%% content similarity", similar.Similarity*100)},
			SimilarityType: req.SimilarityType,
			MatchFactors:   map[string]float64{"similarity": similar.Similarity},
			Confidence:     similar.Similarity,
		}

		recommendations = append(recommendations, recommendation)
	}

	// Apply filters if provided
	if req.Filters != nil {
		recommendations = s.applyFilters(recommendations, req.Filters)
	}

	return &dto.RecommendationResponse{
		Recommendations: s.convertToBookRecommendations(recommendations),
		TotalCount:      len(recommendations),
		AlgorithmUsed:   fmt.Sprintf("similar_books_%s", req.SimilarityType),
		GeneratedAt:     time.Now(),
		ExpiresAt:       time.Now().Add(24 * time.Hour),
	}, nil
}

func (s *recommendationService) GetRecommendationInsights(ctx context.Context, userID uuid.UUID) (*dto.RecommendationInsightsResponse, error) {
	s.logger.Info("Getting recommendation insights")

	// Get user interactions for analysis
	interactions, err := s.interactionRepo.GetByUserID(ctx, userID, 100, 0)
	if err != nil {
		return nil, fmt.Errorf("failed to get user interactions: %w", err)
	}

	// Analyze reading patterns
	genreCount := make(map[string]int)
	totalBooks := len(interactions)
	avgRating := 0.0

	for _, interaction := range interactions {
		if interaction.InteractionValue != nil {
			avgRating += *interaction.InteractionValue
		}
	}
	if totalBooks > 0 {
		avgRating /= float64(totalBooks)
	}

	// Mock insights - in a real system this would be more sophisticated
	dominantGenres := make([]string, 0)
	for genre := range genreCount {
		dominantGenres = append(dominantGenres, genre)
		if len(dominantGenres) >= 3 {
			break
		}
	}

	return &dto.RecommendationInsightsResponse{
		UserReadingProfile: dto.UserReadingProfile{
			DominantGenres:      dominantGenres,
			PreferredDifficulty: "medium",
			TypicalReadingLength: "medium",
			ReadingPace:         "medium",
			ExplorationLevel:    "balanced",
			Consistency:         0.7,
			DiversityScore:      0.6,
		},
		TrendingGenres: []dto.TrendingItem{
			{Name: "現代小説", Score: 0.9, Growth: 15.5, BookCount: 245},
			{Name: "古典文学", Score: 0.8, Growth: 8.2, BookCount: 189},
		},
		PersonalizedTips: []string{
			"あなたの読書パターンから、朝の時間帯に短編作品を読むことをお勧めします",
			"新しいジャンルを探索することで、読書体験がより豊かになります",
		},
		ExplorationSuggestions: []dto.ExplorationSuggestion{
			{Type: "genre", Value: "SF小説", Reason: "現在のお気に入りと関連性が高い", Confidence: 0.8, BookCount: 67},
		},
		ReadingGoalSuggestions: []string{
			"今月は3冊の本を読んでみましょう",
			"新しい作家の作品に挑戦してみませんか",
		},
	}, nil
}

func (s *recommendationService) RecalculateUserSimilarities(ctx context.Context, userID uuid.UUID) error {
	s.logger.Info("Recalculating user similarities")

	// In a real implementation, this would:
	// 1. Get user's interaction history
	// 2. Calculate similarities with other users
	// 3. Store the results in user_similarities table
	// For now, just return success

	return s.similarityRepo.CalculateAndStoreSimilarities(ctx, userID)
}

func (s *recommendationService) UpdateBookVectors(ctx context.Context, bookID int64) error {
	s.logger.Info("Updating book vectors")

	// In a real implementation, this would:
	// 1. Extract features from book content
	// 2. Generate ML embeddings
	// 3. Update the book_vectors table
	// For now, just return success

	return nil
}

func (s *recommendationService) InvalidateRecommendationCache(ctx context.Context, userID uuid.UUID) error {
	s.logger.Info("Invalidating recommendation cache")

	return s.cacheRepo.InvalidateUserCache(ctx, userID)
}

func (s *recommendationService) getCachedRecommendations(ctx context.Context, userID uuid.UUID, recType string) (*domain.RecommendationCache, error) {
	cached, err := s.cacheRepo.GetByUserIDAndType(ctx, userID, recType)
	if err != nil {
		return nil, err
	}

	// Check if cache is still valid
	if cached != nil && time.Now().After(cached.ExpiresAt) {
		s.cacheRepo.Delete(ctx, cached.ID)
		return nil, nil
	}

	return cached, nil
}

func (s *recommendationService) convertCacheToResponse(cache *domain.RecommendationCache, req *dto.RecommendationRequest) *dto.RecommendationResponse {
	// Convert cached results to response format
	var bookRecs []dto.BookRecommendation

	for i, bookID := range cache.BookIDs {
		score := 0.5 // default score
		if i < len(cache.Scores) {
			score = float64(cache.Scores[i])
		}

		// In a real implementation, we'd fetch book details
		bookRecs = append(bookRecs, dto.BookRecommendation{
			BookID: bookID,
			Score:  score,
		})

		if len(bookRecs) >= req.Count {
			break
		}
	}

	return &dto.RecommendationResponse{
		Recommendations: bookRecs,
		TotalCount:      len(bookRecs),
		AlgorithmUsed:   cache.RecommendationType,
		GeneratedAt:     cache.CreatedAt,
		ExpiresAt:       cache.ExpiresAt,
	}
}

func (s *recommendationService) cacheRecommendations(ctx context.Context, userID uuid.UUID, recType string, recommendations []*domain.BookRecommendation, req *dto.RecommendationRequest) {
	if len(recommendations) == 0 {
		return
	}

	bookIDs := make([]int64, len(recommendations))
	scores := make([]float64, len(recommendations))

	for i, rec := range recommendations {
		bookIDs[i] = rec.Book.ID
		scores[i] = rec.Score
	}

	cache := &domain.RecommendationCache{
		ID:                 uuid.New(),
		UserID:             userID,
		RecommendationType: recType,
		BookIDs:            bookIDs,
		Scores:             scores,
		ExpiresAt:          time.Now().Add(time.Duration(s.config.CacheTTLHours) * time.Hour),
		CreatedAt:          time.Now(),
	}

	s.cacheRepo.Create(ctx, cache)
}

func (s *recommendationService) generateExplanations(recommendations []*domain.BookRecommendation, algorithmUsed string) map[string]string {
	explanations := map[string]string{
		"algorithm": algorithmUsed,
		"note":      "これらの推薦は、あなたの読書履歴と好みに基づいてパーソナライズされています",
	}

	switch algorithmUsed {
	case "content_based":
		explanations["method"] = "あなたが過去に高評価した本と類似したコンテンツの本を推薦しています"
	case "collaborative_filtering":
		explanations["method"] = "あなたと似た読書嗜好を持つユーザーが好んだ本を推薦しています"
	case "hybrid":
		explanations["method"] = "コンテンツベースと協調フィルタリングを組み合わせた高精度な推薦です"
	case "trending":
		explanations["method"] = "現在人気上昇中の高評価本を推薦しています"
	case "personalized_hybrid":
		explanations["method"] = "あなたの発見モードに最適化された個人向け推薦です"
	}

	return explanations
}