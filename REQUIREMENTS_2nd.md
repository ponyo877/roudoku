# Aozora StoryWalk Implementation Instructions

Please implement the following features for the Aozora StoryWalk Flutter application following the requirements document. This is a mobile reading app that finds and narrates the perfect Aozora Bunko book for users based on their context.

## Phase 1: Infrastructure & Database Setup

### Google Cloud Platform Configuration
- Create GCP project for Aozora StoryWalk
- Enable required APIs:
  - Cloud SQL API
  - Cloud Firestore API
  - Cloud Text-to-Speech API
  - Firebase Authentication API
  - Cloud Storage API
  - Cloud Run API
  - Vertex AI API
  - Cloud Pub/Sub API
  - Cloud Tasks API
- Set up service accounts with appropriate IAM roles


## Phase 2: Authentication & User Profile

### Fix User Profile
- Create Flutter screens for:
  - Profile viewing/editing
  - Voice preset configuration (gender, pitch, speed)
  - Preference tags management
- Implement profile data synchronization between Firebase Auth and PostgreSQL

## Phase 3: Aozora Bunko ETL & Search API

### Aozora Bunko Data Pipeline
- Create Cloud Functions for ETL process:
  - Fetch data from GitHub (aozorabunko/aozorabunko_text)
  - Parse XHTML/text files
  - Extract metadata (title, author, epoch, word count)
  - Generate embeddings using Vertex AI Text Embedding API
  - Store in PostgreSQL
- Set up Cloud Scheduler for monthly updates
- Prioritize 200 high-profile works for initial launch

## Phase 4: TTS Audio Player MVP

### 8. Basic TTS Implementation
- Integrate Google Cloud Text-to-Speech API (WaveNet voices)
- Create Flutter audio player with:
  - Play/pause controls
  - Speed adjustment (0.5x-2.0x)
  - Progress tracking
  - Background playback support
- Implement fixed voice preset initially

## Phase 5: Swipe/Pair UI Implementation

### 9. Entertainment Feedback Modes
- Implement Tinder mode:
  - Single quote card display
  - Swipe right (like) / left (dislike) gestures
  - Visual feedback animations
- Implement Facemash mode:
  - Side-by-side quote comparison
  - Tap to select preferred quote
  - Log all interactions to swipe_logs table

## Phase 6: Recommendation Engine v1

### Basic Recommendation System
- Implement weighted hybrid scoring:
  ```
  Score = w1*SwipePref + w2*ContextMatch + w3*MoodMatch + w4*CFScore
  ```
- Create microservices:
  - Embedding service (Vertex AI integration)
  - Context matching service (weather, location, time)
  - Collaborative filtering service
- Start with simple random recommendations from high-profile works pool

## Phase 7: Voice Preset Optimization & BGM

### Advanced Audio Features
- Implement dynamic voice selection based on:
  - User preferences
  - Book genre/epoch
  - Time of day
- Add BGM/environmental sound options:
  - Scene analysis for automatic selection
  - Fade in/out controls
  - Volume mixing

## Phase 8: Reading Logs & Admin Dashboard

### Analytics and Management
- Create reading statistics dashboard:
  - Daily/weekly/monthly reading time
  - Completion rates
  - Genre preferences
- Implement push notifications for reading reminders
- Build web-based admin dashboard for:
  - Content metadata editing
  - Recommendation model monitoring
  - User analytics

## Phase 9: Production Optimization & Beta Testing

### Performance and Launch Preparation
- Implement offline caching:
  - Store up to 10 books locally (subscription feature)
  - Audio file management with automatic cleanup
- Optimize for:
  - API response time < 300ms
  - Search results < 1s
- Implement monetization:
  - AdMob integration (free tier)
  - Subscription system (¥300/month)
  - 20 book limit for free users
- Conduct beta testing
- Prepare app store submissions

## Important Implementation Notes

### Business Model Implementation
- Free tier: AdMob ads between chapters, 20 book limit
- Premium tier: ¥300/month, no ads, 200+ books, offline playback
- No free trial period

### Technical Considerations
- Use Provider or Riverpod for state management
- Implement proper error handling and loading states
- Ensure all Japanese text displays correctly
- Support dark mode and accessibility features
- Implement i18n for future internationalization

### Initial Content Strategy
- Launch with 200 carefully selected high-profile works
- Free users access 20 most popular titles
- Use download/access statistics for popularity ranking

### Infrastructure Settings
- Cloud Run: min/max instances = 1 (initial)
- Monitoring: Firebase Analytics
- Feedback: In-app feedback system

Please proceed with Phase 1 and update me on progress before moving to the next phase.