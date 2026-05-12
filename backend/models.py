from sqlalchemy import Column, String, Integer, Float, DateTime, Boolean, Text, JSON, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from database import Base
import uuid
from datetime import datetime

class Student(Base):
    __tablename__ = "students"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    subscription_level = Column(String, default="free")
    target_exam = Column(String, default="jee")
    class_level = Column(String, default="Class 11")
    
    # Relationships
    attempts = relationship("QuestionAttempt", back_populates="student")
    mastery_records = relationship("ConceptMastery", back_populates="student")
    weak_areas = relationship("WeakArea", back_populates="student")

class QuestionAttempt(Base):
    __tablename__ = "question_attempts"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(String, ForeignKey("students.id"))
    question_id = Column(String, nullable=False)
    
    # Attempt data
    selected_option_index = Column(Integer)
    is_correct = Column(Boolean, nullable=False)
    confidence_level = Column(String)  # "not_sure", "somewhat_sure", "very_sure"
    time_spent_seconds = Column(Integer)
    
    # Learning metadata
    mistake_pattern = Column(String)
    misconception_detected = Column(String)
    topic_id = Column(String)
    concept_id = Column(String)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    student = relationship("Student", back_populates="attempts")

class ConceptMastery(Base):
    __tablename__ = "concept_mastery"
    
    student_id = Column(String, ForeignKey("students.id"), primary_key=True)
    concept_id = Column(String, primary_key=True)
    
    # Mastery metrics
    mastery_score = Column(Float, default=0.0)  # 0.0 to 1.0
    total_attempts = Column(Integer, default=0)
    correct_attempts = Column(Integer, default=0)
    recent_attempts = Column(Integer, default=0)
    recent_correct = Column(Integer, default=0)
    
    # Learning data
    first_attempt_at = Column(DateTime)
    last_attempt_at = Column(DateTime)
    last_correct_at = Column(DateTime)
    
    # Timestamps
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    student = relationship("Student", back_populates="mastery_records")

class WeakArea(Base):
    __tablename__ = "weak_areas"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(String, ForeignKey("students.id"))
    concept_id = Column(String)
    topic_id = Column(String)
    
    # Priority and metrics
    priority_score = Column(Float)  # Higher = more urgent
    mastery_gap = Column(Float)  # Difference between target and current mastery
    recent_mistake_count = Column(Integer, default=0)
    consecutive_mistakes = Column(Integer, default=0)
    
    # Recommendations
    recommended_practice_questions = Column(JSON)  # List of question IDs
    recommended_study_materials = Column(JSON)  # List of resource IDs
    practice_intensity = Column(String, default="medium")  # "low", "medium", "high"
    
    # Timestamps
    identified_at = Column(DateTime, default=datetime.utcnow)
    last_assessed_at = Column(DateTime, default=datetime.utcnow)
    resolved_at = Column(DateTime, nullable=True)
    
    # Relationships
    student = relationship("Student", back_populates="weak_areas")

class QuestionBank(Base):
    __tablename__ = "question_bank"
    
    id = Column(String, primary_key=True)
    
    # Question content (minimal - full content in JSON files)
    text = Column(Text)
    topic_id = Column(String)
    concept_id = Column(String)
    difficulty = Column(String)  # "easy", "medium", "hard"
    question_type = Column(String)  # "mcq", "integer", etc.
    estimated_seconds = Column(Integer)
    
    # Metadata
    subject = Column(String)
    chapter = Column(String)
    exam_type = Column(String)
    frequently_asked = Column(Boolean, default=False)
    high_weight_topic = Column(Boolean, default=False)
    
    # Content management
    is_published = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class StudySession(Base):
    __tablename__ = "study_sessions"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(String, ForeignKey("students.id"))
    
    # Session metadata
    session_type = Column(String)  # "practice", "mock_test", "revision", "quick_drill"
    topic_id = Column(String, nullable=True)
    start_time = Column(DateTime, default=datetime.utcnow)
    end_time = Column(DateTime, nullable=True)
    duration_seconds = Column(Integer, nullable=True)
    
    # Session metrics
    questions_attempted = Column(Integer, default=0)
    questions_correct = Column(Integer, default=0)
    average_time_per_question = Column(Float, nullable=True)
    mastery_before = Column(Float, nullable=True)
    mastery_after = Column(Float, nullable=True)
    
    # Session state
    is_completed = Column(Boolean, default=False)
    completion_reason = Column(String, nullable=True)  # "finished", "timeout", "manual"
    
    # Relationships
    student = relationship("Student")