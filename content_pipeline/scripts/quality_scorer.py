#!/usr/bin/env python3
"""
Quality Scorer
Implements strict 85+ threshold quality scoring for content approval
"""

import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime

class QualityScorer:
    """Implements quality scoring with 85+ threshold for publishing"""
    
    def __init__(self, pipeline_root: str):
        self.pipeline_root = Path(pipeline_root)
        self.questions_dir = self.pipeline_root / "questions"
        self.concepts_dir = self.pipeline_root / "concepts"
        
        # Quality scoring dimensions with weights
        self.scoring_dimensions = {
            "concept_tagging_completeness": {
                "weight": 20,
                "description": "Primary concept, secondary concepts, prerequisites all present and valid"
            },
            "prerequisite_mapping": {
                "weight": 15,
                "description": "All prerequisites exist in concept taxonomy and are appropriate"
            },
            "why_wrong_explanations": {
                "weight": 15,
                "description": "Clear explanations for why incorrect options are wrong"
            },
            "rescue_ladder_quality": {
                "weight": 15,
                "description": "Rescue ladders exist for hard questions and are pedagogically sound"
            },
            "diagram_usefulness": {
                "weight": 15,
                "description": "Diagrams are necessary and well-specified when required"
            },
            "solution_clarity": {
                "weight": 10,
                "description": "Step-by-step solution is clear, correct, and easy to follow"
            },
            "copyright_safety": {
                "weight": 10,
                "description": "Content is original or properly attributed with low copyright risk"
            }
        }
        
        # Minimum score for publishing
        self.publishing_threshold = 85
        
        # Critical requirements (must pass to be eligible for scoring)
        self.critical_requirements = {
            "primary_concept_required": "Every question must have a primary concept",
            "solution_required": "Every question must have a solution",
            "correct_answer_required": "Every question must have a correct answer",
            "academic_review_complete": "Academic review must be completed",
            "copyright_review_complete": "Copyright review must be completed"
        }
    
    def calculate_question_score(self, question_file: Path) -> Tuple[float, Dict[str, any]]:
        """Calculate quality score for a question"""
        
        try:
            with open(question_file) as f:
                question = json.load(f)
        except Exception as e:
            return 0.0, {"error": f"Could not read question file: {e}"}
        
        # Check critical requirements first
        critical_check = self._check_critical_requirements(question)
        if not critical_check["passed"]:
            return 0.0, {"critical_failures": critical_check["failures"]}
        
        # Calculate dimension scores
        dimension_scores = {}
        total_score = 0.0
        
        for dimension, config in self.scoring_dimensions.items():
            score = self._calculate_dimension_score(dimension, question)
            dimension_scores[dimension] = {
                "score": score,
                "weight": config["weight"],
                "weighted_score": score * config["weight"] / 100,
                "description": config["description"]
            }
            total_score += score * config["weight"] / 100
        
        # Determine if publishable
        is_publishable = total_score >= self.publishing_threshold
        
        result = {
            "total_score": total_score,
            "is_publishable": is_publishable,
            "threshold": self.publishing_threshold,
            "dimension_scores": dimension_scores,
            "critical_requirements": critical_check,
            "recommendations": self._generate_recommendations(dimension_scores, total_score)
        }
        
        return total_score, result
    
    def _check_critical_requirements(self, question: Dict) -> Dict[str, any]:
        """Check critical requirements that must be met"""
        
        failures = []
        
        # Check primary concept
        if not question.get("primary_concept"):
            failures.append(self.critical_requirements["primary_concept_required"])
        
        # Check solution exists
        if not question.get("solution"):
            failures.append(self.critical_requirements["solution_required"])
        
        # Check correct answer
        if "answer" not in question or question["answer"] is None:
            failures.append(self.critical_requirements["correct_answer_required"])
        
        # Check review status (would need to check review files in practice)
        status = question.get("status", "")
        if status not in ["academic_review", "copyright_review", "approved", "published"]:
            failures.append("Question has not completed required reviews")
        
        return {
            "passed": len(failures) == 0,
            "failures": failures
        }
    
    def _calculate_dimension_score(self, dimension: str, question: Dict) -> float:
        """Calculate score for a specific dimension"""
        
        if dimension == "concept_tagging_completeness":
            return self._score_concept_tagging(question)
        elif dimension == "prerequisite_mapping":
            return self._score_prerequisites(question)
        elif dimension == "why_wrong_explanations":
            return self._score_why_wrong_explanations(question)
        elif dimension == "rescue_ladder_quality":
            return self._score_rescue_ladders(question)
        elif dimension == "diagram_usefulness":
            return self._score_diagram_usefulness(question)
        elif dimension == "solution_clarity":
            return self._score_solution_clarity(question)
        elif dimension == "copyright_safety":
            return self._score_copyright_safety(question)
        else:
            return 0.0
    
    def _score_concept_tagging(self, question: Dict) -> float:
        """Score concept tagging completeness"""
        
        score = 0.0
        
        # Primary concept present (40% of this dimension)
        if question.get("primary_concept"):
            score += 40
        
        # Secondary concepts appropriate (30% of this dimension)
        secondary = question.get("secondary_concepts", [])
        if secondary:
            score += 20
            if len(secondary) <= 3:  # Not too many secondary concepts
                score += 10
        
        # Prerequisites present and reasonable (30% of this dimension)
        prerequisites = question.get("prerequisites", [])
        if prerequisites:
            score += 20
            if len(prerequisites) <= 5:  # Not too many prerequisites
                score += 10
        
        return score
    
    def _score_prerequisites(self, question: Dict) -> float:
        """Score prerequisite mapping quality"""
        
        score = 75.0  # Base score for having prerequisites
        
        prerequisites = question.get("prerequisites", [])
        if not prerequisites:
            return 0.0
        
        # Check if prerequisites are appropriate for difficulty
        difficulty = question.get("difficulty", "")
        if difficulty == "foundation" and len(prerequisites) <= 2:
            score += 25
        elif difficulty == "bridge" and 2 <= len(prerequisites) <= 4:
            score += 25
        elif difficulty in ["jee_pattern", "mock_exam"] and len(prerequisites) >= 3:
            score += 25
        
        return min(score, 100.0)
    
    def _score_why_wrong_explanations(self, question: Dict) -> float:
        """Score why-wrong explanations"""
        
        score = 0.0
        
        # Check if question has multiple choice options
        options = question.get("options", [])
        if not options:
            return 100.0  # Not applicable for numerical questions
        
        # Check mistake patterns
        mistake_patterns = question.get("mistake_patterns", [])
        if mistake_patterns:
            score += 50
            # Check quality of mistake patterns
            for pattern in mistake_patterns:
                if pattern.get("why_wrong") and len(pattern["why_wrong"]) > 20:
                    score += 10
                if pattern.get("frequency"):
                    score += 5
        
        # Check options have why-wrong explanations
        correct_answer = question.get("answer")
        for option in options:
            if not option.get("isCorrect"):
                if option.get("whyWrong"):
                    score += 25
                break  # Found at least one incorrect option with explanation
        
        return min(score, 100.0)
    
    def _score_rescue_ladders(self, question: Dict) -> float:
        """Score rescue ladder quality"""
        
        difficulty = question.get("difficulty", "")
        rescue_ladder = question.get("rescue_ladder", [])
        
        # Foundation and bridge questions don't need rescue ladders
        if difficulty in ["foundation", "bridge"]:
            return 100.0
        
        # JEE pattern and mock exam questions should have rescue ladders
        if difficulty in ["jee_pattern", "mock_exam"]:
            if not rescue_ladder:
                return 0.0
            
            score = 50.0  # Base score for having rescue ladder
            
            # Check quality of rescue ladder
            if len(rescue_ladder) >= 2:
                score += 25
            if len(rescue_ladder) >= 4:
                score += 25
            
            return score
        
        return 100.0
    
    def _score_diagram_usefulness(self, question: Dict) -> float:
        """Score diagram usefulness"""
        
        diagram_reqs = question.get("diagram_requirements", {})
        needs_diagram = diagram_reqs.get("needs_diagram", False)
        
        if not needs_diagram:
            return 100.0  # No diagram needed
        
        score = 50.0  # Base score for recognizing diagram need
        
        # Check if diagram type is specified
        if diagram_reqs.get("diagram_type"):
            score += 25
        
        # Check if diagram specification is provided
        if diagram_reqs.get("diagram_specification"):
            score += 25
        
        return score
    
    def _score_solution_clarity(self, question: Dict) -> float:
        """Score solution clarity"""
        
        solution = question.get("solution", {})
        if not solution:
            return 0.0
        
        score = 0.0
        
        # Check if solution has steps
        steps = solution.get("steps", [])
        if steps:
            score += 40
            
            # Check step quality
            for step in steps:
                if step.get("description") and len(step["description"]) > 10:
                    score += 10
                if step.get("calculation"):
                    score += 10
                break  # Checked at least one good step
        
        # Check if final answer is provided
        if solution.get("final_answer"):
            score += 20
        
        # Check if method is described
        if solution.get("method"):
            score += 20
        
        return min(score, 100.0)
    
    def _score_copyright_safety(self, question: Dict) -> float:
        """Score copyright safety"""
        
        score = 80.0  # Base score for being in pipeline
        
        source_ref = question.get("source_reference", {})
        source_type = source_ref.get("source_type", "")
        
        # Original content gets highest score
        if source_type == "original_content":
            return 100.0
        
        # NCERT syllabus is safe
        elif source_type == "ncert_syllabus":
            score += 20
        
        # JEE pattern analysis is safer than direct reproduction
        elif source_type == "jee_previous_paper":
            adaptation_notes = source_ref.get("adaptation_notes", "")
            if adaptation_notes:
                score += 15
            else:
                score -= 20  # Penalty for no adaptation notes
        
        # NCERT textbook needs careful review
        elif source_type == "ncert_textbook":
            score -= 30  # High risk
        
        return max(0.0, min(score, 100.0))
    
    def _generate_recommendations(self, dimension_scores: Dict, total_score: float) -> List[str]:
        """Generate improvement recommendations"""
        
        recommendations = []
        
        for dimension, score_data in dimension_scores.items():
            score = score_data["score"]
            
            if score < 70:
                if dimension == "concept_tagging_completeness":
                    recommendations.append("Add missing primary concept or improve concept tagging")
                elif dimension == "prerequisite_mapping":
                    recommendations.append("Review and improve prerequisite mapping")
                elif dimension == "why_wrong_explanations":
                    recommendations.append("Add detailed why-wrong explanations for incorrect options")
                elif dimension == "rescue_ladder_quality":
                    recommendations.append("Add rescue ladders for difficult questions")
                elif dimension == "diagram_usefulness":
                    recommendations.append("Improve diagram specifications or remove unnecessary diagram requirements")
                elif dimension == "solution_clarity":
                    recommendations.append("Improve solution clarity with detailed steps")
                elif dimension == "copyright_safety":
                    recommendations.append("Review copyright compliance and add adaptation notes")
        
        if total_score < self.publishing_threshold:
            recommendations.append(f"Score must be {self.publishing_threshold}+ for publishing (current: {total_score:.1f})")
        
        return recommendations
    
    def score_all_questions(self) -> Dict[str, Dict]:
        """Score all questions in the pipeline"""
        
        results = {}
        
        for question_file in self.questions_dir.glob("*.json"):
            score, details = self.calculate_question_score(question_file)
            results[question_file.name] = {
                "score": score,
                "details": details
            }
        
        return results
    
    def generate_quality_report(self, output_filename: Optional[str] = None) -> str:
        """Generate comprehensive quality report"""
        
        if output_filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_filename = f"quality_report_{timestamp}.json"
        
        output_path = self.pipeline_root / "review" / output_filename
        
        all_scores = self.score_all_questions()
        
        # Calculate summary statistics
        scores = [result["score"] for result in all_scores.values()]
        publishable_count = sum(1 for result in all_scores.values() if result["details"]["is_publishable"])
        
        summary = {
            "total_questions": len(all_scores),
            "average_score": sum(scores) / len(scores) if scores else 0,
            "highest_score": max(scores) if scores else 0,
            "lowest_score": min(scores) if scores else 0,
            "publishable_questions": publishable_count,
            "publishing_threshold": self.publishing_threshold,
            "publishable_percentage": (publishable_count / len(all_scores) * 100) if all_scores else 0
        }
        
        report = {
            "generated_at": datetime.now().isoformat(),
            "summary": summary,
            "scoring_dimensions": self.scoring_dimensions,
            "all_scores": all_scores,
            "recommendations": self._generate_overall_recommendations(all_scores)
        }
        
        with open(output_path, 'w') as f:
            json.dump(report, f, indent=2)
        
        return str(output_path)
    
    def _generate_overall_recommendations(self, all_scores: Dict) -> List[str]:
        """Generate overall quality improvement recommendations"""
        
        recommendations = []
        
        # Calculate average scores by dimension
        dimension_averages = {}
        for dimension in self.scoring_dimensions.keys():
            scores = []
            for result in all_scores.values():
                dim_scores = result["details"].get("dimension_scores", {})
                if dimension in dim_scores:
                    scores.append(dim_scores[dimension]["score"])
            
            if scores:
                dimension_averages[dimension] = sum(scores) / len(scores)
        
        # Find weakest dimensions
        if dimension_averages:
            weakest = min(dimension_averages.items(), key=lambda x: x[1])
            if weakest[1] < 70:
                recommendations.append(f"Focus on improving {weakest[0]} (average: {weakest[1]:.1f})")
        
        # Check overall quality
        avg_score = sum(result["score"] for result in all_scores.values()) / len(all_scores) if all_scores else 0
        if avg_score < self.publishing_threshold:
            recommendations.append("Overall quality below publishing threshold - comprehensive review needed")
        
        return recommendations

def main():
    """Example usage"""
    scorer = QualityScorer("/home/vashista/diagram-engine/content_pipeline")
    
    # Score all questions
    all_scores = scorer.score_all_questions()
    
    print(f"Quality Scoring Results:")
    print(f"Total questions: {len(all_scores)}")
    
    publishable = sum(1 for result in all_scores.values() if result["details"]["is_publishable"])
    print(f"Publishable questions: {publishable}/{len(all_scores)}")
    
    if all_scores:
        avg_score = sum(result["score"] for result in all_scores.values()) / len(all_scores)
        print(f"Average score: {avg_score:.1f}/{scorer.publishing_threshold}")
    
    # Generate quality report
    report_path = scorer.generate_quality_report()
    print(f"Quality report generated: {report_path}")

if __name__ == "__main__":
    main()