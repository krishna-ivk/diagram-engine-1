# Diagram Engine Backend API

FastAPI backend for adaptive learning platform with intelligent question selection, mastery tracking, and offline sync support.

## Features

- **Adaptive Question Selection**: ML-inspired algorithms that select questions based on student performance
- **Mastery Tracking**: Real-time tracking of concept mastery with trend analysis
- **Weak Area Detection**: Automatic identification and prioritization of weak areas
- **Mock Test Generation**: Personalized mock tests based on student profiles
- **Offline Sync Support**: Handles offline attempts and syncs when online
- **Content Integration**: Works with existing Flutter content pipeline

## Quick Start

### 1. Setup Environment

```bash
# Copy environment file
cp .env.example .env

# Edit .env with your database configuration
nano .env
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Setup Database

For PostgreSQL:
```bash
# Create database
createdb diagram_engine

# Run migrations (if using Alembic)
alembic upgrade head
```

For SQLite (development):
```bash
# Set DATABASE_URL=sqlite:///./diagram_engine.db in .env
```

### 4. Start Server

```bash
python main.py
```

The API will be available at `http://localhost:8000`

## API Documentation

Visit `http://localhost:8000/docs` for interactive API documentation.

### Key Endpoints

#### Student Management
- `POST /api/v1/students` - Create new student
- `GET /api/v1/students/{student_id}` - Get student profile

#### Adaptive Learning
- `POST /api/v1/adaptive/next-question` - Get next adaptive question
- `POST /api/v1/attempts` - Record question attempt

#### Mastery & Analytics
- `GET /api/v1/students/{student_id}/mastery` - Get mastery profile
- `GET /api/v1/analytics/weak-areas/{student_id}` - Get weak areas

#### Mock Tests
- `POST /api/v1/mock-tests/generate` - Generate personalized mock test

## Architecture

### Services

1. **AdaptiveLearningService**: Intelligent question selection
2. **MasteryTrackingService**: Mastery score calculation and trend analysis
3. **MockTestService**: Personalized test generation
4. **ContentLoader**: Integration with Flutter content pipeline

### Database Models

- **Student**: Student profiles and metadata
- **QuestionAttempt**: Detailed attempt tracking
- **ConceptMastery**: Per-concept mastery scores
- **WeakArea**: Identified weak areas with recommendations
- **StudySession**: Session-based analytics

### Adaptive Algorithm

The question selection algorithm considers:

- Recent performance patterns
- Concept mastery gaps
- Mistake patterns
- Confidence levels
- Time spent on questions
- Consecutive correct/incorrect answers

## Development

### Running Tests

```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run tests
pytest tests/
```

### Database Migrations

```bash
# Create new migration
alembic revision --autogenerate -m "Description"

# Apply migrations
alembic upgrade head
```

## Integration with Flutter

The backend is designed to work seamlessly with the Flutter frontend:

1. **Content Loading**: Uses the same JSON content files as Flutter
2. **Offline Support**: Handles sync when Flutter app is offline
3. **Real-time Updates**: Provides immediate feedback on attempts
4. **Adaptive Intelligence**: Enhances Flutter's local capabilities

## Monitoring

### Health Check

```bash
curl http://localhost:8000/api/v1/health
```

### Logs

The API provides structured logs for monitoring:
- Request/response logging
- Error tracking
- Performance metrics
- Sync status

## Deployment

### Docker

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Environment Variables

Key environment variables:

- `DATABASE_URL`: Database connection string
- `API_HOST`: Server host (default: 0.0.0.0)
- `API_PORT`: Server port (default: 8000)
- `CORS_ORIGINS`: Allowed CORS origins
- `LOG_LEVEL`: Logging level (info, debug, warning, error)

## Performance Considerations

- **Database Indexing**: Proper indexes on frequently queried fields
- **Caching**: In-memory caching for frequently accessed content
- **Connection Pooling**: Database connection pooling for scalability
- **Async Operations**: Non-blocking I/O for better concurrency

## Security

- **CORS**: Configurable CORS for Flutter web app
- **Input Validation**: Pydantic models for request validation
- **SQL Injection Prevention**: SQLAlchemy ORM protection
- **Rate Limiting**: Can be added with middleware

## Contributing

1. Follow PEP 8 style guidelines
2. Add type hints for all functions
3. Write unit tests for new features
4. Update API documentation
5. Test with Flutter frontend integration