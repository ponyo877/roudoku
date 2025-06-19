-- Add tables for analytics and progress tracking

-- Reading analytics table (aggregated daily stats)
CREATE TABLE IF NOT EXISTS reading_analytics (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_reading_time_minutes INTEGER NOT NULL DEFAULT 0,
    total_pages_read INTEGER NOT NULL DEFAULT 0,
    total_words_read INTEGER NOT NULL DEFAULT 0,
    books_started INTEGER NOT NULL DEFAULT 0,
    books_completed INTEGER NOT NULL DEFAULT 0,
    reading_sessions_count INTEGER NOT NULL DEFAULT 0,
    longest_session_minutes INTEGER NOT NULL DEFAULT 0,
    average_session_minutes INTEGER NOT NULL DEFAULT 0,
    favorite_genre TEXT,
    favorite_time_of_day TEXT, -- morning, afternoon, evening, night
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Reading streaks table
CREATE TABLE IF NOT EXISTS reading_streaks (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    current_streak_days INTEGER NOT NULL DEFAULT 0,
    longest_streak_days INTEGER NOT NULL DEFAULT 0,
    last_reading_date DATE,
    streak_start_date DATE,
    total_reading_days INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Reading goals table
CREATE TABLE IF NOT EXISTS reading_goals (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goal_type TEXT NOT NULL CHECK (goal_type IN ('daily_minutes', 'daily_pages', 'weekly_books', 'monthly_books', 'yearly_books')),
    target_value INTEGER NOT NULL,
    current_value INTEGER NOT NULL DEFAULT 0,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    is_achieved BOOLEAN NOT NULL DEFAULT false,
    achieved_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Achievements table
CREATE TABLE IF NOT EXISTS achievements (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    icon_url TEXT,
    category TEXT NOT NULL CHECK (category IN ('reading_time', 'books_completed', 'streak', 'variety', 'social', 'special')),
    requirement_type TEXT NOT NULL,
    requirement_value INTEGER NOT NULL,
    points INTEGER NOT NULL DEFAULT 10,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- User achievements table (earned achievements)
CREATE TABLE IF NOT EXISTS user_achievements (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    earned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    progress INTEGER NOT NULL DEFAULT 100, -- percentage progress
    notified BOOLEAN NOT NULL DEFAULT false,
    UNIQUE(user_id, achievement_id)
);

-- Reading contexts table (mood, weather, location tracking)
CREATE TABLE IF NOT EXISTS reading_contexts (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID REFERENCES reading_sessions(id) ON DELETE CASCADE,
    mood TEXT CHECK (mood IN ('happy', 'sad', 'relaxed', 'excited', 'tired', 'focused', 'anxious', 'neutral')),
    weather TEXT CHECK (weather IN ('sunny', 'cloudy', 'rainy', 'snowy', 'windy', 'stormy')),
    location_type TEXT CHECK (location_type IN ('home', 'office', 'cafe', 'library', 'park', 'transit', 'other')),
    time_of_day TEXT CHECK (time_of_day IN ('early_morning', 'morning', 'afternoon', 'evening', 'night', 'late_night')),
    device_type TEXT CHECK (device_type IN ('phone', 'tablet', 'e-reader', 'computer')),
    ambient_noise_level TEXT CHECK (ambient_noise_level IN ('silent', 'quiet', 'moderate', 'loud')),
    reading_position TEXT CHECK (reading_position IN ('sitting', 'lying', 'standing', 'walking')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Book progress table (detailed progress tracking)
CREATE TABLE IF NOT EXISTS book_progress (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id BIGINT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    current_chapter_id UUID REFERENCES chapters(id),
    current_position INTEGER NOT NULL DEFAULT 0, -- character position in book
    current_page INTEGER NOT NULL DEFAULT 0,
    total_pages INTEGER NOT NULL DEFAULT 0,
    progress_percentage NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    estimated_time_remaining_minutes INTEGER,
    average_reading_speed_wpm INTEGER, -- words per minute
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_read_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    is_abandoned BOOLEAN NOT NULL DEFAULT false,
    abandoned_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, book_id)
);

-- Reading insights table (AI-generated insights)
CREATE TABLE IF NOT EXISTS reading_insights (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    insight_type TEXT NOT NULL CHECK (insight_type IN ('pattern', 'recommendation', 'milestone', 'improvement', 'comparison')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    data JSONB, -- flexible data storage for various insight types
    relevance_score NUMERIC(3,2) NOT NULL DEFAULT 0.50,
    is_read BOOLEAN NOT NULL DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_reading_analytics_user_date ON reading_analytics(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_reading_analytics_date ON reading_analytics(date);

CREATE INDEX IF NOT EXISTS idx_reading_streaks_user_id ON reading_streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_reading_streaks_last_reading ON reading_streaks(last_reading_date);

CREATE INDEX IF NOT EXISTS idx_reading_goals_user_id ON reading_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_reading_goals_active ON reading_goals(user_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_reading_goals_period ON reading_goals(period_start, period_end);

CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_earned_at ON user_achievements(earned_at DESC);

CREATE INDEX IF NOT EXISTS idx_reading_contexts_user_id ON reading_contexts(user_id);
CREATE INDEX IF NOT EXISTS idx_reading_contexts_session_id ON reading_contexts(session_id);
CREATE INDEX IF NOT EXISTS idx_reading_contexts_created_at ON reading_contexts(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_book_progress_user_id ON book_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_book_progress_book_id ON book_progress(book_id);
CREATE INDEX IF NOT EXISTS idx_book_progress_active ON book_progress(user_id, is_completed, is_abandoned) 
    WHERE is_completed = false AND is_abandoned = false;

CREATE INDEX IF NOT EXISTS idx_reading_insights_user_id ON reading_insights(user_id);
CREATE INDEX IF NOT EXISTS idx_reading_insights_unread ON reading_insights(user_id, is_read) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_reading_insights_expires ON reading_insights(expires_at) WHERE expires_at IS NOT NULL;

-- Function to update reading analytics
CREATE OR REPLACE FUNCTION update_reading_analytics()
RETURNS TRIGGER AS $$
DECLARE
    v_date DATE;
    v_duration_minutes INTEGER;
    v_words_read INTEGER;
BEGIN
    -- Only process on UPDATE when session ends or on INSERT if session already has duration
    IF (TG_OP = 'UPDATE' AND OLD.duration_sec < NEW.duration_sec) OR 
       (TG_OP = 'INSERT' AND NEW.duration_sec > 0) THEN
        
        v_date := NEW.created_at::DATE;
        v_duration_minutes := NEW.duration_sec / 60;
        
        -- Calculate words read (approximate)
        SELECT (NEW.current_pos - NEW.start_pos) INTO v_words_read;
        
        -- Insert or update analytics
        INSERT INTO reading_analytics (
            id, user_id, date, total_reading_time_minutes, 
            total_words_read, reading_sessions_count
        ) VALUES (
            gen_random_uuid(), NEW.user_id, v_date, v_duration_minutes,
            v_words_read, 1
        )
        ON CONFLICT (user_id, date) DO UPDATE SET
            total_reading_time_minutes = reading_analytics.total_reading_time_minutes + v_duration_minutes,
            total_words_read = reading_analytics.total_words_read + v_words_read,
            reading_sessions_count = reading_analytics.reading_sessions_count + 1,
            longest_session_minutes = GREATEST(reading_analytics.longest_session_minutes, v_duration_minutes),
            average_session_minutes = (reading_analytics.total_reading_time_minutes + v_duration_minutes) / 
                                    (reading_analytics.reading_sessions_count + 1),
            updated_at = NOW();
            
        -- Update reading streak
        PERFORM update_reading_streak(NEW.user_id, v_date);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update reading streaks
CREATE OR REPLACE FUNCTION update_reading_streak(p_user_id UUID, p_reading_date DATE)
RETURNS VOID AS $$
DECLARE
    v_last_reading_date DATE;
    v_current_streak INTEGER;
    v_streak_start DATE;
BEGIN
    -- Get current streak info
    SELECT last_reading_date, current_streak_days, streak_start_date
    INTO v_last_reading_date, v_current_streak, v_streak_start
    FROM reading_streaks
    WHERE user_id = p_user_id;
    
    IF NOT FOUND THEN
        -- First time reading
        INSERT INTO reading_streaks (
            id, user_id, current_streak_days, longest_streak_days,
            last_reading_date, streak_start_date, total_reading_days
        ) VALUES (
            gen_random_uuid(), p_user_id, 1, 1, p_reading_date, p_reading_date, 1
        );
    ELSE
        -- Update existing streak
        IF v_last_reading_date = p_reading_date THEN
            -- Already read today, no update needed
            RETURN;
        ELSIF v_last_reading_date = p_reading_date - INTERVAL '1 day' THEN
            -- Consecutive day, increment streak
            UPDATE reading_streaks SET
                current_streak_days = current_streak_days + 1,
                longest_streak_days = GREATEST(longest_streak_days, current_streak_days + 1),
                last_reading_date = p_reading_date,
                total_reading_days = total_reading_days + 1,
                updated_at = NOW()
            WHERE user_id = p_user_id;
        ELSIF v_last_reading_date < p_reading_date - INTERVAL '1 day' THEN
            -- Streak broken, start new
            UPDATE reading_streaks SET
                current_streak_days = 1,
                last_reading_date = p_reading_date,
                streak_start_date = p_reading_date,
                total_reading_days = total_reading_days + 1,
                updated_at = NOW()
            WHERE user_id = p_user_id;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updating analytics on reading session changes
CREATE TRIGGER trigger_update_reading_analytics
    AFTER INSERT OR UPDATE ON reading_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_reading_analytics();

-- Insert default achievements
INSERT INTO achievements (id, name, description, category, requirement_type, requirement_value, points) VALUES
    (gen_random_uuid(), 'First Page', 'Start your first book', 'books_completed', 'books_started', 1, 10),
    (gen_random_uuid(), 'Bookworm', 'Complete 10 books', 'books_completed', 'books_completed', 10, 50),
    (gen_random_uuid(), 'Speed Reader', 'Read 1000 words per session', 'reading_time', 'words_per_session', 1000, 20),
    (gen_random_uuid(), 'Night Owl', 'Read after midnight', 'special', 'time_based', 0, 15),
    (gen_random_uuid(), 'Early Bird', 'Read before 6 AM', 'special', 'time_based', 6, 15),
    (gen_random_uuid(), 'Consistent Reader', '7-day reading streak', 'streak', 'streak_days', 7, 30),
    (gen_random_uuid(), 'Marathon Reader', '30-day reading streak', 'streak', 'streak_days', 30, 100),
    (gen_random_uuid(), 'Genre Explorer', 'Read books from 5 different genres', 'variety', 'genres_read', 5, 40),
    (gen_random_uuid(), 'Social Reader', 'Rate 10 books', 'social', 'books_rated', 10, 25),
    (gen_random_uuid(), 'Time Traveler', 'Read books from 3 different epochs', 'variety', 'epochs_read', 3, 35)
ON CONFLICT (name) DO NOTHING;