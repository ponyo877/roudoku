package main

import (
	"log"
	"net/http"

	"github.com/gorilla/mux"

	"github.com/ponyo877/roudoku/backend2/handlers"
	"github.com/ponyo877/roudoku/backend2/internal/config"
	"github.com/ponyo877/roudoku/backend2/internal/database"
	"github.com/ponyo877/roudoku/backend2/repository"
	"github.com/ponyo877/roudoku/backend2/services"
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
	
	// Initialize services
	bookService := services.NewBookService(bookRepo)
	
	// Initialize handlers
	bookHandler := handlers.NewBookHandler(bookService)
	
	// Setup routes
	router := mux.NewRouter()
	api := router.PathPrefix("/api/v1").Subrouter()
	
	// Book routes
	api.HandleFunc("/books", bookHandler.SearchBooks).Methods("GET")
	api.HandleFunc("/books", bookHandler.CreateBook).Methods("POST")
	api.HandleFunc("/books/{id}", bookHandler.GetBook).Methods("GET")
	api.HandleFunc("/books/{id}/quotes/random", bookHandler.GetRandomQuotes).Methods("GET")
	
	// Health check
	api.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"ok"}`))
	}).Methods("GET")
	
	log.Printf("Server starting on port %s", cfg.Port)
	log.Fatal(http.ListenAndServe(":"+cfg.Port, router))
}