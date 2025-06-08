package main

import (
	"context"
	"log"
	"net/http"

	"github.com/gorilla/mux"

	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/handlers"
	"github.com/ponyo877/roudoku/server/services"
)

// mockBookRepository implements BookRepository for testing without database
type mockBookRepository struct{}

func (m *mockBookRepository) Create(ctx context.Context, book *domain.Book) error { return nil }
func (m *mockBookRepository) GetByID(ctx context.Context, id int64) (*domain.Book, error) {
	return &domain.Book{ID: id, Title: "Test Book", Author: "Test Author"}, nil
}
func (m *mockBookRepository) Update(ctx context.Context, book *domain.Book) error { return nil }
func (m *mockBookRepository) Delete(ctx context.Context, id int64) error          { return nil }
func (m *mockBookRepository) List(ctx context.Context, req *domain.BookSearchRequest) ([]*domain.Book, int, error) {
	books := []*domain.Book{
		{ID: 1, Title: "テスト本1", Author: "著者1"},
		{ID: 2, Title: "テスト本2", Author: "著者2"},
	}
	return books, 2, nil
}
func (m *mockBookRepository) CreateChapter(ctx context.Context, chapter *domain.Chapter) error {
	return nil
}
func (m *mockBookRepository) GetChaptersByBookID(ctx context.Context, bookID int64) ([]*domain.Chapter, error) {
	return nil, nil
}
func (m *mockBookRepository) CreateQuote(ctx context.Context, quote *domain.Quote) error { return nil }
func (m *mockBookRepository) GetRandomQuotes(ctx context.Context, bookID int64, limit int) ([]*domain.Quote, error) {
	return nil, nil
}

func main() {
	// Initialize mock repository
	bookRepo := &mockBookRepository{}

	// Initialize services
	bookService := services.NewBookService(bookRepo)

	// Initialize handlers
	bookHandler := handlers.NewBookHandler(bookService)

	// Setup routes
	router := mux.NewRouter()
	api := router.PathPrefix("/api/v1").Subrouter()

	// Book routes
	api.HandleFunc("/books", bookHandler.SearchBooks).Methods("GET")
	api.HandleFunc("/books/{id}", bookHandler.GetBook).Methods("GET")

	// Health check
	api.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"ok","message":"Test server running without database"}`))
	}).Methods("GET")

	log.Println("Test server starting on :8080 (without database)")
	log.Fatal(http.ListenAndServe(":8080", router))
}
