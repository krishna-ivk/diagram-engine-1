#!/usr/bin/env python3
"""
Export Manager
Handles exporting content pipeline data to human-reviewable formats
"""

import json
import csv
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime

class ExportManager:
    """Manages export of pipeline data to various formats"""
    
    def __init__(self, pipeline_root: str):
        self.pipeline_root = Path(pipeline_root)
        self.export_dir = self.pipeline_root / "export"
        self.questions_dir = self.pipeline_root / "questions"
        self.concepts_dir = self.pipeline_root / "concepts"
        self.review_dir = self.pipeline_root / "review"
        
    def export_questions_to_csv(self, output_filename: Optional[str] = None) -> str:
        """Export all questions to CSV format for human review"""
        
        if output_filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_filename = f"questions_review_{timestamp}.csv"
        
        output_path = self.export_dir / output_filename
        self.export_dir.mkdir(parents=True, exist_ok=True)
        
        # CSV headers for question review
        headers = [
            "question_id",
            "question_text",
            "question_type",
            "difficulty",
            "primary_concept",
            "secondary_concepts",
            "answer",
            "estimated_time",
            "class_floor",
            "needs_diagram",
            "diagram_type",
            "mistake_patterns_count",
            "rescue_ladder_count",
            "status",
            "source_type",
            "copyright_status",
            "review_priority"
        ]
        
        with open(output_path, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=headers)
            writer.writeheader()
            
            # Process all question files
            for question_file in self.questions_dir.glob("*.json"):
                try:
                    with open(question_file, 'r') as f:
                        question = json.load(f)
                    
                    # Extract relevant fields for CSV
                    row = {
                        "question_id": question.get("question_id", ""),
                        "question_text": question.get("question_text", ""),
                        "question_type": question.get("question_type", ""),
                        "difficulty": question.get("difficulty", ""),
                        "primary_concept": question.get("primary_concept", ""),
                        "secondary_concepts": ", ".join(question.get("secondary_concepts", [])),
                        "answer": str(question.get("answer", "")),
                        "estimated_time": question.get("estimated_time", 0),
                        "class_floor": question.get("class_floor", ""),
                        "needs_diagram": question.get("diagram_requirements", {}).get("needs_diagram", False),
                        "diagram_type": question.get("diagram_requirements", {}).get("diagram_type", ""),
                        "mistake_patterns_count": len(question.get("mistake_patterns", [])),
                        "rescue_ladder_count": len(question.get("rescue_ladder", [])),
                        "status": question.get("status", ""),
                        "source_type": question.get("source_reference", {}).get("source_type", ""),
                        "copyright_status": self._get_copyright_status(question.get("source_reference", {}).get("source_id", "")),
                        "review_priority": self._calculate_review_priority(question)
                    }
                    
                    writer.writerow(row)
                    
                except Exception as e:
                    print(f"Error processing {question_file}: {e}")
        
        print(f"Exported questions to {output_path}")
        return str(output_path)
    
    def export_concepts_to_csv(self, output_filename: Optional[str] = None) -> str:
        """Export concepts to CSV for academic review"""
        
        if output_filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_filename = f"concepts_review_{timestamp}.csv"
        
        output_path = self.export_dir / output_filename
        
        headers = [
            "concept_id",
            "name",
            "subject",
            "chapter",
            "class_floor",
            "class_ceiling",
            "jee_relevance",
            "prerequisites_count",
            "learning_outcomes_count",
            "needs_diagram",
            "diagram_types",
            "ncert_aligned",
            "estimated_mastery_time",
            "common_misconceptions_count"
        ]
        
        # Load concept taxonomy
        taxonomy_file = self.concepts_dir / "maths_concept_taxonomy.json"
        if not taxonomy_file.exists():
            raise FileNotFoundError("Concept taxonomy file not found")
        
        with open(taxonomy_file) as f:
            taxonomy = json.load(f)
        
        with open(output_path, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=headers)
            writer.writeheader()
            
            for chapter in taxonomy.get("chapters", []):
                for concept in chapter.get("concepts", []):
                    row = {
                        "concept_id": concept.get("concept_id", ""),
                        "name": concept.get("name", ""),
                        "subject": taxonomy.get("subject", ""),
                        "chapter": chapter.get("name", ""),
                        "class_floor": concept.get("class_floor", ""),
                        "class_ceiling": concept.get("class_ceiling", ""),
                        "jee_relevance": concept.get("jee_relevance", ""),
                        "prerequisites_count": len(concept.get("prerequisites", [])),
                        "learning_outcomes_count": len(concept.get("learning_outcomes", [])),
                        "needs_diagram": concept.get("diagram_requirements", {}).get("needs_diagram", False),
                        "diagram_types": ", ".join(concept.get("diagram_requirements", {}).get("diagram_types", [])),
                        "ncert_aligned": bool(concept.get("ncert_alignment")),
                        "estimated_mastery_time": concept.get("estimated_mastery_time", {}).get("average_minutes", 0),
                        "common_misconceptions_count": len(concept.get("common_misconceptions", []))
                    }
                    writer.writerow(row)
        
        print(f"Exported concepts to {output_path}")
        return str(output_path)
    
    def export_review_dashboard(self, output_filename: Optional[str] = None) -> str:
        """Export comprehensive review dashboard"""
        
        if output_filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_filename = f"review_dashboard_{timestamp}.json"
        
        output_path = self.export_dir / output_filename
        
        dashboard = {
            "generated_at": datetime.now().isoformat(),
            "pipeline_stats": self._get_pipeline_stats(),
            "content_summary": self._get_content_summary(),
            "copyright_status": self._get_copyright_summary(),
            "review_priorities": self._get_review_priorities(),
            "quality_metrics": self._get_quality_metrics()
        }
        
        with open(output_path, 'w') as f:
            json.dump(dashboard, f, indent=2)
        
        print(f"Exported review dashboard to {output_path}")
        return str(output_path)
    
    def export_batch_for_review(self, status_filter: str = "academic_review") -> str:
        """Export questions needing specific review"""
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_filename = f"batch_review_{status_filter}_{timestamp}.json"
        output_path = self.export_dir / output_filename
        
        batch_data = {
            "batch_info": {
                "status_filter": status_filter,
                "generated_at": datetime.now().isoformat(),
                "total_items": 0
            },
            "items": []
        }
        
        for question_file in self.questions_dir.glob("*.json"):
            try:
                with open(question_file, 'r') as f:
                    question = json.load(f)
                
                if question.get("status") == status_filter:
                    batch_data["items"].append(question)
                    batch_data["batch_info"]["total_items"] += 1
                    
            except Exception as e:
                print(f"Error processing {question_file}: {e}")
        
        with open(output_path, 'w') as f:
            json.dump(batch_data, f, indent=2)
        
        print(f"Exported {batch_data['batch_info']['total_items']} items for {status_filter} review to {output_path}")
        return str(output_path)
    
    def _get_copyright_status(self, source_id: str) -> str:
        """Get copyright status for a source"""
        
        # This would typically check a sources registry
        # For now, return default status
        return "needs_review"
    
    def _calculate_review_priority(self, question: Dict) -> str:
        """Calculate review priority based on various factors"""
        
        priority_score = 0
        
        # Higher priority for JEE questions
        if question.get("target_exam") == "jee_main":
            priority_score += 3
        
        # Higher priority for questions with diagrams
        if question.get("diagram_requirements", {}).get("needs_diagram"):
            priority_score += 2
        
        # Higher priority for complex questions
        difficulty = question.get("difficulty", "")
        if difficulty in ["jee_pattern", "mock_exam"]:
            priority_score += 2
        
        # Lower priority for foundation questions
        if difficulty == "foundation":
            priority_score -= 1
        
        # Map score to priority
        if priority_score >= 5:
            return "high"
        elif priority_score >= 3:
            return "medium"
        else:
            return "low"
    
    def _get_pipeline_stats(self) -> Dict:
        """Get overall pipeline statistics"""
        
        stats = {
            "total_questions": 0,
            "questions_by_status": {},
            "questions_by_difficulty": {},
            "questions_by_concept": {},
            "diagram_required": 0
        }
        
        for question_file in self.questions_dir.glob("*.json"):
            try:
                with open(question_file, 'r') as f:
                    question = json.load(f)
                
                stats["total_questions"] += 1
                
                # Count by status
                status = question.get("status", "unknown")
                stats["questions_by_status"][status] = stats["questions_by_status"].get(status, 0) + 1
                
                # Count by difficulty
                difficulty = question.get("difficulty", "unknown")
                stats["questions_by_difficulty"][difficulty] = stats["questions_by_difficulty"].get(difficulty, 0) + 1
                
                # Count by concept
                concept = question.get("primary_concept", "unknown")
                stats["questions_by_concept"][concept] = stats["questions_by_concept"].get(concept, 0) + 1
                
                # Count diagram requirements
                if question.get("diagram_requirements", {}).get("needs_diagram"):
                    stats["diagram_required"] += 1
                    
            except Exception as e:
                print(f"Error processing {question_file}: {e}")
        
        return stats
    
    def _get_content_summary(self) -> Dict:
        """Get content summary by type and quality"""
        
        summary = {
            "foundation_questions": 0,
            "bridge_questions": 0,
            "jee_pattern_questions": 0,
            "mock_exam_questions": 0,
            "rescue_questions": 0,
            "questions_with_solutions": 0,
            "questions_with_mistake_patterns": 0,
            "questions_with_rescue_ladders": 0
        }
        
        for question_file in self.questions_dir.glob("*.json"):
            try:
                with open(question_file, 'r') as f:
                    question = json.load(f)
                
                role = question.get("question_role", "")
                if role in summary:
                    summary[role] += 1
                
                if question.get("solution"):
                    summary["questions_with_solutions"] += 1
                
                if question.get("mistake_patterns"):
                    summary["questions_with_mistake_patterns"] += 1
                
                if question.get("rescue_ladder"):
                    summary["questions_with_rescue_ladders"] += 1
                    
            except Exception as e:
                print(f"Error processing {question_file}: {e}")
        
        return summary
    
    def _get_copyright_summary(self) -> Dict:
        """Get copyright status summary"""
        
        summary = {
            "total_sources": 0,
            "by_status": {},
            "by_type": {}
        }
        
        sources_dir = self.pipeline_root / "sources"
        if sources_dir.exists():
            for source_file in sources_dir.glob("*.json"):
                try:
                    with open(source_file, 'r') as f:
                        source = json.load(f)
                    
                    summary["total_sources"] += 1
                    
                    status = source.get("copyright_status", "unknown")
                    summary["by_status"][status] = summary["by_status"].get(status, 0) + 1
                    
                    source_type = source.get("source_type", "unknown")
                    summary["by_type"][source_type] = summary["by_type"].get(source_type, 0) + 1
                    
                except Exception as e:
                    print(f"Error processing {source_file}: {e}")
        
        return summary
    
    def _get_review_priorities(self) -> Dict:
        """Get review priorities breakdown"""
        
        priorities = {
            "high": 0,
            "medium": 0,
            "low": 0
        }
        
        for question_file in self.questions_dir.glob("*.json"):
            try:
                with open(question_file, 'r') as f:
                    question = json.load(f)
                
                priority = self._calculate_review_priority(question)
                priorities[priority] += 1
                
            except Exception as e:
                print(f"Error processing {question_file}: {e}")
        
        return priorities
    
    def _get_quality_metrics(self) -> Dict:
        """Get quality metrics for content"""
        
        metrics = {
            "average_solution_steps": 0,
            "average_mistake_patterns": 0,
            "completeness_score": 0,
            "pedagogical_quality": 0
        }
        
        total_questions = 0
        total_solution_steps = 0
        total_mistake_patterns = 0
        complete_questions = 0
        
        for question_file in self.questions_dir.glob("*.json"):
            try:
                with open(question_file, 'r') as f:
                    question = json.load(f)
                
                total_questions += 1
                
                # Count solution steps
                solution = question.get("solution", {})
                steps = solution.get("steps", [])
                total_solution_steps += len(steps)
                
                # Count mistake patterns
                mistake_patterns = question.get("mistake_patterns", [])
                total_mistake_patterns += len(mistake_patterns)
                
                # Check completeness
                if (question.get("solution") and 
                    question.get("mistake_patterns") and 
                    question.get("primary_concept")):
                    complete_questions += 1
                    
            except Exception as e:
                print(f"Error processing {question_file}: {e}")
        
        if total_questions > 0:
            metrics["average_solution_steps"] = total_solution_steps / total_questions
            metrics["average_mistake_patterns"] = total_mistake_patterns / total_questions
            metrics["completeness_score"] = complete_questions / total_questions
        
        return metrics

def main():
    """Example usage"""
    export_manager = ExportManager("/home/vashista/diagram-engine/content_pipeline")
    
    # Export questions for review
    questions_csv = export_manager.export_questions_to_csv()
    print(f"Questions exported to: {questions_csv}")
    
    # Export concepts for review
    concepts_csv = export_manager.export_concepts_to_csv()
    print(f"Concepts exported to: {concepts_csv}")
    
    # Export review dashboard
    dashboard = export_manager.export_review_dashboard()
    print(f"Dashboard exported to: {dashboard}")
    
    # Export batch for academic review
    batch = export_manager.export_batch_for_review("academic_review")
    print(f"Batch exported to: {batch}")

if __name__ == "__main__":
    main()