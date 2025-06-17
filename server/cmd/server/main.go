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
		appLogger.Fatal("Failed to connect to database", appLogger.WithError(err))
	}
	defer db.Close()

	// Initialize repositories
	bookRepo := repository.NewPostgresBookRepository(db)
	userRepo := repository.NewPostgresUserRepository(db)
	swipeRepo := repository.NewPostgresSwipeRepository(db)
	sessionRepo := repository.NewPostgresSessionRepository(db)
	ratingRepo := repository.NewPostgresRatingRepository(db)

	// Initialize services
	bookService := services.NewBookService(bookRepo, appLogger)
	userService := services.NewUserService(userRepo, appLogger)
	swipeService := services.NewSwipeService(swipeRepo, appLogger)
	sessionService := services.NewSessionService(sessionRepo, appLogger)
	ratingService := services.NewRatingService(ratingRepo, appLogger)

	// Initialize handlers
	bookHandler := handlers.NewBookHandler(bookService, appLogger)
	userHandler := handlers.NewUserHandler(userService, appLogger)
	swipeHandler := handlers.NewSwipeHandler(swipeService, appLogger)
	sessionHandler := handlers.NewSessionHandler(sessionService, appLogger)
	ratingHandler := handlers.NewRatingHandler(ratingService, appLogger)

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

	// Recommendation routes (integrated from recommendation service)
	api.HandleFunc("/users/{user_id}/recommendations", recommendationHandler.GetRecommendations).Methods("GET")
	api.HandleFunc("/users/{user_id}/recommendations/train", recommendationHandler.TrainModel).Methods("POST")
	api.HandleFunc("/users/{user_id}/recommendations/stats", recommendationHandler.GetRecommendationStats).Methods("GET")

	// TODO: Implement remaining handlers with proper structure
	// TTS, Audio, Content, and Storage handlers need to be refactored

	// Health check
	api.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		response := map[string]interface{}{
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
			appLogger.Fatal("Failed to start server", appLogger.WithError(err))
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
		appLogger.Fatal("Server forced to shutdown", appLogger.WithError(err))
	}

	appLogger.Info("Server exited")
}
