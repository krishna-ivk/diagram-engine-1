import json
import os
from typing import List, Dict, Any, Optional
from pathlib import Path

from schemas import QuestionData, Difficulty, QuestionType

class ContentLoader:
    def __init__(self):
        self.content_base_path = Path(__file__).parent.parent.parent / "content"
        self._question_cache = {}
        self._topic_cache = {}
    
    async def load_topic_questions(self, topic_id: str) -> List[QuestionData]:
        """Load all questions for a specific topic"""
        
        # Check cache first
        if topic_id in self._topic_cache:
            return self._topic_cache[topic_id]
        
        # Load topic manifest to get question files
        topic_file = self.content_base_path / "topics" / f"{topic_id.split('.')[-1]}.json"
        
        if not topic_file.exists():
            # Fallback: try to load from general question files
            return await self._load_all_questions_for_topic(topic_id)
        
        with open(topic_file, 'r') as f:
            topic_data = json.load(f)
        
        # Collect all question IDs from the topic
        all_question_ids = []
        for question_list in [
            topic_data.get("starter_question_ids", []),
            topic_data.get("practice_question_ids", []),
            topic_data.get("challenge_question_ids", []),
            topic_data.get("jee_style_question_ids", []),
            topic_data.get("revision_question_ids", [])
        ]:
            all_question_ids.extend(question_list)
        
        # Load questions by their IDs
        questions = []
        for question_id in all_question_ids:
            question = await self.load_question_by_id(question_id)
            if question:
                questions.append(question)
        
        # Cache the results
        self._topic_cache[topic_id] = questions
        return questions
    
    async def load_question_by_id(self, question_id: str) -> Optional[QuestionData]:
        """Load a specific question by its ID"""
        
        # Check cache first
        if question_id in self._question_cache:
            return self._question_cache[question_id]
        
        # Load question manifest
        manifest_path = self.content_base_path / "questions" / "question_manifest.json"
        with open(manifest_path, 'r') as f:
            manifest = json.load(f)
        
        # Search through question files
        for file_name in manifest.get("files", []):
            file_path = self.content_base_path / "questions" / file_name
            if not file_path.exists():
                continue
            
            with open(file_path, 'r') as f:
                file_data = json.load(f)
            
            questions = file_data if isinstance(file_data, list) else file_data.get("questions", [])
            
            for question_data in questions:
                if question_data.get("question_id") == question_id or question_data.get("id") == question_id:
                    question = self._convert_to_question_data(question_data)
                    self._question_cache[question_id] = question
                    return question
        
        return None
    
    async def _load_all_questions_for_topic(self, topic_id: str) -> List[QuestionData]:
        """Fallback method: load all questions and filter by topic"""
        
        # Load question manifest
        manifest_path = self.content_base_path / "questions" / "question_manifest.json"
        with open(manifest_path, 'r') as f:
            manifest = json.load(f)
        
        questions = []
        
        # Search through all question files
        for file_name in manifest.get("files", []):
            file_path = self.content_base_path / "questions" / file_name
            if not file_path.exists():
                continue
            
            with open(file_path, 'r') as f:
                file_data = json.load(f)
            
            file_questions = file_data if isinstance(file_data, list) else file_data.get("questions", [])
            
            for question_data in file_questions:
                question_topic = question_data.get("topic", "")
                if topic_id.split('.')[-1].lower() in question_topic.lower():
                    question = self._convert_to_question_data(question_data)
                    questions.append(question)
        
        return questions
    
    def _convert_to_question_data(self, raw_data: Dict[str, Any]) -> QuestionData:
        """Convert raw JSON data to QuestionData schema"""
        
        # Parse correct answer as index
        correct_ans = raw_data.get("correct_answer", 0)
        if isinstance(correct_ans, str):
            correct_idx = ord(correct_ans.upper()) - ord('A')
        else:
            correct_idx = int(correct_ans)
        
        # Parse options
        options_data = raw_data.get("options", [])
        if isinstance(options_data, list):
            options = []
            for opt in options_data:
                if isinstance(opt, str):
                    options.append(opt)
                elif isinstance(opt, dict):
                    options.append(opt.get("text", str(opt)))
                else:
                    options.append(str(opt))
        else:
            options = ["A", "B", "C", "D"]
        
        # Parse why wrong explanations
        why_wrong_raw = raw_data.get("why_wrong_explanations", {})
        why_wrong_explanations = {}
        if isinstance(why_wrong_raw, dict):
            for key, value in why_wrong_raw.items():
                try:
                    key_int = int(key) if isinstance(key, str) else key
                    why_wrong_explanations[key_int] = str(value)
                except (ValueError, TypeError):
                    continue
        
        # Parse solution steps
        solution_steps = []
        steps_raw = raw_data.get("solution_steps", [])
        if isinstance(steps_raw, list):
            for step in steps_raw:
                if isinstance(step, dict):
                    solution_steps.append(step.get("description", str(step)))
                else:
                    solution_steps.append(str(step))
        
        # Parse formulae used
        formulae_used = raw_data.get("formulae_used", [])
        if isinstance(formulae_used, list):
            formulae_used = [str(f) for f in formulae_used]
        else:
            formulae_used = []
        
        return QuestionData(
            id=raw_data.get("question_id", raw_data.get("id", "")),
            text=raw_data.get("question_text", raw_data.get("text", "")),
            options=options,
            correct_index=correct_idx,
            explanation=raw_data.get("explanation"),
            subject=raw_data.get("subject", "Mathematics"),
            topic=raw_data.get("topic", ""),
            primary_concept=raw_data.get("primary_concept", raw_data.get("core_concept", "")),
            difficulty=self._parse_difficulty(raw_data.get("difficulty", "medium")),
            question_type=self._parse_question_type(raw_data.get("question_type", "mcq")),
            estimated_seconds=raw_data.get("expected_time_seconds", 120),
            frequently_asked=raw_data.get("frequently_asked", False),
            high_weight_topic=raw_data.get("high_weight_topic", False),
            solution_steps=solution_steps,
            why_wrong_explanations=why_wrong_explanations if why_wrong_explanations else None,
            formulae_used=formulae_used
        )
    
    def _parse_difficulty(self, difficulty_str: str) -> Difficulty:
        """Parse difficulty string to enum"""
        difficulty_map = {
            "easy": Difficulty.easy,
            "foundation": Difficulty.easy,
            "medium": Difficulty.medium,
            "bridge": Difficulty.medium,
            "hard": Difficulty.hard,
            "jee": Difficulty.hard,
            "jee_pattern": Difficulty.hard,
            "mock_exam": Difficulty.hard
        }
        return difficulty_map.get(difficulty_str.lower(), Difficulty.medium)
    
    def _parse_question_type(self, type_str: str) -> QuestionType:
        """Parse question type string to enum"""
        type_map = {
            "mcq": QuestionType.mcq,
            "integer": QuestionType.integer,
            "multiple_correct": QuestionType.multiple_correct,
            "assertion_reason": QuestionType.assertion_reason,
            "comprehension": QuestionType.comprehension
        }
        return type_map.get(type_str.lower(), QuestionType.mcq)
    
    async def get_topic_summary(self, topic_id: str) -> Dict[str, Any]:
        """Get summary statistics for a topic"""
        
        questions = await self.load_topic_questions(topic_id)
        
        if not questions:
            return {
                "topic_id": topic_id,
                "total_questions": 0,
                "difficulty_distribution": {},
                "question_types": {},
                "estimated_total_time": 0
            }
        
        # Calculate distributions
        difficulty_counts = {}
        type_counts = {}
        total_time = 0
        
        for question in questions:
            # Count by difficulty
            diff = question.difficulty.value
            difficulty_counts[diff] = difficulty_counts.get(diff, 0) + 1
            
            # Count by type
            qtype = question.question_type.value
            type_counts[qtype] = type_counts.get(qtype, 0) + 1
            
            # Sum estimated time
            total_time += question.estimated_seconds
        
        return {
            "topic_id": topic_id,
            "total_questions": len(questions),
            "difficulty_distribution": difficulty_counts,
            "question_types": type_counts,
            "estimated_total_time": total_time,
            "frequently_asked_count": sum(1 for q in questions if q.frequently_asked),
            "high_weight_count": sum(1 for q in questions if q.high_weight_topic)
        }