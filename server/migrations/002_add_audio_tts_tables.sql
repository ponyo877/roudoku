-- Add tables for TTS and audio functionality

-- Audio files table (for TTS-generated content)
CREATE TABLE IF NOT EXISTS audio_files (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id BIGINT REFERENCES books(id) ON DELETE CASCADE,
    chapter_id UUID REFERENCES chapters(id) ON DELETE CASCADE,
    text_content TEXT NOT NULL,
    text_hash VARCHAR(64) NOT NULL, -- SHA-256 hash of text for deduplication
    voice_config JSONB NOT NULL, -- Voice settings used for generation
    file_path TEXT NOT NULL, -- Path to the audio file in storage
    file_size_bytes BIGINT NOT NULL DEFAULT 0,
    duration_seconds NUMERIC(10,3) NOT NULL DEFAULT 0.0,
    format TEXT NOT NULL DEFAULT 'mp3' CHECK (format IN ('mp3', 'wav', 'ogg')),
    sample_rate INTEGER NOT NULL DEFAULT 22050,
    bit_rate INTEGER NOT NULL DEFAULT 64000,
    status TEXT NOT NULL DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
    error_message TEXT,
    play_count INTEGER NOT NULL DEFAULT 0,
    last_played_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE, -- For cache management
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Audio playback sessions table (for analytics)
CREATE TABLE IF NOT EXISTS audio_playback_sessions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    audio_file_id UUID NOT NULL REFERENCES audio_files(id) ON DELETE CASCADE,
    start_position_ms INTEGER NOT NULL DEFAULT 0,
    end_position_ms INTEGER,
    duration_ms INTEGER NOT NULL DEFAULT 0,
    playback_speed NUMERIC(3,2) NOT NULL DEFAULT 1.0,
    completed BOOLEAN NOT NULL DEFAULT false,
    device_type TEXT CHECK (device_type IN ('ios', 'android', 'web')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Notification preferences table
CREATE TABLE IF NOT EXISTS notification_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    push_enabled BOOLEAN NOT NULL DEFAULT true,
    email_enabled BOOLEAN NOT NULL DEFAULT false,
    reading_reminders BOOLEAN NOT NULL DEFAULT true,
    reading_reminder_time TIME NOT NULL DEFAULT '19:00:00',
    weekly_progress BOOLEAN NOT NULL DEFAULT true,
    achievements BOOLEAN NOT NULL DEFAULT true,
    recommendations BOOLEAN NOT NULL DEFAULT true,
    silent_hours_enabled BOOLEAN NOT NULL DEFAULT false,
    silent_hours_start TIME NOT NULL DEFAULT '22:00:00',
    silent_hours_end TIME NOT NULL DEFAULT '08:00:00',
    sound_enabled BOOLEAN NOT NULL DEFAULT true,
    vibration_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- FCM tokens table for push notifications
CREATE TABLE IF NOT EXISTS fcm_tokens (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    device_type TEXT NOT NULL CHECK (device_type IN ('ios', 'android', 'web')),
    device_id TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_used_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Notifications table for history and tracking
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    type TEXT NOT NULL CHECK (type IN ('reading_reminder', 'achievement', 'weekly_progress', 'recommendation', 'general')),
    is_read BOOLEAN NOT NULL DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    fcm_message_id TEXT, -- FCM response message ID
    delivery_status TEXT NOT NULL DEFAULT 'pending' CHECK (delivery_status IN ('pending', 'sent', 'delivered', 'failed')),
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Scheduled notifications table for recurring notifications
CREATE TABLE IF NOT EXISTS scheduled_notifications (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    type TEXT NOT NULL,
    schedule_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_recurring BOOLEAN NOT NULL DEFAULT false,
    recurring_frequency TEXT CHECK (recurring_frequency IN ('daily', 'weekly', 'monthly')),
    recurring_days_of_week INTEGER[] CHECK (array_length(recurring_days_of_week, 1) IS NULL OR (recurring_days_of_week <@ ARRAY[0,1,2,3,4,5,6])),
    recurring_time_of_day TIME,
    recurring_end_date TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_executed_at TIMESTAMP WITH TIME ZONE,
    next_execution_at TIMESTAMP WITH TIME ZONE,
    execution_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_audio_files_user_id ON audio_files(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_files_book_id ON audio_files(book_id);
CREATE INDEX IF NOT EXISTS idx_audio_files_chapter_id ON audio_files(chapter_id);
CREATE INDEX IF NOT EXISTS idx_audio_files_text_hash ON audio_files(text_hash);
CREATE INDEX IF NOT EXISTS idx_audio_files_status ON audio_files(status);
CREATE INDEX IF NOT EXISTS idx_audio_files_expires_at ON audio_files(expires_at) WHERE expires_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_audio_playback_sessions_user_id ON audio_playback_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_playback_sessions_audio_file_id ON audio_playback_sessions(audio_file_id);
CREATE INDEX IF NOT EXISTS idx_audio_playback_sessions_created_at ON audio_playback_sessions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_token ON fcm_tokens(token) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_device_id ON fcm_tokens(user_id, device_id);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(user_id, is_read) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_notifications_sent_at ON notifications(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_expires_at ON notifications(expires_at) WHERE expires_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_scheduled_notifications_user_id ON scheduled_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_notifications_next_execution ON scheduled_notifications(next_execution_at) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_scheduled_notifications_schedule_at ON scheduled_notifications(schedule_at);

-- Create a trigger to update audio file play count
CREATE OR REPLACE FUNCTION update_audio_file_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE audio_files SET 
            play_count = play_count + 1,
            last_played_at = NEW.created_at
        WHERE id = NEW.audio_file_id;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_audio_file_stats
    AFTER INSERT ON audio_playback_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_audio_file_stats();

-- Create a trigger to automatically set next_execution_at for recurring notifications
CREATE OR REPLACE FUNCTION calculate_next_execution()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_recurring AND NEW.is_active THEN
        CASE NEW.recurring_frequency
            WHEN 'daily' THEN
                NEW.next_execution_at = (CURRENT_DATE + INTERVAL '1 day' + NEW.recurring_time_of_day)::TIMESTAMP WITH TIME ZONE;
            WHEN 'weekly' THEN
                NEW.next_execution_at = (CURRENT_DATE + INTERVAL '1 week' + NEW.recurring_time_of_day)::TIMESTAMP WITH TIME ZONE;
            WHEN 'monthly' THEN
                NEW.next_execution_at = (CURRENT_DATE + INTERVAL '1 month' + NEW.recurring_time_of_day)::TIMESTAMP WITH TIME ZONE;
        END CASE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_next_execution
    BEFORE INSERT OR UPDATE ON scheduled_notifications
    FOR EACH ROW
    EXECUTE FUNCTION calculate_next_execution();