#!/usr/bin/env python3
"""
Content Lineage Tracker
Tracks and validates content lineage for copyright protection
"""

import json
from pathlib import Path
from typing import Dict, List, Optional, Set
from datetime import datetime
from enum import Enum

class TransformationType(Enum):
    ORIGINAL_CONTENT = "original_content"
    ORIGINAL_QUESTION_FROM_PATTERN = "original_question_from_pattern"
    ADAPTED_FROM_SOURCE = "adapted_from_source"
    CONCEPT_ALIGNMENT_ONLY = "concept_alignment_only"

class LineageTracker:
    """Tracks content lineage and copyright protection"""
    
    def __init__(self, pipeline_root: str):
        self.pipeline_root = Path(pipeline_root)
        self.questions_dir = self.pipeline_root / "questions"
        self.sources_dir = self.pipeline_root / "sources"
        self.review_dir = self.pipeline_root / "review"
        
        # Lineage validation rules
        self.transformation_requirements = {
            TransformationType.ORIGINAL_CONTENT: {
                "requires_source": False,
                "max_similarity": 0.1,
                "requires_attribution": False,
                "commercial_safe": True
            },
            TransformationType.ORIGINAL_QUESTION_FROM_PATTERN: {
                "requires_source": True,
                "max_similarity": 0.3,
                "requires_attribution": True,
                "commercial_safe": True
            },
            TransformationType.ADAPTED_FROM_SOURCE: {
                "requires_source": True,
                "max_similarity": 0.2,
                "requires_attribution": True,
                "commercial_safe": False  # Needs review
            },
            TransformationType.CONCEPT_ALIGNMENT_ONLY: {
                "requires_source": False,
                "max_similarity": 0.05,
                "requires_attribution": True,
                "commercial_safe": True
            }
        }
    
    def validate_lineage(self, question_file: Path) -> tuple[bool, List[str]]:
        """Validate lineage metadata for a question"""
        
        try:
            with open(question_file) as f:
                question = json.load(f)
        except Exception as e:
            return False, [f"Error reading question file: {e}"]
        
        lineage = question.get("lineage")
        if not lineage:
            return False, ["Missing lineage metadata"]
        
        errors = []
        
        # Validate required fields
        required_fields = ["transformation_type", "verbatim_source_used", "human_review_required"]
        for field in required_fields:
            if field not in lineage:
                errors.append(f"Missing required lineage field: {field}")
        
        # Validate transformation type
        transformation_str = lineage.get("transformation_type")
        try:
            transformation = TransformationType(transformation_str)
        except ValueError:
            errors.append(f"Invalid transformation type: {transformation_str}")
            return False, errors
        
        # Check transformation requirements
        requirements = self.transformation_requirements[transformation]
        
        # Check source requirement
        source_ref = question.get("source_reference", {})
        if requirements["requires_source"] and not source_ref.get("source_id"):
            errors.append(f"Transformation {transformation.value} requires source reference")
        
        # Check similarity (would need actual similarity detection in practice)
        if "similarity_score" in question:
            similarity = question["similarity_score"]
            if similarity > requirements["max_similarity"]:
                errors.append(f"Similarity {similarity:.2f} exceeds threshold {requirements['max_similarity']} for {transformation.value}")
        
        # Check attribution requirement
        if requirements["requires_attribution"]:
            if not lineage.get("inspired_by") and not source_ref.get("source_id"):
                errors.append(f"Transformation {transformation.value} requires attribution")
        
        # Check NCERT alignment
        ncert_alignment = lineage.get("ncert_alignment", [])
        if transformation == TransformationType.ADAPTED_FROM_SOURCE and source_ref.get("source_type") == "ncert_textbook":
            if ncert_alignment:
                errors.append("NCERT textbook adaptations should not be used - use concept alignment only")
        
        return len(errors) == 0, errors
    
    def generate_lineage_report(self) -> Dict:
        """Generate comprehensive lineage report"""
        
        report = {
            "generated_at": datetime.now().isoformat(),
            "summary": {
                "total_questions": 0,
                "by_transformation_type": {},
                "commercial_safe_count": 0,
                "requires_review_count": 0,
                "lineage_completeness": 0
            },
            "validation_results": {},
            "risk_assessment": {},
            "recommendations": []
        }
        
        # Process all questions
        total_questions = 0
        transformation_counts = {}
        commercial_safe = 0
        requires_review = 0
        lineage_complete = 0
        
        for question_file in self.questions_dir.glob("*.json"):
            total_questions += 1
            
            # Validate lineage
            is_valid, errors = self.validate_lineage(question_file)
            report["validation_results"][question_file.name] = {
                "valid": is_valid,
                "errors": errors
            }
            
            if is_valid:
                lineage_complete += 1
            
            # Load question for analysis
            try:
                with open(question_file) as f:
                    question = json.load(f)
                
                lineage = question.get("lineage", {})
                transformation_str = lineage.get("transformation_type", "unknown")
                
                # Count transformation types
                transformation_counts[transformation_str] = transformation_counts.get(transformation_str, 0) + 1
                
                # Assess commercial safety
                try:
                    transformation = TransformationType(transformation_str)
                    if self.transformation_requirements[transformation]["commercial_safe"]:
                        commercial_safe += 1
                    else:
                        requires_review += 1
                except ValueError:
                    requires_review += 1
                
            except Exception as e:
                report["validation_results"][question_file.name]["error"] = str(e)
        
        # Update summary
        report["summary"] = {
            "total_questions": total_questions,
            "by_transformation_type": transformation_counts,
            "commercial_safe_count": commercial_safe,
            "requires_review_count": requires_review,
            "lineage_completeness": (lineage_complete / total_questions * 100) if total_questions > 0 else 0
        }
        
        # Generate risk assessment
        report["risk_assessment"] = self._assess_risks(transformation_counts, total_questions)
        
        # Generate recommendations
        report["recommendations"] = self._generate_recommendations(report["summary"], report["validation_results"])
        
        return report
    
    def _assess_risks(self, transformation_counts: Dict[str, int], total: int) -> Dict:
        """Assess copyright risks based on transformation types"""
        
        risks = {
            "overall_risk": "low",
            "risk_factors": [],
            "high_risk_items": []
        }
        
        # Check for high-risk transformations
        high_risk_transformations = ["adapted_from_source"]
        medium_risk_transformations = ["original_question_from_pattern"]
        
        for transformation, count in transformation_counts.items():
            percentage = (count / total * 100) if total > 0 else 0
            
            if transformation in high_risk_transformations:
                risks["risk_factors"].append(f"{percentage:.1f}% high-risk transformations ({transformation})")
                risks["high_risk_items"].append({
                    "type": transformation,
                    "count": count,
                    "percentage": percentage
                })
            elif transformation in medium_risk_transformations:
                risks["risk_factors"].append(f"{percentage:.1f}% medium-risk transformations ({transformation})")
        
        # Determine overall risk
        high_risk_percentage = sum(item["percentage"] for item in risks["high_risk_items"])
        
        if high_risk_percentage > 20:
            risks["overall_risk"] = "high"
        elif high_risk_percentage > 5 or any("medium-risk" in factor for factor in risks["risk_factors"]):
            risks["overall_risk"] = "medium"
        
        return risks
    
    def _generate_recommendations(self, summary: Dict, validation_results: Dict) -> List[str]:
        """Generate recommendations based on lineage analysis"""
        
        recommendations = []
        
        # Check completeness
        if summary["lineage_completeness"] < 100:
            recommendations.append(f"Complete lineage metadata for {100 - summary['lineage_completeness']:.1f}% of questions")
        
        # Check commercial safety
        if summary["requires_review_count"] > 0:
            recommendations.append(f"Review {summary['requires_review_count']} questions for commercial use safety")
        
        # Check transformation distribution
        transformation_counts = summary["by_transformation_type"]
        
        # Too many adaptations
        adapted_count = transformation_counts.get("adapted_from_source", 0)
        if adapted_count > summary["total_questions"] * 0.1:  # More than 10%
            recommendations.append("Reduce adapted content - focus on original content and concept alignment")
        
        # Not enough original content
        original_count = transformation_counts.get("original_content", 0)
        if original_count < summary["total_questions"] * 0.5:  # Less than 50%
            recommendations.append("Increase original content percentage for better copyright safety")
        
        # Check validation errors
        validation_errors = []
        for filename, result in validation_results.items():
            if not result["valid"]:
                validation_errors.extend(result["errors"])
        
        if validation_errors:
            recommendations.append("Fix lineage validation errors across all questions")
        
        return recommendations
    
    def update_lineage_from_source(self, question_file: Path, source_info: Dict) -> bool:
        """Update lineage metadata based on source information"""
        
        try:
            with open(question_file) as f:
                question = json.load(f)
        except Exception:
            return False
        
        # Determine transformation type
        source_type = source_info.get("source_type", "")
        
        if source_type == "original_content":
            transformation = TransformationType.ORIGINAL_CONTENT
        elif source_type == "jee_previous_paper":
            transformation = TransformationType.ORIGINAL_QUESTION_FROM_PATTERN
        elif source_type == "ncert_syllabus":
            transformation = TransformationType.CONCEPT_ALIGNMENT_ONLY
        elif source_type == "ncert_textbook":
            transformation = TransformationType.ADAPTED_FROM_SOURCE
        else:
            transformation = TransformationType.ORIGINAL_CONTENT
        
        # Generate lineage
        lineage = {
            "inspired_by": [source_info.get("source_id", "")] if source_info.get("source_id") else [],
            "ncert_alignment": self._get_ncert_alignment(question.get("primary_concept", "")),
            "transformation_type": transformation.value,
            "verbatim_source_used": False,  # Default to safe
            "human_review_required": transformation != TransformationType.ORIGINAL_CONTENT
        }
        
        # Update question
        question["lineage"] = lineage
        
        # Save updated question
        with open(question_file, 'w') as f:
            json.dump(question, f, indent=2)
        
        return True
    
    def _get_ncert_alignment(self, concept: str) -> List[str]:
        """Get NCERT alignment for a concept"""
        
        ncert_mappings = {
            "cartesian_system": ["Class 9 Mathematics Chapter 3", "Class 10 Mathematics Chapter 7"],
            "distance_formula": ["Class 10 Mathematics Chapter 7"],
            "trigonometric_ratios": ["Class 10 Mathematics Chapter 8"],
            "quadratic_standard_form": ["Class 10 Mathematics Chapter 4"],
            "regular_polygons": ["Class 8 Mathematics Chapter 3"],
            "limits_intuitive": ["Class 11 Mathematics Chapter 13"]
        }
        
        return ncert_mappings.get(concept, [])
    
    def export_lineage_summary(self, output_filename: Optional[str] = None) -> str:
        """Export lineage summary for review"""
        
        if output_filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_filename = f"lineage_summary_{timestamp}.json"
        
        output_path = self.review_dir / output_filename
        
        report = self.generate_lineage_report()
        
        with open(output_path, 'w') as f:
            json.dump(report, f, indent=2)
        
        return str(output_path)

def main():
    """Example usage"""
    tracker = LineageTracker("/home/vashista/diagram-engine/content_pipeline")
    
    # Generate lineage report
    report = tracker.generate_lineage_report()
    
    print(f"Lineage Analysis Results:")
    print(f"Total questions: {report['summary']['total_questions']}")
    print(f"Lineage completeness: {report['summary']['lineage_completeness']:.1f}%")
    print(f"Commercial safe: {report['summary']['commercial_safe_count']}")
    print(f"Requires review: {report['summary']['requires_review_count']}")
    print(f"Overall risk: {report['risk_assessment']['overall_risk']}")
    
    if report['recommendations']:
        print("\nRecommendations:")
        for rec in report['recommendations']:
            print(f"  - {rec}")
    
    # Export detailed report
    report_path = tracker.export_lineage_summary()
    print(f"\nDetailed report exported: {report_path}")

if __name__ == "__main__":
    main()