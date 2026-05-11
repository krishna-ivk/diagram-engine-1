#!/usr/bin/env python3
"""
JEE Paper Parser Interface
Handles parsing and importing of JEE previous year papers into the content pipeline.
"""

import json
import re
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from pathlib import Path

class JEEPaperParser:
    """Parser for JEE previous year papers"""
    
    def __init__(self, pipeline_root: str):
        self.pipeline_root = Path(pipeline_root)
        self.schemas_dir = self.pipeline_root / "schemas"
        self.sources_dir = self.pipeline_root / "sources"
        self.questions_dir = self.pipeline_root / "questions"
        
    def parse_jee_paper(self, paper_data: Dict) -> Dict:
        """Parse a JEE paper and convert to pipeline format"""
        
        # Create source material record
        source_id = f"jee_{paper_data['year']}_{paper_data['session']}_{paper_data['subject'].lower()}"
        
        source_material = {
            "source_id": source_id,
            "source_type": "jee_previous_paper",
            "copyright_status": "needs_review",
            "metadata": {
                "title": f"JEE Main {paper_data['year']} {paper_data['session'].title()} - {paper_data['subject']}",
                "year": paper_data['year'],
                "exam_session": paper_data['session'],
                "subject": paper_data['subject'],
                "class_level": ["Class 11", "Class 12"],
                "chapter": paper_data.get('chapter', 'Mixed'),
                "url": paper_data.get('url', ''),
                "access_date": datetime.now().strftime('%Y-%m-%d')
            },
            "extraction_date": datetime.now().isoformat()
        }
        
        # Parse questions
        parsed_questions = []
        for i, question in enumerate(paper_data['questions'], 1):
            parsed_question = self._parse_question(question, source_id, i)
            parsed_questions.append(parsed_question)
        
        return {
            "source_material": source_material,
            "questions": parsed_questions
        }
    
    def _parse_question(self, question: Dict, source_id: str, question_number: int) -> Dict:
        """Parse individual question"""
        
        question_id = f"{source_id}_q{question_number}"
        
        # Determine question type from format
        question_type = self._detect_question_type(question)
        
        # Extract answer
        answer = self._extract_answer(question, question_type)
        
        # Determine difficulty based on question characteristics
        difficulty = self._assess_difficulty(question)
        
        # Identify primary concept
        primary_concept = self._identify_concept(question)
        
        # Check if diagram is needed
        diagram_reqs = self._check_diagram_requirements(question)
        
        # Identify common mistake patterns
        mistake_patterns = self._identify_mistake_patterns(question, primary_concept)
        
        parsed = {
            "question_id": question_id,
            "source_reference": {
                "source_id": source_id,
                "source_type": "jee_previous_paper",
                "original_question_number": str(question_number),
                "adaptation_notes": question.get('notes', '')
            },
            "question_text": question['text'],
            "question_type": question_type,
            "options": question.get('options', []),
            "answer": answer,
            "solution": question.get('solution', {}),
            "difficulty": difficulty,
            "primary_concept": primary_concept,
            "secondary_concepts": question.get('secondary_concepts', []),
            "prerequisites": self._get_prerequisites(primary_concept),
            "class_floor": question.get('class_floor', 11),
            "target_exam": "jee_main",
            "question_role": "jee_pattern",
            "diagram_requirements": diagram_reqs,
            "mistake_patterns": mistake_patterns,
            "rescue_ladder": self._suggest_rescue_ladder(primary_concept, difficulty),
            "estimated_time": question.get('estimated_time', self._estimate_time(difficulty)),
            "status": "raw_imported",
            "review_history": []
        }
        
        return parsed
    
    def _detect_question_type(self, question: Dict) -> str:
        """Detect question type from format"""
        
        if 'options' in question and len(question['options']) == 4:
            return "multiple_choice"
        elif question.get('answer_type') == 'numerical':
            return "numerical"
        elif question.get('answer_type') == 'integer':
            return "integer_type"
        elif 'comprehension_passage' in question:
            return "comprehension"
        elif 'assertion' in question and 'reason' in question:
            return "assertion_reason"
        else:
            return "multiple_choice"  # Default
    
    def _extract_answer(self, question: Dict, question_type: str) -> str:
        """Extract answer based on question type"""
        
        if question_type == "multiple_choice":
            return question.get('answer', '')
        elif question_type in ["numerical", "integer_type"]:
            return question.get('answer', 0)
        else:
            return question.get('answer', '')
    
    def _assess_difficulty(self, question: Dict) -> str:
        """Assess question difficulty based on characteristics"""
        
        difficulty_score = 0
        
        # Check for multiple concepts
        if question.get('secondary_concepts'):
            difficulty_score += len(question['secondary_concepts'])
        
        # Check for complex calculations
        if 'complex_calculation' in question.get('tags', []):
            difficulty_score += 2
        
        # Check for multiple steps
        if question.get('solution', {}).get('steps'):
            steps = len(question['solution']['steps'])
            if steps > 3:
                difficulty_score += 2
            elif steps > 1:
                difficulty_score += 1
        
        # Check for uncommon concepts
        if 'advanced_concept' in question.get('tags', []):
            difficulty_score += 2
        
        # Map score to difficulty
        if difficulty_score <= 1:
            return "foundation"
        elif difficulty_score <= 3:
            return "bridge"
        elif difficulty_score <= 5:
            return "jee_pattern"
        else:
            return "mock_exam"
    
    def _identify_concept(self, question: Dict) -> str:
        """Identify primary concept from question text and tags"""
        
        # Concept keywords mapping
        concept_keywords = {
            "coordinate_geometry": ["coordinate", "cartesian", "plane", "point", "line", "slope", "distance"],
            "trigonometry": ["sin", "cos", "tan", "angle", "trigonometric", "radian"],
            "quadratic_equations": ["quadratic", "equation", "roots", "discriminant"],
            "geometry_mensuration": ["area", "perimeter", "volume", "polygon", "triangle", "circle"],
            "calculus_basics": ["limit", "derivative", "tangent", "continuity"]
        }
        
        text = question['text'].lower()
        
        for concept, keywords in concept_keywords.items():
            if any(keyword in text for keyword in keywords):
                return concept
        
        # Check explicit tags
        if 'concept' in question:
            return question['concept']
        
        return "general_mathematics"
    
    def _check_diagram_requirements(self, question: Dict) -> Dict:
        """Check if question needs a diagram"""
        
        diagram_keywords = [
            "diagram", "figure", "graph", "plot", "coordinate", "geometry",
            "triangle", "circle", "polygon", "curve", "visual"
        ]
        
        text = question['text'].lower()
        needs_diagram = any(keyword in text for keyword in diagram_keywords)
        
        diagram_type = "geometry"  # Default
        if "coordinate" in text or "graph" in text:
            diagram_type = "coordinate_system"
        elif "trigonometric" in text or "unit circle" in text:
            diagram_type = "trigonometric_circle"
        elif "function" in text or "curve" in text:
            diagram_type = "graph"
        
        return {
            "needs_diagram": needs_diagram,
            "diagram_type": diagram_type if needs_diagram else None,
            "diagram_specification": question.get('diagram_notes', '')
        }
    
    def _identify_mistake_patterns(self, question: Dict, concept: str) -> List[Dict]:
        """Identify common mistake patterns for this question"""
        
        # Common mistake patterns by concept
        patterns_by_concept = {
            "coordinate_geometry": [
                {
                    "pattern": "Wrong order of coordinates",
                    "why_wrong": "Cartesian coordinates are (x, y) not (y, x)",
                    "frequency": "common"
                },
                {
                    "pattern": "Sign errors in distance formula",
                    "why_wrong": "Distance formula uses squared differences, signs don't matter",
                    "frequency": "occasional"
                }
            ],
            "trigonometry": [
                {
                    "pattern": "Confusing sin and cos values",
                    "why_wrong": "Sin is opposite/hypotenuse, Cos is adjacent/hypotenuse",
                    "frequency": "common"
                },
                {
                    "pattern": "Wrong angle identification",
                    "why_wrong": "Always identify the correct angle in right triangle",
                    "frequency": "very_common"
                }
            ],
            "quadratic_equations": [
                {
                    "pattern": "Wrong sign in quadratic formula",
                    "why_wrong": "Formula is -b ± √(b²-4ac) / 2a, not b ± √(...)",
                    "frequency": "common"
                },
                {
                    "pattern": "Discriminant calculation errors",
                    "why_wrong": "Be careful with signs when calculating b²-4ac",
                    "frequency": "occasional"
                }
            ]
        }
        
        return patterns_by_concept.get(concept, [])
    
    def _get_prerequisites(self, concept: str) -> List[str]:
        """Get prerequisites for a concept"""
        
        prerequisites_map = {
            "coordinate_geometry": ["number_line", "ordered_pairs"],
            "distance_formula": ["coordinate_geometry", "pythagorean_theorem"],
            "section_formula": ["distance_formula", "ratio_proportion"],
            "trigonometry": ["right_triangle", "similar_triangles"],
            "quadratic_equations": ["polynomials", "equation_solving"],
            "geometry_mensuration": ["area_basics", "perimeter_basics"],
            "calculus_basics": ["functions", "limits_intuitive"]
        }
        
        return prerequisites_map.get(concept, [])
    
    def _suggest_rescue_ladder(self, concept: str, difficulty: str) -> List[str]:
        """Suggest rescue ladder questions"""
        
        # This would typically reference actual question IDs
        # For now, return placeholder ladder structure
        if difficulty in ["jee_pattern", "mock_exam"]:
            return [
                f"{concept}_foundation_q1",
                f"{concept}_bridge_q1",
                f"{concept}_practice_q1"
            ]
        return []
    
    def _estimate_time(self, difficulty: str) -> int:
        """Estimate solving time in minutes"""
        
        time_map = {
            "foundation": 2,
            "bridge": 4,
            "jee_pattern": 6,
            "mock_exam": 8
        }
        
        return time_map.get(difficulty, 5)
    
    def save_parsed_content(self, parsed_data: Dict, output_dir: Optional[str] = None) -> None:
        """Save parsed content to pipeline directories"""
        
        if output_dir:
            base_path = Path(output_dir)
        else:
            base_path = self.pipeline_root
        
        # Save source material
        sources_path = base_path / "sources" / f"{parsed_data['source_material']['source_id']}.json"
        sources_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(sources_path, 'w') as f:
            json.dump(parsed_data['source_material'], f, indent=2)
        
        # Save questions
        questions_path = base_path / "questions"
        questions_path.mkdir(parents=True, exist_ok=True)
        
        for question in parsed_data['questions']:
            question_file = questions_path / f"{question['question_id']}.json"
            with open(question_file, 'w') as f:
                json.dump(question, f, indent=2)
        
        print(f"Saved {len(parsed_data['questions'])} questions to {questions_path}")
        print(f"Saved source material to {sources_path}")

