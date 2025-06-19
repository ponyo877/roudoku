package handlers

import (
	"net/http"

	"github.com/gorilla/mux"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/utils"
	"github.com/ponyo877/roudoku/server/services"
)

// BookHandler handles book-related HTTP requests
type BookHandler struct {
	*BaseHandler
	bookService services.BookService
}

// NewBookHandler creates a new book handler
func NewBookHandler(bookService services.BookService, log *logger.Logger) *BookHandler {
	return &BookHandler{
		BaseHandler: NewBaseHandler(log),
		bookService: bookService,
	}
}

// SearchBooks handles GET /books
func (h *BookHandler) SearchBooks(w http.ResponseWriter, r *http.Request) {
	var req dto.BookSearchRequest
	
	// Parse query parameters
	req.Query = r.URL.Query().Get("query")
	req.SortBy = r.URL.Query().Get("sort_by")
	req.Limit = utils.ParseQueryInt(r, "limit", 20)
	req.Offset = utils.ParseQueryInt(r, "offset", 0)

	// For more complex filtering, we would need to parse the filter JSON
	// For now, keep it simple

	if err := h.validator.ValidateStruct(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	response, err := h.bookService.SearchBooks(r.Context(), &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, response)
}

// CreateBook handles POST /books
func (h *BookHandler) CreateBook(w http.ResponseWriter, r *http.Request) {
	var req dto.CreateBookRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	if err := h.validator.ValidateStruct(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	book, err := h.bookService.CreateBook(r.Context(), &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, book)
}

// GetBook handles GET /books/{id}
func (h *BookHandler) GetBook(w http.ResponseWriter, r *http.Request) {
	id, err := utils.ParseInt64Param(r, "id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	book, err := h.bookService.GetBook(r.Context(), id)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, book)
}

// GetRandomQuotes handles GET /books/{id}/quotes/random
func (h *BookHandler) GetRandomQuotes(w http.ResponseWriter, r *http.Request) {
	id, err := utils.ParseInt64Param(r, "id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	limit := utils.ParseQueryInt(r, "limit", 10)

	quotes, err := h.bookService.GetRandomQuotes(r.Context(), id, limit)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, quotes)
}

// GetBookChapters handles GET /books/{id}/chapters
func (h *BookHandler) GetBookChapters(w http.ResponseWriter, r *http.Request) {
	id, err := utils.ParseInt64Param(r, "id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	chapters, err := h.bookService.GetBookChapters(r.Context(), id)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, chapters)
}

// GetChapterContent handles GET /books/{id}/chapters/{chapter_id}
func (h *BookHandler) GetChapterContent(w http.ResponseWriter, r *http.Request) {
	bookID, err := utils.ParseInt64Param(r, "id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	// Extract chapter_id from URL path parameters using gorilla/mux
	vars := mux.Vars(r)
	chapterID := vars["chapter_id"]

	chapter, err := h.bookService.GetChapterContent(r.Context(), bookID, chapterID)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, chapter)
}

// GetRecommendations handles GET /books/recommendations
func (h *BookHandler) GetRecommendations(w http.ResponseWriter, r *http.Request) {
	// For now, return empty recommendations
	recommendations := []any{}
	utils.WriteSuccess(w, recommendations)
}