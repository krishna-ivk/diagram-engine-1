from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List, Optional
import uvicorn

from database import get_db, engine, Base
from models import Student, QuestionAttempt, ConceptMastery, WeakArea
from schemas import (
    StudentCreate, StudentResponse, QuestionAttemptRequest, 
    QuestionAttemptResponse, NextQuestionRequest, NextQuestionResponse,
    MasteryProfileResponse, WeakAreaResponse, MockTestRequest, MockTestResponse
)
from services.adaptive_service import AdaptiveLearningService
from services.mastery_service import MasteryTrackingService
from services.mock_test_service import MockTestService

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Diagram Engine Learning API",
    description="Adaptive learning backend for Diagram Engine",
    version="1.0.0"
)

# Enable CORS for Flutter web app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],  # Flutter web dev
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
adaptive_service = AdaptiveLearningService()
mastery_service = MasteryTrackingService()
mock_test_service = MockTestService()

@app.get("/")
async def root():
    return {"message": "Diagram Engine Learning API", "version": "1.0.0"}

@app.post("/api/v1/students", response_model=StudentResponse)
async def create_student(student: StudentCreate, db: Session = Depends(get_db)):
    """Create a new student profile"""
    db_student = Student(**student.dict())
    db.add(db_student)
    db.commit()
    db.refresh(db_student)
    return db_student

@app.get("/api/v1/students/{student_id}", response_model=StudentResponse)
async def get_student(student_id: str, db: Session = Depends(get_db)):
    """Get student profile by ID"""
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    return student

@app.post("/api/v1/adaptive/next-question", response_model=NextQuestionResponse)
async def get_next_question(
    request: NextQuestionRequest, 
    db: Session = Depends(get_db)
):
    """Get next adaptive question based on student performance"""
    try:
        next_question = await adaptive_service.select_next_question(
            db, request.student_id, request.topic_id, request.recent_attempts
        )
        return NextQuestionResponse(
            question=next_question,
            recommended_time_seconds=next_question.estimated_seconds or 60
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/attempts", response_model=QuestionAttemptResponse)
async def record_attempt(
    attempt: QuestionAttemptRequest, 
    db: Session = Depends(get_db)
):
    """Record a student's question attempt and update mastery"""
    try:
        # Save the attempt
        db_attempt = QuestionAttempt(**attempt.dict())
        db.add(db_attempt)
        
        # Update mastery scores
        await mastery_service.update_mastery_from_attempt(
            db, attempt.student_id, attempt.question_id, attempt.is_correct
        )
        
        db.commit()
        db.refresh(db_attempt)
        
        return QuestionAttemptResponse(
            id=db_attempt.id,
            mastery_updated=True,
            weak_areas_identified=[]
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/students/{student_id}/mastery", response_model=MasteryProfileResponse)
async def get_mastery_profile(student_id: str, db: Session = Depends(get_db)):
    """Get student's mastery profile across all concepts"""
    try:
        mastery_data = await mastery_service.get_mastery_profile(db, student_id)
        return MasteryProfileResponse(
            student_id=student_id,
            concept_mastery=mastery_data["concept_mastery"],
            overall_mastery_score=mastery_data["overall_score"],
            strong_areas=mastery_data["strong_areas"],
            weak_areas=mastery_data["weak_areas"]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/analytics/weak-areas/{student_id}", response_model=List[WeakAreaResponse])
async def get_weak_areas(student_id: str, db: Session = Depends(get_db)):
    """Get prioritized weak areas for focused practice"""
    try:
        weak_areas = await mastery_service.get_weak_areas(db, student_id)
        return [WeakAreaResponse(**area) for area in weak_areas]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/mock-tests/generate", response_model=MockTestResponse)
async def generate_mock_test(
    request: MockTestRequest, 
    db: Session = Depends(get_db)
):
    """Generate personalized mock test based on weak areas"""
    try:
        mock_test = await mock_test_service.generate_test(
            db, request.student_id, request.duration_minutes, request.topics
        )
        return MockTestResponse(**mock_test)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "diagram-engine-api"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )