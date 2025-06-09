package main

import (
	"log"
	"net/http"

	"github.com/gorilla/mux"

	"github.com/ponyo877/roudoku/server/handlers"
	"github.com/ponyo877/roudoku/server/internal/config"
	"github.com/ponyo877/roudoku/server/internal/database"
	"github.com/ponyo877/roudoku/server/repository"
	"github.com/ponyo877/roudoku/server/services"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Connect to database
	db, err := database.Connect(cfg.Database)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Initialize repositories
	bookRepo := repository.NewPostgresBookRepository(db)
	userRepo := repository.NewPostgresUserRepository(db)
	swipeRepo := repository.NewPostgresSwipeRepository(db)
	sessionRepo := repository.NewPostgresSessionRepository(db)
	ratingRepo := repository.NewPostgresRatingRepository(db)

	// Initialize services
	bookService := services.NewBookService(bookRepo)
	userService := services.NewUserService(userRepo)
	swipeService := services.NewSwipeService(swipeRepo)
	sessionService := services.NewSessionService(sessionRepo)
	ratingService := services.NewRatingService(ratingRepo)

	// Initialize handlers
	bookHandler := handlers.NewBookHandler(bookService)
	userHandler := handlers.NewUserHandler(userService)
	swipeHandler := handlers.NewSwipeHandler(swipeService)
	sessionHandler := handlers.NewSessionHandler(sessionService)
	ratingHandler := handlers.NewRatingHandler(ratingService)
	recommendationHandler := handlers.NewRecommendationHandler(bookService, swipeService, sessionService)

	// Setup routes
	router := mux.NewRouter()
	api := router.PathPrefix("/api/v1").Subrouter()

	// Book routes
	api.HandleFunc("/books", bookHandler.SearchBooks).Methods("GET")
	api.HandleFunc("/books", bookHandler.CreateBook).Methods("POST")
	api.HandleFunc("/books/{id}", bookHandler.GetBook).Methods("GET")
	api.HandleFunc("/books/{id}/quotes/random", bookHandler.GetRandomQuotes).Methods("GET")

	// User routes
	api.HandleFunc("/users", userHandler.CreateUser).Methods("POST")
	api.HandleFunc("/users/{id}", userHandler.GetUser).Methods("GET")
	api.HandleFunc("/users/{id}", userHandler.UpdateUser).Methods("PUT")
	api.HandleFunc("/users/{id}", userHandler.DeleteUser).Methods("DELETE")

	// Swipe routes
	api.HandleFunc("/users/{user_id}/swipes", swipeHandler.CreateSwipeLog).Methods("POST")
	api.HandleFunc("/users/{user_id}/swipes", swipeHandler.GetSwipeLogs).Methods("GET")

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

	// Health check
	api.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"ok","services":["api","recommendations"]}`))
	}).Methods("GET")

	log.Printf("Server starting on port %s", cfg.Port)
	log.Fatal(http.ListenAndServe(":"+cfg.Port, router))
}
