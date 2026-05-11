#!/usr/bin/env python3
"""
Copyright Guardrails
Enforces copyright compliance and tracks legal status of content
"""

import json
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime
from enum import Enum

class CopyrightStatus(Enum):
    PUBLIC_DOMAIN = "public_domain"
    NEEDS_REVIEW = "needs_review"
    RESTRICTED = "restricted"
    ORIGINAL = "original"
    EDUCATIONAL_FAIR_USE = "educational_fair_use"

class SourceType(Enum):
    JEE_PREVIOUS_PAPER = "jee_previous_paper"
    NCERT_TEXTBOOK = "ncert_textbook"
    NCERT_SYLLABUS = "ncert_syllabus"
    ORIGINAL_CONTENT = "original_content"
    COACHING_MATERIAL = "coaching_material"

class CopyrightGuardrails:
    """Enforces copyright compliance for content pipeline"""
    
    def __init__(self, pipeline_root: str):
        self.pipeline_root = Path(pipeline_root)
        self.sources_dir = self.pipeline_root / "sources"
        self.questions_dir = self.pipeline_root / "questions"
        self.review_dir = self.pipeline_root / "review"
        
        # Copyright rules by source type
        self.copyright_rules = {
            SourceType.JEE_PREVIOUS_PAPER: {
                "allowed_uses": ["pattern_mining", "style_analysis", "difficulty_assessment"],
                "restricted_uses": ["direct_reproduction", "commercial_redistribution"],
                "attribution_required": True,
                "commercial_use": "needs_permission",
                "max_similarity": 0.3  # 30% similarity threshold
            },
            SourceType.NCERT_TEXTBOOK: {
                "allowed_uses": ["concept_alignment", "syllabus_mapping", "prerequisite_sequencing"],
                "restricted_uses": ["text_copying", "diagram_reproduction", "exercise_republishing"],
                "attribution_required": True,
                "commercial_use": "prohibited",
                "max_similarity": 0.1  # 10% similarity threshold
            },
            SourceType.NCERT_SYLLABUS: {
                "allowed_uses": ["full_usage", "concept_mapping", "curriculum_alignment"],
                "restricted_uses": [],
                "attribution_required": True,
                "commercial_use": "allowed_with_attribution",
                "max_similarity": 1.0  # Syllabus can be fully used
            },
            SourceType.ORIGINAL_CONTENT: {
                "allowed_uses": ["full_usage", "commercial_use", "redistribution"],
                "restricted_uses": [],
                "attribution_required": False,
                "commercial_use": "allowed",
                "max_similarity": 1.0
            }
        }
    
    def check_content_compliance(self, content: Dict, source_type: SourceType) -> Tuple[bool, List[str]]:
        """Check if content complies with copyright rules"""
        
        violations = []
        rules = self.copyright_rules[source_type]
        
        # Check similarity threshold (would need text similarity algorithm in practice)
        if "similarity_score" in content:
            similarity = content["similarity_score"]
            if similarity > rules["max_similarity"]:
                violations.append(f"Similarity {similarity:.2f} exceeds threshold {rules['max_similarity']}")
        
        # Check for restricted content
        if source_type == SourceType.NCERT_TEXTBOOK:
            violations.extend(self._check_ncert_restrictions(content))
        elif source_type == SourceType.JEE_PREVIOUS_PAPER:
            violations.extend(self._check_jee_restrictions(content))
        
        # Check attribution requirements
        if rules["attribution_required"] and not self._has_proper_attribution(content):
            violations.append("Missing required attribution")
        
        # Check commercial use compliance
        if content.get("intended_commercial_use", False):
            if rules["commercial_use"] == "prohibited":
                violations.append("Commercial use prohibited for this source type")
            elif rules["commercial_use"] == "needs_permission":
                violations.append("Commercial use requires explicit permission")
        
        return len(violations) == 0, violations
    
    def _check_ncert_restrictions(self, content: Dict) -> List[str]:
        """Check NCERT-specific restrictions"""
        
        violations = []
        
        # Check for direct textbook copying
        if content.get("source_reference", {}).get("source_type") == "ncert_textbook":
            question_text = content.get("question_text", "")
            
            # Flag potential direct copying (simplified check)
            ncert_indicators = ["NCERT", "Exercise", "Example", "Fig.", "Page"]
            for indicator in ncert_indicators:
                if indicator in question_text:
                    violations.append(f"Potential NCERT direct copying: contains '{indicator}'")
        
        # Check for diagram reproduction
        diagram_reqs = content.get("diagram_requirements", {})
        if diagram_reqs.get("source_diagram_reference"):
            violations.append("NCERT diagram reproduction requires permission")
        
        return violations
    
    def _check_jee_restrictions(self, content: Dict) -> List[str]:
        """Check JEE-specific restrictions"""
        
        violations = []
        
        # Check for direct question reproduction
        source_ref = content.get("source_reference", {})
        if source_ref.get("source_type") == "jee_previous_paper":
            if not content.get("adaptation_notes"):
                violations.append("JEE question requires adaptation notes")
        
        # Check for excessive similarity
        if content.get("similarity_score", 0) > 0.3:
            violations.append("JEE question similarity too high for commercial use")
        
        return violations
    
    def _has_proper_attribution(self, content: Dict) -> bool:
        """Check if content has proper attribution"""
        
        source_ref = content.get("source_reference", {})
        if not source_ref:
            return True  # Original content doesn't need attribution
        
        # Check for required attribution elements
        required_elements = ["source_id", "source_type"]
        for element in required_elements:
            if not source_ref.get(element):
                return False
        
        return True
    
    def update_copyright_status(self, item_id: str, item_type: str, status: CopyrightStatus, 
                              reviewer_id: str, notes: str = "") -> bool:
        """Update copyright status for an item"""
        
        review_file = self.review_dir / f"{item_id}_copyright.json"
        review_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Load existing review or create new
        if review_file.exists():
            with open(review_file) as f:
                review_data = json.load(f)
        else:
            review_data = {
                "item_id": item_id,
                "item_type": item_type,
                "copyright_status": status.value,
                "review_history": []
            }
        
        # Add review entry
        review_entry = {
            "timestamp": datetime.now().isoformat(),
            "reviewer_id": reviewer_id,
            "status": status.value,
            "notes": notes,
            "automated_check": False
        }
        
        review_data["review_history"].append(review_entry)
        review_data["copyright_status"] = status.value
        review_data["last_reviewed"] = datetime.now().isoformat()
        
        # Save updated review
        with open(review_file, 'w') as f:
            json.dump(review_data, f, indent=2)
        
        return True
    
    def automated_copyright_check(self, item_id: str, item_type: str) -> Tuple[bool, List[str]]:
        """Perform automated copyright compliance check"""
        
        # Load the item
        if item_type == "question":
            item_file = self.questions_dir / f"{item_id}.json"
        else:
            item_file = self.sources_dir / f"{item_id}.json"
        
        if not item_file.exists():
            return False, [f"Item file not found: {item_file}"]
        
        try:
            with open(item_file) as f:
                item = json.load(f)
        except Exception as e:
            return False, [f"Error loading item: {e}"]
        
        # Determine source type
        source_type_str = item.get("source_reference", {}).get("source_type", "original_content")
        try:
            source_type = SourceType(source_type_str)
        except ValueError:
            source_type = SourceType.ORIGINAL_CONTENT
        
        # Check compliance
        is_compliant, violations = self.check_content_compliance(item, source_type)
        
        # Update review status
        status = CopyrightStatus.NEEDS_REVIEW if violations else CopyrightStatus.PUBLIC_DOMAIN
        notes = "; ".join(violations) if violations else "Automated check passed"
        
        self.update_copyright_status(item_id, item_type, status, "automated_check", notes)
        
        return is_compliant, violations
    
    def get_copyright_summary(self) -> Dict:
        """Get summary of copyright status across pipeline"""
        
        summary = {
            "total_items": 0,
            "by_status": {},
            "by_source_type": {},
            "items_needing_review": [],
            "high_risk_items": []
        }
        
        # Process all review files
        for review_file in self.review_dir.glob("*_copyright.json"):
            try:
                with open(review_file) as f:
                    review = json.load(f)
                
                summary["total_items"] += 1
                
                # Count by status
                status = review.get("copyright_status", "unknown")
                summary["by_status"][status] = summary["by_status"].get(status, 0) + 1
                
                # Load original item to get source type
                item_id = review.get("item_id", "")
                item_type = review.get("item_type", "")
                
                if item_type == "question":
                    item_file = self.questions_dir / f"{item_id}.json"
                else:
                    item_file = self.sources_dir / f"{item_id}.json"
                
                if item_file.exists():
                    with open(item_file) as f:
                        item = json.load(f)
                    
                    source_type = item.get("source_reference", {}).get("source_type", "original_content")
                    summary["by_source_type"][source_type] = summary["by_source_type"].get(source_type, 0) + 1
                    
                    # Flag items needing review
                    if status in ["needs_review", "restricted"]:
                        summary["items_needing_review"].append({
                            "item_id": item_id,
                            "item_type": item_type,
                            "source_type": source_type,
                            "status": status
                        })
                    
                    # Flag high-risk items
                    if source_type == "ncert_textbook" and status != "public_domain":
                        summary["high_risk_items"].append({
                            "item_id": item_id,
                            "item_type": item_type,
                            "risk": "NCERT content requires careful review"
                        })
                
            except Exception as e:
                print(f"Error processing review file {review_file}: {e}")
        
        return summary
    
    def generate_copyright_report(self, output_filename: Optional[str] = None) -> str:
        """Generate comprehensive copyright compliance report"""
        
        if output_filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_filename = f"copyright_report_{timestamp}.json"
        
        output_path = self.review_dir / output_filename
        
        report = {
            "generated_at": datetime.now().isoformat(),
            "summary": self.get_copyright_summary(),
            "recommendations": self._generate_recommendations(),
            "action_items": self._generate_action_items()
        }
        
        with open(output_path, 'w') as f:
            json.dump(report, f, indent=2)
        
        return str(output_path)
    
    def _generate_recommendations(self) -> List[str]:
        """Generate copyright compliance recommendations"""
        
        recommendations = [
            "Review all NCERT textbook references for commercial use compliance",
            "Ensure proper attribution for all JEE previous paper adaptations",
            "Implement text similarity checking for automated compliance",
            "Create explicit permission tracking for restricted content",
            "Document fair use analysis for educational content"
        ]
        
        return recommendations
    
    def _generate_action_items(self) -> List[Dict]:
        """Generate specific action items for copyright compliance"""
        
        action_items = [
            {
                "action": "Review NCERT content usage",
                "priority": "high",
                "responsible": "copyright_specialist",
                "due_date": "2024-02-01",
                "description": "Review all NCERT textbook references for commercial compliance"
            },
            {
                "action": "Add attribution metadata",
                "priority": "medium",
                "responsible": "content_engineer",
                "due_date": "2024-01-15",
                "description": "Ensure all sourced content has proper attribution metadata"
            },
            {
                "action": "Implement similarity detection",
                "priority": "medium",
                "responsible": "technical_team",
                "due_date": "2024-02-15",
                "description": "Implement automated text similarity detection"
            }
        ]
        
        return action_items

def main():
    """Example usage"""
    guardrails = CopyrightGuardrails("/home/vashista/diagram-engine/content_pipeline")
    
    # Perform automated check on a sample question
    is_compliant, violations = guardrails.automated_copyright_check("sample_foundation_1", "question")
    print(f"Compliant: {is_compliant}")
    if violations:
        print("Violations:")
        for violation in violations:
            print(f"  - {violation}")
    
    # Generate copyright report
    report_path = guardrails.generate_copyright_report()
    print(f"Copyright report generated: {report_path}")
    
    # Get summary
    summary = guardrails.get_copyright_summary()
    print(f"Total items: {summary['total_items']}")
    print(f"Items needing review: {len(summary['items_needing_review'])}")

if __name__ == "__main__":
    main()