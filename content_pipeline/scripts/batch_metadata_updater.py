#!/usr/bin/env python3
"""
Batch Metadata Updater
Updates all questions with class floor, rescue level, and lineage metadata
"""

import json
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime

class BatchMetadataUpdater:
    """Updates metadata across all questions"""
    
    def __init__(self, pipeline_root: str):
        self.pipeline_root = Path(pipeline_root)
        self.questions_dir = self.pipeline_root / "questions"
        
        # Class level mappings for different difficulties
        self.class_mappings = {
            "foundation": {
                "target_class": 9,
                "class_floor": 7,
                "rescue_start_level": 7
            },
            "bridge": {
                "target_class": 10,
                "class_floor": 8,
                "rescue_start_level": 8
            },
            "jee_pattern": {
                "target_class": 11,
                "class_floor": 9,
                "rescue_start_level": 9
            },
            "mock_exam": {
                "target_class": 12,
                "class_floor": 10,
                "rescue_start_level": 10
            },
            "rescue": {
                "target_class": 8,
                "class_floor": 7,
                "rescue_start_level": 7
            }
        }
    
    def update_all_questions(self, dry_run: bool = True) -> Dict[str, List[str]]:
        """Update all questions with required metadata"""
        
        updates = {}
        
        for question_file in self.questions_dir.glob("*.json"):
            try:
                with open(question_file) as f:
                    question = json.load(f)
                
                changes = []
                
                # Add class metadata if missing
                difficulty = question.get("difficulty", "foundation")
                class_mapping = self.class_mappings.get(difficulty, self.class_mappings["foundation"])
                
                if "target_class" not in question:
                    question["target_class"] = class_mapping["target_class"]
                    changes.append(f"Added target_class: {class_mapping['target_class']}")
                
                if "rescue_start_level" not in question:
                    question["rescue_start_level"] = class_mapping["rescue_start_level"]
                    changes.append(f"Added rescue_start_level: {class_mapping['rescue_start_level']}")
                
                # Add learning objective score if missing
                if "learning_objective_score" not in question:
                    question["learning_objective_score"] = 0
                    changes.append("Added learning_objective_score: 0")
                
                # Add lineage if missing
                if "lineage" not in question:
                    lineage = self._generate_lineage(question)
                    question["lineage"] = lineage
                    changes.append("Added lineage metadata")
                
                # Add why-wrong explanations to options if missing
                options = question.get("options", [])
                for i, option in enumerate(options):
                    if not option.get("isCorrect") and "whyWrong" not in option:
                        # Generate basic why-wrong explanation
                        option["whyWrong"] = f"This option is incorrect. {option.get('text', '')}"
                        changes.append(f"Added whyWrong to option {option['label']}")
                
                # Save changes if not dry run
                if changes and not dry_run:
                    with open(question_file, 'w') as f:
                        json.dump(question, f, indent=2)
                
                if changes:
                    updates[question_file.name] = changes + ["(DRY RUN)" if dry_run else ""]
            
            except Exception as e:
                updates[question_file.name] = [f"Error: {e}"]
        
        return updates
    
    def _generate_lineage(self, question: Dict) -> Dict:
        """Generate lineage metadata for a question"""
        
        source_ref = question.get("source_reference", {})
        source_type = source_ref.get("source_type", "original_content")
        
        lineage = {
            "inspired_by": [],
            "ncert_alignment": [],
            "transformation_type": "original_content",
            "verbatim_source_used": False,
            "human_review_required": True
        }
        
        # Set transformation type based on source
        if source_type == "jee_previous_paper":
            lineage["transformation_type"] = "original_question_from_pattern"
            lineage["inspired_by"] = [source_ref.get("source_id", "jee_pattern")]
        elif source_type == "ncert_textbook":
            lineage["transformation_type"] = "adapted_from_source"
            lineage["ncert_alignment"] = ["NCERT reference"]
        elif source_type == "original_content":
            lineage["transformation_type"] = "original_content"
        
        # Add NCERT alignment based on concept
        concept = question.get("primary_concept", "")
        if "coordinate" in concept:
            lineage["ncert_alignment"] = ["Class 9 Mathematics Chapter 3", "Class 10 Mathematics Chapter 7"]
        elif "trigonometry" in concept:
            lineage["ncert_alignment"] = ["Class 10 Mathematics Chapter 8"]
        elif "quadratic" in concept:
            lineage["ncert_alignment"] = ["Class 10 Mathematics Chapter 4"]
        elif "geometry" in concept:
            lineage["ncert_alignment"] = ["Class 8 Mathematics Chapter 3", "Class 9 Mathematics Chapter 9"]
        
        return lineage
    
    def validate_metadata_completeness(self) -> Dict[str, List[str]]:
        """Validate that all questions have required metadata"""
        
        validation_results = {}
        
        for question_file in self.questions_dir.glob("*.json"):
            try:
                with open(question_file) as f:
                    question = json.load(f)
                
                missing_fields = []
                
                # Check required fields
                required_fields = [
                    "target_class",
                    "rescue_start_level", 
                    "learning_objective_score",
                    "lineage"
                ]
                
                for field in required_fields:
                    if field not in question:
                        missing_fields.append(field)
                
                # Check options have why-wrong explanations
                options = question.get("options", [])
                for option in options:
                    if not option.get("isCorrect") and not option.get("whyWrong"):
                        missing_fields.append(f"whyWrong for option {option.get('label')}")
                
                if missing_fields:
                    validation_results[question_file.name] = missing_fields
            
            except Exception as e:
                validation_results[question_file.name] = [f"Error reading file: {e}"]
        
        return validation_results

def main():
    """Example usage"""
    updater = BatchMetadataUpdater("/home/vashista/diagram-engine/content_pipeline")
    
    # Validate current metadata
    validation = updater.validate_metadata_completeness()
    print(f"Questions with missing metadata: {len(validation)}")
    
    if validation:
        print("\nSample missing metadata:")
        for filename, missing in list(validation.items())[:3]:
            print(f"\n{filename}:")
            for field in missing[:3]:
                print(f"  - Missing: {field}")
    
    # Show what updates would be applied
    updates = updater.update_all_questions(dry_run=True)
    print(f"\nQuestions needing updates: {len(updates)}")
    
    if updates:
        print("\nSample updates:")
        for filename, changes in list(updates.items())[:3]:
            print(f"\n{filename}:")
            for change in changes[:2]:
                if change and not "(DRY RUN)" in change:
                    print(f"  - {change}")

if __name__ == "__main__":
    main()