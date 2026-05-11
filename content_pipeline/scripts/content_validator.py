#!/usr/bin/env python3
"""
Content Validator
Validates content against schemas and business rules
"""

import json
import jsonschema
from pathlib import Path
from typing import Dict, List, Any

class ContentValidator:
    """Validates content pipeline data"""
    
    def __init__(self, pipeline_root: str):
        self.pipeline_root = Path(pipeline_root)
        self.schemas_dir = self.pipeline_root / "schemas"
        self.schemas = self._load_schemas()
    
    def _load_schemas(self) -> Dict[str, Dict]:
        """Load all JSON schemas"""
        schemas = {}
        schema_files = {
            "source_material": "source_material.json",
            "concept_node": "concept_node.json", 
            "question_item": "question_item.json",
            "rescue_ladder": "rescue_ladder.json",
            "diagram_spec": "diagram_spec.json",
            "review_status": "review_status.json"
        }
        
        for schema_name, filename in schema_files.items():
            schema_path = self.schemas_dir / filename
            if schema_path.exists():
                with open(schema_path) as f:
                    schemas[schema_name] = json.load(f)
        
        return schemas
    
    def validate_content(self, content: Dict, content_type: str) -> tuple[bool, List[str]]:
        """Validate content against its schema"""
        
        if content_type not in self.schemas:
            return False, [f"Unknown content type: {content_type}"]
        
        schema = self.schemas[content_type]
        validator = jsonschema.Draft7Validator(schema)
        
        errors = []
        for error in validator.iter_errors(content):
            errors.append(f"{'.'.join(str(p) for p in error.path)}: {error.message}")
        
        return len(errors) == 0, errors
    
    def validate_business_rules(self, question: Dict) -> List[str]:
        """Validate business rules for questions"""
        
        violations = []
        
        # Check if prerequisites are reasonable
        if question.get("prerequisites"):
            if len(question["prerequisites"]) > 5:
                violations.append("Too many prerequisites (>5)")
        
        # Check if rescue ladder makes sense
        if question.get("question_role") == "foundation" and question.get("rescue_ladder"):
            violations.append("Foundation questions should not have rescue ladders")
        
        # Check diagram requirements
        diagram_reqs = question.get("diagram_requirements", {})
        if diagram_reqs.get("needs_diagram") and not diagram_reqs.get("diagram_type"):
            violations.append("Diagram required but no type specified")
        
        # Check estimated time vs difficulty
        difficulty_time_map = {
            "foundation": (1, 3),
            "bridge": (3, 6),
            "jee_pattern": (5, 10),
            "mock_exam": (8, 15)
        }
        
        difficulty = question.get("difficulty")
        estimated_time = question.get("estimated_time", 0)
        
        if difficulty in difficulty_time_map:
            min_time, max_time = difficulty_time_map[difficulty]
            if not (min_time <= estimated_time <= max_time):
                violations.append(f"Estimated time {estimated_time}min not appropriate for {difficulty} difficulty")
        
        return violations

def main():
    """Example validation"""
    validator = ContentValidator("/home/vashista/diagram-engine/content_pipeline")
    
    # Example validation
    sample_question = {
        "question_id": "test_q1",
        "question_text": "What is 2+2?",
        "question_type": "multiple_choice",
        "difficulty": "foundation",
        "primary_concept": "basic_arithmetic",
        "answer": "4",
        "status": "raw_imported"
    }
    
    is_valid, errors = validator.validate_content(sample_question, "question_item")
    print(f"Valid: {is_valid}")
    if errors:
        print("Errors:")
        for error in errors:
            print(f"  - {error}")

if __name__ == "__main__":
    main()