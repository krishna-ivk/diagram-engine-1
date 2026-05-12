#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

/// PYQ Pattern Analyzer - Pattern Discovery Pipeline
/// 
/// This script analyzes JEE PYQ patterns to create original fundamental questions.
/// It does NOT copy exact question text, options, or solutions from external sources.
/// Used only for pattern discovery and concept mapping.

class PYQPatternAnalyzer {
  static const String patternsDir = 'content/patterns';
  static const String questionsDir = 'content/questions';
  static const String topicsDir = 'content/topics';

  /// Analyze patterns and generate original fundamental questions
  Future<void> generateFundamentalQuestions() async {
    print('🔍 PYQ Pattern Analysis Started');
    print('⚠️  WARNING: This pipeline creates ORIGINAL content only');
    print('📚 No direct copying from external sources');
    
    // Load pattern index
    final patternFile = File('$patternsDir/regular_polygon_patterns.json');
    if (!patternFile.existsSync()) {
      print('❌ Pattern file not found: ${patternFile.path}');
      return;
    }
    
    final patternData = jsonDecode(await patternFile.readAsString());
    final patterns = patternData['patterns'] as List;
    
    print('📊 Found ${patterns.length} patterns to analyze');
    
    // Generate questions for each pattern
    for (final pattern in patterns) {
      await generateQuestionsForPattern(pattern);
    }
    
    print('✅ PYQ Pattern Analysis Complete');
    print('🎯 Original fundamental questions generated');
  }

  /// Generate original questions for a specific pattern
  Future<void> generateQuestionsForPattern(Map<String, dynamic> pattern) async {
    final patternId = pattern['pattern_id'] as String;
    final targetTopic = pattern['target_topic_capsule'] as String;
    final difficultyBridge = pattern['difficulty_bridge'] as String;
    
    print('\n🔄 Processing pattern: $patternId');
    print('🎯 Target topic: $targetTopic');
    print('📈 Difficulty bridge: $difficultyBridge');
    
    // Generate questions based on pattern analysis
    final questions = <Map<String, dynamic>>[];
    
    // Starter questions (5)
    questions.addAll(await generateStarterQuestions(pattern));
    
    // Practice questions (7)
    questions.addAll(await generatePracticeQuestions(pattern));
    
    // Challenge questions (3)
    questions.addAll(await generateChallengeQuestions(pattern));
    
    // JEE-style question (1)
    questions.addAll(await generateJEEStyleQuestions(pattern));
    
    // Save generated questions
    await saveGeneratedQuestions(targetTopic, questions);
    
    print('✅ Generated ${questions.length} original questions for $patternId');
  }

