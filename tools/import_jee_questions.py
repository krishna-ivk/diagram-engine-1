#!/usr/bin/env python3
"""
JEE Question Import Pipeline
Converts JEE Main previous-year questions into structured JSON format
with concept tagging and rescue ladder generation
"""

import json
import yaml
import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime

class JEEQuestionImporter:
    """Imports and structures JEE questions with concept mapping"""
    
    def __init__(self):
        self.concepts_file = Path("content/math/concepts.yaml")
        self.output_dir = Path("content/sample_questions")
        self.schema_file = Path("content_schema.json")
        
        # Load concepts taxonomy
        with open(self.concepts_file) as f:
            self.concepts = yaml.safe_load(f)
        
        # Load schema for validation
        with open(self.schema_file) as f:
            self.schema = json.load(f)
        
        # Ensure output directory exists
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def parse_jee_question(self, raw_data: Dict) -> Dict:
        """Parse raw JEE question data into structured format"""
        
        # Extract basic information
        question_id = self._generate_question_id(raw_data)
        topic = self._extract_topic(raw_data)
        primary_concept = self._map_to_concept(topic)
        
        # Build structured question
        structured_question = {
            "question_id": question_id,
            "source_type": "jee_previous_paper",
            "source_metadata": {
                "source_year": raw_data.get("year", 2023),
                "source_session": raw_data.get("session", "session_1"),
                "source_paper": raw_data.get("paper", "paper_1"),
                "source_shift": raw_data.get("shift", "shift_1"),
                "question_number": raw_data.get("question_number", "")
            },
            "subject": "Mathematics",
            "chapter": self._map_to_chapter(topic),
            "topic": topic,
            "primary_concept": primary_concept,
            "prerequisites": self._get_prerequisites(primary_concept),
            "class_level": self._determine_class_level(raw_data),
            "bridge_level": "jee",
            "difficulty": self._assess_difficulty(raw_data),
            "expected_time_seconds": self._estimate_time(raw_data),
            "question_text": raw_data.get("question_text", ""),
            "question_type": self._detect_question_type(raw_data),
            "correct_answer": raw_data.get("answer", ""),
            "solution_steps": self._structure_solution(raw_data.get("solution", "")),
            "rescue_question_ids": [],  # Will be filled later
            "diagram_required": self._needs_diagram(raw_data),
            "review_status": "ai_generated",
            "review_history": [{
                "status": "ai_generated",
                "timestamp": datetime.now().isoformat(),
                "reviewer": "ai_importer",
                "comments": "Auto-imported from JEE source"
            }]
        }
        
        # Add options if multiple choice
        if structured_question["question_type"] == "multiple_choice":
            structured_question["options"] = raw_data.get("options", [])
            structured_question["why_wrong_explanations"] = self._generate_why_wrong_explanations(raw_data)
        
        # Add diagram specification if required
        if structured_question["diagram_required"]:
            structured_question["diagram_id"] = f"diag_{primary_concept}_{question_id.split('_')[-1]}"
            structured_question["diagram_specification"] = self._generate_diagram_spec(raw_data, primary_concept)
        
        # Add learning objectives
        structured_question["learning_objectives"] = self._generate_learning_objectives(primary_concept)
        
        # Add common mistakes
        structured_question["common_mistakes"] = self._identify_common_mistakes(primary_concept, raw_data)
        
        return structured_question
    
    def _generate_question_id(self, raw_data: Dict) -> str:
        """Generate unique question ID"""
        year = raw_data.get("year", 2023)
        session = raw_data.get("session", "s1")
        chapter = self._extract_topic(raw_data).lower().replace(" ", "_")
        number = raw_data.get("question_number", "001")
        
        return f"jee_math_{chapter}_{year}_{session}_{number}"
    
    def _extract_topic(self, raw_data: Dict) -> str:
        """Extract topic from question text and metadata"""
        question_text = raw_data.get("question_text", "").lower()
        topic_hint = raw_data.get("topic", "")
        
        # Topic keywords mapping
        topic_keywords = {
            "regular polygon": ["regular polygon", "octagon", "hexagon", "pentagon", "square"],
            "central angle": ["central angle", "center", "angle", "360°"],
            "coordinate geometry": ["coordinate", "cartesian", "point", "distance", "section"],
            "trigonometry": ["sin", "cos", "tan", "angle", "trigonometric"],
            "quadratic equations": ["quadratic", "equation", "roots", "discriminant"],
            "functions": ["function", "graph", "domain", "range"],
            "calculus": ["limit", "derivative", "integral", "tangent"],
            "vectors": ["vector", "dot product", "magnitude"]
        }
        
        # Check for topic keywords
        for topic, keywords in topic_keywords.items():
            if topic_hint.lower() in topic.lower():
                return topic
            for keyword in keywords:
                if keyword in question_text:
                    return topic
        
        return topic_hint or "General"
    
    def _map_to_chapter(self, topic: str) -> str:
        """Map topic to chapter"""
        chapter_mapping = {
            "regular polygon": "Geometry",
            "central angle": "Geometry", 
            "coordinate geometry": "Coordinate Geometry",
            "trigonometry": "Trigonometry",
            "quadratic equations": "Quadratic Equations",
            "functions": "Functions and Graphs",
            "calculus": "Limits, Derivatives, Integrals",
            "vectors": "Vectors"
        }
        
        return chapter_mapping.get(topic, "Geometry")
    
    def _map_to_concept(self, topic: str) -> str:
        """Map topic to concept ID from concepts.yaml"""
        concept_mapping = {
            "regular polygon": "regular_polygon",
            "central angle": "central_angle_regular_polygon",
            "coordinate geometry": "cartesian_system",
            "distance": "distance_formula",
            "section": "section_formula",
            "trigonometry": "trigonometric_ratios",
            "quadratic equations": "quadratic_formula",
            "functions": "function_basics",
            "calculus": "limits_intuitive",
            "vectors": "vector_basics"
        }
        
        return concept_mapping.get(topic.lower(), "basic_angle")
    
    def _get_prerequisites(self, concept: str) -> List[str]:
        """Get prerequisites for a concept"""
        concept_data = self.concepts.get(concept, {})
        return concept_data.get("prerequisites", [])
    
    def _determine_class_level(self, raw_data: Dict) -> str:
        """Determine appropriate class level"""
        difficulty = raw_data.get("difficulty", "medium")
        
        if difficulty == "easy":
            return "Class 10"
        elif difficulty == "medium":
            return "Class 11"
        else:  # hard
            return "Class 11-12"
    
    def _assess_difficulty(self, raw_data: Dict) -> str:
        """Assess question difficulty"""
        # Check for complexity indicators
        question_text = raw_data.get("question_text", "").lower()
        
        complexity_indicators = [
            "prove", "derivation", "general", "formula", "expression",
            "maximum", "minimum", "optimization", "inequality"
        ]
        
        if any(indicator in question_text for indicator in complexity_indicators):
            return "hard"
        elif len(question_text.split()) > 20:
            return "medium"
        else:
            return "easy"
    
    def _estimate_time(self, raw_data: Dict) -> int:
        """Estimate solving time in seconds"""
        difficulty = self._assess_difficulty(raw_data)
        
        time_mapping = {
            "easy": 60,      # 1 minute
            "medium": 120,   # 2 minutes  
            "hard": 180      # 3 minutes
        }
        
        return time_mapping.get(difficulty, 120)
    
    def _detect_question_type(self, raw_data: Dict) -> str:
        """Detect question type"""
        if "options" in raw_data:
            return "multiple_choice"
        elif raw_data.get("answer_type") == "integer":
            return "integer_type"
        else:
            return "numerical"
    
    def _structure_solution(self, solution_text: str) -> List[Dict]:
        """Structure solution into steps"""
        if not solution_text:
            return [{
                "step_number": 1,
                "description": "Solution not provided",
                "calculation": ""
            }]
        
        # Split solution into steps (simple heuristic)
        steps = []
        sentences = solution_text.split('. ')
        
        for i, sentence in enumerate(sentences, 1):
            if sentence.strip():
                steps.append({
                    "step_number": i,
                    "description": sentence.strip(),
                    "calculation": ""  # Could be enhanced with formula extraction
                })
        
        return steps
    
    def _generate_why_wrong_explanations(self, raw_data: Dict) -> Dict[str, str]:
        """Generate why-wrong explanations for incorrect options"""
        options = raw_data.get("options", [])
        correct_answer = raw_data.get("answer", "")
        
        explanations = {}
        
        for option in options:
            label = option.get("label", "")
            text = option.get("text", "")
            
            if label != correct_answer:
                # Generate basic explanation (would be enhanced with AI)
                explanations[label] = f"This option is incorrect. {text} is not the right answer based on the given conditions."
        
        return explanations
    
    def _needs_diagram(self, raw_data: Dict) -> bool:
        """Determine if question needs a diagram"""
        question_text = raw_data.get("question_text", "").lower()
        
        diagram_keywords = [
            "diagram", "figure", "graph", "plot", "coordinate", "geometry",
            "triangle", "circle", "polygon", "angle", "visual", "shown"
        ]
        
        return any(keyword in question_text for keyword in diagram_keywords)
    
    def _generate_diagram_spec(self, raw_data: Dict, concept: str) -> Dict:
        """Generate diagram specification"""
        question_text = raw_data.get("question_text", "").lower()
        
        # Basic diagram specification based on concept
        if "coordinate" in question_text:
            return {
                "type": "coordinate_system",
                "elements": [
                    {"id": "axes", "type": "coordinate_system"},
                    {"id": "points", "type": "point"}
                ]
            }
        elif "triangle" in question_text or "polygon" in question_text:
            return {
                "type": "geometry",
                "elements": [
                    {"id": "polygon", "type": "polygon"},
                    {"id": "angles", "type": "angle"},
                    {"id": "labels", "type": "label"}
                ]
            }
        elif "circle" in question_text:
            return {
                "type": "geometry",
                "elements": [
                    {"id": "circle", "type": "circle"},
                    {"id": "center", "type": "point"},
                    {"id": "radius", "type": "line"}
                ]
            }
        else:
            return {
                "type": "geometry",
                "elements": []
            }
    
    def _generate_learning_objectives(self, concept: str) -> List[str]:
        """Generate learning objectives for a concept"""
        concept_data = self.concepts.get(concept, {})
        description = concept_data.get("description", "")
        
        # Extract learning objectives from description
        objectives = [f"Understand {description}"]
        
        # Add concept-specific objectives
        if "angle" in concept:
            objectives.append("Calculate angle measures using appropriate formulas")
        if "area" in concept:
            objectives.append("Apply area formulas to solve problems")
        if "coordinate" in concept:
            objectives.append("Use coordinate geometry methods")
        
        return objectives
    
    def _identify_common_mistakes(self, concept: str, raw_data: Dict) -> List[Dict]:
        """Identify common mistakes for this concept"""
        mistakes = []
        
        # Concept-specific mistake patterns
        mistake_patterns = {
            "central_angle_regular_polygon": [
                {
                    "mistake": "Using wrong formula for central angle",
                    "explanation": "Central angle = 360°/n, not 180°/n or 360°/(n-1)",
                    "frequency": "common"
                },
                {
                    "mistake": "Confusing central angle with interior angle",
                    "explanation": "Central angle is at the center, interior angle is at the vertex",
                    "frequency": "very_common"
                }
            ],
            "distance_formula": [
                {
                    "mistake": "Forgetting to square the differences",
                    "explanation": "Distance formula uses squared differences: √[(x₂-x₁)² + (y₂-y₁)²]",
                    "frequency": "common"
                },
                {
                    "mistake": "Wrong order of coordinates",
                    "explanation": "Order doesn't matter due to squaring, but be consistent",
                    "frequency": "occasional"
                }
            ]
        }
        
        return mistake_patterns.get(concept, [])
    
    def generate_rescue_ladders(self, question: Dict) -> List[Dict]:
        """Generate rescue ladder questions for a JEE question"""
        primary_concept = question["primary_concept"]
        
        # Get rescue ladder progression
        rescue_progression = self.concepts.get("rescue_ladders", {})
        progression_key = None
        
        # Find matching progression
        for key, progression in rescue_progression.items():
            if progression["target"] == primary_concept:
                progression_key = key
                break
        
        if not progression_key:
            return []
        
        progression = rescue_progression[progression_key]
        rescue_questions = []
        
        # Generate foundation question
        foundation_concept = progression["levels"]["foundation"]
        rescue_questions.append(self._generate_foundation_question(foundation_concept, question))
        
        # Generate bridge question
        bridge_concept = progression["levels"]["bridge"]
        rescue_questions.append(self._generate_bridge_question(bridge_concept, question))
        
        return rescue_questions
    
    def _generate_foundation_question(self, concept: str, target_question: Dict) -> Dict:
        """Generate foundation level rescue question"""
        concept_data = self.concepts.get(concept, {})
        
        foundation_question = {
            "question_id": f"rescue_foundation_{concept}_{target_question['question_id'].split('_')[-1]}",
            "source_type": "ncert_aligned",
            "subject": "Mathematics",
            "chapter": target_question["chapter"],
            "topic": concept_data.get("name", concept),
            "primary_concept": concept,
            "prerequisites": self._get_prerequisites(concept),
            "class_level": "Class 8-9",
            "bridge_level": "foundation",
            "difficulty": "easy",
            "expected_time_seconds": 60,
            "question_text": self._generate_foundation_question_text(concept),
            "question_type": "multiple_choice",
            "correct_answer": "B",
            "solution_steps": self._generate_foundation_solution(concept),
            "rescue_question_ids": [],
            "diagram_required": concept_data.get("diagram_required", False),
            "review_status": "ai_generated",
            "learning_objectives": [f"Understand basic {concept_data.get('name', concept)}"],
            "common_mistakes": []
        }
        
        # Add options and explanations
        foundation_question["options"] = self._generate_foundation_options(concept)
        foundation_question["why_wrong_explanations"] = self._generate_foundation_why_wrong()
        
        return foundation_question
    
    def _generate_bridge_question(self, concept: str, target_question: Dict) -> Dict:
        """Generate bridge level rescue question"""
        concept_data = self.concepts.get(concept, {})
        
        bridge_question = {
            "question_id": f"rescue_bridge_{concept}_{target_question['question_id'].split('_')[-1]}",
            "source_type": "ncert_aligned",
            "subject": "Mathematics", 
            "chapter": target_question["chapter"],
            "topic": concept_data.get("name", concept),
            "primary_concept": concept,
            "prerequisites": self._get_prerequisites(concept),
            "class_level": "Class 9-10",
            "bridge_level": "school",
            "difficulty": "medium",
            "expected_time_seconds": 90,
            "question_text": self._generate_bridge_question_text(concept),
            "question_type": "multiple_choice",
            "correct_answer": "C",
            "solution_steps": self._generate_bridge_solution(concept),
            "rescue_question_ids": [],
            "diagram_required": concept_data.get("diagram_required", False),
            "review_status": "ai_generated",
            "learning_objectives": [f"Apply {concept_data.get('name', concept)} in problem solving"],
            "common_mistakes": self._identify_common_mistakes(concept, {})
        }
        
        # Add options and explanations
        bridge_question["options"] = self._generate_bridge_options(concept)
        bridge_question["why_wrong_explanations"] = self._generate_bridge_why_wrong()
        
        return bridge_question
    
    def _generate_foundation_question_text(self, concept: str) -> str:
        """Generate foundation level question text"""
        question_templates = {
            "square_center_angle": "A square is divided from its center into 4 equal triangles. What is the measure of each central angle?",
            "triangle_center_angle": "An equilateral triangle is divided from its center into 3 equal triangles. What is the measure of each central angle?",
            "hexagon_center_angle": "A regular hexagon is divided from its center into 6 equal triangles. What is the measure of each central angle?",
            "cartesian_system": "Which quadrant contains the point (-2, 3)?",
            "distance_formula": "Find the distance between the points (0, 0) and (3, 4).",
            "trigonometric_ratios": "In a right triangle with sides 3, 4, 5, what is sin of the angle opposite side 3?"
        }
        
        return question_templates.get(concept, f"Basic question about {concept}")
    
    def _generate_bridge_question_text(self, concept: str) -> str:
        """Generate bridge level question text"""
        question_templates = {
            "hexagon_center_angle": "A regular hexagon has a side length of 6 cm. Find the area of one of the central triangles.",
            "octagon_center_angle": "A regular octagon is inscribed in a circle of radius 5 cm. Find the length of each side.",
            "distance_formula": "The distance between points (x, 3) and (5, 7) is 5 units. Find the value of x.",
            "section_formula": "Find the coordinates of the point that divides the line segment joining (2, 3) and (8, 9) in the ratio 2:1.",
            "trigonometric_ratios": "If tan θ = 3/4 in a right triangle, find sin θ."
        }
        
        return question_templates.get(concept, f"Bridge question about {concept}")
    
    def _generate_foundation_solution(self, concept: str) -> List[Dict]:
        """Generate foundation level solution"""
        solutions = {
            "square_center_angle": [
                {"step_number": 1, "description": "A full circle has 360°", "calculation": "360°"},
                {"step_number": 2, "description": "Square divides circle into 4 equal parts", "calculation": "360° ÷ 4 = 90°"},
                {"step_number": 3, "description": "Each central angle is 90°", "calculation": "Answer: 90°"}
            ],
            "cartesian_system": [
                {"step_number": 1, "description": "Point (-2, 3) has x = -2 (negative) and y = 3 (positive)", "calculation": "x negative, y positive"},
                {"step_number": 2, "description": "Second quadrant has negative x and positive y", "calculation": "Quadrant II"},
                {"step_number": 3, "description": "Point (-2, 3) is in second quadrant", "calculation": "Answer: Second quadrant"}
            ]
        }
        
        return solutions.get(concept, [{"step_number": 1, "description": "Solution steps", "calculation": ""}])
    
    def _generate_bridge_solution(self, concept: str) -> List[Dict]:
        """Generate bridge level solution"""
        solutions = {
            "hexagon_center_angle": [
                {"step_number": 1, "description": "Central angle of regular hexagon = 360°/6", "calculation": "360° ÷ 6 = 60°"},
                {"step_number": 2, "description": "Each central triangle is isosceles with vertex angle 60°", "calculation": "Vertex angle = 60°"},
                {"step_number": 3, "description": "Area of triangle = (1/2) × r² × sin(60°)", "calculation": "Area = (1/2) × 6² × (√3/2) = 9√3 cm²"}
            ]
        }
        
        return solutions.get(concept, [{"step_number": 1, "description": "Bridge solution steps", "calculation": ""}])
    
    def _generate_foundation_options(self, concept: str) -> List[Dict]:
        """Generate foundation level options"""
        options_templates = {
            "square_center_angle": [
                {"label": "A", "text": "45°", "isCorrect": False},
                {"label": "B", "text": "90°", "isCorrect": True},
                {"label": "C", "text": "180°", "isCorrect": False},
                {"label": "D", "text": "360°", "isCorrect": False}
            ],
            "cartesian_system": [
                {"label": "A", "text": "First quadrant", "isCorrect": False},
                {"label": "B", "text": "Second quadrant", "isCorrect": True},
                {"label": "C", "text": "Third quadrant", "isCorrect": False},
                {"label": "D", "text": "Fourth quadrant", "isCorrect": False}
            ]
        }
        
        return options_templates.get(concept, [
            {"label": "A", "text": "Option A", "isCorrect": False},
            {"label": "B", "text": "Option B", "isCorrect": True},
            {"label": "C", "text": "Option C", "isCorrect": False},
            {"label": "D", "text": "Option D", "isCorrect": False}
        ])
    
    def _generate_bridge_options(self, concept: str) -> List[Dict]:
        """Generate bridge level options"""
        options_templates = {
            "hexagon_center_angle": [
                {"label": "A", "text": "6√3 cm²", "isCorrect": False},
                {"label": "B", "text": "9√3 cm²", "isCorrect": True},
                {"label": "C", "text": "12√3 cm²", "isCorrect": False},
                {"label": "D", "text": "18√3 cm²", "isCorrect": False}
            ]
        }
        
        return options_templates.get(concept, [
            {"label": "A", "text": "Bridge Option A", "isCorrect": False},
            {"label": "B", "text": "Bridge Option B", "isCorrect": True},
            {"label": "C", "text": "Bridge Option C", "isCorrect": False},
            {"label": "D", "text": "Bridge Option D", "isCorrect": False}
        ])
    
    def _generate_foundation_why_wrong(self) -> Dict[str, str]:
        """Generate foundation why-wrong explanations"""
        return {
            "A": "This option is incorrect. Check your calculation again.",
            "C": "This option is incorrect. Review the basic concept.",
            "D": "This option is incorrect. This is the total angle, not the individual angle."
        }
    
    def _generate_bridge_why_wrong(self) -> Dict[str, str]:
        """Generate bridge why-wrong explanations"""
        return {
            "A": "This option is incorrect. You may have used the wrong formula.",
            "C": "This option is incorrect. Check your trigonometric values.",
            "D": "This option is incorrect. Review the area calculation."
        }
    
    def save_question(self, question: Dict) -> str:
        """Save question to JSON file"""
        filename = f"{question['question_id']}.json"
        filepath = self.output_dir / filename
        
        with open(filepath, 'w') as f:
            json.dump(question, f, indent=2)
        
        return str(filepath)
    
    def process_jee_batch(self, raw_questions: List[Dict]) -> Dict[str, List[str]]:
        """Process a batch of JEE questions with rescue ladders"""
        results = {
            "jee_questions": [],
            "rescue_questions": [],
            "errors": []
        }
        
        for raw_question in raw_questions:
            try:
                # Process main JEE question
                jee_question = self.parse_jee_question(raw_question)
                jee_file = self.save_question(jee_question)
                results["jee_questions"].append(jee_file)
                
                # Generate rescue ladders
                rescue_questions = self.generate_rescue_ladders(jee_question)
                
                # Update JEE question with rescue references
                jee_question["rescue_question_ids"] = [rq["question_id"] for rq in rescue_questions]
                
                # Save rescue questions
                for rescue_q in rescue_questions:
                    rescue_file = self.save_question(rescue_q)
                    results["rescue_questions"].append(rescue_file)
                
                # Re-save JEE question with rescue references
                self.save_question(jee_question)
                
            except Exception as e:
                results["errors"].append(f"Error processing question: {e}")
        
        return results

def main():
    """Example usage"""
    importer = JEEQuestionImporter()
    
    # Sample JEE question data
    sample_jee_questions = [
        {
            "year": 2023,
            "session": "session_1",
            "paper": "paper_1",
            "shift": "shift_1",
            "question_number": "Q12",
            "question_text": "A regular octagon is formed by joining the midpoints of the sides of a square of side length 8 cm. Find the area of the octagon.",
            "options": [
                {"label": "A", "text": "32√2 cm²"},
                {"label": "B", "text": "64 cm²"},
                {"label": "C", "text": "32 cm²"},
                {"label": "D", "text": "32(2-√2) cm²"}
            ],
            "answer": "D",
            "solution": "The octagon area = square area - 4 corner triangles = 64 - 4×8 = 32 cm²",
            "topic": "Regular Polygons",
            "difficulty": "hard"
        }
    ]
    
    # Process questions
    results = importer.process_jee_batch(sample_jee_questions)
    
    print(f"Processed {len(results['jee_questions'])} JEE questions")
    print(f"Generated {len(results['rescue_questions'])} rescue questions")
    
    if results["errors"]:
        print(f"Errors: {len(results['errors'])}")
        for error in results["errors"]:
            print(f"  - {error}")

if __name__ == "__main__":
    main()