package handlers

import (
	"net/http"

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

	utils.WriteCreated(w, book)
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

// SearchBooks handles GET /books
func (h *BookHandler) SearchBooks(w http.ResponseWriter, r *http.Request) {
	req := &dto.BookSearchRequest{}

	// Parse query parameters
	req.Query = utils.ParseQueryString(r, "query", "")
	req.SortBy = utils.ParseQueryString(r, "sort_by", "")

	// Parse pagination parameters
	page, perPage := utils.ParsePaginationParams(r)
	req.Limit = perPage
	req.Offset = (page - 1) * perPage

	response, err := h.bookService.SearchBooks(r.Context(), req)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	// Calculate meta information
	meta := utils.CalculateMeta(page, perPage, response.TotalCount)
	utils.WriteSuccessWithMeta(w, response.Books, meta)
}

// GetRandomQuotes handles GET /books/{id}/quotes/random
func (h *BookHandler) GetRandomQuotes(w http.ResponseWriter, r *http.Request) {
	id, err := utils.ParseInt64Param(r, "id")
	if err != nil {
		utils.WriteJSONError(w, "Invalid or missing book ID", utils.CodeInvalidParameter, http.StatusBadRequest)
		return
	}

	// Get limit with default of 10
	pagination := utils.ParsePaginationParams(r, 10)
	limit := pagination.Limit

	quotes, err := h.bookService.GetRandomQuotes(r.Context(), id, limit)
	if err != nil {
		if err == services.ErrBookNotFound {
			utils.WriteJSONError(w, "Book not found", utils.CodeResourceNotFound, http.StatusNotFound)
		} else {
			utils.WriteJSONError(w, err.Error(), utils.CodeInternal, http.StatusInternalServerError)
		}
		return
	}

	utils.WriteJSONSuccess(w, quotes, "", http.StatusOK)
}

// GetRecommendations handles GET /books/recommendations
func (h *BookHandler) GetRecommendations(w http.ResponseWriter, r *http.Request) {
	pagination := utils.ParsePaginationParams(r, 20)
	
	req := &dto.BookSearchRequest{
		SortBy: "popularity",
		Limit:  pagination.Limit,
		Offset: pagination.Offset,
	}

	response, err := h.bookService.SearchBooks(r.Context(), req)
	if err != nil {
		utils.WriteJSONError(w, err.Error(), utils.CodeInternal, http.StatusInternalServerError)
		return
	}

	utils.WriteJSONSuccess(w, response, "", http.StatusOK)
}

// GetBookChapters handles GET /books/{id}/chapters
func (h *BookHandler) GetBookChapters(w http.ResponseWriter, r *http.Request) {
	id, err := utils.ParseInt64Param(r, "id")
	if err != nil {
		utils.WriteJSONError(w, "Invalid or missing book ID", utils.CodeInvalidParameter, http.StatusBadRequest)
		return
	}

	chapters, err := h.bookService.GetBookChapters(r.Context(), id)
	if err != nil {
		if err == services.ErrBookNotFound {
			utils.WriteJSONError(w, "Book not found", utils.CodeResourceNotFound, http.StatusNotFound)
		} else {
			utils.WriteJSONError(w, err.Error(), utils.CodeInternal, http.StatusInternalServerError)
		}
		return
	}

	response := map[string]interface{}{
		"chapters": chapters,
	}
	utils.WriteJSONSuccess(w, response, "", http.StatusOK)
}

// GetChapterContent handles GET /books/{id}/chapters/{chapter_id}
func (h *BookHandler) GetChapterContent(w http.ResponseWriter, r *http.Request) {
	bookID, err := utils.ParseInt64Param(r, "id")
	if err != nil {
		utils.WriteJSONError(w, "Invalid or missing book ID", utils.CodeInvalidParameter, http.StatusBadRequest)
		return
	}

	chapterIDStr, err := utils.ParseStringParam(r, "chapter_id")
	if err != nil {
		utils.WriteJSONError(w, "Missing chapter ID", utils.CodeInvalidParameter, http.StatusBadRequest)
		return
	}

	chapterContent, err := h.bookService.GetChapterContent(r.Context(), bookID, chapterIDStr)
	if err != nil {
		if err == services.ErrChapterNotFound {
			utils.WriteJSONError(w, "Chapter not found", utils.CodeResourceNotFound, http.StatusNotFound)
		} else {
			utils.WriteJSONError(w, err.Error(), utils.CodeInternal, http.StatusInternalServerError)
		}
		return
	}

	// Try to decode the content if it's in ZIP format
	decodedContent, err := h.decodeChapterContent(chapterContent.Content)
	if err != nil {
		// If decoding fails, use original content
		decodedContent = chapterContent.Content
	}

	// Return chapter with decoded content
	response := map[string]interface{}{
		"ID":        chapterContent.ID,
		"BookID":    chapterContent.BookID,
		"Title":     chapterContent.Title,
		"Content":   decodedContent,
		"Position":  chapterContent.Position,
		"WordCount": chapterContent.WordCount,
		"CreatedAt": chapterContent.CreatedAt,
	}

	utils.WriteJSONSuccess(w, response, "", http.StatusOK)
}

// decodeChapterContent tries to decode ZIP-encoded content to readable text
func (h *BookHandler) decodeChapterContent(content string) (string, error) {
	// Check if content looks like ZIP data (starts with PK)
	if !strings.HasPrefix(content, "PK") {
		return content, nil
	}

	// Try to decode as ZIP
	reader := strings.NewReader(content)
	zipReader, err := zip.NewReader(reader, int64(len(content)))
	if err != nil {
		return content, err
	}

	// Read the first text file in the ZIP
	for _, file := range zipReader.File {
		if strings.HasSuffix(file.Name, ".txt") {
			rc, err := file.Open()
			if err != nil {
				continue
			}

			// Read the content
			zipContent, err := io.ReadAll(rc)
			rc.Close()
			if err != nil {
				continue
			}

			// Try to decode from Shift_JIS to UTF-8
			decoder := japanese.ShiftJIS.NewDecoder()
			utf8Content, err := io.ReadAll(transform.NewReader(bytes.NewReader(zipContent), decoder))
			if err != nil {
				// If Shift_JIS decoding fails, try as UTF-8
				utf8Content = zipContent
			}

			text := string(utf8Content)
			
			// Clean up the text
			text = strings.ReplaceAll(text, "\x00", "")
			text = strings.ReplaceAll(text, "｜", "")
			
			// Remove ruby annotations (《》)
			for strings.Contains(text, "《") && strings.Contains(text, "》") {
				start := strings.Index(text, "《")
				end := strings.Index(text, "》")
				if start != -1 && end != -1 && end > start {
					text = text[:start] + text[end+len("》"):]
				} else {
					break
				}
			}
			
			// Remove annotations ([])
			for strings.Contains(text, "［") && strings.Contains(text, "］") {
				start := strings.Index(text, "［")
				end := strings.Index(text, "］")
				if start != -1 && end != -1 && end > start {
					text = text[:start] + text[end+len("］"):]
				} else {
					break
				}
			}

			return strings.TrimSpace(text), nil
		}
	}

	return content, nil
}