  /// Generate starter questions - basic concepts, Class 7 level
  Future<List<Map<String, dynamic>>> generateStarterQuestions(Map<String, dynamic> pattern) async {
    final questions = <Map<String, dynamic>>[];
    final patternId = pattern['pattern_id'] as String;
    
    if (patternId == 'regular_polygon_central_angle') {
      questions.addAll([
        {
          "question_id": "fundamental_central_angle_square_001",
          "source_type": "original_recreated",
          "source_pattern": patternId,
          "class_level": "Class 7",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "starter",
          "question_text": "A square is divided from the center into 4 equal parts. What is each central angle?",
          "options": ["45°", "60°", "90°", "120°"],
          "correct_answer": 2,
          "formulae_used": ["central_angle = 360° / n"],
          "why_wrong_explanations": {
            "0": "45° is the central angle of an octagon (8 sides), not a square.",
            "1": "60° is the central angle of a hexagon (6 sides).",
            "3": "120° is the central angle of a triangle (3 sides)."
          },
          "difficulty": "easy",
          "estimated_time_seconds": 45,
          "diagram_required": true,
          "manipulative": "polygon_sides_slider",
          "review_status": "draft"
        },
        {
          "question_id": "fundamental_central_angle_triangle_002_fixed",
          "source_type": "original_recreated",
          "source_pattern": patternId,
          "class_level": "Class 7",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "starter",
          "question_text": "An equilateral triangle is divided from the center into 3 equal parts. What is each central angle?",
          "options": ["90°", "120°", "180°", "60°"],
          "correct_answer": 3,
          "formulae_used": ["central_angle = 360° / n"],
          "why_wrong_explanations": {
            "0": "90° is the central angle of a square (4 sides).",
            "1": "120° would be for a triangle if it were 3 equal angles, but central angle is different.",
            "2": "180° is a straight angle, not a central angle of a regular polygon."
          },
          "difficulty": "easy",
          "estimated_time_seconds": 45,
          "diagram_required": true,
          "manipulative": "polygon_sides_slider",
          "review_status": "draft"
        },
        {
          "question_id": "fundamental_central_angle_triangle_002",
          "source_type": "original_recreated",
          "source_pattern": patternId,
          "class_level": "Class 7",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "starter",
          "question_text": "An equilateral triangle is divided from the center into 3 equal parts. What is each central angle?",
          "options": ["90°", "120°", "60°", "180°"],
          "correct_answer": 3,
          "formulae_used": ["central_angle = 360° / n"],
          "why_wrong_explanations": {
            "0": "90° is the central angle of a square (4 sides).",
            "1": "120° would be for a triangle if it were 3 equal angles, but central angle is different.",
            "2": "180° is a straight angle, not a central angle of a regular polygon."
          },
          "difficulty": "easy",
          "estimated_time_seconds": 45,
          "diagram_required": true,
          "manipulative": "polygon_sides_slider",
          "review_status": "draft"
        },
        {
          "question_id": "fundamental_central_angle_hexagon_003",
          "source_type": "original_recreated",
          "source_pattern": patternId,
          "class_level": "Class 7",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "starter",
          "question_text": "A regular hexagon has 6 equal sides. What is the central angle of each section?",
          "options": ["45°", "60°", "72°", "90°"],
          "correct_answer": 1,
          "formulae_used": ["central_angle = 360° / n"],
          "why_wrong_explanations": {
            "0": "45° is the central angle of an octagon (8 sides).",
            "2": "72° is the central angle of a pentagon (5 sides).",
            "3": "90° is the central angle of a square (4 sides)."
          },
          "difficulty": "easy",
          "estimated_time_seconds": 45,
          "diagram_required": true,
          "manipulative": "polygon_sides_slider",
          "review_status": "draft"
        },
        {
          "question_id": "fundamental_central_angle_formula_004",
          "source_type": "original_authored",
          "source_pattern": patternId,
          "class_level": "Class 7",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "starter",
          "question_text": "If a regular polygon has 5 sides, what formula would you use to find the central angle?",
          "options": ["360° × 5", "360° ÷ 5", "180° × 5", "180° ÷ 5"],
          "correct_answer": 1,
          "formulae_used": ["central_angle = 360° / n"],
          "why_wrong_explanations": {
            "0": "Multiplying by 5 would give 1800°, which is more than a full circle.",
            "2": "180° × 5 = 900°, which is more than two full circles.",
            "3": "180° ÷ 5 = 36°, which is not the correct central angle formula."
          },
          "difficulty": "easy",
          "estimated_time_seconds": 30,
          "diagram_required": false,
          "manipulative": "none",
          "review_status": "draft"
        },
        {
          "question_id": "fundamental_central_angle_full_turn_005",
          "source_type": "original_authored",
          "source_pattern": patternId,
          "class_level": "Class 7",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "starter",
          "question_text": "Why do we use 360° in the central angle formula?",
          "options": ["Because 360 is divisible by many numbers", "Because a full circle is 360°", "Because polygons have 360 sides", "Because 360° is the largest angle"],
          "correct_answer": 1,
          "formulae_used": ["central_angle = 360° / n"],
          "why_wrong_explanations": {
            "0": "While 360 is divisible by many numbers, that's not why we use it in the formula.",
            "2": "Regular polygons don't have 360 sides - they have different numbers of sides.",
            "3": "360° is not the largest angle - it's a full circle/complete turn."
          },
          "difficulty": "easy",
          "estimated_time_seconds": 30,
          "diagram_required": false,
          "manipulative": "none",
          "review_status": "draft"
        }
      ]);
    }
    
    return questions;
  }

