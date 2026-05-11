#!/usr/bin/env python3
"""
Concept ID Validator
Ensures canonical concept ID consistency across all content
"""

import json
from pathlib import Path
from typing import Dict, List, Set, Optional
from re import match

class ConceptIDValidator:
    """Validates canonical concept ID consistency"""
    
    def __init__(self, pipeline_root: str):
        self.pipeline_root = Path(pipeline_root)
        self.concepts_dir = self.pipeline_root / "concepts"
        self.questions_dir = self.pipeline_root / "questions"
        self.rescue_dir = self.pipeline_root / "review"  # Rescue ladders stored in review
        
        # Load canonical mapping
        mapping_file = self.concepts_dir / "canonical_concept_mapping.json"
        with open(mapping_file) as f:
            self.canonical_mapping = json.load(f)
        
        # Build reverse lookup
        self.legacy_to_canonical = self.canonical_mapping.get("legacy_mappings", {})
        self.canonical_concepts = set()
        self._build_canonical_set()
    
    def _build_canonical_set(self):
        """Build set of all valid canonical concept IDs"""
        chapters = self.canonical_mapping.get("chapters", {})
        for chapter_data in chapters.values():
            concepts = chapter_data.get("concepts", {})
            self.canonical_concepts.update(concepts.values())
    
    def validate_concept_id(self, concept_id: str) -> tuple[bool, str]:
        """Validate a single concept ID"""
        
        # Check if it's a valid canonical ID
        if concept_id in self.canonical_concepts:
            return True, "Valid canonical concept ID"
        
        # Check if it's a legacy ID that needs mapping
        if concept_id in self.legacy_to_canonical:
            canonical = self.legacy_to_canonical[concept_id]
            return False, f"Legacy ID '{concept_id}' should be '{canonical}'"
        
        # Check format
        pattern = r"^math\.[a-z_]+\.[a-z_]+$"
        if not match(pattern, concept_id):
            return False, f"Invalid format: should match 'math.chapter.concept' pattern"
        
        return False, f"Unknown concept ID: '{concept_id}'"
    
    def validate_question_concepts(self, question_file: Path) -> List[str]:
        """Validate all concept IDs in a question file"""
        
        errors = []
        
        try:
            with open(question_file) as f:
                question = json.load(f)
            
            # Validate primary concept
            primary = question.get("primary_concept")
            if primary:
                is_valid, message = self.validate_concept_id(primary)
                if not is_valid:
                    errors.append(f"Primary concept: {message}")
            
            # Validate secondary concepts
            secondary = question.get("secondary_concepts", [])
            for i, concept in enumerate(secondary):
                is_valid, message = self.validate_concept_id(concept)
                if not is_valid:
                    errors.append(f"Secondary concept {i}: {message}")
            
            # Validate prerequisites
            prerequisites = question.get("prerequisites", [])
            for i, concept in enumerate(prerequisites):
                is_valid, message = self.validate_concept_id(concept)
                if not is_valid:
                    errors.append(f"Prerequisite {i}: {message}")
            
            # Validate rescue ladder concepts (if they reference concepts)
            mistake_patterns = question.get("mistake_patterns", [])
            for i, pattern in enumerate(mistake_patterns):
                rescue_concept = pattern.get("rescue_concept_id")
                if rescue_concept:
                    is_valid, message = self.validate_concept_id(rescue_concept)
                    if not is_valid:
                        errors.append(f"Mistake pattern {i} rescue concept: {message}")
            
        except Exception as e:
            errors.append(f"Error reading question file: {e}")
        
        return errors
    
    def validate_all_questions(self) -> Dict[str, List[str]]:
        """Validate concept IDs in all question files"""
        
        all_errors = {}
        
        for question_file in self.questions_dir.glob("*.json"):
            errors = self.validate_question_concepts(question_file)
            if errors:
                all_errors[question_file.name] = errors
        
        return all_errors
    
    def validate_concept_taxonomy(self) -> List[str]:
        """Validate concept taxonomy uses canonical IDs"""
        
        errors = []
        taxonomy_file = self.concepts_dir / "maths_concept_taxonomy.json"
        
        try:
            with open(taxonomy_file) as f:
                taxonomy = json.load(f)
            
            chapters = taxonomy.get("chapters", [])
            for chapter in chapters:
                concepts = chapter.get("concepts", [])
                for concept in concepts:
                    concept_id = concept.get("concept_id")
                    if concept_id:
                        is_valid, message = self.validate_concept_id(concept_id)
                        if not is_valid:
                            errors.append(f"Concept '{concept_id}' in taxonomy: {message}")
                        
                        # Check prerequisites
                        prerequisites = concept.get("prerequisites", [])
                        for prereq in prerequisites:
                            is_valid, message = self.validate_concept_id(prereq)
                            if not is_valid:
                                errors.append(f"Prerequisite '{prereq}' for concept '{concept_id}': {message}")
        
        except Exception as e:
            errors.append(f"Error reading taxonomy file: {e}")
        
        return errors
    
    def fix_legacy_concepts(self, dry_run: bool = True) -> Dict[str, str]:
        """Fix legacy concept IDs in all files"""
        
        fixes_applied = {}
        
        for question_file in self.questions_dir.glob("*.json"):
            try:
                with open(question_file) as f:
                    question = json.load(f)
                
                modified = False
                file_fixes = []
                
                # Fix primary concept
                primary = question.get("primary_concept")
                if primary and primary in self.legacy_to_canonical:
                    old_id = primary
                    new_id = self.legacy_to_canonical[primary]
                    question["primary_concept"] = new_id
                    file_fixes.append(f"primary_concept: {old_id} → {new_id}")
                    modified = True
                
                # Fix secondary concepts
                secondary = question.get("secondary_concepts", [])
                for i, concept in enumerate(secondary):
                    if concept in self.legacy_to_canonical:
                        old_id = concept
                        new_id = self.legacy_to_canonical[concept]
                        secondary[i] = new_id
                        file_fixes.append(f"secondary_concepts[{i}]: {old_id} → {new_id}")
                        modified = True
                
                # Fix prerequisites
                prerequisites = question.get("prerequisites", [])
                for i, concept in enumerate(prerequisites):
                    if concept in self.legacy_to_canonical:
                        old_id = concept
                        new_id = self.legacy_to_canonical[concept]
                        prerequisites[i] = new_id
                        file_fixes.append(f"prerequisites[{i}]: {old_id} → {new_id}")
                        modified = True
                
                if modified and not dry_run:
                    with open(question_file, 'w') as f:
                        json.dump(question, f, indent=2)
                    fixes_applied[question_file.name] = file_fixes
                elif modified:
                    fixes_applied[question_file.name] = file_fixes + ["(DRY RUN - not saved)"]
            
            except Exception as e:
                fixes_applied[question_file.name] = [f"Error: {e}"]
        
        return fixes_applied
    
    def generate_consistency_report(self) -> Dict:
        """Generate comprehensive concept ID consistency report"""
        
        report = {
            "summary": {
                "total_canonical_concepts": len(self.canonical_concepts),
                "legacy_mappings": len(self.legacy_to_canonical),
                "questions_with_errors": 0,
                "taxonomy_errors": 0
            },
            "question_errors": self.validate_all_questions(),
            "taxonomy_errors": self.validate_concept_taxonomy(),
            "recommendations": []
        }
        
        report["summary"]["questions_with_errors"] = len(report["question_errors"])
        report["summary"]["taxonomy_errors"] = len(report["taxonomy_errors"])
        
        # Generate recommendations
        if report["question_errors"]:
            report["recommendations"].append("Fix concept ID errors in question files")
        
        if report["taxonomy_errors"]:
            report["recommendations"].append("Update concept taxonomy to use canonical IDs")
        
        if self.legacy_to_canonical:
            report["recommendations"].append("Run legacy concept ID fix to update all files")
        
        return report

def main():
    """Example usage"""
    validator = ConceptIDValidator("/home/vashista/diagram-engine/content_pipeline")
    
    # Validate all questions
    errors = validator.validate_all_questions()
    print(f"Questions with concept ID errors: {len(errors)}")
    
    if errors:
        print("\nSample errors:")
        for filename, file_errors in list(errors.items())[:3]:
            print(f"\n{filename}:")
            for error in file_errors[:2]:
                print(f"  - {error}")
    
    # Show legacy fixes needed
    fixes = validator.fix_legacy_concepts(dry_run=True)
    if fixes:
        print(f"\nFiles needing legacy concept fixes: {len(fixes)}")
    
    # Generate report
    report = validator.generate_consistency_report()
    print(f"\nConcept consistency report generated")
    print(f"Canonical concepts: {report['summary']['total_canonical_concepts']}")
    print(f"Questions with errors: {report['summary']['questions_with_errors']}")

if __name__ == "__main__":
    main()