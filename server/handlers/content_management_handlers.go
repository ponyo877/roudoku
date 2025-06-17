package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strconv"

	"github.com/jackc/pgx/v5/pgxpool"
)

// InitializeContentRequest represents a request to initialize book content
type InitializeContentRequest struct {
	Force bool `json:"force"` // Force regeneration even if content exists
}

// InitializeContentResponse represents the response from content initialization
type InitializeContentResponse struct {
	Message       string                  `json:"message"`
	BooksCreated  int                    `json:"books_created"`
	AudioGenerated int                   `json:"audio_generated"`
	Books         []BookCreationResult   `json:"books"`
}

type BookCreationResult struct {
	BookID       int    `json:"book_id"`
	Title        string `json:"title"`
	ChaptersText int    `json:"chapters_text"`
	ChaptersAudio int   `json:"chapters_audio"`
	Status       string `json:"status"`
	Error        string `json:"error,omitempty"`
}

// InitializeAllContent creates all book content and generates audio files
func InitializeAllContent(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	db := ctx.Value("db").(*pgxpool.Pool)

	var req InitializeContentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		// If no body, use default values
		req.Force = false
	}

	// Get all books from database
	books, err := getBooksFromDatabase(db)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to get books from database: %v", err), http.StatusInternalServerError)
		return
	}

	var results []BookCreationResult
	totalBooksCreated := 0
	totalAudioGenerated := 0

	for _, book := range books {
		result := BookCreationResult{
			BookID: book.ID,
			Title:  book.Title,
			Status: "processing",
		}

		// Get chapters from database
		chapters, err := getChaptersFromDatabase(db, book.ID)
		if err != nil {
			result.Status = "error"
			result.Error = fmt.Sprintf("Failed to get chapters: %v", err)
			results = append(results, result)
			continue
		}

		result.ChaptersText = len(chapters)
		totalBooksCreated++

		// Generate audio for all chapters
		audioCount := 0
		for i, chapter := range chapters {
			chapterContent := ChapterContent{
				ID:      strconv.Itoa(int(chapter.ID)),
				Title:   chapter.Title,
				Content: chapter.Content,
			}
			_, err := generateChapterAudio(book.ID, i, chapterContent, "", 1.0)
			if err != nil {
				result.Error = fmt.Sprintf("Failed to generate audio for chapter %d: %v", i, err)
				continue
			}
			audioCount++
			totalAudioGenerated++
		}

		result.ChaptersAudio = audioCount
		result.Status = "completed"
		results = append(results, result)
	}

	response := InitializeContentResponse{
		Message:        "Content initialization completed",
		BooksCreated:   totalBooksCreated,
		AudioGenerated: totalAudioGenerated,
		Books:          results,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// GetContentStatus returns the current status of book content and audio files
func GetContentStatus(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	db := ctx.Value("db").(*pgxpool.Pool)

	// Get all books from database
	books, err := getBooksFromDatabase(db)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to get books: %v", err), http.StatusInternalServerError)
		return
	}

	var results []BookCreationResult

	for _, book := range books {
		result := BookCreationResult{
			BookID: book.ID,
			Title:  book.Title,
			Status: "checking",
		}

		// Get chapters from database
		chapters, err := getChaptersFromDatabase(db, book.ID)
		if err != nil {
			result.Status = "error"
			result.Error = fmt.Sprintf("Failed to get chapters: %v", err)
			results = append(results, result)
			continue
		}

		result.ChaptersText = len(chapters)

		// Check audio files
		audioCount := 0
		for i := range chapters {
			filePath := getAudioFilePath(book.ID, i)
			if _, err := os.Stat(filePath); err == nil {
				audioCount++
			}
		}

		result.ChaptersAudio = audioCount
		if audioCount == len(chapters) {
			result.Status = "complete"
		} else {
			result.Status = "partial"
		}

		results = append(results, result)
	}

	response := map[string]interface{}{
		"books": results,
		"total_books": len(books),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Helper types for database results
type BookDB struct {
	ID                     int
	Title                  string
	Author                 string
	WordCount              int
	EstimatedReadingMinutes int
}

type ChapterDB struct {
	ID        int64
	BookID    int
	Title     string
	Content   string
	Position  int
	WordCount int
}

// getBooksFromDatabase retrieves all active books from the database
func getBooksFromDatabase(db *pgxpool.Pool) ([]BookDB, error) {
	query := `
		SELECT id, title, author, word_count, estimated_reading_minutes
		FROM books
		WHERE is_active = true
		ORDER BY id
		LIMIT 100
	`

	rows, err := db.Query(context.Background(), query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var books []BookDB
	for rows.Next() {
		var book BookDB
		err := rows.Scan(&book.ID, &book.Title, &book.Author, &book.WordCount, &book.EstimatedReadingMinutes)
		if err != nil {
			return nil, err
		}
		books = append(books, book)
	}

	return books, nil
}

// getChaptersFromDatabase retrieves all chapters for a specific book
func getChaptersFromDatabase(db *pgxpool.Pool, bookID int) ([]ChapterDB, error) {
	query := `
		SELECT id, book_id, title, content, position, word_count
		FROM chapters
		WHERE book_id = $1
		ORDER BY position
	`

	rows, err := db.Query(context.Background(), query, bookID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var chapters []ChapterDB
	for rows.Next() {
		var chapter ChapterDB
		err := rows.Scan(&chapter.ID, &chapter.BookID, &chapter.Title, &chapter.Content, &chapter.Position, &chapter.WordCount)
		if err != nil {
			return nil, err
		}
		chapters = append(chapters, chapter)
	}

	return chapters, nil
}