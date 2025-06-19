-- Add tables for AI recommendation engine and premium features

-- User preferences for recommendation engine
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    preferred_genres TEXT[] DEFAULT '{}',
    preferred_authors TEXT[] DEFAULT '{}',
    preferred_epochs TEXT[] DEFAULT '{}',
    preferred_difficulty_levels INTEGER[] DEFAULT '{1,2,3}',
    preferred_reading_length TEXT CHECK (preferred_reading_length IN ('short', 'medium', 'long', 'any')) DEFAULT 'any',
    min_rating NUMERIC(3,2) DEFAULT 0.0,
    max_word_count INTEGER,
    exclude_completed BOOLEAN DEFAULT true,
    exclude_abandoned BOOLEAN DEFAULT true,
    discovery_mode TEXT CHECK (discovery_mode IN ('conservative', 'balanced', 'adventurous')) DEFAULT 'balanced',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Book vectors for content-based filtering (pre-computed embeddings)
CREATE TABLE IF NOT EXISTS book_vectors (
    book_id BIGINT PRIMARY KEY REFERENCES books(id) ON DELETE CASCADE,
    content_vector VECTOR(768), -- Assuming 768-dimensional embeddings
    genre_vector VECTOR(50),    -- Genre-based features
    style_vector VECTOR(100),   -- Writing style features
    difficulty_score NUMERIC(5,3) DEFAULT 0.0,
    popularity_score NUMERIC(5,3) DEFAULT 0.0,
    quality_score NUMERIC(5,3) DEFAULT 0.0,
    novelty_score NUMERIC(5,3) DEFAULT 0.0,
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- User interaction matrix for collaborative filtering
CREATE TABLE IF NOT EXISTS user_interactions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id BIGINT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    interaction_type TEXT NOT NULL CHECK (interaction_type IN ('view', 'start', 'progress', 'complete', 'rate', 'like', 'share', 'bookmark')),
    interaction_value NUMERIC(5,3), -- normalized value 0.0-1.0
    implicit_score NUMERIC(5,3) DEFAULT 0.0, -- calculated implicit preference
    session_duration_minutes INTEGER DEFAULT 0,
    completion_percentage NUMERIC(5,2) DEFAULT 0.0,
    context_data JSONB, -- mood, time, location etc.
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, book_id, interaction_type)
);

-- User similarity matrix for collaborative filtering
CREATE TABLE IF NOT EXISTS user_similarities (
    user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    similarity_score NUMERIC(5,4) NOT NULL,
    similarity_type TEXT NOT NULL CHECK (similarity_type IN ('cosine', 'pearson', 'jaccard')),
    common_books_count INTEGER DEFAULT 0,
    last_calculated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_a_id, user_b_id, similarity_type),
    CHECK (user_a_id != user_b_id)
);

-- Recommendation results cache
CREATE TABLE IF NOT EXISTS recommendation_cache (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recommendation_type TEXT NOT NULL CHECK (recommendation_type IN ('content_based', 'collaborative', 'hybrid', 'trending', 'similar_users')),
    book_ids BIGINT[] NOT NULL,
    scores NUMERIC(5,4)[] NOT NULL,
    reasoning JSONB, -- explanation for recommendations
    context_filters JSONB, -- filters used for generation
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    INDEX(user_id, recommendation_type, expires_at)
);

