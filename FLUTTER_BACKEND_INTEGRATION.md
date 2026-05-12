# Flutter + Backend Integration Guide

Complete implementation of adaptive learning platform with Flutter frontend and FastAPI backend.

## Architecture Overview

```
Flutter Web App (Student Experience)
    ↓ HTTP API Calls
FastAPI Backend (Learning Intelligence)
    ↓
PostgreSQL/SQLite (Data Persistence)
    ↓
JSON Content Files (Question Bank)
```

## What's Been Implemented

### ✅ Backend (FastAPI)

**Core Services:**
- `main.py` - FastAPI application with all endpoints
- `database.py` - Database configuration and session management
- `models.py` - SQLAlchemy models for students, attempts, mastery
- `schemas.py` - Pydantic models for API validation

**Learning Intelligence:**
- `services/adaptive_service.py` - ML-inspired question selection
- `services/mastery_service.py` - Mastery tracking and weak area detection
- `services/mock_test_service.py` - Personalized test generation
- `services/content_loader.py` - Integration with Flutter content pipeline

**Key Features:**
- Adaptive question selection based on performance patterns
- Real-time mastery score calculation with trend analysis
- Weak area identification with prioritized recommendations
- Personalized mock test generation
- Comprehensive attempt tracking and analytics

### ✅ Flutter Frontend Integration

**API Integration:**
- `services/api_client.dart` - HTTP client with error handling
- `services/learning_service.dart` - High-level learning operations
- `services/connectivity_service.dart` - Network connectivity monitoring
- `services/sync_service.dart` - Offline-first synchronization

**UI Components:**
- `widgets/adaptive_question_player.dart` - Smart question player with offline support
- Enhanced question flow with confidence levels and immediate feedback
- Connectivity indicators and offline mode support

**Offline-First Architecture:**
- Local attempt storage with SharedPreferences
- Automatic sync when connectivity restored
- Graceful fallback to local content when API unavailable
- Background sync with retry mechanisms

## Quick Start Guide

### 1. Start Backend

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your database configuration
python main.py
```

Backend will be available at `http://localhost:8000`

### 2. Update Flutter Dependencies

```bash
cd ..
flutter pub get
```

### 3. Run Flutter App

```bash
flutter run -d chrome --web-port 3000
```

Flutter app will be available at `http://localhost:3000`

### 4. Test Integration

Run the integration tests:

```bash
flutter test test/integration_test.dart
```

## API Endpoints

### Student Management
```http
POST /api/v1/stents          # Create student
GET  /api/v1/students/{id}    # Get student profile
```

### Adaptive Learning
```http
POST /api/v1/adaptive/next-question  # Get next adaptive question
POST /api/v1/attempts                # Record question attempt
```

### Analytics
```http
GET /api/v1/students/{id}/mastery    # Get mastery profile
GET /api/v1/analytics/weak-areas/{id} # Get weak areas
```

### Mock Tests
```http
POST /api/v1/mock-tests/generate      # Generate personalized test
```

## Key Features in Action

### 1. Adaptive Question Selection

The backend analyzes:
- Recent accuracy patterns
- Consecutive correct/incorrect answers
- Time spent per question
- Confidence levels
- Mistake patterns

And selects the optimal next question to maximize learning.

### 2. Offline-First Sync

- **Online**: Attempts sync immediately to backend
- **Offline**: Attempts stored locally, queued for sync
- **Reconnection**: Automatic sync of all pending attempts
- **Conflict Resolution**: Last-writer-wins with timestamps

### 3. Mastery Tracking

Real-time calculation of:
- Per-concept mastery scores (0.0 to 1.0)
- Performance trends (improving/stable/declining)
- Weak area identification with priority scoring
- Personalized recommendations

### 4. Mock Test Generation

Creates personalized tests based on:
- Student's weak areas (60% of questions)
- Current mastery level
- Target difficulty distribution
- Time constraints and exam patterns

## Testing the Integration

### 1. Basic Flow Test

```dart
// Test complete learning flow
final student = await learningService.getOrCreateStudent();
final question = await learningService.getNextAdaptiveQuestion(
  topicId: 'math.geometry.central_angle_regular_polygon'
);

// User answers question
final attempt = QuestionAttempt(
  questionId: question.id,
  confidenceLevel: ConfidenceLevel.somewhatSure,
  isCorrect: selectedOption == question.correctIndex,
  timeSpentSeconds: stopwatch.elapsedSeconds,
  timestamp: DateTime.now(),
  levelIndex: 0,
);

await learningService.recordAttempt(attempt);
```

### 2. Offline Mode Test

```dart
// Simulate offline
connectivityService.setConnectivityStatus(false);

// Record attempt (stored locally)
await learningService.recordAttempt(attempt);

// Come back online
connectivityService.setConnectivityStatus(true);

// Sync happens automatically
await Future.delayed(Duration(seconds: 5));
```

### 3. Mastery Profile Test

```dart
final mastery = await learningService.getMasteryProfile();
print('Overall mastery: ${mastery['overall_mastery_score']}');
print('Weak areas: ${mastery['weak_areas']}');
print('Recommendations: ${mastery['recommendations']}');
```

## Performance Optimizations

### Backend
- Database indexes on frequently queried fields
- Connection pooling for scalability
- Async operations throughout
- Content caching for repeated requests

### Flutter
- Lazy loading of questions by topic
- Local caching of mastery data
- Debounced sync operations
- Efficient state management with Riverpod

## Monitoring & Debugging

### Backend Logs
```bash
# View API logs
tail -f /var/log/diagram_engine/api.log

# Database queries
export DATABASE_URL=...
python -c "from database import engine; print(engine.execute('SELECT COUNT(*) FROM question_attempts').scalar())"
```

### Flutter Debugging
```dart
// Enable debug logging
import 'package:flutter/foundation.dart';
if (kDebugMode) {
  print('API Response: $response');
}

// Monitor sync status
final syncStatus = await syncService.getSyncStatus();
print('Pending attempts: ${syncStatus['pending_attempts_count']}');
```

## Next Steps

### Phase 2 Enhancements
1. **Real-time WebSocket** for live progress updates
2. **Advanced Analytics** with learning path recommendations
3. **Parent/Teacher Dashboards** for progress monitoring
4. **Mobile Apps** using same backend API
5. **Content Management System** for teachers

### Scaling Considerations
1. **Redis Caching** for frequently accessed content
2. **Load Balancing** with multiple API instances
3. **Database Sharding** for large student populations
4. **CDN Integration** for static content delivery

## Troubleshooting

### Common Issues

**CORS Errors:**
```python
# In main.py, ensure CORS origins include your Flutter dev URL
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],
)
```

**Database Connection:**
```bash
# Check database is running
pg_isready -h localhost -p 5432

# Test connection
python -c "from database import engine; print('Connected:', engine.url)"
```

**Flutter Build Issues:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Performance Issues

**Slow API Responses:**
- Check database query performance
- Add missing database indexes
- Monitor memory usage

**Flutter Bundle Size:**
- Use lazy loading for content
- Compress images and assets
- Enable web optimizations

## Success Metrics

Track these metrics to ensure the integration is working:

1. **API Response Time** < 200ms for question requests
2. **Sync Success Rate** > 99% for attempt recording
3. **Offline Recovery** 100% of pending attempts sync when online
4. **Adaptive Accuracy** Students show measurable improvement over time
5. **User Engagement** Increased session duration and return visits

This integration provides a solid foundation for your adaptive learning platform with Flutter's excellent UI capabilities combined with powerful backend intelligence.