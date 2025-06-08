package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/services"
)

// BookHandler handles book-related HTTP requests
type BookHandler struct {
	bookService services.BookService
}

// NewBookHandler creates a new book handler
func NewBookHandler(bookService services.BookService) *BookHandler {
	return &BookHandler{
		bookService: bookService,
	}
}

// CreateBook handles POST /books
func (h *BookHandler) CreateBook(w http.ResponseWriter, r *http.Request) {
	var req dto.CreateBookRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	book, err := h.bookService.CreateBook(r.Context(), &req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(book)
}

// GetBook handles GET /books/{id}
func (h *BookHandler) GetBook(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	idStr, ok := vars["id"]
	if !ok {
		http.Error(w, "Missing book ID", http.StatusBadRequest)
		return
	}

	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		http.Error(w, "Invalid book ID", http.StatusBadRequest)
		return
	}

	book, err := h.bookService.GetBook(r.Context(), id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(book)
}

// SearchBooks handles GET /books
func (h *BookHandler) SearchBooks(w http.ResponseWriter, r *http.Request) {
	req := &dto.BookSearchRequest{}

	// Parse query parameters
	if query := r.URL.Query().Get("query"); query != "" {
		req.Query = query
	}

	if sortBy := r.URL.Query().Get("sort_by"); sortBy != "" {
		req.SortBy = sortBy
	}

	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if limit, err := strconv.Atoi(limitStr); err == nil {
			req.Limit = limit
		}
	}

	if offsetStr := r.URL.Query().Get("offset"); offsetStr != "" {
		if offset, err := strconv.Atoi(offsetStr); err == nil {
			req.Offset = offset
		}
	}

	response, err := h.bookService.SearchBooks(r.Context(), req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// GetRandomQuotes handles GET /books/{id}/quotes/random
func (h *BookHandler) GetRandomQuotes(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	idStr, ok := vars["id"]
	if !ok {
		http.Error(w, "Missing book ID", http.StatusBadRequest)
		return
	}

	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		http.Error(w, "Invalid book ID", http.StatusBadRequest)
		return
	}

	limit := 10
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil {
			limit = l
		}
	}

	quotes, err := h.bookService.GetRandomQuotes(r.Context(), id, limit)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(quotes)
}
