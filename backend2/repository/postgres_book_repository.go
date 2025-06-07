package repository

import (
	"context"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/ponyo877/roudoku/backend2/models"
)

// postgresBookRepository implements BookRepository for PostgreSQL
type postgresBookRepository struct {
	db *pgxpool.Pool
}

// NewPostgresBookRepository creates a new PostgreSQL book repository
func NewPostgresBookRepository(db *pgxpool.Pool) BookRepository {
	return &postgresBookRepository{db: db}
}

// Create creates a new book
func (r *postgresBookRepository) Create(ctx context.Context, book *models.Book) error {
	query := `
		INSERT INTO books (id, title, author, epoch, word_count, content_url, summary, genre, 
			difficulty_level, estimated_reading_minutes, download_count, rating_average, rating_count,
			is_premium, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
	`
	
	_, err := r.db.Exec(ctx, query,
		book.ID, book.Title, book.Author, book.Epoch, book.WordCount, book.ContentURL,
		book.Summary, book.Genre, book.DifficultyLevel, book.EstimatedReadingMinutes,
		book.DownloadCount, book.RatingAverage, book.RatingCount,
		book.IsPremium, book.IsActive, book.CreatedAt, book.UpdatedAt,
	)
	
	if err != nil {
		return fmt.Errorf("failed to create book: %w", err)
	}
	
	return nil
}

// GetByID retrieves a book by its ID
func (r *postgresBookRepository) GetByID(ctx context.Context, id int64) (*models.Book, error) {
	query := `
		SELECT id, title, author, epoch, word_count, content_url, summary, genre,
			difficulty_level, estimated_reading_minutes, download_count, rating_average, rating_count,
			is_premium, is_active, created_at, updated_at
		FROM books 
		WHERE id = $1 AND is_active = true
	`
	
	book := &models.Book{}
	err := r.db.QueryRow(ctx, query, id).Scan(
		&book.ID, &book.Title, &book.Author, &book.Epoch, &book.WordCount,
		&book.ContentURL, &book.Summary, &book.Genre, &book.DifficultyLevel,
		&book.EstimatedReadingMinutes, &book.DownloadCount, &book.RatingAverage,
		&book.RatingCount, &book.IsPremium, &book.IsActive, &book.CreatedAt, &book.UpdatedAt,
	)
	
	if err != nil {
		return nil, fmt.Errorf("failed to get book by ID: %w", err)
	}
	
	return book, nil
}

// List retrieves books based on search criteria
func (r *postgresBookRepository) List(ctx context.Context, req *models.BookSearchRequest) ([]*models.Book, int, error) {
	var conditions []string
	var args []interface{}
	argIndex := 1

	baseQuery := `
		SELECT id, title, author, epoch, word_count, content_url, summary, genre,
			difficulty_level, estimated_reading_minutes, download_count, rating_average, rating_count,
			is_premium, is_active, created_at, updated_at
		FROM books
	`
	
	countQuery := "SELECT COUNT(*) FROM books"
	
	// Add WHERE conditions
	conditions = append(conditions, "is_active = true")
	
	// Handle full-text search query
	if req.Query != "" {
		conditions = append(conditions, fmt.Sprintf("(title ILIKE $%d OR author ILIKE $%d)", argIndex, argIndex))
		args = append(args, "%"+req.Query+"%")
		argIndex++
	}
	
	// Handle filters
	if req.Filter != nil {
		if len(req.Filter.Authors) > 0 {
			placeholders := make([]string, len(req.Filter.Authors))
			for i, author := range req.Filter.Authors {
				placeholders[i] = fmt.Sprintf("$%d", argIndex)
				args = append(args, author)
				argIndex++
			}
			conditions = append(conditions, fmt.Sprintf("author = ANY(ARRAY[%s])", strings.Join(placeholders, ",")))
		}
		
		if len(req.Filter.Genres) > 0 {
			placeholders := make([]string, len(req.Filter.Genres))
			for i, genre := range req.Filter.Genres {
				placeholders[i] = fmt.Sprintf("$%d", argIndex)
				args = append(args, genre)
				argIndex++
			}
			conditions = append(conditions, fmt.Sprintf("genre = ANY(ARRAY[%s])", strings.Join(placeholders, ",")))
		}
		
		if req.Filter.DifficultyLevel != nil {
			conditions = append(conditions, fmt.Sprintf("difficulty_level = $%d", argIndex))
			args = append(args, *req.Filter.DifficultyLevel)
			argIndex++
		}
		
		if req.Filter.IsPremium != nil {
			conditions = append(conditions, fmt.Sprintf("is_premium = $%d", argIndex))
			args = append(args, *req.Filter.IsPremium)
			argIndex++
		}
		
		if req.Filter.MinWordCount != nil {
			conditions = append(conditions, fmt.Sprintf("word_count >= $%d", argIndex))
			args = append(args, *req.Filter.MinWordCount)
			argIndex++
		}
		
		if req.Filter.MaxWordCount != nil {
			conditions = append(conditions, fmt.Sprintf("word_count <= $%d", argIndex))
			args = append(args, *req.Filter.MaxWordCount)
			argIndex++
		}
		
		if req.Filter.MinRating != nil {
			conditions = append(conditions, fmt.Sprintf("rating_average >= $%d", argIndex))
			args = append(args, *req.Filter.MinRating)
			argIndex++
		}
	}
	
	whereClause := ""
	if len(conditions) > 0 {
		whereClause = " WHERE " + strings.Join(conditions, " AND ")
	}
	
	// Get total count
	var total int
	err := r.db.QueryRow(ctx, countQuery+whereClause, args...).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get total count: %w", err)
	}
	
	// Add ORDER BY
	orderBy := " ORDER BY " + req.SortBy.ToSQLOrderBy()
	if req.SortBy == "" {
		orderBy = " ORDER BY download_count DESC, rating_average DESC"
	}
	
	// Add LIMIT and OFFSET
	limitOffset := fmt.Sprintf(" LIMIT $%d OFFSET $%d", argIndex, argIndex+1)
	args = append(args, req.Limit, req.Offset)
	
	// Execute the main query
	finalQuery := baseQuery + whereClause + orderBy + limitOffset
	rows, err := r.db.Query(ctx, finalQuery, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list books: %w", err)
	}
	defer rows.Close()
	
	var books []*models.Book
	for rows.Next() {
		book := &models.Book{}
		err := rows.Scan(
			&book.ID, &book.Title, &book.Author, &book.Epoch, &book.WordCount,
			&book.ContentURL, &book.Summary, &book.Genre, &book.DifficultyLevel,
			&book.EstimatedReadingMinutes, &book.DownloadCount, &book.RatingAverage,
			&book.RatingCount, &book.IsPremium, &book.IsActive, &book.CreatedAt, &book.UpdatedAt,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("failed to scan book: %w", err)
		}
		books = append(books, book)
	}
	
	if err = rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("rows iteration error: %w", err)
	}
	
	return books, total, nil
}

