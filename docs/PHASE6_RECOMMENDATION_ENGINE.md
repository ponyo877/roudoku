# Phase 6: Recommendation Engine v1 Implementation

## Overview

This document describes the implementation of the comprehensive recommendation engine for the roudoku project. The engine provides personalized, context-aware book recommendations using a hybrid approach that combines multiple recommendation techniques.

## Architecture

### Core Components

1. **Hybrid Recommendation Service** (`internal/services/hybrid_recommendation_service.go`)
   - Central orchestrator combining all recommendation approaches
   - Weighted hybrid scoring: `Score = w1*SwipePref + w2*ContextMatch + w3*MoodMatch + w4*CFScore + w5*ContentSim + w6*Popularity + w7*Novelty`
   - Real-time caching with 15-minute TTL
   - Response time optimization (<300ms target)

2. **Embedding Service** (`internal/services/embedding_service.go`)
   - Content-based filtering using 768-dimension vectors
   - User preference vector computation from interaction data
   - Cosine similarity calculations for book recommendations
   - Vector operations and normalization utilities

3. **Collaborative Filtering Service** (`internal/services/collaborative_filtering_service.go`)
   - User-item matrix construction from ratings and swipes
   - Pearson correlation for user similarity calculation
   - Implicit feedback handling (swipes, reading sessions)
   - Item-based collaborative filtering

4. **Context-Aware Service** (`internal/services/context_aware_service.go`)
   - Time-based recommendations (morning/evening preferences)
   - Weather-mood correlation analysis
   - Location-based content suggestions
   - Seasonal preference patterns
   - Reading time availability matching

5. **Learning Service** (`internal/services/learning_service.go`)
   - Real-time preference updates from user feedback
   - A/B testing framework for algorithm optimization
   - Performance metrics tracking (CTR, completion rate)
   - Recommendation weight optimization

6. **Personalization Service** (`internal/services/personalization_service.go`)
   - User reading pattern analysis
   - Personalized recommendation strategy determination
   - Cold start problem handling for new users
   - Onboarding question processing

7. **Performance Optimization Service** (`internal/services/performance_optimization_service.go`)
   - Diversity filtering to avoid filter bubbles
   - Novelty vs familiarity balance
   - Response time optimization through caching
   - Quality monitoring and auto-tuning

## Database Schema

### Recommendation Tables (`backend/migrations/015_create_recommendation_tables.sql`)

- **user_preference_vectors**: Stores user embedding vectors and preferences
- **recommendation_feedback**: Tracks user interactions with recommendations
- **ab_test_experiments**: A/B testing experiment configurations
- **user_experiment_assignments**: User assignments to experiment variants
- **recommendation_metrics**: Performance metrics aggregation
- **trending_content**: Trending books and quotes analysis
- **book_similarities**: Precomputed content-based similarities
- **user_similarities**: Precomputed collaborative filtering similarities
- **recommendation_cache**: Response caching for performance

## API Endpoints

### Public Endpoints (`internal/handlers/recommendation_handlers.go`)

- `GET /api/recommendations/books` - Get personalized book recommendations
- `GET /api/recommendations/quotes` - Get quotes for home feed
- `POST /api/recommendations/feedback` - Submit recommendation feedback
- `GET /api/recommendations/explain/{bookId}` - Explain recommendation reasoning
- `GET /api/recommendations/similar/{bookId}` - Get similar books
- `GET /api/recommendations/trending` - Get trending recommendations
- `POST /api/recommendations/update-preferences` - Update user preferences

### Admin Endpoints

- `GET /api/recommendations/metrics` - Get recommendation system metrics

## Key Features

### 1. Hybrid Scoring Algorithm

The recommendation score combines multiple signals:

```
Score = w1*SwipePref + w2*ContextMatch + w3*MoodMatch + w4*CFScore + w5*ContentSim + w6*Popularity + w7*Novelty
```

Default weights:
- Swipe Preference: 25%
- Context Match: 20%
- Mood Match: 15%
- Collaborative Score: 20%
- Content Similarity: 10%
- Popularity: 5%
- Novelty: 5%

### 2. Context-Aware Recommendations

#### Time-based Patterns
- **Morning**: Philosophy, self-help, educational content
- **Afternoon**: Adventure, mystery, engaging content
- **Evening**: Romance, mystery, contemplative content
- **Night**: Poetry, philosophy, relaxing content