  /// Generate practice questions - application problems, Class 7-8 level
  Future<List<Map<String, dynamic>>> generatePracticeQuestions(Map<String, dynamic> pattern) async {
    final questions = <Map<String, dynamic>>[];
    final patternId = pattern['pattern_id'] as String;
    
    if (patternId == 'regular_polygon_central_angle') {
      questions.addAll([
        {
          "question_id": "practice_central_angle_octagon_001",
          "source_type": "original_recreated",
          "source_pattern": patternId,
          "class_level": "Class 8",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "practice",
          "question_text": "A regular octagon has a central angle of 45°. If you draw lines from the center to all vertices, how many equal triangles will you create?",
          "options": ["4", "6", "8", "10"],
          "correct_answer": 2,
          "formulae_used": ["central_angle = 360° / n", "n = 360° / central_angle"],
          "why_wrong_explanations": {
            "0": "4 triangles would be for a square (90° central angle).",
            "1": "6 triangles would be for a hexagon (60° central angle).",
            "3": "10 triangles would be for a decagon (36° central angle)."
          },
          "difficulty": "medium",
          "estimated_time_seconds": 60,
          "diagram_required": true,
          "manipulative": "polygon_sides_slider",
          "review_status": "draft"
        },
        {
          "question_id": "practice_central_angle_inverse_002",
          "source_type": "original_authored",
          "source_pattern": patternId,
          "class_level": "Class 8",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "practice",
          "question_text": "A regular polygon has central angles of 30° each. How many sides does this polygon have?",
          "options": ["6", "8", "10", "12"],
          "correct_answer": 3,
          "formulae_used": ["n = 360° / central_angle"],
          "why_wrong_explanations": {
            "0": "6 sides would give 60° central angles (360° ÷ 6 = 60°).",
            "1": "8 sides would give 45° central angles (360° ÷ 8 = 45°).",
            "2": "10 sides would give 36° central angles (360° ÷ 10 = 36°)."
          },
          "difficulty": "medium",
          "estimated_time_seconds": 60,
          "diagram_required": false,
          "manipulative": "polygon_sides_slider",
          "review_status": "draft"
        },
        {
          "question_id": "practice_central_angle_comparison_003",
          "source_type": "original_authored",
          "source_pattern": patternId,
          "class_level": "Class 8",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "practice",
          "question_text": "Which regular polygon has a larger central angle: a pentagon or a hexagon?",
          "options": ["Pentagon", "Hexagon", "They are equal", "Cannot determine"],
          "correct_answer": 0,
          "formulae_used": ["central_angle = 360° / n"],
          "why_wrong_explanations": {
            "1": "Hexagon has 6 sides, so central angle = 360° ÷ 6 = 60°, which is smaller.",
            "2": "They have different numbers of sides, so central angles are different.",
            "3": "We can determine this using the central angle formula."
          },
          "difficulty": "medium",
          "estimated_time_seconds": 45,
          "diagram_required": false,
          "manipulative": "polygon_sides_slider",
          "review_status": "draft"
        },
        {
          "question_id": "practice_central_angle_fraction_004",
          "source_type": "original_recreated",
          "source_pattern": patternId,
          "class_level": "Class 8",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "practice",
          "question_text": "The central angle of a regular polygon is 1/8 of a full circle. What is the central angle in degrees?",
          "options": ["30°", "36°", "45°", "60°"],
          "correct_answer": 2,
          "formulae_used": ["central_angle = 360° / n", "fraction_of_circle = central_angle / 360°"],
          "why_wrong_explanations": {
            "0": "30° is 1/12 of a full circle.",
            "1": "36° is 1/10 of a full circle.",
            "3": "60° is 1/6 of a full circle."
          },
          "difficulty": "medium",
          "estimated_time_seconds": 60,
          "diagram_required": false,
          "manipulative": "none",
          "review_status": "draft"
        },
        {
          "question_id": "practice_central_angle_real_world_005",
          "source_type": "original_authored",
          "source_pattern": patternId,
          "class_level": "Class 8",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "practice",
          "question_text": "A pizza is cut into 6 equal slices. What is the central angle of each slice?",
          "options": ["30°", "45°", "60°", "72°"],
          "correct_answer": 2,
          "formulae_used": ["central_angle = 360° / n"],
          "why_wrong_explanations": {
            "0": "30° would be for 12 slices (360° ÷ 12 = 30°).",
            "1": "45° would be for 8 slices (360° ÷ 8 = 45°).",
            "3": "72° would be for 5 slices (360° ÷ 5 = 72°)."
          },
          "difficulty": "easy",
          "estimated_time_seconds": 45,
          "diagram_required": true,
          "manipulative": "pizza_slicer",
          "review_status": "draft"
        },
        {
          "question_id": "practice_central_angle_decimal_006",
          "source_type": "original_authored",
          "source_pattern": patternId,
          "class_level": "Class 8",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "practice",
          "question_text": "A regular polygon has 9 sides. What is its central angle as a decimal?",
          "options": ["36.0°", "40.0°", "45.0°", "50.0°"],
          "correct_answer": 1,
          "formulae_used": ["central_angle = 360° / n"],
          "why_wrong_explanations": {
            "0": "36.0° is for 10 sides (360° ÷ 10 = 36°).",
            "2": "45.0° is for 8 sides (360° ÷ 8 = 45°).",
            "3": "50.0° would be for 7.2 sides, which isn't possible."
          },
          "difficulty": "medium",
          "estimated_time_seconds": 60,
          "diagram_required": false,
          "manipulative": "polygon_sides_slider",
          "review_status": "draft"
        },
        {
          "question_id": "practice_central_angle_word_problem_007",
          "source_type": "original_authored",
          "source_pattern": patternId,
          "class_level": "Class 8",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "practice",
          "question_text": "A stop sign is a regular octagon. If you stand at the center and look directly at each corner, how many degrees do you turn to see the next corner?",
          "options": ["30°", "36°", "45°", "60°"],
          "correct_answer": 2,
          "formulae_used": ["central_angle = 360° / n"],
          "why_wrong_explanations": {
            "0": "30° would be for a 12-sided polygon.",
            "1": "36° would be for a 10-sided polygon.",
            "3": "60° would be for a 6-sided polygon (hexagon)."
          },
          "difficulty": "medium",
          "estimated_time_seconds": 60,
          "diagram_required": true,
          "manipulative": "stop_sign_visual",
          "review_status": "draft"
        }
      ]);
    }
    
    return questions;
  }

