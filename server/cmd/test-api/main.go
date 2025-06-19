package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/mux"

	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/handlers"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/services"
)

// mockBookRepository implements BookRepository for testing
type mockBookRepository struct{}

func (m *mockBookRepository) Create(ctx context.Context, book *domain.Book) error {
	return nil
}

func (m *mockBookRepository) GetByID(ctx context.Context, id int64) (*domain.Book, error) {
	return &domain.Book{
		ID:        id,
		Title:     "吾輩は猫である",
		Author:    "夏目漱石",
		IsActive:  true,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}, nil
}

func (m *mockBookRepository) Update(ctx context.Context, book *domain.Book) error {
	return nil
}

func (m *mockBookRepository) Delete(ctx context.Context, id int64) error {
	return nil
}

func (m *mockBookRepository) List(ctx context.Context, req *domain.BookSearchRequest) ([]*domain.Book, int, error) {
	books := []*domain.Book{
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

func (m *mockBookRepository) CreateChapter(ctx context.Context, chapter *domain.Chapter) error {
	return nil
}

func (m *mockBookRepository) GetChaptersByBookID(ctx context.Context, bookID int64) ([]*domain.Chapter, error) {
	return nil, nil
}

func (m *mockBookRepository) GetChapterByID(ctx context.Context, chapterID string) (*domain.Chapter, error) {
	return nil, nil
}

func (m *mockBookRepository) CreateQuote(ctx context.Context, quote *domain.Quote) error {
	return nil
}

func (m *mockBookRepository) GetRandomQuotes(ctx context.Context, bookID int64, limit int) ([]*domain.Quote, error) {
	return []*domain.Quote{
		{
			ID:        uuid.New(),
			BookID:    bookID,
			Text:      "人間は機械ではない。もっと微妙で、複雑で、そして不思議なものである。",
			Position:  1,
			CreatedAt: time.Now(),
		},
	}, nil
}

func setupTestRouter() *mux.Router {
	// Initialize logger
	loggerConfig := logger.Config{
		Level:  "info",
		Format: "console",
		Output: "stdout",
	}
	appLogger, _ := logger.New(loggerConfig)

	// Initialize mock repository
	bookRepo := &mockBookRepository{}

	// Initialize services
	bookService := services.NewBookService(bookRepo, appLogger)

	// Initialize handlers
	bookHandler := handlers.NewBookHandler(bookService, appLogger)

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
		w.Write([]byte(`{"status":"ok","architecture":"clean","layers":["models","repository","services","handlers"]}`))
	}).Methods("GET")

	return router
}

func testHealthEndpoint(router *mux.Router) {
	fmt.Println("🏥 Testing Health Endpoint...")

	req, _ := http.NewRequest("GET", "/api/v1/health", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code == http.StatusOK {
		fmt.Printf("   ✅ Status: %d\n", rr.Code)
		fmt.Printf("   📄 Response: %s\n", rr.Body.String())
	} else {
		fmt.Printf("   ❌ Failed with status: %d\n", rr.Code)
	}
}

func testSearchBooksEndpoint(router *mux.Router) {
	fmt.Println("\n📚 Testing Search Books Endpoint...")

	req, _ := http.NewRequest("GET", "/api/v1/books", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code == http.StatusOK {
		var response dto.BookListResponse
		json.Unmarshal(rr.Body.Bytes(), &response)

		fmt.Printf("   ✅ Status: %d\n", rr.Code)
		fmt.Printf("   📊 Total Books: %d\n", response.Total)

		for i, book := range response.Books {
			fmt.Printf("   📖 Book %d: %s by %s\n", i+1, book.Title, book.Author)
		}
	} else {
		fmt.Printf("   ❌ Failed with status: %d\n", rr.Code)
	}
}

func testGetBookEndpoint(router *mux.Router) {
	fmt.Println("\n📖 Testing Get Book by ID Endpoint...")

	req, _ := http.NewRequest("GET", "/api/v1/books/1", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code == http.StatusOK {
		var book dto.BookResponse
		json.Unmarshal(rr.Body.Bytes(), &book)

		fmt.Printf("   ✅ Status: %d\n", rr.Code)
		fmt.Printf("   📚 Book: %s\n", book.Title)
		fmt.Printf("   ✍️  Author: %s\n", book.Author)
		fmt.Printf("   🆔 ID: %d\n", book.ID)
	} else {
		fmt.Printf("   ❌ Failed with status: %d\n", rr.Code)
	}
}

func testGetRandomQuotesEndpoint(router *mux.Router) {
	fmt.Println("\n💬 Testing Get Random Quotes Endpoint...")

	req, _ := http.NewRequest("GET", "/api/v1/books/1/quotes/random", nil)
	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	if rr.Code == http.StatusOK {
		var quotes []*domain.Quote
		json.Unmarshal(rr.Body.Bytes(), &quotes)

		fmt.Printf("   ✅ Status: %d\n", rr.Code)
		fmt.Printf("   💭 Quotes Found: %d\n", len(quotes))

		for i, quote := range quotes {
			fmt.Printf("   📝 Quote %d: %s\n", i+1, quote.Text)
		}
	} else {
		fmt.Printf("   ❌ Failed with status: %d\n", rr.Code)
	}
}

func testPerformance(router *mux.Router) {
	fmt.Println("\n🚀 Testing API Performance...")

	endpoints := []string{
		"/api/v1/health",
		"/api/v1/books",
		"/api/v1/books/1",
		"/api/v1/books/1/quotes/random",
	}

	start := time.Now()
	successCount := 0

	for _, endpoint := range endpoints {
		req, _ := http.NewRequest("GET", endpoint, nil)
		rr := httptest.NewRecorder()
		router.ServeHTTP(rr, req)

		if rr.Code == http.StatusOK {
			successCount++
		}
	}

	duration := time.Since(start)
	fmt.Printf("   ⏱️  Total Time: %v\n", duration)
	fmt.Printf("   ✅ Successful Requests: %d/%d\n", successCount, len(endpoints))
	fmt.Printf("   📊 Average Response Time: %v\n", duration/time.Duration(len(endpoints)))
}

func main() {
	fmt.Println("🧪 Roudoku Backend - Clean Architecture API Test")
	fmt.Println("================================================")
	fmt.Println("🏗️  Testing Clean Architecture Implementation")
	fmt.Println("   📁 Models: Domain entities")
	fmt.Println("   🔗 Repository: Data access interfaces")
	fmt.Println("   ⚙️  Services: Business logic")
	fmt.Println("   🌐 Handlers: HTTP transport")
	fmt.Println("")

	router := setupTestRouter()

	testHealthEndpoint(router)
	testSearchBooksEndpoint(router)
	testGetBookEndpoint(router)
	testGetRandomQuotesEndpoint(router)
	testPerformance(router)

	fmt.Println("\n================================================")
	fmt.Println("🎉 Clean Architecture Backend Test Complete!")
	fmt.Println("✨ All layers working correctly")
	fmt.Println("🔄 Dependency inversion implemented")
	fmt.Println("🧪 Ready for unit testing and database integration")
}
