from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc, func
from datetime import datetime
import random
import uuid

from models import QuestionAttempt, ConceptMastery, WeakArea, StudySession
from schemas import MockTestQuestion, Difficulty
from services.content_loader import ContentLoader

class MockTestService:
    def __init__(self):
        self.content_loader = ContentLoader()
    
    async def generate_test(
        self, 
        db: Session, 
        student_id: str, 
        duration_minutes: int = 180,
        topics: Optional[List[str]] = None,
        difficulty_distribution: Optional[Dict[str, int]] = None
    ) -> Dict[str, Any]:
        """Generate personalized mock test"""
        
        # Get student's weak areas and mastery profile
        weak_areas = await self._get_student_weak_areas(db, student_id)
        mastery_profile = await self._get_mastery_profile(db, student_id)
        
        # Determine question distribution
        if not difficulty_distribution:
            difficulty_distribution = self._calculate_optimal_distribution(
                weak_areas, mastery_profile
            )
        
        # Select questions for the test
        test_questions = await self._select_test_questions(
            db, student_id, topics, difficulty_distribution, weak_areas
        )
        
        # Create study session
        session = StudySession(
            id=str(uuid.uuid4()),
            student_id=student_id,
            session_type="mock_test",
            duration_seconds=duration_minutes * 60,
            questions_attempted=0,
            questions_correct=0
        )
        db.add(session)
        db.commit()
        
        # Calculate total marks
        total_marks = sum(q["marks"] for q in test_questions)
        
        return {
            "id": session.id,
            "student_id": student_id,
            "questions": [MockTestQuestion(**q).dict() for q in test_questions],
            "total_marks": total_marks,
            "duration_minutes": duration_minutes,
            "created_at": session.start_time,
            "instructions": self._generate_test_instructions(duration_minutes, total_marks)
        }
    
    async def _get_student_weak_areas(self, db: Session, student_id: str) -> List[str]:
        """Get student's weak areas"""
        weak_areas = db.query(WeakArea).filter(
            WeakArea.student_id == student_id,
            WeakArea.resolved_at.is_(None)
        ).order_by(desc(WeakArea.priority_score)).limit(5).all()
        
        return [area.concept_id for area in weak_areas]
    
    async def _get_mastery_profile(self, db: Session, student_id: str) -> Dict[str, float]:
        """Get student's mastery profile"""
        mastery_records = db.query(ConceptMastery).filter(
            ConceptMastery.student_id == student_id
        ).all()
        
        profile = {}
        for record in mastery_records:
            profile[record.concept_id] = record.mastery_score
        
        return profile
    
    def _calculate_optimal_distribution(
        self, 
        weak_areas: List[str], 
        mastery_profile: Dict[str, float]
    ) -> Dict[str, int]:
        """Calculate optimal difficulty distribution based on student profile"""
        
        # Calculate average mastery
        avg_mastery = sum(mastery_profile.values()) / len(mastery_profile) if mastery_profile else 0.5
        
        # Base distribution
        if avg_mastery >= 0.8:
            # Strong student - more hard questions
            return {"easy": 10, "medium": 35, "hard": 35}
        elif avg_mastery >= 0.6:
            # Average student - balanced distribution
            return {"easy": 15, "medium": 40, "hard": 25}
        else:
            # Struggling student - more easy and medium
            return {"easy": 20, "medium": 45, "hard": 15}
    
    async def _select_test_questions(
        self, 
        db: Session, 
        student_id: str, 
        topics: Optional[List[str]], 
        difficulty_distribution: Dict[str, int],
        weak_areas: List[str]
    ) -> List[Dict[str, Any]]:
        """Select questions for the mock test"""
        
        selected_questions = []
        
        # Get recently attempted questions to avoid repetition
        recent_question_ids = db.query(QuestionAttempt.question_id).filter(
            QuestionAttempt.student_id == student_id,
            QuestionAttempt.created_at >= datetime.utcnow() - timedelta(days=30)
        ).distinct().all()
        recent_ids = [qid[0] for qid in recent_question_ids]
        
        # Select questions by difficulty
        for difficulty, count in difficulty_distribution.items():
            difficulty_enum = Difficulty(difficulty)
            
            # Get candidate questions
            candidates = await self._get_candidate_questions(
                db, topics, difficulty_enum, recent_ids, weak_areas
            )
            
            # Select questions with preference for weak areas
            selected = self._select_questions_with_weak_area_preference(
                candidates, count, weak_areas
            )
            
            # Convert to test question format
            for question in selected:
                test_question = {
                    "question_id": question.id,
                    "question_data": question.dict(),
                    "marks": self._calculate_marks(question.difficulty),
                    "time_limit_seconds": question.estimated_seconds
                }
                selected_questions.append(test_question)
        
        # Shuffle questions to randomize order
        random.shuffle(selected_questions)
        
        return selected_questions
    
    async def _get_candidate_questions(
        self, 
        db: Session, 
        topics: Optional[List[str]], 
        difficulty: Difficulty, 
        recent_ids: List[str],
        weak_areas: List[str]
    ) -> List:
        """Get candidate questions for selection"""
        
        candidates = []
        
        # If topics specified, load from those topics
        if topics:
            for topic_id in topics:
                topic_questions = await self.content_loader.load_topic_questions(topic_id)
                candidates.extend([q for q in topic_questions 
                                 if q.difficulty == difficulty and q.id not in recent_ids])
        else:
            # Load from all available topics
            # For now, load from central angle topic as example
            topic_questions = await self.content_loader.load_topic_questions(
                "math.geometry.central_angle_regular_polygon"
            )
            candidates.extend([q for q in topic_questions 
                             if q.difficulty == difficulty and q.id not in recent_ids])
        
        return candidates
    
    def _select_questions_with_weak_area_preference(
        self, 
        candidates: List, 
        count: int, 
        weak_areas: List[str]
    ) -> List:
        """Select questions with preference for weak areas"""
        
        if not candidates:
            return []
        
        # Separate questions by weak area relevance
        weak_area_questions = []
        other_questions = []
        
        for question in candidates:
            if question.primary_concept in weak_areas:
                weak_area_questions.append(question)
            else:
                other_questions.append(question)
        
        # Select 60% from weak areas if available
        weak_area_count = min(int(count * 0.6), len(weak_area_questions))
        other_count = count - weak_area_count
        
        selected = []
        
        # Select weak area questions
        if weak_area_questions:
            selected.extend(random.sample(
                weak_area_questions, 
                min(weak_area_count, len(weak_area_questions))
            ))
        
        # Select other questions
        if other_questions:
            remaining_needed = count - len(selected)
            selected.extend(random.sample(
                other_questions,
                min(remaining_needed, len(other_questions))
            ))
        
        # If still need more questions, take from any category
        if len(selected) < count and candidates:
            remaining = [q for q in candidates if q not in selected]
            needed = count - len(selected)
            selected.extend(random.sample(remaining, min(needed, len(remaining))))
        
        return selected[:count]
    
    def _calculate_marks(self, difficulty: Difficulty) -> int:
        """Calculate marks based on difficulty"""
        marks_map = {
            Difficulty.easy: 3,
            Difficulty.medium: 4,
            Difficulty.hard: 5
        }
        return marks_map.get(difficulty, 4)
    
    def _generate_test_instructions(self, duration_minutes: int, total_marks: int) -> List[str]:
        """Generate test instructions"""
        return [
            f"This test contains questions worth {total_marks} marks.",
            f"Duration: {duration_minutes} minutes ({duration_minutes//60} hours {duration_minutes%60} minutes).",
            "Each question has recommended time limit - try to stick to it.",
            "No negative marking for incorrect answers.",
            "You can navigate between questions and review your answers.",
            "Make sure to submit before time runs out.",
            "Good luck!"
        ]