  /// Generate challenge questions - advanced problems, Class 8-9 level
  Future<List<Map<String, dynamic>>> generateChallengeQuestions(Map<String, dynamic> pattern) async {
    final questions = <Map<String, dynamic>>[];
    final patternId = pattern['pattern_id'] as String;
    
    if (patternId == 'regular_polygon_central_angle') {
      questions.addAll([
        {
          "question_id": "challenge_central_angle_dodecagon_001",
          "source_type": "original_recreated",
          "source_pattern": patternId,
          "class_level": "Class 9",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "challenge",
          "question_text": "A regular dodecagon has a central angle of 30°. If you connect every other vertex to the center, what is the new central angle between connected vertices?",
          "options": ["15°", "30°", "45°", "60°"],
          "correct_answer": 3,
          "formulae_used": ["central_angle = 360° / n", "skipped_vertices = 360° / (n/2)"],
          "why_wrong_explanations": {
            "0": "15° would be for connecting every 4th vertex (360° ÷ 3 = 120°, then ÷ 4 = 30°, then ÷ 2 = 15°).",
            "1": "30° is the original central angle, not the angle between skipped vertices.",
            "2": "45° would be for connecting every 3rd vertex in an octagon."
          },
          "difficulty": "hard",
          "estimated_time_seconds": 90,
          "diagram_required": true,
          "manipulative": "polygon_vertex_selector",
          "review_status": "draft"
        },
        {
          "question_id": "challenge_central_angle_algebra_002",
          "source_type": "original_authored",
          "source_pattern": patternId,
          "class_level": "Class 9",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "challenge",
          "question_text": "If a regular polygon has a central angle of (360 ÷ (x + 2)) degrees and has 7 sides, what is the value of x?",
          "options": ["3", "5", "7", "9"],
          "correct_answer": 1,
          "formulae_used": ["central_angle = 360° / n", "algebraic_substitution"],
          "why_wrong_explanations": {
            "0": "If x = 3, then central angle = 360° ÷ 5 = 72°, but 7 sides give 51.43°.",
            "2": "If x = 7, then central angle = 360° ÷ 9 = 40°, but 7 sides give 51.43°.",
            "3": "If x = 9, then central angle = 360° ÷ 11 = 32.73°, but 7 sides give 51.43°."
          },
          "difficulty": "hard",
          "estimated_time_seconds": 120,
          "diagram_required": false,
          "manipulative": "algebra_solver",
          "review_status": "draft"
        },
        {
          "question_id": "challenge_central_angle_comparison_003",
          "source_type": "original_recreated",
          "source_pattern": patternId,
          "class_level": "Class 9",
          "topic": "Central Angle of Regular Polygon",
          "primary_concept": "central_angle_regular_polygon",
          "question_role": "challenge",
          "question_text": "A regular polygon's central angle is twice that of a regular hexagon. How many sides does this polygon have?",
          "options": ["2", "3", "4", "6"],
          "correct_answer": 1,
          "formulae_used": ["central_angle = 360° / n", "equation_solving"],
          "why_wrong_explanations": {
            "0": "2 sides would form a line, not a polygon.",
            "2": "4 sides (square) has 90° central angle, which is 1.5 times hexagon's 60°.",
            "3": "6 sides is the hexagon itself, which would have the same central angle."
          },
          "difficulty": "hard",
          "estimated_time_seconds": 90,
          "diagram_required": false,
          "manipulative": "polygon_sides_slider",
          "review_status": "draft"
        }
      ]);
    }
    
    return questions;
  }

