package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gorilla/mux"

	"github.com/ponyo877/roudoku/server/handlers"
	"github.com/ponyo877/roudoku/server/internal/database"
	"github.com/ponyo877/roudoku/server/pkg/config"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/middleware"
	"github.com/ponyo877/roudoku/server/pkg/utils"
	"github.com/ponyo877/roudoku/server/repository"
	"github.com/ponyo877/roudoku/server/services"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize logger
	appLogger, err := logger.New(cfg.Logging)
	if err != nil {
		log.Fatalf("Failed to initialize logger: %v", err)
	}
	defer appLogger.Sync()

	// Connect to database
	dbConfig := database.Config{
		Host:     cfg.Database.Host,
		Port:     cfg.Database.Port,
		Database: cfg.Database.Name,
		Username: cfg.Database.User,
		Password: cfg.Database.Password,
		SSLMode:  cfg.Database.SSLMode,
	}

	db, err := database.Connect(dbConfig)
	if err != nil {
		appLogger.Fatal("Failed to connect to database")
	}
	defer db.Close()

	// Initialize repositories
	bookRepo := repository.NewPostgresBookRepository(db)
	userRepo := repository.NewPostgresUserRepository(db)
	swipeRepo := repository.NewPostgresSwipeRepository(db)
	sessionRepo := repository.NewPostgresSessionRepository(db)
	ratingRepo := repository.NewPostgresRatingRepository(db)
	fcmTokenRepo := repository.NewPostgresFCMTokenRepository(db)
	notificationRepo := repository.NewPostgresNotificationRepository(db)
	analyticsRepo := repository.NewPostgresReadingAnalyticsRepository(db)
	streakRepo := repository.NewPostgresReadingStreakRepository(db)
	goalRepo := repository.NewPostgresReadingGoalRepository(db)
	achievementRepo := repository.NewPostgresAchievementRepository(db)
	userAchievementRepo := repository.NewPostgresUserAchievementRepository(db)
	progressRepo := repository.NewPostgresBookProgressRepository(db)
	contextRepo := repository.NewPostgresReadingContextRepository(db)
	insightRepo := repository.NewPostgresReadingInsightRepository(db)
	
	// Initialize recommendation repositories
	preferencesRepo := repository.NewPostgresUserPreferencesRepository(db)
	interactionRepo := repository.NewPostgresUserInteractionRepository(db)
	similarityRepo := repository.NewPostgresUserSimilarityRepository(db)
	cacheRepo := repository.NewPostgresRecommendationCacheRepository(db)
	feedbackRepo := repository.NewPostgresRecommendationFeedbackRepository(db)
	vectorRepo := repository.NewPostgresBookVectorRepository(db)
	
	// Initialize subscription repositories
	planRepo := repository.NewPostgresSubscriptionPlanRepository(db)
	subscriptionRepo := repository.NewPostgresUserSubscriptionRepository(db)
	usageRepo := repository.NewPostgresUsageTrackingRepository(db)

	// Initialize services
	validationService := services.NewBusinessValidationService(appLogger)
	bookService := services.NewBookService(bookRepo, appLogger)
	userService := services.NewUserService(userRepo, appLogger)
	swipeService := services.NewSwipeService(swipeRepo, validationService, appLogger)
	sessionService := services.NewSessionService(sessionRepo, validationService, appLogger)
	ratingService := services.NewRatingService(ratingRepo, appLogger)

	// Initialize TTS service
	ttsService, err := services.NewTTSService(cfg.TTS.CredentialsPath, appLogger)
	if err != nil {
		appLogger.Fatal("Failed to initialize TTS service")
	}

	// Initialize notification service
	notificationService, err := services.NewNotificationService(
		fcmTokenRepo, notificationRepo, nil, nil, cfg.Firebase.CredentialsPath, appLogger)
	if err != nil {
		appLogger.Fatal("Failed to initialize notification service")
	}

	// Initialize analytics service
	analyticsService := services.NewAnalyticsService(
		analyticsRepo, streakRepo, goalRepo, achievementRepo, userAchievementRepo,
		progressRepo, contextRepo, insightRepo, bookRepo, appLogger)

	// Initialize recommendation service
	recommendationService := services.NewRecommendationService(
		preferencesRepo, interactionRepo, similarityRepo, cacheRepo, feedbackRepo,
		vectorRepo, bookRepo, progressRepo, appLogger)

	// Initialize subscription service
	subscriptionService := services.NewSubscriptionService(
		planRepo, subscriptionRepo, usageRepo, appLogger)

	// Initialize advanced recommendation service
	advancedRecommendationService := services.NewAdvancedRecommendationService(
		recommendationService, interactionRepo, vectorRepo, bookRepo, analyticsRepo, feedbackRepo, cacheRepo, appLogger)

	// Initialize A/B testing service (placeholder repositories needed)
	// experimentRepo := repository.NewPostgresExperimentRepository(db)
	// assignmentRepo := repository.NewPostgresExperimentAssignmentRepository(db)
	// experimentInteractionRepo := repository.NewPostgresExperimentInteractionRepository(db)
	// abTestingService := services.NewABTestingService(experimentRepo, assignmentRepo, experimentInteractionRepo, recommendationService, appLogger)

	// Initialize admin dashboard service
	adminDashboardService := services.NewAdminDashboardService(
		userRepo, bookRepo, subscriptionRepo, analyticsRepo, interactionRepo, feedbackRepo, nil, subscriptionService, appLogger)

	// Initialize authentication middleware
	authMiddleware, err := middleware.NewAuthMiddleware(cfg.Firebase.CredentialsPath, appLogger)
	if err != nil {
		appLogger.Fatal("Failed to initialize auth middleware")
	}

	// Initialize handlers
	bookHandler := handlers.NewBookHandler(bookService, appLogger)
	userHandler := handlers.NewUserHandler(userService, appLogger)
	swipeHandler := handlers.NewSwipeHandler(swipeService, appLogger)
	sessionHandler := handlers.NewSessionHandler(sessionService, appLogger)
	ratingHandler := handlers.NewRatingHandler(ratingService, appLogger)
	recommendationHandler := handlers.NewRecommendationHandler(recommendationService, appLogger)
	subscriptionHandler := handlers.NewSubscriptionHandler(subscriptionService, appLogger)
	ttsHandler := handlers.NewTTSHandler(ttsService, appLogger)
	notificationHandler := handlers.NewNotificationHandler(notificationService, appLogger)
	analyticsHandler := handlers.NewAnalyticsHandler(analyticsService, appLogger)
	adminDashboardHandler := handlers.NewAdminDashboardHandler(adminDashboardService, appLogger)
	advancedRecommendationHandler := handlers.NewAdvancedRecommendationHandler(advancedRecommendationService, appLogger)
	
	// Initialize webhook handler
	webhookHandler := handlers.NewWebhookHandler(subscriptionService, recommendationService, "", appLogger)

	// Setup routes
	router := mux.NewRouter()
	
	// Add middleware
	router.Use(middleware.CORS())
	router.Use(middleware.Logging(appLogger))
	router.Use(middleware.Recovery(appLogger))
	router.Use(middleware.Timeout(cfg.Server.Timeout, appLogger))
	
	api := router.PathPrefix("/api/v1").Subrouter()

	// Book routes
	api.HandleFunc("/books", bookHandler.SearchBooks).Methods("GET")
	api.HandleFunc("/books", bookHandler.CreateBook).Methods("POST")
	api.HandleFunc("/books/{id}", bookHandler.GetBook).Methods("GET")
	api.HandleFunc("/books/{id}/quotes/random", bookHandler.GetRandomQuotes).Methods("GET")
	api.HandleFunc("/books/{id}/chapters", bookHandler.GetBookChapters).Methods("GET")
	api.HandleFunc("/books/{id}/chapters/{chapter_id}", bookHandler.GetChapterContent).Methods("GET")
	api.HandleFunc("/books/recommendations", bookHandler.GetRecommendations).Methods("GET")

	// User routes
	api.HandleFunc("/users", userHandler.CreateUser).Methods("POST")
	api.HandleFunc("/users/{id}", userHandler.GetUser).Methods("GET")
	api.HandleFunc("/users/{id}", userHandler.UpdateUser).Methods("PUT")
	api.HandleFunc("/users/{id}", userHandler.DeleteUser).Methods("DELETE")

	// Swipe routes
	api.HandleFunc("/users/{user_id}/swipes", swipeHandler.CreateSwipeLog).Methods("POST")
	api.HandleFunc("/users/{user_id}/swipes", swipeHandler.GetSwipeLogs).Methods("GET")
	api.HandleFunc("/swipe/log", swipeHandler.CreateSwipeLog).Methods("POST")
	api.HandleFunc("/swipe/log/batch", swipeHandler.CreateSwipeLogBatch).Methods("POST")
	api.HandleFunc("/swipe/stats/{user_id}", swipeHandler.GetSwipeStats).Methods("GET")
	api.HandleFunc("/swipe/history", swipeHandler.GetSwipeHistory).Methods("GET")

	// Reading session routes
	api.HandleFunc("/users/{user_id}/sessions", sessionHandler.CreateReadingSession).Methods("POST")
	api.HandleFunc("/users/{user_id}/sessions", sessionHandler.GetUserReadingSessions).Methods("GET")
	api.HandleFunc("/users/{user_id}/sessions/{session_id}", sessionHandler.GetReadingSession).Methods("GET")
	api.HandleFunc("/users/{user_id}/sessions/{session_id}", sessionHandler.UpdateReadingSession).Methods("PUT")

	// Rating routes
	api.HandleFunc("/users/{user_id}/ratings", ratingHandler.CreateOrUpdateRating).Methods("POST")
	api.HandleFunc("/users/{user_id}/ratings", ratingHandler.GetUserRatings).Methods("GET")
	api.HandleFunc("/users/{user_id}/ratings/{book_id}", ratingHandler.GetRating).Methods("GET")
	api.HandleFunc("/users/{user_id}/ratings/{book_id}", ratingHandler.DeleteRating).Methods("DELETE")

	// Legacy recommendation routes (basic implementation)
	api.HandleFunc("/users/{user_id}/recommendations", func(w http.ResponseWriter, r *http.Request) {
		utils.WriteSuccess(w, map[string]string{"message": "Please use /api/v1/recommendations instead"})
	}).Methods("GET")
	api.HandleFunc("/users/{user_id}/recommendations/train", func(w http.ResponseWriter, r *http.Request) {
		utils.WriteSuccess(w, map[string]string{"message": "Model training handled automatically"})
	}).Methods("POST")
	api.HandleFunc("/users/{user_id}/recommendations/stats", func(w http.ResponseWriter, r *http.Request) {
		utils.WriteSuccess(w, map[string]string{"message": "Please use /api/v1/recommendations/insights instead"})
	}).Methods("GET")

	// TTS routes (require authentication)
	ttsRoutes := api.PathPrefix("/tts").Subrouter()
	ttsRoutes.Use(authMiddleware.RequireAuth())
	ttsRoutes.HandleFunc("/synthesize", ttsHandler.SynthesizeText).Methods("POST")
	ttsRoutes.HandleFunc("/voices", ttsHandler.GetVoices).Methods("GET")
	ttsRoutes.HandleFunc("/preview", ttsHandler.PreviewVoice).Methods("POST")

	// Notification routes (require authentication)
	notificationRoutes := api.PathPrefix("/notifications").Subrouter()
	notificationRoutes.Use(authMiddleware.RequireAuth())
	notificationRoutes.HandleFunc("/tokens", notificationHandler.RegisterFCMToken).Methods("POST")
	notificationRoutes.HandleFunc("/tokens", notificationHandler.GetUserTokens).Methods("GET")
	notificationRoutes.HandleFunc("/tokens/{token_id}", notificationHandler.DeactivateToken).Methods("DELETE")
	notificationRoutes.HandleFunc("/preferences", notificationHandler.GetNotificationPreferences).Methods("GET")
	notificationRoutes.HandleFunc("/preferences", notificationHandler.UpdateNotificationPreferences).Methods("PUT")
	notificationRoutes.HandleFunc("/history", notificationHandler.GetNotificationHistory).Methods("GET")
	notificationRoutes.HandleFunc("/unread", notificationHandler.GetUnreadNotifications).Methods("GET")
	notificationRoutes.HandleFunc("/unread/count", notificationHandler.GetUnreadCount).Methods("GET")
	notificationRoutes.HandleFunc("/{notification_id}/read", notificationHandler.MarkNotificationAsRead).Methods("POST")
	notificationRoutes.HandleFunc("/read-all", notificationHandler.MarkAllNotificationsAsRead).Methods("POST")
	notificationRoutes.HandleFunc("/schedule", notificationHandler.ScheduleNotification).Methods("POST")

	// Admin notification routes (require authentication)
	adminRoutes := api.PathPrefix("/admin").Subrouter()
	adminRoutes.Use(authMiddleware.RequireAuth())
	adminRoutes.HandleFunc("/notifications/send", notificationHandler.SendNotification).Methods("POST")

	// Analytics routes (require authentication)
	analyticsRoutes := api.PathPrefix("/analytics").Subrouter()
	analyticsRoutes.Use(authMiddleware.RequireAuth())
	analyticsRoutes.HandleFunc("/stats", analyticsHandler.GetReadingStats).Methods("GET")
	analyticsRoutes.HandleFunc("/streak", analyticsHandler.GetReadingStreak).Methods("GET")
	analyticsRoutes.HandleFunc("/goals", analyticsHandler.CreateGoal).Methods("POST")
	analyticsRoutes.HandleFunc("/goals", analyticsHandler.GetGoals).Methods("GET")
	analyticsRoutes.HandleFunc("/goals/{goal_id}", analyticsHandler.UpdateGoal).Methods("PUT")
	analyticsRoutes.HandleFunc("/goals/{goal_id}", analyticsHandler.DeleteGoal).Methods("DELETE")
	analyticsRoutes.HandleFunc("/achievements", analyticsHandler.GetAchievements).Methods("GET")
	analyticsRoutes.HandleFunc("/insights", analyticsHandler.GetReadingInsights).Methods("GET")
	analyticsRoutes.HandleFunc("/insights/{insight_id}/read", analyticsHandler.MarkInsightAsRead).Methods("POST")
	analyticsRoutes.HandleFunc("/context", analyticsHandler.RecordReadingContext).Methods("POST")
	analyticsRoutes.HandleFunc("/context/insights", analyticsHandler.GetContextInsights).Methods("GET")

	// Progress routes (require authentication)
	progressRoutes := api.PathPrefix("/progress").Subrouter()
	progressRoutes.Use(authMiddleware.RequireAuth())
	progressRoutes.HandleFunc("/books/{book_id}", analyticsHandler.GetBookProgress).Methods("GET")
	progressRoutes.HandleFunc("/books", analyticsHandler.UpdateBookProgress).Methods("POST")
	progressRoutes.HandleFunc("/books/{book_id}/complete", analyticsHandler.MarkBookAsCompleted).Methods("POST")
	progressRoutes.HandleFunc("/currently-reading", analyticsHandler.GetCurrentlyReading).Methods("GET")

	// AI Recommendation routes (require authentication)
	recommendationRoutes := api.PathPrefix("/recommendations").Subrouter()
	recommendationRoutes.Use(authMiddleware.RequireAuth())
	recommendationRoutes.HandleFunc("", recommendationHandler.GetRecommendations).Methods("GET")
	recommendationRoutes.HandleFunc("/similar/{bookId}", recommendationHandler.GetSimilarBooks).Methods("GET")
	recommendationRoutes.HandleFunc("/preferences", recommendationHandler.GetUserPreferences).Methods("GET")
	recommendationRoutes.HandleFunc("/preferences", recommendationHandler.UpdateUserPreferences).Methods("PUT")
	recommendationRoutes.HandleFunc("/feedback", recommendationHandler.RecordFeedback).Methods("POST")
	recommendationRoutes.HandleFunc("/insights", recommendationHandler.GetRecommendationInsights).Methods("GET")
	recommendationRoutes.HandleFunc("/refresh", recommendationHandler.RefreshRecommendations).Methods("POST")

	// Subscription routes (require authentication)
	subscriptionRoutes := api.PathPrefix("/subscriptions").Subrouter()
	subscriptionRoutes.Use(authMiddleware.RequireAuth())
	subscriptionRoutes.HandleFunc("/plans", subscriptionHandler.GetPlans).Methods("GET")
	subscriptionRoutes.HandleFunc("/plans/{planId}", subscriptionHandler.GetPlan).Methods("GET")
	subscriptionRoutes.HandleFunc("/me", subscriptionHandler.GetUserSubscription).Methods("GET")
	subscriptionRoutes.HandleFunc("", subscriptionHandler.CreateSubscription).Methods("POST")
	subscriptionRoutes.HandleFunc("/me", subscriptionHandler.UpdateSubscription).Methods("PUT")
	subscriptionRoutes.HandleFunc("/me", subscriptionHandler.CancelSubscription).Methods("DELETE")
	subscriptionRoutes.HandleFunc("/usage", subscriptionHandler.GetUsageStats).Methods("GET")
	subscriptionRoutes.HandleFunc("/features/{feature}/access", subscriptionHandler.CheckFeatureAccess).Methods("GET")

	// Webhook routes (no authentication required for external services)
	webhookRoutes := api.PathPrefix("/webhooks").Subrouter()
	webhookRoutes.HandleFunc("/stripe", webhookHandler.StripeWebhook).Methods("POST")
	webhookRoutes.HandleFunc("/paypal", webhookHandler.PayPalWebhook).Methods("POST")
	webhookRoutes.HandleFunc("/ml", webhookHandler.RecommendationWebhook).Methods("POST")

	// Admin Dashboard routes (require authentication)
	adminDashboardRoutes := adminRoutes.PathPrefix("/dashboard").Subrouter()
	adminDashboardRoutes.HandleFunc("/overview", adminDashboardHandler.GetSystemOverview).Methods("GET")
	adminDashboardRoutes.HandleFunc("/metrics/realtime", adminDashboardHandler.GetRealtimeMetrics).Methods("GET")
	adminDashboardRoutes.HandleFunc("/users/statistics", adminDashboardHandler.GetUserStatistics).Methods("POST")
	adminDashboardRoutes.HandleFunc("/users/engagement", adminDashboardHandler.GetUserEngagementMetrics).Methods("GET")
	adminDashboardRoutes.HandleFunc("/books/statistics", adminDashboardHandler.GetBookStatistics).Methods("GET")
	adminDashboardRoutes.HandleFunc("/content/performance", adminDashboardHandler.GetContentPerformance).Methods("POST")
	adminDashboardRoutes.HandleFunc("/recommendations/effectiveness", adminDashboardHandler.GetRecommendationEffectiveness).Methods("GET")
	adminDashboardRoutes.HandleFunc("/recommendations/quality", adminDashboardHandler.GetRecommendationQuality).Methods("GET")
	adminDashboardRoutes.HandleFunc("/revenue/analytics", adminDashboardHandler.GetRevenueAnalytics).Methods("POST")
	adminDashboardRoutes.HandleFunc("/subscriptions/metrics", adminDashboardHandler.GetSubscriptionMetrics).Methods("GET")
	adminDashboardRoutes.HandleFunc("/subscriptions/churn", adminDashboardHandler.GetChurnAnalysis).Methods("GET")
	adminDashboardRoutes.HandleFunc("/system/performance", adminDashboardHandler.GetSystemPerformance).Methods("GET")
	adminDashboardRoutes.HandleFunc("/api/metrics", adminDashboardHandler.GetAPIMetrics).Methods("GET")
	adminDashboardRoutes.HandleFunc("/errors/analysis", adminDashboardHandler.GetErrorAnalysis).Methods("GET")
	adminDashboardRoutes.HandleFunc("/ml/performance", adminDashboardHandler.GetModelPerformance).Methods("GET")

	// Advanced Recommendation routes (require authentication)
	advancedRecRoutes := recommendationRoutes.PathPrefix("/advanced").Subrouter()
	advancedRecRoutes.HandleFunc("/deep-learning", advancedRecommendationHandler.GetDeepLearningRecommendations).Methods("POST")
	advancedRecRoutes.HandleFunc("/contextual", advancedRecommendationHandler.GetContextualRecommendations).Methods("POST")
	advancedRecRoutes.HandleFunc("/sequential/{bookId}", advancedRecommendationHandler.GetSequentialRecommendations).Methods("GET")
	advancedRecRoutes.HandleFunc("/profile/update", advancedRecommendationHandler.UpdateUserProfileRealtime).Methods("POST")
	advancedRecRoutes.HandleFunc("/refresh", advancedRecommendationHandler.TriggerRealtimeRecommendationUpdate).Methods("POST")
	advancedRecRoutes.HandleFunc("/trends", advancedRecommendationHandler.GetRealtimeReadingTrends).Methods("GET")
	advancedRecRoutes.HandleFunc("/multi-objective", advancedRecommendationHandler.GetMultiObjectiveRecommendations).Methods("POST")
	advancedRecRoutes.HandleFunc("/exploration", advancedRecommendationHandler.GetExplorationRecommendations).Methods("GET")
	advancedRecRoutes.HandleFunc("/social", advancedRecommendationHandler.GetSocialRecommendations).Methods("GET")
	advancedRecRoutes.HandleFunc("/group", advancedRecommendationHandler.GetGroupRecommendations).Methods("POST")
	advancedRecRoutes.HandleFunc("/accuracy", advancedRecommendationHandler.CalculateRecommendationAccuracy).Methods("GET")
	advancedRecRoutes.HandleFunc("/performance", advancedRecommendationHandler.GetRecommendationPerformanceMetrics).Methods("GET")

	// Health check
	api.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		response := map[string]any{
			"status":   "ok",
			"services": []string{"api", "database"},
			"version":  "1.0.0",
			"timestamp": time.Now().UTC().Format(time.RFC3339),
		}
		utils.WriteSuccess(w, response)
	}).Methods("GET")

	// Start server with graceful shutdown
	srv := &http.Server{
		Addr:         ":" + cfg.Server.Port,
		Handler:      router,
		ReadTimeout:  cfg.Server.Timeout,
		WriteTimeout: cfg.Server.Timeout,
		IdleTimeout:  cfg.Server.Timeout * 2,
	}

	go func() {
		appLogger.Info(fmt.Sprintf("Server starting on port %s", cfg.Server.Port))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			appLogger.Fatal("Failed to start server")
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	appLogger.Info("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), cfg.Server.ShutdownTimeout)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		appLogger.Fatal("Server forced to shutdown")
	}

	appLogger.Info("Server exited")
}
