from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc, func
import json
import random
from datetime import datetime, timedelta

from models import QuestionAttempt, ConceptMastery, QuestionBank, Student
from schemas import QuestionData, Difficulty, NextQuestionRequest
from services.content_loader import ContentLoader

class AdaptiveLearningService:
    def __init__(self):
        self.content_loader = ContentLoader()
    
    async def select_next_question(
        self, 
        db: Session, 
        student_id: str, 
        topic_id: str, 
        recent_attempts: List[Dict[str, Any]],
        requested_difficulty: Optional[Difficulty] = None
    ) -> QuestionData:
        """Select the next adaptive question based on student performance"""
        
        # Get student's mastery data for this topic
        mastery_data = self._get_topic_mastery(db, student_id, topic_id)
        
        # Analyze recent performance patterns
        performance_analysis = self._analyze_recent_performance(recent_attempts)
        
        # Determine target difficulty
        target_difficulty = requested_difficulty or self._determine_target_difficulty(
            mastery_data, performance_analysis
        )
        
        # Get candidate questions
        candidate_questions = await self._get_candidate_questions(
            db, topic_id, target_difficulty, student_id
        )
        
        # Select best question using adaptive algorithm
        selected_question = self._select_optimal_question(
            candidate_questions, mastery_data, performance_analysis
        )
        
        return selected_question
    
    def _get_topic_mastery(self, db: Session, student_id: str, topic_id: str) -> Dict[str, float]:
        """Get student's mastery scores for concepts in this topic"""
        mastery_records = db.query(ConceptMastery).filter(
            ConceptMastery.student_id == student_id,
            ConceptMastery.concept_id.like(f"{topic_id}%")
        ).all()
        
        mastery_data = {}
        for record in mastery_records:
            mastery_data[record.concept_id] = record.mastery_score
        
        return mastery_data
    
    def _analyze_recent_performance(self, recent_attempts: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Analyze recent attempt patterns"""
        if not recent_attempts:
            return {
                "recent_accuracy": 0.5,
                "confidence_trend": "stable",
                "time_trend": "stable",
                "mistake_patterns": [],
                "consecutive_correct": 0,
                "consecutive_wrong": 0
            }
        
        # Get last 10 attempts
        recent = recent_attempts[-10:]
        
        correct_count = sum(1 for attempt in recent if attempt.get("is_correct", False))
        recent_accuracy = correct_count / len(recent)
        
        # Analyze consecutive patterns
        consecutive_correct = 0
        consecutive_wrong = 0
        
        for attempt in reversed(recent):
            if attempt.get("is_correct", False):
                if consecutive_wrong == 0:
                    consecutive_correct += 1
                else:
                    break
            else:
                if consecutive_correct == 0:
                    consecutive_wrong += 1
                else:
                    break
        
        # Extract mistake patterns
        mistake_patterns = []
        for attempt in recent:
            if not attempt.get("is_correct", False):
                pattern = attempt.get("mistake_pattern")
                if pattern and pattern not in mistake_patterns:
                    mistake_patterns.append(pattern)
        
        return {
            "recent_accuracy": recent_accuracy,
            "confidence_trend": self._calculate_trend([a.get("confidence_level") for a in recent]),
            "time_trend": self._calculate_time_trend([a.get("time_spent_seconds", 0) for a in recent]),
            "mistake_patterns": mistake_patterns,
            "consecutive_correct": consecutive_correct,
            "consecutive_wrong": consecutive_wrong
        }
    
    def _calculate_trend(self, values: List[str]) -> str:
        """Calculate trend from categorical values"""
        if len(values) < 3:
            return "stable"
        
        # Map confidence levels to numeric values
        confidence_map = {"not_sure": 1, "somewhat_sure": 2, "very_sure": 3}
        numeric_values = [confidence_map.get(v, 2) for v in values if v in confidence_map]
        
        if len(numeric_values) < 3:
            return "stable"
        
        # Simple trend calculation
        first_half = numeric_values[:len(numeric_values)//2]
        second_half = numeric_values[len(numeric_values)//2:]
        
        first_avg = sum(first_half) / len(first_half)
        second_avg = sum(second_half) / len(second_half)
        
        if second_avg > first_avg + 0.3:
            return "improving"
        elif second_avg < first_avg - 0.3:
            return "declining"
        else:
            return "stable"
    
    def _calculate_time_trend(self, times: List[int]) -> str:
        """Calculate trend in time spent"""
        if len(times) < 3:
            return "stable"
        
        first_half = times[:len(times)//2]
        second_half = times[len(times)//2:]
        
        first_avg = sum(first_half) / len(first_half)
        second_avg = sum(second_half) / len(second_half)
        
        if second_avg < first_avg * 0.8:
            return "improving"  # Getting faster
        elif second_avg > first_avg * 1.2:
            return "declining"  # Getting slower
        else:
            return "stable"
    
    def _determine_target_difficulty(
        self, 
        mastery_data: Dict[str, float], 
        performance: Dict[str, Any]
    ) -> Difficulty:
        """Determine appropriate difficulty level"""
        
        recent_accuracy = performance["recent_accuracy"]
        consecutive_correct = performance["consecutive_correct"]
        consecutive_wrong = performance["consecutive_wrong"]
        
        # Calculate average mastery
        avg_mastery = sum(mastery_data.values()) / len(mastery_data) if mastery_data else 0.5
        
        # Difficulty adjustment logic
        if consecutive_correct >= 3 and recent_accuracy >= 0.8:
            return Difficulty.hard
        elif consecutive_correct >= 2 and recent_accuracy >= 0.7:
            return Difficulty.medium
        elif consecutive_wrong >= 3 or recent_accuracy <= 0.3:
            return Difficulty.easy
        elif avg_mastery >= 0.7:
            return Difficulty.medium
        else:
            return Difficulty.easy
    
    async def _get_candidate_questions(
        self, 
        db: Session, 
        topic_id: str, 
        difficulty: Difficulty, 
        student_id: str
    ) -> List[QuestionData]:
        """Get candidate questions for selection"""
        
        # Get recently attempted question IDs to avoid repetition
        recent_question_ids = db.query(QuestionAttempt.question_id).filter(
            QuestionAttempt.student_id == student_id,
            QuestionAttempt.created_at >= datetime.utcnow() - timedelta(days=7)
        ).distinct().all()
        
        recent_ids = [qid[0] for qid in recent_question_ids]
        
        # Load questions from content files
        topic_questions = await self.content_loader.load_topic_questions(topic_id)
        
        # Filter by difficulty and avoid recent questions
        candidates = []
        for question in topic_questions:
            if (question.difficulty == difficulty and 
                question.id not in recent_ids):
                candidates.append(question)
        
        return candidates
    
    def _select_optimal_question(
        self, 
        candidates: List[QuestionData], 
        mastery_data: Dict[str, float], 
        performance: Dict[str, Any]
    ) -> QuestionData:
        """Select the optimal question from candidates using adaptive algorithm"""
        
        if not candidates:
            # Fallback: return any question from the topic
            raise ValueError("No suitable questions found")
        
        # Score each candidate
        scored_candidates = []
        for question in candidates:
            score = self._calculate_question_score(
                question, mastery_data, performance
            )
            scored_candidates.append((question, score))
        
        # Sort by score (descending) and select from top candidates
        scored_candidates.sort(key=lambda x: x[1], reverse=True)
        
        # Add some randomness to prevent predictability
        top_candidates = scored_candidates[:min(5, len(scored_candidates))]
        selected_question, _ = random.choice(top_candidates)
        
        return selected_question
    
    def _calculate_question_score(
        self, 
        question: QuestionData, 
        mastery_data: Dict[str, float], 
        performance: Dict[str, Any]
    ) -> float:
        """Calculate adaptive score for a question"""
        
        score = 0.0
        
        # Base score from concept mastery gap
        concept_mastery = mastery_data.get(question.primary_concept, 0.5)
        mastery_gap = 1.0 - concept_mastery
        score += mastery_gap * 0.4  # 40% weight
        
        # Boost for frequently asked questions
        if question.frequently_asked:
            score += 0.2
        
        # Boost for high weight topics
        if question.high_weight_topic:
            score += 0.15
        
        # Adjust based on mistake patterns
        if performance["mistake_patterns"]:
            # Prefer questions that address recent mistakes
            for pattern in performance["mistake_patterns"]:
                if pattern.lower() in question.text.lower():
                    score += 0.1
                    break
        
        # Time-based adjustment
        if performance["consecutive_wrong"] >= 2:
            # Prefer easier questions after mistakes
            if question.difficulty == Difficulty.easy:
                score += 0.2
        elif performance["consecutive_correct"] >= 3:
            # Prefer harder questions after success
            if question.difficulty == Difficulty.hard:
                score += 0.2
        
        # Add small randomness
        score += random.uniform(0, 0.1)
        
        return score