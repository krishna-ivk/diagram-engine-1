#!/usr/bin/env python3
"""
Review Checklist Processor
Processes structured reviewer checklists and tracks compliance
"""

import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime
from enum import Enum

class ReviewOutcome(Enum):
    APPROVE = "approve"
    REQUEST_REVISION = "request_revision"
    REJECT = "reject"
    ESCALATE = "escalate"

class ChecklistProcessor:
    """Processes reviewer checklists and generates structured reviews"""
    
    def __init__(self, pipeline_root: str):
        self.pipeline_root = Path(pipeline_root)
        self.review_dir = self.pipeline_root / "review"
        self.questions_dir = self.pipeline_root / "questions"
        
        # Load checklists
        self.academic_checklist = self._load_checklist("academic_reviewer_checklist.json")
        self.copyright_checklist = self._load_checklist("copyright_reviewer_checklist.json")
    
    def _load_checklist(self, filename: str) -> Dict:
        """Load a checklist from file"""
        checklist_file = self.review_dir / filename
        with open(checklist_file) as f:
            return json.load(f)
    
    def create_review_session(self, item_id: str, item_type: str, 
                            reviewer_role: str, checklist_type: str) -> str:
        """Create a new review session for an item"""
        
        # Select appropriate checklist
        if checklist_type == "academic":
            checklist = self.academic_checklist
        elif checklist_type == "copyright":
            checklist = self.copyright_checklist
        else:
            raise ValueError(f"Unknown checklist type: {checklist_type}")
        
        # Create review session
        session_id = f"{item_id}_{checklist_type}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        review_session = {
            "session_id": session_id,
            "item_id": item_id,
            "item_type": item_type,
            "reviewer_role": reviewer_role,
            "checklist_type": checklist_type,
            "checklist_version": checklist["version"],
            "created_at": datetime.now().isoformat(),
            "status": "in_progress",
            "responses": {},
            "scores": {},
            "risk_flags": [],
            "conditional_failures": []
        }
        
        # Initialize responses for all questions
        for section in checklist["sections"]:
            for question in section["questions"]:
                question_id = question["id"]
                review_session["responses"][question_id] = {
                    "answer": None,
                    "notes": "",
                    "timestamp": None
                }
        
        # Save review session
        session_file = self.review_dir / f"{session_id}.json"
        with open(session_file, 'w') as f:
            json.dump(review_session, f, indent=2)
        
        return session_id
    
    def submit_review_response(self, session_id: str, question_id: str, 
                            answer: any, notes: str = "") -> bool:
        """Submit a response to a checklist question"""
        
        session_file = self.review_dir / f"{session_id}.json"
        
        if not session_file.exists():
            return False
        
        with open(session_file) as f:
            session = json.load(f)
        
        if question_id not in session["responses"]:
            return False
        
        # Update response
        session["responses"][question_id] = {
            "answer": answer,
            "notes": notes,
            "timestamp": datetime.now().isoformat()
        }
        
        # Save updated session
        with open(session_file, 'w') as f:
            json.dump(session, f, indent=2)
        
        return True
    
    def complete_review(self, session_id: str, reviewer_id: str) -> Tuple[ReviewOutcome, Dict]:
        """Complete a review and calculate outcome"""
        
        session_file = self.review_dir / f"{session_id}.json"
        
        with open(session_file) as f:
            session = json.load(f)
        
        # Get appropriate checklist
        checklist = self.academic_checklist if session["checklist_type"] == "academic" else self.copyright_checklist
        
        # Calculate scores and check requirements
        total_score = 0
        total_weight = 0
        conditional_failures = []
        risk_flags = []
        
        for section in checklist["sections"]:
            for question in section["questions"]:
                question_id = question["id"]
                response = session["responses"].get(question_id, {})
                answer = response.get("answer")
                
                if answer is None:
                    continue  # Skip unanswered questions
                
                weight = question.get("weight", 0)
                total_weight += weight
                
                # Score based on question type
                if question["type"] == "boolean":
                    score = weight if answer else 0
                elif question["type"] == "scale":
                    scale_options = question["scale"]
                    if isinstance(scale_options, list):
                        # Equal distribution across scale options
                        score = (scale_options.index(answer) + 1) * weight / len(scale_options)
                    else:
                        score = weight if answer else 0
                else:
                    score = weight if answer else 0
                
                total_score += score
                
                # Store question score
                session["scores"][question_id] = {
                    "score": score,
                    "weight": weight,
                    "percentage": (score / weight * 100) if weight > 0 else 0
                }
                
                # Check conditional requirements
                conditional_reqs = checklist.get("scoring", {}).get("conditional_requirements", {})
                if question_id in conditional_reqs:
                    req = conditional_reqs[question_id]
                    required_value = req.get("required_value")
                    
                    if isinstance(required_value, list):
                        if answer not in required_value:
                            conditional_failures.append({
                                "question_id": question_id,
                                "requirement": req,
                                "actual": answer,
                                "action": req.get("failure_action", "require_revision")
                            })
                    elif answer != required_value:
                        conditional_failures.append({
                            "question_id": question_id,
                            "requirement": req,
                            "actual": answer,
                            "action": req.get("failure_action", "require_revision")
                        })
                
                # Check for risk flags
                risk_flag_mappings = checklist.get("scoring", {}).get("risk_flags", {})
                for flag_condition, flag_message in risk_flag_mappings.items():
                    if answer == flag_condition:
                        risk_flags.append({
                            "flag": flag_condition,
                            "message": flag_message,
                            "question_id": question_id
                        })
        
        # Calculate overall percentage
        overall_percentage = (total_score / total_weight * 100) if total_weight > 0 else 0
        passing_threshold = checklist["scoring"]["passing_threshold"]
        passing_percentage = (passing_threshold / checklist["scoring"]["total_weight"] * 100)
        
        # Determine outcome
        outcome = ReviewOutcome.APPROVE
        outcome_reasons = []
        
        # Check for auto-reject conditions
        auto_reject_failures = [f for f in conditional_failures if f.get("action") == "auto_reject"]
        if auto_reject_failures:
            outcome = ReviewOutcome.REJECT
            outcome_reasons.extend([f"Auto-reject: {f['question_id']}" for f in auto_reject_failures])
        
        # Check for auto-escalate conditions
        auto_escalate_failures = [f for f in conditional_failures if f.get("action") == "escalate"]
        if auto_escalate_failures:
            outcome = ReviewOutcome.ESCALATE
            outcome_reasons.extend([f"Escalate: {f['question_id']}" for f in auto_escalate_failures])
        
        # Check passing score
        if outcome == ReviewOutcome.APPROVE and total_score < passing_threshold:
            outcome = ReviewOutcome.REQUEST_REVISION
            outcome_reasons.append(f"Score below threshold: {overall_percentage:.1f}% < {passing_percentage:.1f}%")
        
        # Check for critical risk flags
        if risk_flags and outcome == ReviewOutcome.APPROVE:
            outcome = ReviewOutcome.REQUEST_REVISION
            outcome_reasons.extend([f"Risk flag: {flag['message']}" for flag in risk_flags])
        
        # Update session with results
        session.update({
            "status": "completed",
            "completed_at": datetime.now().isoformat(),
            "reviewer_id": reviewer_id,
            "total_score": total_score,
            "total_weight": total_weight,
            "overall_percentage": overall_percentage,
            "passing_threshold": passing_threshold,
            "outcome": outcome.value,
            "outcome_reasons": outcome_reasons,
            "conditional_failures": conditional_failures,
            "risk_flags": risk_flags
        })
        
        # Save completed session
        with open(session_file, 'w') as f:
            json.dump(session, f, indent=2)
        
        # Generate outcome description
        outcome_descriptions = checklist.get("review_outcomes", {})
        description = outcome_descriptions.get(outcome.value, "Review completed")
        
        result = {
            "outcome": outcome,
            "description": description,
            "score": total_score,
            "percentage": overall_percentage,
            "reasons": outcome_reasons,
            "conditional_failures": conditional_failures,
            "risk_flags": risk_flags
        }
        
        return outcome, result
    
    def get_pending_reviews(self, reviewer_role: str) -> List[Dict]:
        """Get all pending reviews for a reviewer"""
        
        pending_reviews = []
        
        for session_file in self.review_dir.glob("*_academic_*.json"):
            try:
                with open(session_file) as f:
                    session = json.load(f)
                
                if session["status"] == "in_progress" and session["reviewer_role"] == reviewer_role:
                    pending_reviews.append(session)
            except Exception:
                continue
        
        for session_file in self.review_dir.glob("*_copyright_*.json"):
            try:
                with open(session_file) as f:
                    session = json.load(f)
                
                if session["status"] == "in_progress" and session["reviewer_role"] == reviewer_role:
                    pending_reviews.append(session)
            except Exception:
                continue
        
        return pending_reviews
    
    def generate_review_summary(self, item_id: str) -> Dict:
        """Generate summary of all reviews for an item"""
        
        reviews = []
        
        # Find all review sessions for this item
        for session_file in self.review_dir.glob(f"{item_id}_*.json"):
            try:
                with open(session_file) as f:
                    session = json.load(f)
                
                if session.get("status") == "completed":
                    reviews.append({
                        "session_id": session["session_id"],
                        "checklist_type": session["checklist_type"],
                        "reviewer_role": session["reviewer_role"],
                        "reviewer_id": session.get("reviewer_id"),
                        "outcome": session.get("outcome"),
                        "percentage": session.get("overall_percentage"),
                        "completed_at": session.get("completed_at")
                    })
            except Exception:
                continue
        
        return {
            "item_id": item_id,
            "total_reviews": len(reviews),
            "reviews": reviews,
            "overall_status": self._determine_overall_status(reviews)
        }
    
    def _determine_overall_status(self, reviews: List[Dict]) -> str:
        """Determine overall status based on all reviews"""
        
        if not reviews:
            return "pending"
        
        # Check for any rejections
        if any(review["outcome"] == "reject" for review in reviews):
            return "rejected"
        
        # Check for escalations
        if any(review["outcome"] == "escalate" for review in reviews):
            return "escalated"
        
        # Check if all required reviews are complete
        academic_review = next((r for r in reviews if r["checklist_type"] == "academic"), None)
        copyright_review = next((r for r in reviews if r["checklist_type"] == "copyright"), None)
        
        if academic_review and copyright_review:
            if academic_review["outcome"] == "approve" and copyright_review["outcome"] == "approve":
                return "approved"
            else:
                return "revision_required"
        
        return "in_progress"

def main():
    """Example usage"""
    processor = ChecklistProcessor("/home/vashista/diagram-engine/content_pipeline")
    
    # Create a review session
    session_id = processor.create_review_session(
        "sample_foundation_1", 
        "question", 
        "academic_reviewer_1", 
        "academic"
    )
    
    print(f"Created review session: {session_id}")
    
    # Submit some responses
    processor.submit_review_response(session_id, "concept_tag_correct", True, "Concept is accurately identified")
    processor.submit_review_response(session_id, "answer_correct", True, "Answer verified mathematically")
    processor.submit_review_response(session_id, "solution_correct", True, "All steps are accurate")
    
    # Complete the review
    outcome, result = processor.complete_review(session_id, "academic_reviewer_1")
    
    print(f"Review outcome: {outcome.value}")
    print(f"Score: {result['percentage']:.1f}%")
    if result['reasons']:
        print("Reasons:")
        for reason in result['reasons']:
            print(f"  - {reason}")

if __name__ == "__main__":
    main()