-- Recommendation feedback for ML training
CREATE TABLE IF NOT EXISTS recommendation_feedback (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id BIGINT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    recommendation_id UUID REFERENCES recommendation_cache(id) ON DELETE SET NULL,
    feedback_type TEXT NOT NULL CHECK (feedback_type IN ('click', 'view', 'start', 'complete', 'rate', 'like', 'dislike', 'not_interested', 'already_read')),
    feedback_value NUMERIC(3,2), -- -1.0 to 1.0
    position_in_list INTEGER, -- where in recommendation list
    time_to_action_seconds INTEGER, -- how long user took to act
    context_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Subscription plans
CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    price_monthly NUMERIC(10,2) NOT NULL,
    price_yearly NUMERIC(10,2),
    features JSONB NOT NULL, -- list of features included
    max_premium_books INTEGER, -- -1 for unlimited
    max_tts_minutes_per_day INTEGER, -- -1 for unlimited
    max_offline_downloads INTEGER, -- -1 for unlimited
    has_advanced_analytics BOOLEAN DEFAULT false,
    has_ai_recommendations BOOLEAN DEFAULT false,
    has_priority_support BOOLEAN DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- User subscriptions
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id),
    status TEXT NOT NULL CHECK (status IN ('active', 'canceled', 'expired', 'pending', 'suspended')),
    billing_cycle TEXT NOT NULL CHECK (billing_cycle IN ('monthly', 'yearly')),
    price_paid NUMERIC(10,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    current_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    current_period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    trial_end TIMESTAMP WITH TIME ZONE,
    canceled_at TIMESTAMP WITH TIME ZONE,
    cancel_reason TEXT,
    external_subscription_id TEXT, -- Stripe/PayPal ID
    payment_method_id TEXT,
    auto_renew BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Usage tracking for premium features
CREATE TABLE IF NOT EXISTS usage_tracking (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    feature_type TEXT NOT NULL CHECK (feature_type IN ('tts_minutes', 'premium_book_access', 'offline_download', 'ai_recommendation')),
    usage_date DATE NOT NULL,
    usage_count INTEGER NOT NULL DEFAULT 0,
    usage_value NUMERIC(10,2) DEFAULT 0.0, -- for features with measured values (e.g., TTS minutes)
    metadata JSONB, -- additional usage context
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, feature_type, usage_date)
);

