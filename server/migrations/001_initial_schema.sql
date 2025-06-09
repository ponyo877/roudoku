-- Create tables for roudoku application

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    display_name TEXT NOT NULL DEFAULT '',
    email TEXT UNIQUE,
    voice_preset JSONB NOT NULL DEFAULT '{"gender": "neutral", "pitch": 0.5, "speed": 1.0}',
    subscription_status TEXT NOT NULL DEFAULT 'free' CHECK (subscription_status IN ('free', 'premium')),
    subscription_expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Books table (enhanced from existing requirements)
CREATE TABLE IF NOT EXISTS books (
    id BIGINT PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    epoch TEXT,
    word_count INTEGER NOT NULL DEFAULT 0,
    embedding TEXT, -- For AI recommendations (vector as JSON)
    content_url TEXT,
    summary TEXT,
    genre TEXT,
    difficulty_level INTEGER DEFAULT 1 CHECK (difficulty_level BETWEEN 1 AND 5),
    estimated_reading_minutes INTEGER DEFAULT 0,
    download_count INTEGER NOT NULL DEFAULT 0,
    rating_average NUMERIC(3,2) DEFAULT 0.0 CHECK (rating_average BETWEEN 0.0 AND 5.0),
    rating_count INTEGER NOT NULL DEFAULT 0,
    is_premium BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Chapters table
CREATE TABLE IF NOT EXISTS chapters (
    id UUID PRIMARY KEY,
    book_id BIGINT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    position INTEGER NOT NULL,
    word_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Quotes table (for recommendation system)
CREATE TABLE IF NOT EXISTS quotes (
    id UUID PRIMARY KEY,
    book_id BIGINT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    position INTEGER NOT NULL, -- paragraph index
    chapter_title TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Swipe logs table (for Tinder/Facemash style interactions)
CREATE TABLE IF NOT EXISTS swipe_logs (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    quote_id UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
    mode TEXT NOT NULL CHECK (mode IN ('tinder', 'facemash')),
    choice INTEGER NOT NULL CHECK (choice IN (-1, 0, 1)), -- -1=left, 0=dislike, 1=like
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Reading sessions table
CREATE TABLE IF NOT EXISTS reading_sessions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id BIGINT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    start_pos INTEGER NOT NULL DEFAULT 0,
    current_pos INTEGER NOT NULL DEFAULT 0,
    duration_sec INTEGER NOT NULL DEFAULT 0,
    mood TEXT,
    weather TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Ratings table (composite primary key on user_id + book_id)
CREATE TABLE IF NOT EXISTS ratings (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id BIGINT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, book_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_books_title ON books(title);
CREATE INDEX IF NOT EXISTS idx_books_author ON books(author);
CREATE INDEX IF NOT EXISTS idx_books_genre ON books(genre);
CREATE INDEX IF NOT EXISTS idx_books_epoch ON books(epoch);
CREATE INDEX IF NOT EXISTS idx_books_rating ON books(rating_average DESC);
CREATE INDEX IF NOT EXISTS idx_books_download_count ON books(download_count DESC);
CREATE INDEX IF NOT EXISTS idx_books_is_active ON books(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_books_is_premium ON books(is_premium);

CREATE INDEX IF NOT EXISTS idx_chapters_book_id ON chapters(book_id);
CREATE INDEX IF NOT EXISTS idx_chapters_position ON chapters(book_id, position);

CREATE INDEX IF NOT EXISTS idx_quotes_book_id ON quotes(book_id);
CREATE INDEX IF NOT EXISTS idx_quotes_position ON quotes(book_id, position);

CREATE INDEX IF NOT EXISTS idx_swipe_logs_user_id ON swipe_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_swipe_logs_quote_id ON swipe_logs(quote_id);
CREATE INDEX IF NOT EXISTS idx_swipe_logs_created_at ON swipe_logs(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_reading_sessions_user_id ON reading_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_reading_sessions_book_id ON reading_sessions(book_id);
CREATE INDEX IF NOT EXISTS idx_reading_sessions_created_at ON reading_sessions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ratings_user_id ON ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_book_id ON ratings(book_id);
CREATE INDEX IF NOT EXISTS idx_ratings_rating ON ratings(rating DESC);

-- Create a trigger to update book rating averages when ratings change
CREATE OR REPLACE FUNCTION update_book_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        UPDATE books SET 
            rating_average = COALESCE((
                SELECT AVG(rating)::NUMERIC(3,2) 
                FROM ratings 
                WHERE book_id = OLD.book_id
            ), 0.0),
            rating_count = COALESCE((
                SELECT COUNT(*) 
                FROM ratings 
                WHERE book_id = OLD.book_id
            ), 0)
        WHERE id = OLD.book_id;
        RETURN OLD;
    ELSE
        UPDATE books SET 
            rating_average = COALESCE((
                SELECT AVG(rating)::NUMERIC(3,2) 
                FROM ratings 
                WHERE book_id = NEW.book_id
            ), 0.0),
            rating_count = COALESCE((
                SELECT COUNT(*) 
                FROM ratings 
                WHERE book_id = NEW.book_id
            ), 0)
        WHERE id = NEW.book_id;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_book_rating_stats
    AFTER INSERT OR UPDATE OR DELETE ON ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_book_rating_stats();