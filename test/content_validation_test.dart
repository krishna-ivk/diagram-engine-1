import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';
import 'dart:io';
import 'dart:convert';

import '../tools/validate_content.dart';

void main() {
  group('Content Validation Tests', () {
    test('Content Schema Validation', () async {
      final validator = ContentValidator();
      
      // Test schema validation with valid question
      final validQuestion = {
        "question_id": "test_geometry_001",
        "source_type": "ncert_aligned",
        "subject": "Mathematics",
        "chapter": "Geometry",
        "topic": "Regular Polygons",
        "primary_concept": "regular_polygon",
        "prerequisites": ["polygon_vertices"],
        "class_level": "Class 9",
        "bridge_level": "foundation",
        "difficulty": "easy",
        "expected_time_seconds": 60,
        "question_text": "What is the central angle of a square?",
        "question_type": "multiple_choice",
        "options": [
          {"label": "A", "text": "45°", "isCorrect": false},
          {"label": "B", "text": "90°", "isCorrect": true},
          {"label": "C", "content": "180°", "isCorrect": false},
          {"label": "D", "content": "360°", "isCorrect": false}
        ],
        "correct_answer": "B",
        "solution_steps": [
          {
            "step_number": 1,
            "description": "A full circle is 360°",
            "calculation": "360°"
          },
          {
            "step_number": 2,
            "description": "Square has 4 equal angles",
            "calculation": "360° ÷ 4 = 90°"
          }
        ],
        "rescue_question_ids": [],
        "diagram_required": true,
        "diagram_id": "diag_square_001",
        "review_status": "published"
      };
      
      final result = validator._validateContent(validQuestion, 'test_question.json');
      expect(result.isValid, true, reason: 'Valid question should pass validation');
      expect(result.errors, isEmpty, reason: 'No errors expected');
    });
    
    test('JEE Question Requirements', () async {
      final validator = ContentValidator();
      
      // Test JEE question without prerequisites (should fail)
      final invalidJEE = {
        "question_id": "jee_geometry_001",
        "source_type": "jee_previous_paper",
        "subject": "Mathematics",
        "chapter": "Geometry",
        "topic": "Regular Polygons",
        "primary_concept": "regular_polygon",
        "prerequisites": [], // Missing prerequisites for JEE
        "class_level": "Class 11-12",
        "bridge_level": "jee",
        "difficulty": "hard",
        "expected_time_seconds": 180,
        "question_text": "Complex JEE question",
        "question_type": "multiple_choice",
        "correct_answer": "D",
        "solution_steps": [
          {"step_number": 1, "description": "Step 1", "calculation": "Calc 1"}
        ],
        "rescue_question_ids": [], // Missing rescue questions for JEE
        "diagram_required": false, // Missing diagram for JEE
        "review_status": "published"
      };
      
      final result = validator._validateContent(invalidJEE, 'test_jee_invalid.json');
      expect(result.isValid, false, reason: 'JEE question without prerequisites should fail');
      expect(result.errors, contains('JEE-level question must have prerequisites'), reason: 'Should fail for missing prerequisites');
      expect(result.errors, contains('JEE question must have at least 2 rescue question IDs'), reason: 'Should fail for missing rescue questions');
      expect(result.errors, contains('JEE question must have diagram_id'), reason: 'Should fail for missing diagram');
    });
    
    test('Multiple Choice Requirements', () async {
      final validator = ContentValidator();
      
      // Test MCQ without why-wrong explanations (should fail)
      final invalidMCQ = {
        "question_id": "test_mcq_001",
        "source_type": "ncert_aligned",
        "subject": "Mathematics",
        "chapter": "Geometry",
        "topic": "Angles",
        "primary_concept": "basic_angle",
        "prerequisites": [],
        "class_level": "Class 8",
        "bridge_level": "foundation",
        "difficulty": "easy",
        "expected_time_seconds": 60,
        "question_text": "What is a right angle?",
        "question_type": "multiple_choice",
        "options": [
          {"label": "A", "text": "45°", "isCorrect": false},
          {"label": "B", "text": "90°", "isCorrect": true},
          {"label": "C", "text": "180°", "isCorrect": false},
          {"label": "D", "text": "360°", "isCorrect": false}
        ],
        "correct_answer": "B",
        "solution_steps": [
          {"step_number": 1, "description": "Step 1", "calculation": "Calc 1"}
        ],
        "why_wrong_explanations": {
          "A": "Wrong explanation"
        }, // Missing 2 explanations
        "rescue_question_ids": [],
        "diagram_required": false,
        "review_status": "published"
      };
      
      final result = validator._validateContent(invalidMCQ, 'test_mcq_invalid.json');
      expect(result.isValid, false, reason: 'MCQ without enough why-wrong explanations should fail');
      expect(result.errors, contains('MCQ must have why-wrong explanations for at least 3 incorrect options'), reason: 'Should fail for insufficient why-wrong explanations');
    });
    
    test('Diagram Question Requirements', () async {
      final validator = ContentValidator();
      
      // Test diagram question without diagram_id (should fail)
      final invalidDiagram = {
        "question_id": "test_diagram_001",
        "source_type": "ncert_aligned",
        "subject": "Mathematics",
        "chapter": "Geometry",
        "topic": "Coordinate Geometry",
        "primary_concept": "cartesian_system",
        "prerequisites": ["basic_angle"],
        "class_level": "Class 9",
        "bridge_level": "foundation",
        "difficulty": "medium",
        "expected_time_seconds": 90,
        "question_text": "Plot the point (2, 3)",
        "question_type": "multiple_choice",
        "correct_answer": "B",
        "solution_steps": [
          {"step_number": 1, "description": "Step 1", "content": "Calc 1"}
        ],
        "diagram_required": true, // Requires diagram but no diagram_id
        "review_status": "published"
      };
      
      final result = validator._validateContent(invalidDiagram, 'test_diagram_invalid.json');
      expect(result.isValid, false, reason: 'Diagram question without diagram_id should fail');
      expect(result.errors, contains('Diagram required but no diagram_id provided'), reason: 'Should fail for missing diagram_id');
    });
    
    test('Source Metadata Requirements', () async {
      final validator = ContentValidator();
      
      // Test JEE question without source metadata (should fail)
      final invalidSource = {
        "question_id": "jee_source_001",
        "source_type": "jee_previous_paper",
        "subject": "Mathematics",
        "chapter": "Geometry",
        "topic": "Regular Polygons",
        "primary_concept": "regular_polygon",
        "prerequisites": ["polygon_vertices"],
        "class_level": "Class 11-12",
        "bridge_level": "jee",
        "difficulty": "hard",
        "expected_time_seconds": 180,
        "question_text": "JEE question",
        "question_type": "multiple_choice",
        "correct_answer": "D",
        "solution_steps": [
          {"step_number": 1, "description": "Step 1", "calculation": "Calc 1"}
        ],
        "rescue_question_ids": ["rescue_001", "rescue_002"],
        "diagram_required": true,
        "diagram_id": "diag_001",
        "review_status": "published"
        // Missing source_metadata
      };
      
      final result = validator._validateContent(invalidSource, 'test_source_invalid.json');
      expect(result.isValid, false, reason: 'JEE question without source metadata should fail');
      expect(result.errors, contains('JEE question must have source_metadata'), reason: 'Should fail for missing source metadata');
    });
    
    test('Question ID Format Validation', () async {
      final validator = ContentValidator();
      
      // Test invalid question ID format (should fail)
      final invalidID = {
        "question_id": "Invalid_ID_Format",
        "source_type": "ncert_aligned",
        "subject": "Mathematics",
        "chapter": "Geometry",
        "topic": "Angles",
        "primary_concept": "basic_angle",
        "prerequisites": [],
        "class_level": "Class 8",
        "bridge_level": "expected_time_seconds",
        "difficulty": "easy",
        "expected_time_seconds": 60,
        "question_text": "Test question",
        "question_type": "multiple_choice",
        "correct_answer": "B",
        "solution_steps": [
          {"step_number": 1, "description": "Step 1", "calculation": "Calc 1"}
        ],
        "rescue_question_ids": [],
        "diagram_required": false,
        "review_status": "published"
      };
      
      final result = validator._validateContent(invalidID, 'test_id_invalid.json');
      expect(result.isValid, false, reason: 'Invalid question ID format should fail');
      expect(result.errors, contains('Invalid question_id format'), reason: 'Should fail for invalid ID format');
    });
    
    test('Expected Time Validation', () async {
      final validator = ContentValidator();
      
      // Test expected time outside range (should warn)
      final invalidTime = {
        "question_id": "test_time_001",
        "source_type": "ncert_aligned",
        "subject": "Mathematics",
        "chapter": "Geometry",
        "topic": "Angles",
        "primary_concept": "basic_angle",
        "prerequisites": [],
        "class_level": "Class 8",
        "bridge_level": "foundation",
        "difficulty": "easy",
        "expected_time_seconds": 25, // Too short
        "question_text": "Test question",
        "question_type": "multiple_choice",
        "correct_answer": "B",
        "solution_steps": [
          {"step_number": 1, "description": "Step 1", "calculation": "Calc 1"}
        ],
        "rescue_question_ids": [],
        "diagram_required": false,
        "review_status": "published"
      };
      
      final result = validator._validateContent(invalidTime, 'test_time_invalid.json');
      expect(result.isValid, true, reason: 'Expected time outside range should warn but still pass');
      expect(result.warnings, contains('Expected time 25 seconds is outside recommended range'), reason: 'Should warn for time outside 30-300 range');
    });
  });
  
  group('Rescue Flow Tests', () {
    test('Rescue Question Loading', () async {
      final loader = ContentLoader();
      
      // Test loading rescue ladder
      final rescueQuestions = await loader.loadGeometryRescueLadder();
      
      expect(rescueQuestions.isNotEmpty, reason: 'Should load rescue questions');
      expect(rescueQuestions.length, 3, reason: 'Should have 3 rescue questions in ladder');
      
      // Check that rescue questions have proper structure
      for (final question in rescueQuestions) {
        expect(question.id.isNotEmpty, reason: 'Each rescue question should have an ID');
        expect(question.questionText.isNotEmpty, reason: 'Each rescue question should have text');
        expect(question.primaryConcept.isNotEmpty, reason: 'Each rescue question should have primary concept');
      }
    });
    
    test('Mock Rescue Question Creation', () async {
      final loader = ContentLoader();
      
      // Test mock question creation
      final mockQuestion = loader.createMockRescueQuestion(
        id: 'mock_foundation_001',
        text: 'What is the central angle of a square?',
        primaryConcept: 'square_center_angle',
        correctAnswer: 'B',
        difficulty: 'easy',
        questionRole: 'foundation',
      );
      
      expect(mockQuestion.id, 'mock_foundation_001');
      expect(mockQuestion.questionText, 'What is the central angle of a square?');
      expect(mockQuestion.primaryConcept, 'square_center_angle');
      expect(mockQuestion.correctAnswer, 'B');
      expect(mockQuestion.difficulty, Difficulty.foundation);
      expect(mockQuestion.questionRole, QuestionRole.foundation);
      expect(mockQuestion.reviewStatus, 'published');
    });
  });
  
  group('Pipeline Completeness', () {
    test('Required Files Exist', () async {
      final validator = ContentValidator();
      
      final result = validator.validatePipelineCompleteness();
      expect(result.isValid, true, reason: 'All required files should exist');
      expect(result.errors, isEmpty, reason: 'No errors expected in pipeline');
    });
    
    test('Sample Questions Directory', () async {
      final validator = ContentValidator();
      
      final result = validator.validateDirectory('content/sample_questions');
      expect(result.isValid, true, reason: 'Sample questions should be valid');
      expect(result.summary, contains('Validated'), reason: 'Should show validation summary');
    });
  });
  
  group('Integration Tests', () {
    test('Complete Workflow', () async {
      final validator = ContentValidator();
      
      // Run full pipeline validation
      validator.generateReport('content/validation_report.json');
      
      // Check if report was created
      final reportFile = File('content/validation_report.json');
      expect(reportFile.existsSync(), true, reason: 'Validation report should be created');
      
      final reportContent = reportFile.readAsStringSync();
      expect(reportContent.isNotEmpty, reason: 'Report should have content');
      
      final reportData = json.decode(reportContent) as Map<String, dynamic>;
      expect(reportData.containsKey('pipeline_validation'), reason: 'Report should have pipeline validation section');
      expect(reportData.containsKey('sample_questions_validation'), reason: 'Report should have sample questions section');
    });
  });
}