#### Weather-Mood Correlation
- **Sunny**: Happy, energetic, optimistic content
- **Rainy**: Cozy, introspective, romantic content
- **Cloudy**: Contemplative, thoughtful content

#### Location-based Recommendations
- **Home**: Any length, intimate content
- **Commute**: Short content (≤30 min), engaging
- **Outdoor**: Adventure, nature-themed content

### 3. Cold Start Handling

For new users without preference data:
- Onboarding questionnaire for quick preference capture
- Popular content recommendations with context filtering
- Exploration-focused weights (popularity: 25%, context: 35%)
- Gradual transition to personalized recommendations

### 4. Performance Optimizations

#### Caching Strategy
- Response caching with context-aware cache keys
- 15-minute TTL for recommendation responses
- Precomputed similarity matrices
- User preference vector caching

#### Diversity Filtering
- Maximum 40% concentration from single genre
- Author and epoch diversity enforcement
- Filter bubble prevention with 15% exploration rate
- Novelty vs familiarity balance (default 30% novelty)

### 5. A/B Testing Framework

- Consistent user assignment using hashing
- Traffic splitting capabilities
- Experiment performance tracking
- Automatic variant selection

### 6. Real-time Learning

- Immediate preference updates from user feedback
- Seasonal pattern recognition
- Reading behavior adaptation
- Performance-based weight optimization

## Implementation Details

### Vector Operations

The system uses 768-dimensional vectors for content representation:
- Books are embedded using content analysis
- User preferences are learned from interaction patterns
- Cosine similarity for content matching
- Weighted average for preference aggregation

### Similarity Calculations

#### Content-based Similarity
```go
similarity = cosine_similarity(book_embedding, user_preference_vector)
```

#### User-based Similarity
```go
similarity = pearson_correlation(user1_ratings, user2_ratings)
```

### Context Vector Construction

Context vectors include:
- Time of day (morning, afternoon, evening, night)
- Day of week (weekday patterns)
- Season (seasonal content preferences)
- Weather conditions
- Mood state
- Location context
- Available reading time

## Performance Metrics

### Target Metrics
- Response time: <300ms
- Click-through rate: >12%
- User satisfaction: >80%
- Diversity score: >70%
- Coverage: >60% of catalog

### Monitoring
- Real-time performance tracking
- Quality metric collection
- A/B test result analysis
- User feedback aggregation

## Usage Examples

### Getting Personalized Recommendations

```bash
GET /api/recommendations/books?limit=20&time_of_day=evening&mood=calm&location=home&available_time=30
```

### Submitting Feedback

```bash
POST /api/recommendations/feedback
{
  "book_id": 12345,
  "action": "liked",
  "feedback_score": 5,
  "recommendation_type": "personalized"
}
```

### Getting Similar Books

```bash
GET /api/recommendations/similar/12345?limit=10
```

## Integration Points

### With Existing Services
- **Book Service**: Content metadata and search
- **User Service**: User preferences and profiles
- **Swipe Service**: User interaction data
- **Reading Session Service**: Usage patterns

### External Dependencies
- **PostgreSQL**: Primary data storage with vector support
- **Vertex AI**: Text embedding generation (future)
- **BigQuery**: Analytics and large-scale processing (future)

## Deployment Considerations

### Environment Variables
- Cache TTL configuration
- A/B test traffic splits
- Performance thresholds
- Database connection settings

### Scaling
- Horizontal scaling of recommendation service
- Database read replicas for recommendation queries
- CDN caching for static recommendations
- Background job processing for batch updates

## Future Enhancements

1. **Machine Learning Integration**
   - Deep learning models for enhanced embedding
   - AutoML for weight optimization
   - Reinforcement learning for exploration

2. **Advanced Features**
   - Cross-book series recommendations
   - Social recommendations from friends
   - Mood-based playlist generation
   - Reading goal alignment

3. **Performance Improvements**
   - GPU acceleration for similarity calculations
   - Distributed caching with Redis
   - Batch prediction APIs
   - Edge computing for low latency

## Monitoring and Maintenance

### Daily Tasks
- Cache cleanup of expired entries
- User similarity matrix updates
- Trending content analysis
- Performance metric collection

### Weekly Tasks
- A/B test performance review
- Recommendation weight optimization
- Quality metric analysis
- User feedback processing

### Monthly Tasks
- Algorithm performance evaluation
- Model retraining with new data
- Seasonal pattern analysis
- System capacity planning

This recommendation engine provides a robust, scalable foundation for personalized content discovery in the roudoku application, with built-in learning capabilities and performance optimization.