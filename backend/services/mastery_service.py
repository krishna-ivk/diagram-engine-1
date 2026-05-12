from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc, func, and_
from datetime import datetime, timedelta
import math

from models import QuestionAttempt, ConceptMastery, WeakArea, Student
from schemas import ConceptMasteryData, WeakAreaResponse

class MasteryTrackingService:
    
    async def update_mastery_from_attempt(
        self, 
        db: Session, 
        student_id: str, 
        question_id: str, 
        is_correct: bool
    ) -> None:
        """Update mastery scores based on a question attempt"""
        
        # Get the attempt details
        attempt = db.query(QuestionAttempt).filter(
            QuestionAttempt.student_id == student_id,
            QuestionAttempt.question_id == question_id
        ).order_by(desc(QuestionAttempt.created_at)).first()
        
        if not attempt:
            return
        
        # Update concept mastery
        if attempt.concept_id:
            await self._update_concept_mastery(
                db, student_id, attempt.concept_id, is_correct, attempt
            )
        
        # Update weak areas if incorrect
        if not is_correct and attempt.concept_id:
            await self._update_weak_areas(db, student_id, attempt)
    
    async def _update_concept_mastery(
        self, 
        db: Session, 
        student_id: str, 
        concept_id: str, 
        is_correct: bool, 
        attempt: QuestionAttempt
    ) -> None:
        """Update mastery score for a specific concept"""
        
        # Get or create mastery record
        mastery = db.query(ConceptMastery).filter(
            ConceptMastery.student_id == student_id,
            ConceptMastery.concept_id == concept_id
        ).first()
        
        if not mastery:
            mastery = ConceptMastery(
                student_id=student_id,
                concept_id=concept_id,
                total_attempts=0,
                correct_attempts=0,
                recent_attempts=0,
                recent_correct=0,
                first_attempt_at=datetime.utcnow()
            )
            db.add(mastery)
        
        # Update counts
        mastery.total_attempts += 1
        mastery.recent_attempts += 1
        
        if is_correct:
            mastery.correct_attempts += 1
            mastery.recent_correct += 1
            mastery.last_correct_at = datetime.utcnow()
        
        mastery.last_attempt_at = datetime.utcnow()
        
        # Calculate new mastery score using exponential moving average
        base_accuracy = mastery.correct_attempts / mastery.total_attempts
        recent_accuracy = mastery.recent_correct / max(mastery.recent_attempts, 1)
        
        # Weight recent performance more heavily
        mastery.mastery_score = (0.7 * recent_accuracy + 0.3 * base_accuracy)
        
        # Apply confidence adjustment
        confidence_multiplier = self._get_confidence_multiplier(attempt.confidence_level)
        if is_correct:
            mastery.mastery_score = min(1.0, mastery.mastery_score * (1 + 0.1 * confidence_multiplier))
        else:
            mastery.mastery_score = max(0.0, mastery.mastery_score * (1 - 0.15 * confidence_multiplier))
        
        mastery.updated_at = datetime.utcnow()
        
        # Reset recent counts if they get too high
        if mastery.recent_attempts >= 20:
            mastery.recent_attempts = mastery.recent_correct = 0
        
        db.commit()
    
    def _get_confidence_multiplier(self, confidence_level: str) -> float:
        """Get multiplier based on confidence level"""
        multipliers = {
            "not_sure": 0.5,
            "somewhat_sure": 1.0,
            "very_sure": 1.5
        }
        return multipliers.get(confidence_level, 1.0)
    
    async def _update_weak_areas(
        self, 
        db: Session, 
        student_id: str, 
        attempt: QuestionAttempt
    ) -> None:
        """Update weak areas based on incorrect attempt"""
        
        # Check if weak area already exists
        weak_area = db.query(WeakArea).filter(
            WeakArea.student_id == student_id,
            WeakArea.concept_id == attempt.concept_id
        ).first()
        
        if not weak_area:
            weak_area = WeakArea(
                student_id=student_id,
                concept_id=attempt.concept_id,
                topic_id=attempt.topic_id,
                priority_score=0.0,
                mastery_gap=0.0,
                recent_mistake_count=0,
                consecutive_mistakes=0
            )
            db.add(weak_area)
        
        # Update mistake tracking
        weak_area.recent_mistake_count += 1
        weak_area.consecutive_mistakes += 1
        weak_area.last_assessed_at = datetime.utcnow()
        
        # Get current mastery for gap calculation
        mastery = db.query(ConceptMastery).filter(
            ConceptMastery.student_id == student_id,
            ConceptMastery.concept_id == attempt.concept_id
        ).first()
        
        current_mastery = mastery.mastery_score if mastery else 0.0
        target_mastery = 0.8  # Target 80% mastery
        weak_area.mastery_gap = target_mastery - current_mastery
        
        # Calculate priority score
        weak_area.priority_score = self._calculate_priority_score(weak_area, attempt)
        
        # Update practice intensity based on priority
        weak_area.practice_intensity = self._determine_practice_intensity(
            weak_area.priority_score
        )
        
        # Reset consecutive mistakes if they were previously resolved
        if weak_area.resolved_at and weak_area.resolved_at > datetime.utcnow() - timedelta(days=7):
            weak_area.consecutive_mistakes = 1
            weak_area.resolved_at = None
        
        db.commit()
    
    def _calculate_priority_score(self, weak_area, attempt: QuestionAttempt) -> float:
        """Calculate priority score for weak area"""
        
        score = 0.0
        
        # Base score from mastery gap
        score += weak_area.mastery_gap * 0.4
        
        # Boost for consecutive mistakes
        score += min(weak_area.consecutive_mistakes * 0.1, 0.3)
        
        # Boost for recent mistake frequency
        if weak_area.recent_mistake_count >= 3:
            score += 0.2
        elif weak_area.recent_mistake_count >= 2:
            score += 0.1
        
        # Boost for high-weight topics
        if attempt.topic_id and "high_weight" in attempt.topic_id.lower():
            score += 0.15
        
        # Time decay - older mistakes get lower priority
        days_since_last = (datetime.utcnow() - weak_area.last_assessed_at).days
        time_factor = max(0.3, 1.0 - (days_since_last * 0.05))
        score *= time_factor
        
        return min(1.0, score)
    
    def _determine_practice_intensity(self, priority_score: float) -> str:
        """Determine practice intensity based on priority score"""
        if priority_score >= 0.7:
            return "high"
        elif priority_score >= 0.4:
            return "medium"
        else:
            return "low"
    
    async def get_mastery_profile(self, db: Session, student_id: str) -> Dict[str, Any]:
        """Get comprehensive mastery profile for a student"""
        
        # Get all mastery records
        mastery_records = db.query(ConceptMastery).filter(
            ConceptMastery.student_id == student_id
        ).all()
        
        # Convert to response format
        concept_mastery = []
        total_score = 0.0
        total_attempts = 0
        
        for record in mastery_records:
            # Calculate recent accuracy
            recent_accuracy = (record.recent_correct / max(record.recent_attempts, 1) 
                             if record.recent_attempts > 0 else 0.0)
            
            # Determine trend
            trend = self._calculate_mastery_trend(record)
            
            concept_data = ConceptMasteryData(
                concept_id=record.concept_id,
                mastery_score=record.mastery_score,
                total_attempts=record.total_attempts,
                correct_attempts=record.correct_attempts,
                recent_accuracy=recent_accuracy,
                trend=trend
            )
            concept_mastery.append(concept_data)
            
            total_score += record.mastery_score
            total_attempts += record.total_attempts
        
        # Calculate overall metrics
        overall_score = total_score / len(mastery_records) if mastery_records else 0.0
        
        # Identify strong and weak areas
        strong_areas = [cm.concept_id for cm in concept_mastery if cm.mastery_score >= 0.7]
        weak_areas = [cm.concept_id for cm in concept_mastery if cm.mastery_score <= 0.4]
        
        # Generate recommendations
        recommendations = self._generate_recommendations(concept_mastery, weak_areas)
        
        return {
            "concept_mastery": [cm.dict() for cm in concept_mastery],
            "overall_score": overall_score,
            "strong_areas": strong_areas,
            "weak_areas": weak_areas,
            "recommendations": recommendations
        }
    
    def _calculate_mastery_trend(self, record: ConceptMastery) -> str:
        """Calculate mastery trend based on recent vs overall performance"""
        if record.recent_attempts < 3:
            return "stable"
        
        recent_accuracy = record.recent_correct / record.recent_attempts
        overall_accuracy = record.correct_attempts / max(record.total_attempts, 1)
        
        if recent_accuracy > overall_accuracy + 0.15:
            return "improving"
        elif recent_accuracy < overall_accuracy - 0.15:
            return "declining"
        else:
            return "stable"
    
    def _generate_recommendations(
        self, 
        concept_mastery: List[ConceptMasteryData], 
        weak_areas: List[str]
    ) -> List[str]:
        """Generate personalized recommendations"""
        
        recommendations = []
        
        if not concept_mastery:
            return ["Start with foundational topics to build your baseline mastery."]
        
        # Analyze weak areas
        if weak_areas:
            weak_count = len(weak_areas)
            if weak_count >= 5:
                recommendations.append("Focus on strengthening your weak areas before moving to advanced topics.")
            elif weak_count >= 2:
                recommendations.append(f"Practice your {weak_count} weak concepts to improve overall performance.")
            else:
                recommendations.append("You have few weak areas - maintain your current practice routine.")
        
        # Analyze overall performance
        avg_mastery = sum(cm.mastery_score for cm in concept_mastery) / len(concept_mastery)
        if avg_mastery >= 0.8:
            recommendations.append("Excellent mastery! Consider challenging yourself with harder problems.")
        elif avg_mastery >= 0.6:
            recommendations.append("Good progress! Continue regular practice to reach mastery level.")
        else:
            recommendations.append("Focus on building foundational concepts through consistent practice.")
        
        # Check for declining trends
        declining_concepts = [cm for cm in concept_mastery if cm.trend == "declining"]
        if declining_concepts:
            recommendations.append(f"Review {len(declining_concepts)} concepts where performance is declining.")
        
        return recommendations[:3]  # Return top 3 recommendations
    
    async def get_weak_areas(self, db: Session, student_id: str) -> List[Dict[str, Any]]:
        """Get prioritized weak areas for a student"""
        
        # Get unresolved weak areas, ordered by priority
        weak_areas = db.query(WeakArea).filter(
            WeakArea.student_id == student_id,
            WeakArea.resolved_at.is_(None)
        ).order_by(desc(WeakArea.priority_score)).limit(10).all()
        
        result = []
        for area in weak_areas:
            result.append({
                "id": area.id,
                "concept_id": area.concept_id,
                "topic_id": area.topic_id,
                "priority_score": area.priority_score,
                "mastery_gap": area.mastery_gap,
                "recent_mistake_count": area.recent_mistake_count,
                "consecutive_mistakes": area.consecutive_mistakes,
                "recommended_practice_questions": area.recommended_practice_questions or [],
                "practice_intensity": area.practice_intensity,
                "identified_at": area.identified_at
            })
        
        return result