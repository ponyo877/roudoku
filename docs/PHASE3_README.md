# Phase 3: Aozora Bunko ETL / Search API / Catalog Implementation

This document describes the implementation of Phase 3 of the roudoku project, which includes the Aozora Bunko ETL system, Book Management API, and Search/Catalog functionality.

## 🎯 Implementation Overview

Phase 3 has been successfully implemented with the following components:

### ✅ Completed Features

1. **Book Models and Data Structures**
2. **Book Repository with PostgreSQL integration**
3. **Book Service with business logic**
4. **REST API endpoints for book management**
5. **Aozora Bunko ETL system**
6. **XHTML/HTML content parser**
7. **Quote extraction for recommendations**
8. **Full-text search with PostgreSQL**
9. **ETL CLI command**
10. **API route integration**
11. **Sample data for testing**

## 📁 File Structure

```
/Users/ponyo877/Documents/workspace/roudoku/
├── internal/
│   ├── models/
│   │   └── book.go                    # Book, Chapter, Quote models
│   ├── repository/
│   │   └── book_repository.go         # Database operations
│   ├── services/
│   │   ├── base.go                    # Service interfaces (updated)
│   │   └── book_service.go            # Business logic
│   ├── handlers/
│   │   └── book_handlers.go           # HTTP handlers
│   └── etl/
│       ├── aozora_fetcher.go          # GitHub data fetcher
│       ├── content_parser.go          # XHTML/HTML parser
│       └── etl_service.go             # ETL orchestration
├── cmd/
│   ├── api/
│   │   └── main.go                    # API server (updated)
│   └── etl/
│       └── main.go                    # ETL CLI command
├── backend/migrations/
│   ├── 012_create_chapters_table.sql  # Chapters table
│   ├── 013_add_fulltext_search.sql    # Search indexes
│   └── 014_insert_sample_books.sql    # Sample data
├── scripts/
│   └── test_api.sh                    # API testing script
├── Makefile                           # Updated with ETL commands
└── PHASE3_README.md                   # This file
```

## 🔧 Key Components

### 1. Book Models (`internal/models/book.go`)

**Core Models:**
- `Book`: Complete book information with metadata
- `Chapter`: Book chapters with content
- `Quote`: Extracted quotes for recommendations
- `AozoraMetadata`: Aozora Bunko CSV metadata

**Request/Response Models:**
- `BookSearchRequest`: Search and filtering
- `BookListResponse`: Paginated results
- `BookContentResponse`: Book with chapters
- `BookQuotesResponse`: Book with quotes

**Features:**
- Comprehensive filtering and sorting
- Premium content support
- Japanese text handling
- Search result pagination

### 2. Book Repository (`internal/repository/book_repository.go`)

**Core Operations:**
- CRUD operations for books, chapters, quotes
- Bulk operations for ETL
- Full-text search with PostgreSQL
- Advanced filtering and pagination

**Search Features:**
- PostgreSQL full-text search with tsvector
- Fallback to ILIKE for compatibility
- Multi-field search (title, author, summary)
- Filter by author, genre, epoch, difficulty, etc.

### 3. Book Service (`internal/services/book_service.go`)

**Business Logic:**
- User subscription validation
- Premium content access control
- Search with user context
- Rating and analytics tracking

**Key Methods:**
- `SearchBooks`: Full search with filters
- `GetBookContent`: Content with access control
- `GetBookQuotes`: Random quotes for swiping
- `RecordBookAccess`: Analytics tracking

### 4. ETL System

#### Aozora Fetcher (`internal/etl/aozora_fetcher.go`)
- Fetches CSV metadata from GitHub
- Downloads XHTML/HTML content
- Converts to internal models
- Handles Japanese text encoding

#### Content Parser (`internal/etl/content_parser.go`)
- Parses XHTML/HTML content
- Extracts chapters and structure
- Generates quotes for recommendations
- Cleans and normalizes text

#### ETL Service (`internal/etl/etl_service.go`)
- Orchestrates complete ETL process
- Parallel processing with worker pools
- Incremental updates
- Error handling and reporting

### 5. REST API Endpoints

**Public Endpoints:**
- `GET /api/books` - Search and list books
- `GET /api/books/popular` - Popular books
- `GET /api/books/author/{author}` - Books by author
- `GET /api/books/genre/{genre}` - Books by genre
- `GET /api/books/{id}` - Book details
- `GET /api/books/{id}/content` - Book content (auth for premium)
- `GET /api/books/{id}/quotes` - Random quotes (auth for premium)

**Authenticated Endpoints:**
- `POST /api/books/{id}/rate` - Rate a book

**Admin Endpoints:**
- `POST /api/admin/books` - Create book
- `PUT /api/admin/books/{id}` - Update book
- `DELETE /api/admin/books/{id}` - Delete book

