package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"go.uber.org/zap"

	"github.com/ponyo877/roudoku/server/handlers"
	"github.com/ponyo877/roudoku/server/internal/config"
	"github.com/ponyo877/roudoku/server/internal/database"
	"github.com/ponyo877/roudoku/server/middleware"
	"github.com/ponyo877/roudoku/server/repository"
	"github.com/ponyo877/roudoku/server/services"
)

func main() {
	// Initialize logger
	logger, err := zap.NewProduction()
	if err != nil {
		log.Fatalf("Failed to initialize logger: %v", err)
	}
	defer logger.Sync()

	// Load configuration
	cfg := config.Load()

	// Connect to database
	db, err := database.Connect(cfg.Database)
	if err != nil {
		logger.Fatal("Failed to connect to database", zap.Error(err))
	}
	defer db.Close()

	// Initialize repositories
	bookRepo := repository.NewPostgresBookRepository(db)
	userRepo := repository.NewPostgresUserRepository(db)
	swipeRepo := repository.NewPostgresSwipeRepository(db)
	sessionRepo := repository.NewPostgresSessionRepository(db)
	ratingRepo := repository.NewPostgresRatingRepository(db)

	// Initialize services using factory
	serviceFactory := services.NewServiceFactory(logger)
	serviceContainer := serviceFactory.CreateServices(bookRepo, userRepo, ratingRepo, sessionRepo, swipeRepo)

	// Initialize handlers
	bookHandler := handlers.NewBookHandler(serviceContainer.BookService)
	userHandler := handlers.NewUserHandler(serviceContainer.UserService)
	swipeHandler := handlers.NewSwipeHandler(serviceContainer.SwipeService)
	sessionHandler := handlers.NewSessionHandler(serviceContainer.SessionService)
	ratingHandler := handlers.NewRatingHandler(serviceContainer.RatingService)
	recommendationHandler := handlers.NewRecommendationHandler(serviceContainer.RecommendationService)
	ttsHandler := handlers.NewTTSHandler()
	defer ttsHandler.Close()

	// Setup routes
	router := mux.NewRouter()
	
	// Add middleware
	router.Use(middleware.CORSMiddleware)
	router.Use(middleware.LoggingMiddleware)
	router.Use(middleware.RecoveryMiddleware)
	
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

	// Recommendation routes (integrated from recommendation service)
	api.HandleFunc("/users/{user_id}/recommendations", recommendationHandler.GetRecommendations).Methods("GET")
	api.HandleFunc("/users/{user_id}/recommendations/train", recommendationHandler.TrainModel).Methods("POST")
	api.HandleFunc("/users/{user_id}/recommendations/stats", recommendationHandler.GetRecommendationStats).Methods("GET")

	// TTS routes
	api.HandleFunc("/tts/synthesize", ttsHandler.SynthesizeSpeech).Methods("POST")
	api.HandleFunc("/tts/voices", ttsHandler.GetAvailableVoices).Methods("GET")
	
	// Audio generation routes
	api.HandleFunc("/audio/generate", handlers.GenerateBookAudio).Methods("POST")
	api.HandleFunc("/audio/book", handlers.GetBookAudio).Methods("GET")
	api.HandleFunc("/audio/regenerate", handlers.RegenerateAllBookAudio).Methods("POST")
	api.HandleFunc("/audio/files/{filename}", handlers.ServeAudioFile).Methods("GET")
	
	// Content management routes
	api.HandleFunc("/content/initialize", handlers.InitializeAllContent).Methods("POST")
	api.HandleFunc("/content/status", handlers.GetContentStatus).Methods("GET")
	
	// Cloud Storage routes
	api.HandleFunc("/storage/upload", handlers.UploadAudioToCloudStorage).Methods("POST")
	api.HandleFunc("/storage/sync", handlers.SyncAllAudioToCloudStorage).Methods("POST")
	api.HandleFunc("/storage/audio", handlers.GetAudioFromCloudStorage).Methods("GET")
	api.HandleFunc("/storage/status", handlers.GetCloudStorageStatus).Methods("GET")

	// Health check
	api.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		response := map[string]interface{}{
			"status":   "ok",
			"services": []string{"api", "recommendations", "tts"},
			"version":  "1.0.0",
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(response)
	}).Methods("GET")

	log.Printf("Server starting on port %s", cfg.Port)
	log.Fatal(http.ListenAndServe(":"+cfg.Port, router))
}