def main():
    """Example usage"""
    
    # Sample JEE paper data
    sample_paper = {
        "year": 2023,
        "session": "shift_1",
        "subject": "Mathematics",
        "chapter": "Coordinate Geometry",
        "url": "https://example.com/jee-2023-paper",
        "questions": [
            {
                "text": "The distance between the points (2, 3) and (5, 7) is:",
                "options": [
                    {"label": "A", "text": "5", "is_correct": False},
                    {"label": "B", "text": "√25", "is_correct": True},
                    {"label": "C", "text": "7", "is_correct": False},
                    {"label": "D", "text": "√34", "is_correct": False}
                ],
                "answer": "B",
                "solution": {
                    "method": "Distance formula",
                    "steps": [
                        {"step_number": 1, "description": "Use distance formula: √[(x₂-x₁)² + (y₂-y₁)²]"},
                        {"step_number": 2, "description": "Substitute values: √[(5-2)² + (7-3)²]"},
                        {"step_number": 3, "description": "Calculate: √[3² + 4²] = √[9 + 16] = √25 = 5"}
                    ],
                    "final_answer": "5"
                },
                "tags": ["coordinate_geometry", "distance_formula"],
                "estimated_time": 3
            }
        ]
    }
    
    parser = JEEPaperParser("/home/vashista/diagram-engine/content_pipeline")
    parsed_data = parser.parse_jee_paper(sample_paper)
    parser.save_parsed_content(parsed_data)

if __name__ == "__main__":
    main()