-- A/B testing experiments for recommendations
CREATE TABLE IF NOT EXISTS recommendation_experiments (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    algorithm_type TEXT NOT NULL,
    parameters JSONB NOT NULL,
    target_percentage NUMERIC(5,2) NOT NULL, -- 0.0-100.0
    is_active BOOLEAN NOT NULL DEFAULT false,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    success_metrics JSONB, -- metrics to track
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- User experiment assignments
CREATE TABLE IF NOT EXISTS user_experiment_assignments (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    experiment_id UUID NOT NULL REFERENCES recommendation_experiments(id) ON DELETE CASCADE,
    variant TEXT NOT NULL, -- 'control' or 'treatment'
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, experiment_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_interactions_user_id ON user_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_interactions_book_id ON user_interactions(book_id);
CREATE INDEX IF NOT EXISTS idx_user_interactions_type_created ON user_interactions(interaction_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_similarities_score ON user_similarities(similarity_score DESC);
CREATE INDEX IF NOT EXISTS idx_user_similarities_type ON user_similarities(similarity_type);

CREATE INDEX IF NOT EXISTS idx_recommendation_cache_expires ON recommendation_cache(expires_at);
CREATE INDEX IF NOT EXISTS idx_recommendation_cache_user_type ON recommendation_cache(user_id, recommendation_type);

CREATE INDEX IF NOT EXISTS idx_recommendation_feedback_user_book ON recommendation_feedback(user_id, book_id);
CREATE INDEX IF NOT EXISTS idx_recommendation_feedback_type ON recommendation_feedback(feedback_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_status ON user_subscriptions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_period ON user_subscriptions(current_period_start, current_period_end);

CREATE INDEX IF NOT EXISTS idx_usage_tracking_user_date ON usage_tracking(user_id, usage_date DESC);
CREATE INDEX IF NOT EXISTS idx_usage_tracking_feature_date ON usage_tracking(feature_type, usage_date);

-- Function to calculate implicit interaction scores
CREATE OR REPLACE FUNCTION calculate_implicit_score(
    p_interaction_type TEXT,
    p_session_duration INTEGER DEFAULT 0,
    p_completion_percentage NUMERIC DEFAULT 0.0,
    p_interaction_value NUMERIC DEFAULT 0.0
) RETURNS NUMERIC AS $$
DECLARE
    v_score NUMERIC := 0.0;
BEGIN
    CASE p_interaction_type
        WHEN 'view' THEN
            v_score := 0.1 + (p_session_duration::NUMERIC / 3600.0) * 0.2; -- max 0.3
        WHEN 'start' THEN
            v_score := 0.3;
        WHEN 'progress' THEN
            v_score := 0.2 + (p_completion_percentage / 100.0) * 0.5; -- 0.2 to 0.7
        WHEN 'complete' THEN
            v_score := 0.9;
        WHEN 'rate' THEN
            v_score := 0.4 + (p_interaction_value / 5.0) * 0.5; -- 0.4 to 0.9
        WHEN 'like' THEN
            v_score := 0.8;
        WHEN 'share' THEN
            v_score := 0.7;
        WHEN 'bookmark' THEN
            v_score := 0.6;
        ELSE
            v_score := 0.1;
    END CASE;
    
    -- Ensure score is between 0.0 and 1.0
    RETURN GREATEST(0.0, LEAST(1.0, v_score));
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-calculate implicit scores
CREATE OR REPLACE FUNCTION update_implicit_score()
RETURNS TRIGGER AS $$
BEGIN
    NEW.implicit_score := calculate_implicit_score(
        NEW.interaction_type,
        NEW.session_duration_minutes * 60,
        NEW.completion_percentage,
        NEW.interaction_value
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_implicit_score
    BEFORE INSERT OR UPDATE ON user_interactions
    FOR EACH ROW
    EXECUTE FUNCTION update_implicit_score();

-- Function to update usage tracking
CREATE OR REPLACE FUNCTION track_feature_usage(
    p_user_id UUID,
    p_feature_type TEXT,
    p_usage_count INTEGER DEFAULT 1,
    p_usage_value NUMERIC DEFAULT 0.0
) RETURNS VOID AS $$
BEGIN
    INSERT INTO usage_tracking (
        id, user_id, feature_type, usage_date, usage_count, usage_value
    ) VALUES (
        gen_random_uuid(), p_user_id, p_feature_type, CURRENT_DATE, p_usage_count, p_usage_value
    )
    ON CONFLICT (user_id, feature_type, usage_date) DO UPDATE SET
        usage_count = usage_tracking.usage_count + p_usage_count,
        usage_value = usage_tracking.usage_value + p_usage_value,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Insert default subscription plans
INSERT INTO subscription_plans (id, name, description, price_monthly, price_yearly, features, max_premium_books, max_tts_minutes_per_day, max_offline_downloads, has_advanced_analytics, has_ai_recommendations, has_priority_support, sort_order) VALUES
    (
        gen_random_uuid(),
        'Free',
        'Basic reading experience with limited features',
        0.00,
        0.00,
        '["basic_reading", "limited_tts", "basic_stats"]'::JSONB,
        0, -- No premium books
        30, -- 30 minutes TTS per day
        5, -- 5 offline downloads
        false,
        false,
        false,
        1
    ),
    (
        gen_random_uuid(),
        'Premium',
        'Enhanced reading experience with AI recommendations',
        9.99,
        99.99,
        '["unlimited_reading", "unlimited_tts", "advanced_stats", "ai_recommendations", "offline_reading"]'::JSONB,
        -1, -- Unlimited premium books
        -1, -- Unlimited TTS
        -1, -- Unlimited downloads
        true,
        true,
        false,
        2
    ),
    (
        gen_random_uuid(),
        'Premium Plus',
        'Complete reading suite with priority support',
        19.99,
        199.99,
        '["everything_in_premium", "priority_support", "early_access", "advanced_analytics", "custom_recommendations"]'::JSONB,
        -1, -- Unlimited premium books
        -1, -- Unlimited TTS
        -1, -- Unlimited downloads
        true,
        true,
        true,
        3
    )
ON CONFLICT (name) DO NOTHING;