## 🗄️ Database Schema

### Books Table
```sql
CREATE TABLE books (
    id BIGINT PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    epoch TEXT,
    word_count INTEGER DEFAULT 0,
    content_url TEXT,
    summary TEXT,
    genre TEXT,
    difficulty_level INTEGER DEFAULT 1,
    estimated_reading_minutes INTEGER DEFAULT 0,
    download_count INTEGER DEFAULT 0,
    rating_average DECIMAL(3,2) DEFAULT 0.0,
    rating_count INTEGER DEFAULT 0,
    is_premium BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    search_vector tsvector,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Full-Text Search
- Automatic tsvector generation with triggers
- GIN indexes for fast search
- Multi-field search weighting
- Support for Japanese text

## 🚀 Usage

### Running the API Server
```bash
# Start the API server
make run

# Or directly with go
go run cmd/api/main.go
```

### ETL Operations
```bash
# Run ETL with sample data (20 books max)
make etl-sample

# Run incremental update
make etl-incremental

# Dry run to see what would be processed
make etl-dry-run

# Full ETL with content parsing
make book-fetch
```

### Testing the API
```bash
# Run API tests
make test-api

# Or directly
./scripts/test_api.sh
```

## 📊 Sample Data

The implementation includes 15 sample books from famous Japanese authors:

**Authors Included:**
- 夏目漱石 (Natsume Soseki)
- 芥川龍之介 (Akutagawa Ryunosuke)
- 宮沢賢治 (Miyazawa Kenji)
- 森鴎外 (Mori Ogai)
- 太宰治 (Dazai Osamu)
- 与謝野晶子 (Yosano Akiko)
- 樋口一葉 (Higuchi Ichiyo)
- 中島敦 (Nakajima Atsushi)
- 新美南吉 (Niimi Nankichi)
- 小泉八雲 (Koizumi Yakumo)

**Features:**
- Multiple epochs (明治, 大正, 昭和)
- Various genres (小説, 童話, 詩, 怪談)
- Different difficulty levels
- Sample chapters and quotes

## 🔍 Search Capabilities

### Basic Search
```bash
# Search by text
GET /api/books?q=夏目漱石

# Pagination
GET /api/books?limit=10&offset=20
```

### Advanced Filtering
```bash
# Filter by multiple criteria
GET /api/books?authors=夏目漱石,芥川龍之介&genres=小説&epochs=明治,大正&min_rating=4.0

# Sort options
GET /api/books?sort=rating
GET /api/books?sort=popularity
GET /api/books?sort=publication
```

### Full-Text Search
- Searches across title, author, and summary
- Uses PostgreSQL's built-in Japanese text search
- Fallback to pattern matching for broader compatibility

## 🔐 Access Control

### Public Access
- Book listing and search
- Book details for free content
- Author and genre browsing

### Premium Content
- Full book content for premium books
- Quotes from premium books
- Requires valid subscription

### Authentication Integration
- Uses existing Firebase Auth middleware
- Optional auth for public endpoints
- Required auth for premium features and rating

## 📈 Analytics Features

- Download count tracking
- Rating aggregation
- Book access logging
- User engagement metrics

## 🛠️ Development Tools

### Makefile Commands
- `make run` - Start API server
- `make etl-sample` - Run ETL with sample data
- `make test-api` - Test API endpoints
- `make book-fetch` - Fetch real Aozora Bunko data

### ETL CLI Options
```bash
go run cmd/etl/main.go [options]

Options:
  -full          Perform full refresh
  -max N         Maximum number of books
  -content       Download and parse content
  -dry-run       Show what would be done
  -verbose       Enable detailed logging
  -output FILE   Save results to JSON file
```

## 🔮 Future Enhancements

1. **Advanced Search**
   - Semantic search with embeddings
   - AI-powered content recommendations
   - Reading difficulty analysis

2. **Content Processing**
   - Better chapter detection
   - Automatic genre classification
   - Reading time optimization

3. **Performance**
   - Search result caching
   - CDN for content delivery
   - Database query optimization

4. **Features**
   - Book similarity scoring
   - Reading progress tracking
   - Social features (reviews, lists)

## 🧪 Testing

The implementation is ready for integration testing with:
- Sample data loaded
- All API endpoints functional
- ETL system tested with real Aozora Bunko data
- Full-text search working
- Authentication integration complete

## 📝 Notes

- All Japanese text is properly handled with UTF-8 encoding
- PostgreSQL full-text search is optimized for Japanese content
- The system supports both incremental and full data refreshes
- Premium content filtering is implemented throughout
- Error handling and logging are comprehensive
- The architecture is ready for mobile app integration

This implementation provides a solid foundation for the book catalog and search functionality of the roudoku reading app, with proper Japanese text handling, scalable search capabilities, and integration with the existing authentication system.