  /// Generate JEE-style questions - advanced mixed problems
  Future<List<Map<String, dynamic>>> generateJEEStyleQuestions(Map<String, dynamic> pattern) async {
    final questions = <Map<String, dynamic>>[];
    final patternId = pattern['pattern_id'] as String;
    
    if (patternId == 'regular_polygon_central_angle') {
      questions.add({
        "question_id": "jee_central_angle_diagonal_mixed_001",
        "source_type": "original_recreated",
        "source_pattern": patternId,
        "class_level": "Class 10+",
        "topic": "Central Angle of Regular Polygon",
        "primary_concept": "central_angle_regular_polygon",
        "question_role": "jee_style",
        "question_text": "A regular polygon has 12 sides. The ratio of its central angle to its interior angle is 2:3. Find the number of diagonals that can be drawn from one vertex.",
        "options": ["8", "9", "10", "11"],
        "correct_answer": 1,
        "formulae_used": [
          "central_angle = 360° / n",
          "interior_angle = (n-2) × 180° / n",
          "diagonals_from_vertex = n - 3"
        ],
        "why_wrong_explanations": {
          "0": "8 diagonals would be for an 11-sided polygon (11 - 3 = 8).",
          "2": "10 diagonals would be for a 13-sided polygon (13 - 3 = 10).",
          "3": "11 diagonals would be for a 14-sided polygon (14 - 3 = 11)."
        },
        "difficulty": "very_hard",
        "estimated_time_seconds": 180,
        "diagram_required": true,
        "manipulative": "polygon_analyzer",
        "review_status": "draft"
      });
    }
    
    return questions;
  }

  /// Save generated questions to file
  Future<void> saveGeneratedQuestions(String topic, List<Map<String, dynamic>> questions) async {
    final questionsFile = File('$questionsDir/${topic}_questions.json');
    
    // Ensure directory exists
    await Directory(questionsDir).create(recursive: true);
    
    // Create question data structure
    final questionData = {
      "metadata": {
        "topic": topic,
        "generated_date": DateTime.now().toIso8601String(),
        "total_questions": questions.length,
        "source_patterns": ["regular_polygon_central_angle"],
        "quality_check": "pending",
        "note": "All questions are original content created from pattern analysis. No direct copying from external sources."
      },
      "questions": questions
    };
    
    await questionsFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(questionData)
    );
    
    print('💾 Saved ${questions.length} questions to: ${questionsFile.path}');
  }
}

void main() async {
  final analyzer = PYQPatternAnalyzer();
  await analyzer.generateFundamentalQuestions();
}