// Update updates an existing book
func (r *postgresBookRepository) Update(ctx context.Context, book *models.Book) error {
	query := `
		UPDATE books SET 
			title = $2, author = $3, epoch = $4, content_url = $5, summary = $6, 
			genre = $7, difficulty_level = $8, estimated_reading_minutes = $9, 
			is_premium = $10, updated_at = $11
		WHERE id = $1
	`
	
	_, err := r.db.Exec(ctx, query,
		book.ID, book.Title, book.Author, book.Epoch, book.ContentURL,
		book.Summary, book.Genre, book.DifficultyLevel, book.EstimatedReadingMinutes,
		book.IsPremium, book.UpdatedAt,
	)
	
	if err != nil {
		return fmt.Errorf("failed to update book: %w", err)
	}
	
	return nil
}

// Delete soft deletes a book by setting is_active to false
func (r *postgresBookRepository) Delete(ctx context.Context, id int64) error {
	query := `UPDATE books SET is_active = false, updated_at = NOW() WHERE id = $1`
	
	_, err := r.db.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete book: %w", err)
	}
	
	return nil
}

// CreateChapter creates a new chapter
func (r *postgresBookRepository) CreateChapter(ctx context.Context, chapter *models.Chapter) error {
	query := `
		INSERT INTO chapters (id, book_id, title, content, position, word_count, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	
	_, err := r.db.Exec(ctx, query,
		chapter.ID, chapter.BookID, chapter.Title, chapter.Content,
		chapter.Position, chapter.WordCount, chapter.CreatedAt,
	)
	
	if err != nil {
		return fmt.Errorf("failed to create chapter: %w", err)
	}
	
	return nil
}

// GetChaptersByBookID retrieves all chapters for a book
func (r *postgresBookRepository) GetChaptersByBookID(ctx context.Context, bookID int64) ([]*models.Chapter, error) {
	query := `
		SELECT id, book_id, title, content, position, word_count, created_at
		FROM chapters 
		WHERE book_id = $1 
		ORDER BY position ASC
	`
	
	rows, err := r.db.Query(ctx, query, bookID)
	if err != nil {
		return nil, fmt.Errorf("failed to get chapters: %w", err)
	}
	defer rows.Close()
	
	var chapters []*models.Chapter
	for rows.Next() {
		chapter := &models.Chapter{}
		err := rows.Scan(
			&chapter.ID, &chapter.BookID, &chapter.Title, &chapter.Content,
			&chapter.Position, &chapter.WordCount, &chapter.CreatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan chapter: %w", err)
		}
		chapters = append(chapters, chapter)
	}
	
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("chapters rows iteration error: %w", err)
	}
	
	return chapters, nil
}

// CreateQuote creates a new quote
func (r *postgresBookRepository) CreateQuote(ctx context.Context, quote *models.Quote) error {
	query := `
		INSERT INTO quotes (id, book_id, text, position, chapter_title, created_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`
	
	_, err := r.db.Exec(ctx, query,
		quote.ID, quote.BookID, quote.Text, quote.Position,
		quote.ChapterTitle, quote.CreatedAt,
	)
	
	if err != nil {
		return fmt.Errorf("failed to create quote: %w", err)
	}
	
	return nil
}

// GetRandomQuotes retrieves random quotes for a book
func (r *postgresBookRepository) GetRandomQuotes(ctx context.Context, bookID int64, limit int) ([]*models.Quote, error) {
	query := `
		SELECT id, book_id, text, position, chapter_title, created_at
		FROM quotes 
		WHERE book_id = $1 
		ORDER BY RANDOM() 
		LIMIT $2
	`
	
	rows, err := r.db.Query(ctx, query, bookID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get random quotes: %w", err)
	}
	defer rows.Close()
	
	var quotes []*models.Quote
	for rows.Next() {
		quote := &models.Quote{}
		err := rows.Scan(
			&quote.ID, &quote.BookID, &quote.Text, &quote.Position,
			&quote.ChapterTitle, &quote.CreatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan quote: %w", err)
		}
		quotes = append(quotes, quote)
	}
	
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("quotes rows iteration error: %w", err)
	}
	
	return quotes, nil
}