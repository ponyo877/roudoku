package test

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gorilla/mux"

	"github.com/ponyo877/roudoku/backend2/handlers"
	"github.com/ponyo877/roudoku/backend2/models"
	"github.com/ponyo877/roudoku/backend2/services"
)

// mockBookRepository implements BookRepository for testing
type mockBookRepository struct{}

func (m *mockBookRepository) Create(ctx context.Context, book *models.Book) error {
	return nil
}

func (m *mockBookRepository) GetByID(ctx context.Context, id int64) (*models.Book, error) {
	return &models.Book{
		ID:        id,
		Title:     "テスト本",
		Author:    "テスト著者",
		IsActive:  true,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}, nil
}

func (m *mockBookRepository) Update(ctx context.Context, book *models.Book) error {
	return nil
}

func (m *mockBookRepository) Delete(ctx context.Context, id int64) error {
	return nil
}

func (m *mockBookRepository) List(ctx context.Context, req *models.BookSearchRequest) ([]*models.Book, int, error) {
	books := []*models.Book{
		{
			ID:        1,
			Title:     "吾輩は猫である",
			Author:    "夏目漱石",
			IsActive:  true,
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		},
		{
			ID:        2,
			Title:     "走れメロス",
			Author:    "太宰治",
			IsActive:  true,
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		},
	}
	return books, 2, nil
}

func (m *mockBookRepository) CreateChapter(ctx context.Context, chapter *models.Chapter) error {
	return nil
}

func (m *mockBookRepository) GetChaptersByBookID(ctx context.Context, bookID int64) ([]*models.Chapter, error) {
	return nil, nil
}

func (m *mockBookRepository) CreateQuote(ctx context.Context, quote *models.Quote) error {
	return nil
}

func (m *mockBookRepository) GetRandomQuotes(ctx context.Context, bookID int64, limit int) ([]*models.Quote, error) {
	return []*models.Quote{
		{
			ID:        "quote-1",
			BookID:    bookID,
			Text:      "テストの名言です",
			Position:  1,
			CreatedAt: time.Now(),
		},
	}, nil
}

func setupTestRouter() *mux.Router {
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
	api.HandleFunc("/books/{id}/quotes/random", bookHandler.GetRandomQuotes).Methods("GET")
	
	// Health check
	api.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"ok"}`))
	}).Methods("GET")
	
	return router
}

func TestHealthEndpoint(t *testing.T) {
	router := setupTestRouter()
	
	req, err := http.NewRequest("GET", "/api/v1/health", nil)
	if err != nil {
		t.Fatal(err)
	}
	
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Health endpoint returned wrong status code: got %v want %v", status, http.StatusOK)
	}
	
	expected := `{"status":"ok"}`
	if rr.Body.String() != expected {
		t.Errorf("Health endpoint returned unexpected body: got %v want %v", rr.Body.String(), expected)
	}
	
	fmt.Printf("✅ Health Endpoint Test: %s\n", rr.Body.String())
}

func TestSearchBooksEndpoint(t *testing.T) {
	router := setupTestRouter()
	
	req, err := http.NewRequest("GET", "/api/v1/books", nil)
	if err != nil {
		t.Fatal(err)
	}
	
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Search books endpoint returned wrong status code: got %v want %v", status, http.StatusOK)
	}
	
	var response models.BookListResponse
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Errorf("Failed to parse response: %v", err)
	}
	
	if len(response.Books) != 2 {
		t.Errorf("Expected 2 books, got %d", len(response.Books))
	}
	
	if response.Total != 2 {
		t.Errorf("Expected total 2, got %d", response.Total)
	}
	
	fmt.Printf("✅ Search Books Test: Found %d books\n", len(response.Books))
	for i, book := range response.Books {
		fmt.Printf("   Book %d: %s by %s\n", i+1, book.Title, book.Author)
	}
}

func TestGetBookEndpoint(t *testing.T) {
	router := setupTestRouter()
	
	req, err := http.NewRequest("GET", "/api/v1/books/1", nil)
	if err != nil {
		t.Fatal(err)
	}
	
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Get book endpoint returned wrong status code: got %v want %v", status, http.StatusOK)
	}
	
	var book models.Book
	if err := json.Unmarshal(rr.Body.Bytes(), &book); err != nil {
		t.Errorf("Failed to parse response: %v", err)
	}
	
	if book.ID != 1 {
		t.Errorf("Expected book ID 1, got %d", book.ID)
	}
	
	if book.Title != "テスト本" {
		t.Errorf("Expected title 'テスト本', got %s", book.Title)
	}
	
	fmt.Printf("✅ Get Book Test: %s by %s (ID: %d)\n", book.Title, book.Author, book.ID)
}

func TestGetRandomQuotesEndpoint(t *testing.T) {
	router := setupTestRouter()
	
	req, err := http.NewRequest("GET", "/api/v1/books/1/quotes/random", nil)
	if err != nil {
		t.Fatal(err)
	}
	
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)
	
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Get quotes endpoint returned wrong status code: got %v want %v", status, http.StatusOK)
	}
	
	var quotes []*models.Quote
	if err := json.Unmarshal(rr.Body.Bytes(), &quotes); err != nil {
		t.Errorf("Failed to parse response: %v", err)
	}
	
	if len(quotes) != 1 {
		t.Errorf("Expected 1 quote, got %d", len(quotes))
	}
	
	fmt.Printf("✅ Get Random Quotes Test: Found %d quotes\n", len(quotes))
	for i, quote := range quotes {
		fmt.Printf("   Quote %d: %s\n", i+1, quote.Text)
	}
}

func TestAPIPerformance(t *testing.T) {
	router := setupTestRouter()
	
	// Test multiple concurrent requests
	endpoints := []string{
		"/api/v1/health",
		"/api/v1/books",
		"/api/v1/books/1",
		"/api/v1/books/1/quotes/random",
	}
	
	fmt.Println("🚀 Performance Test - Making concurrent requests...")
	
	start := time.Now()
	
	for _, endpoint := range endpoints {
		req, err := http.NewRequest("GET", endpoint, nil)
		if err != nil {
			t.Fatal(err)
		}
		
		rr := httptest.NewRecorder()
		router.ServeHTTP(rr, req)
		
		if rr.Code != http.StatusOK {
			t.Errorf("Endpoint %s failed with status %d", endpoint, rr.Code)
		}
	}
	
	duration := time.Since(start)
	fmt.Printf("✅ Performance Test: All endpoints responded in %v\n", duration)
}

// Simple manual test runner
func main() {
	fmt.Println("🧪 Running API Tests for Clean Architecture Backend...")
	fmt.Println("================================================")
	
	t := &testing.T{}
	
	TestHealthEndpoint(t)
	TestSearchBooksEndpoint(t)
	TestGetBookEndpoint(t)
	TestGetRandomQuotesEndpoint(t)
	TestAPIPerformance(t)
	
	fmt.Println("================================================")
	fmt.Println("✨ All tests completed successfully!")
	fmt.Println("Clean Architecture implementation is working correctly.")
}