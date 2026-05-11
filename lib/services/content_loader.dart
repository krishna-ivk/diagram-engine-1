import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/question_data.dart';
import '../models/rescue_system.dart';

/// Service for loading curated content from JSON files
class ContentLoader {
  static const String _contentBasePath = 'content/sample_questions';
  
  /// Load geometry rescue ladder from JSON file
  static Future<List<QuestionData>> loadGeometryRescueLadder() async {
    try {
      // Load the rescue ladder JSON file
      final String ladderContent = await rootBundle.loadString('$_contentBasePath/geometry_regular_polygon_ladder.json');
      final Map<String, dynamic> ladderData = json.decode(ladderContent);
      
      final List<QuestionData> questions = [];
      
      // Extract questions from the ladder
      if (ladderData.containsKey('questions')) {
        final List<dynamic> questionsList = ladderData['questions'];
        for (final questionData in questionsList) {
          try {
            // Convert JSON to QuestionData - this would need proper mapping
            final question = _convertToQuestionData(questionData);
            questions.add(question);
          } catch (e) {
            print('Error loading question: $e');
          }
        }
      }
      
      return questions;
    } catch (e) {
      print('Error loading geometry rescue ladder: $e');
      return [];
    }
  }
  
  /// Convert JSON data to QuestionData (simplified version)
  static QuestionData _convertToQuestionData(Map<String, dynamic> json) {
    // This is a simplified conversion - in a real implementation,
    // you would need to properly map all fields from your content schema
    return QuestionData(
      id: json['question_id'] ?? '',
      questionText: json['question_text'] ?? '',
      options: _convertOptions(json['options']),
      correctAnswer: json['correct_answer']?.toString() ?? '',
      primaryConcept: json['primary_concept'] ?? '',
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      solutionSteps: _convertSolutionSteps(json['solution_steps']),
      whyWrongExplanations: Map<String, String>.from(json['why_wrong_explanations'] ?? {}),
      rescueLadderIds: List<String>.from(json['rescue_question_ids'] ?? []),
      diagramRequired: json['diagram_required'] ?? false,
      diagramId: json['diagram_id'],
      difficulty: _mapDifficulty(json['difficulty']),
      estimatedTime: json['expected_time_seconds'] ?? 120,
      questionRole: _mapQuestionRole(json['bridge_level']),
      learningObjectiveScore: 85.0, // Default score
      reviewStatus: json['review_status'] ?? 'draft',
    );
  }
  
  /// Convert options from JSON
  static List<QuestionOption> _convertOptions(dynamic optionsData) {
    if (optionsData is List) {
      return (optionsData as List).map((opt) {
        final Map<String, dynamic> option = opt as Map<String, dynamic>;
        return QuestionOption(
          id: option['label'] ?? '',
          text: option['text'] ?? '',
          isCorrect: option['isCorrect'] ?? false,
        );
      }).toList();
    }
    return [];
  }
  
  /// Convert solution steps from JSON
  static List<SolutionStep> _convertSolutionSteps(dynamic stepsData) {
    if (stepsData is List) {
      return (stepsData as List).map((step) {
        final Map<String, dynamic> stepData = step as Map<String, dynamic>;
        return SolutionStep(
          stepNumber: stepData['step_number'] ?? 1,
          description: stepData['description'] ?? '',
          calculation: stepData['calculation'] ?? '',
        );
      }).toList();
    }
    return [];
  }
  
  /// Map difficulty from string to enum
  static Difficulty _mapDifficulty(String? difficultyStr) {
    switch (difficultyStr) {
      case 'easy':
        return Difficulty.foundation;
      case 'medium':
        return Difficulty.bridge;
      case 'hard':
        return Difficulty.jeePattern;
      default:
        return Difficulty.foundation;
    }
  }
  
  /// Map question role from string to enum
  static QuestionRole _mapQuestionRole(String? roleStr) {
    switch (roleStr) {
      case 'foundation':
        return QuestionRole.foundation;
      case 'school':
        return QuestionRole.bridge;
      case 'jee':
        return QuestionRole.mockExam;
      default:
        return QuestionRole.foundation;
    }
  }
  
  /// Load JEE question and merge with rescue ladder
  static Future<List<QuestionData>> loadJEEWithRescueLadder() async {
    // First load the main JEE question
    final jeeQuestion = await _loadSingleJEEQuestion();
    
    // Then load the rescue ladder
    final rescueQuestions = await loadGeometryRescueLadder();
    
    // Combine them
    final allQuestions = <QuestionData>[];
    if (jeeQuestion != null) {
      allQuestions.add(jeeQuestion);
    }
    allQuestions.addAll(rescueQuestions);
    
    return allQuestions;
  }
  
  /// Load a single JEE question
  static Future<QuestionData?> _loadSingleJEEQuestion() async {
    try {
      final String questionContent = await rootBundle.loadString('$_contentBasePath/jee_math_regular_polygon_2023_session_1_Q12.json');
      final Map<String, dynamic> questionData = json.decode(questionContent);
      
      return _convertToQuestionData(questionData);
    } catch (e) {
      print('Error loading JEE question: $e');
      return null;
    }
  }
  
  /// Create a mock rescue question for testing
  static QuestionData createMockRescueQuestion({
    required String id,
    required String text,
    required String primaryConcept,
    required String correctAnswer,
    List<String> prerequisites = const [],
    String difficulty = 'easy',
    String questionRole = 'foundation',
  }) {
    return QuestionData(
      id: id,
      questionText: text,
      options: [
        QuestionOption(id: 'A', text: 'Option A', isCorrect: false),
        QuestionOption(id: 'B', text: 'Option B', isCorrect: true),
        QuestionOption(id: 'C', text: 'Option C', isCorrect: false),
        QuestionOption(id: 'D', text: 'Option D', isCorrect: false),
      ],
      correctAnswer: correctAnswer,
      primaryConcept: primaryConcept,
      prerequisites: prerequisites,
      solutionSteps: [
        SolutionStep(
          stepNumber: 1,
          description: 'Solution step 1',
          calculation: 'Calculation 1',
        ),
        SolutionStep(
          stepNumber: 2,
          description: 'Solution step 2',
          calculation: 'Calculation 2',
        ),
      ],
      whyWrongExplanations: {
        'A': 'This option is incorrect.',
        'C': 'This option is incorrect.',
        'D': 'This option is incorrect.',
      },
      rescueLadderIds: [],
      diagramRequired: false,
      difficulty: _mapDifficulty(difficulty),
      estimatedTime: 60,
      questionRole: _mapQuestionRole(questionRole),
      learningObjectiveScore: 85.0,
      reviewStatus: 'published',
    );
  }
}