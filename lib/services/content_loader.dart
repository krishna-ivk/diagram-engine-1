import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/question_data.dart';
import '../models/diagram_data.dart';

/// Service for loading curated content from JSON files
class ContentLoader {
  static const String _contentBasePath = 'content/sample_questions';

  /// Load geometry rescue ladder from JSON file
  static Future<List<QuestionData>> loadGeometryRescueLadder() async {
    try {
      // Load the rescue ladder JSON file
      final String ladderContent = await rootBundle
          .loadString('$_contentBasePath/geometry_regular_polygon_ladder.json');
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
            debugPrint('Error loading question: $e');
          }
        }
      }

      return questions;
    } catch (e) {
      debugPrint('Error loading geometry rescue ladder: $e');
      return [];
    }
  }

  /// Convert JSON data to QuestionData (simplified version)
  static QuestionData _convertToQuestionData(Map<String, dynamic> json) {
    // Parse correct answer as index
    final correctAns = json['correct_answer'];
    int correctIdx = 0;
    if (correctAns is int) {
      correctIdx = correctAns;
    } else if (correctAns is String) {
      correctIdx = correctAns.codeUnitAt(0) - 65; // 'A' -> 0, 'B' -> 1, etc.
    }

    // Parse why wrong explanations - need Map<int, String>
    final whyWrongRaw = json['why_wrong_explanations'];
    final whyWrongMap = <int, String>{};
    if (whyWrongRaw is Map) {
      for (final entry in whyWrongRaw.entries) {
        final key = entry.key;
        final value = entry.value;
        final k = key is int ? key : (key.toString().codeUnitAt(0) - 65);
        whyWrongMap[k] = value.toString();
      }
    }

    // Parse solution steps as List<String>
    final stepsRaw = json['solution_steps'];
    List<String> solSteps = [];
    if (stepsRaw is List) {
      solSteps = stepsRaw
          .map((s) => s['description']?.toString() ?? s.toString())
          .toList();
    }

    // Parse options as List<String>
    final opts = _convertOptions(json['options']);

    return QuestionData(
      id: json['question_id'] ?? json['id'] ?? '',
      text: json['question_text'] ?? json['text'] ?? '',
      diagram: DiagramData(
        id: json['question_id'] ?? json['id'] ?? 'default',
        type: DiagramType.geometry,
        elements: [],
      ),
      options: opts.isNotEmpty ? opts : ['A', 'B', 'C', 'D'],
      correctIndex: correctIdx.clamp(0, 3),
      explanation: json['explanation'] ?? '',
      subject: json['subject'] ?? 'Mathematics',
      chapter: json['chapter'] ?? '',
      topic: json['topic'] ?? '',
      primaryConcept: json['primary_concept'] ?? '',
      secondaryConcepts: List<String>.from(json['secondary_concepts'] ?? []),
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      exam: ExamType.jeeMain,
      classLevel: json['class_level'] ?? '11',
      questionType: QuestionType.mcq,
      difficulty: _mapDifficulty(json['difficulty']),
      estimatedSeconds: json['expected_time_seconds'] ?? 120,
      revealSteps: _convertSolutionSteps(json['solution_steps']),
      solutionSteps: solSteps,
      whyWrongExplanations: whyWrongMap,
      frequentlyAsked: json['frequently_asked'] ?? false,
      highWeightTopic: json['high_weight'] ?? false,
      coreConcept: json['core_concept'] ?? json['primary_concept'],
      similarQuestionIds: List<String>.from(json['similar_questions'] ?? []),
    );
  }

  /// Convert options from JSON - returns List<String>
  static List<String> _convertOptions(dynamic optionsData) {
    if (optionsData is List) {
      return optionsData.map((opt) {
        if (opt is String) return opt;
        if (opt is Map) return opt['text']?.toString() ?? '';
        return opt.toString();
      }).toList();
    }
    return [];
  }

  /// Convert solution steps from JSON - returns List<RevealStep>
  static List<RevealStep> _convertSolutionSteps(dynamic stepsData) {
    if (stepsData is List) {
      return stepsData.map((step) {
        final Map<String, dynamic> stepData =
            step is Map ? Map<String, dynamic>.from(step) : <String, dynamic>{};
        return RevealStep(
          text: stepData['description']?.toString() ??
              stepData['calculation']?.toString() ??
              '',
        );
      }).toList();
    }
    return [];
  }

  /// Map difficulty from string to enum
  static Difficulty _mapDifficulty(String? difficultyStr) {
    switch (difficultyStr) {
      case 'easy':
      case 'foundation':
        return Difficulty.easy;
      case 'medium':
      case 'bridge':
        return Difficulty.medium;
      case 'hard':
      case 'jee':
        return Difficulty.hard;
      default:
        return Difficulty.medium;
    }
  }

  /// Load questions for a Foundation Journey by question IDs
  static Future<Map<String, QuestionData>> loadJourneyQuestions(
      String journeyId) async {
    try {
      final String jsonString = await rootBundle
          .loadString('content/journeys/${journeyId}_questions.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      final Map<String, QuestionData> questions = {};
      final questionsMap = data['questions'] as Map<String, dynamic>?;
      if (questionsMap != null) {
        for (final entry in questionsMap.entries) {
          try {
            questions[entry.key] =
                _convertJourneyQuestion(entry.value as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Error loading journey question ${entry.key}: $e');
          }
        }
      }

      return questions;
    } catch (e) {
      debugPrint('Error loading journey questions for $journeyId: $e');
      return {};
    }
  }

  /// Convert a journey question JSON entry to QuestionData
  static QuestionData convertJourneyQuestion(Map<String, dynamic> json) {
    final correctAnswer = json['correct_answer'];
    final int correctIdx = correctAnswer is int ? correctAnswer : 0;

    final whyWrongRaw = json['why_wrong_explanations'];
    final whyWrongMap = <int, String>{};
    if (whyWrongRaw is Map) {
      for (final entry in whyWrongRaw.entries) {
        final k = int.tryParse(entry.key.toString()) ?? 0;
        whyWrongMap[k] = entry.value.toString();
      }
    }

    final opts = _convertOptions(json['options']);

    return QuestionData(
      id: json['question_id'] ?? '',
      text: json['question_text'] ?? '',
      diagram: DiagramData(
        id: json['diagram_id'] ?? json['question_id'] ?? 'default',
        type: DiagramType.geometry,
        title: json['topic'] ?? '',
        elements: const [],
      ),
      options: opts.isNotEmpty ? opts : ['A', 'B', 'C', 'D'],
      correctIndex: correctIdx.clamp(0, 3),
      explanation: json['explanation'] ?? '',
      subject: json['subject'] ?? 'Mathematics',
      chapter: json['chapter'] ?? '',
      topic: json['topic'] ?? '',
      primaryConcept: json['primary_concept'] ?? '',
      secondaryConcepts: List<String>.from(json['secondary_concepts'] ?? []),
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      difficulty: _mapDifficulty(json['difficulty']),
      estimatedSeconds: json['expected_time_seconds'] ?? 120,
      revealSteps: _convertSolutionSteps(json['solution_steps']),
      solutionSteps: (json['solution_steps'] as List?)
              ?.map((s) =>
                  (s as Map)['description']?.toString() ?? s.toString())
              .toList() ??
          [],
      whyWrongExplanations: whyWrongMap,
      coreConcept: json['primary_concept'],
    );
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
      final String questionContent = await rootBundle.loadString(
          '$_contentBasePath/jee_math_regular_polygon_2023_session_1_Q12.json');
      final Map<String, dynamic> questionData = json.decode(questionContent);

      return _convertToQuestionData(questionData);
    } catch (e) {
      debugPrint('Error loading JEE question: $e');
      return null;
    }
  }

  /// Create a mock rescue question for testing
  static QuestionData createMockRescueQuestion({
    required String id,
    required String text,
    required String primaryConcept,
    required int correctIndex,
    List<String> prerequisites = const [],
    String difficulty = 'easy',
  }) {
    return QuestionData(
      id: id,
      text: text,
      diagram: DiagramData(
        id: id,
        type: DiagramType.geometry,
        elements: [],
      ),
      options: ['Option A', 'Option B', 'Option C', 'Option D'],
      correctIndex: correctIndex,
      explanation: 'This is the correct answer.',
      subject: 'Mathematics',
      chapter: 'Geometry',
      topic: 'Regular Polygons',
      primaryConcept: primaryConcept,
      secondaryConcepts: [],
      prerequisites: prerequisites,
      exam: ExamType.jeeMain,
      classLevel: '11',
      questionType: QuestionType.mcq,
      difficulty: _mapDifficulty(difficulty),
      estimatedSeconds: 60,
      revealSteps: [
        RevealStep(text: 'Step 1: Understand the problem'),
        RevealStep(text: 'Step 2: Apply the formula'),
      ],
      solutionSteps: ['Step 1 explanation', 'Step 2 explanation'],
      whyWrongExplanations: {
        0: 'Option A is incorrect because...',
        2: 'Option C is incorrect because...',
        3: 'Option D is incorrect because...',
      },
      frequentlyAsked: false,
      highWeightTopic: false,
      coreConcept: primaryConcept,
      similarQuestionIds: [],
    );
  }
}
