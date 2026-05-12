from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

# Enums
class ConfidenceLevel(str, Enum):
    not_sure = "not_sure"
    somewhat_sure = "somewhat_sure"
    very_sure = "very_sure"

class Difficulty(str, Enum):
    easy = "easy"
    medium = "medium"
    hard = "hard"

class QuestionType(str, Enum):
    mcq = "mcq"
    integer = "integer"
    multiple_correct = "multiple_correct"
    assertion_reason = "assertion_reason"
    comprehension = "comprehension"

# Student Schemas
class StudentCreate(BaseModel):
    subscription_level: str = "free"
    target_exam: str = "jee"
    class_level: str = "Class 11"

class StudentResponse(BaseModel):
    id: str
    created_at: datetime
    subscription_level: str
    target_exam: str
    class_level: str
    
    class Config:
        from_attributes = True

# Question Schemas
class QuestionData(BaseModel):
    id: str
    text: str
    options: List[str]
    correct_index: int
    explanation: Optional[str] = None
    subject: str
    topic: str
    primary_concept: str
    difficulty: Difficulty
    question_type: QuestionType
    estimated_seconds: int
    frequently_asked: bool = False
    high_weight_topic: bool = False
    solution_steps: List[str] = []
    why_wrong_explanations: Optional[Dict[int, str]] = None
    formulae_used: List[str] = []

# Attempt Schemas
class QuestionAttemptRequest(BaseModel):
    student_id: str
    question_id: str
    selected_option_index: int
    is_correct: bool
    confidence_level: ConfidenceLevel
    time_spent_seconds: int
    mistake_pattern: Optional[str] = None
    misconception_detected: Optional[str] = None
    topic_id: Optional[str] = None
    concept_id: Optional[str] = None

class QuestionAttemptResponse(BaseModel):
    id: str
    mastery_updated: bool
    weak_areas_identified: List[str]

# Adaptive Learning Schemas
class NextQuestionRequest(BaseModel):
    student_id: str
    topic_id: str
    recent_attempts: List[Dict[str, Any]]
    requested_difficulty: Optional[Difficulty] = None
    session_type: str = "practice"  # "practice", "mock_test", "revision"

class NextQuestionResponse(BaseModel):
    question: QuestionData
    recommended_time_seconds: int
    context: Optional[Dict[str, Any]] = None

# Mastery Schemas
class ConceptMasteryData(BaseModel):
    concept_id: str
    mastery_score: float
    total_attempts: int
    correct_attempts: int
    recent_accuracy: float
    trend: str  # "improving", "stable", "declining"

class MasteryProfileResponse(BaseModel):
    student_id: str
    concept_mastery: List[ConceptMasteryData]
    overall_mastery_score: float
    strong_areas: List[str]
    weak_areas: List[str]
    recommendations: List[str] = []

class WeakAreaResponse(BaseModel):
    id: str
    concept_id: str
    topic_id: str
    priority_score: float
    mastery_gap: float
    recent_mistake_count: int
    recommended_practice_questions: List[str]
    practice_intensity: str
    identified_at: datetime

# Mock Test Schemas
class MockTestRequest(BaseModel):
    student_id: str
    duration_minutes: int = 180  # 3 hours default
    topics: Optional[List[str]] = None
    difficulty_distribution: Optional[Dict[str, int]] = None  # {"easy": 10, "medium": 40, "hard": 30}

class MockTestQuestion(BaseModel):
    question_id: str
    question_data: QuestionData
    marks: int
    time_limit_seconds: int

class MockTestResponse(BaseModel):
    id: str
    student_id: str
    questions: List[MockTestQuestion]
    total_marks: int
    duration_minutes: int
    created_at: datetime
    instructions: List[str]

# Analytics Schemas
class StudySessionRequest(BaseModel):
    student_id: str
    session_type: str
    topic_id: Optional[str] = None
    target_duration_minutes: Optional[int] = None

class StudySessionResponse(BaseModel):
    id: str
    session_type: str
    start_time: datetime
    questions_attempted: int
    accuracy: float
    mastery_change: float
    recommendations: List[str]

# Content Management Schemas
class TopicSummary(BaseModel):
    topic_id: str
    title: str
    total_questions: int
    difficulty_distribution: Dict[str, int]
    average_mastery_score: float
    estimated_study_time_minutes: int

class QuestionFilter(BaseModel):
    topics: Optional[List[str]] = None
    concepts: Optional[List[str]] = None
    difficulty: Optional[Difficulty] = None
    question_type: Optional[QuestionType] = None
    has_diagram: Optional[bool] = None
    frequently_asked: Optional[bool] = None

# Recommendation Schemas
class RecommendationRequest(BaseModel):
    student_id: str
    recommendation_type: str  # "next_topic", "practice_questions", "study_material"
    context: Optional[Dict[str, Any]] = None

class RecommendationResponse(BaseModel):
    recommendations: List[Dict[str, Any]]
    confidence_score: float
    reasoning: str