import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/question_data.dart';
import '../models/diagram_data.dart';

/// Service for loading topic-specific content and questions
class TopicContentLoader {
  static const String _contentBasePath = 'content/questions';

  /// Load topic capsule containing all topic information
  static Future<Map<String, dynamic>?> loadTopicCapsule(String topicId) async {
    try {
      final String content = await rootBundle
          .loadString('content/topics/${topicId}_capsule.json');
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading topic capsule for $topicId: $e');
      return null;
    }
  }

  /// Load questions by their IDs
  static Future<Map<String, QuestionData>> loadQuestionsByIds(
      List<String> questionIds) async {
    try {
      // First load the question manifest
      final manifest = await _loadQuestionManifest();
      if (manifest == null) return {};

      final Map<String, QuestionData> questions = {};
      
      // Load each question file listed in the manifest
      for (final fileName in manifest['files'] as List<dynamic>) {
        final fileContent = await rootBundle
            .loadString('$_contentBasePath/$fileName');
        final List<dynamic> questionsList = json.decode(fileContent);
        
        // Convert each question to QuestionData
        for (final questionData in questionsList) {
          try {
            final question = _convertNewQuestionFormat(questionData);
            if (questionIds.contains(question.id)) {
              questions[question.id] = question;
            }
          } catch (e) {
            debugPrint('Error loading question from $fileName: $e');
          }
        }
      }

      return questions;
    } catch (e) {
      debugPrint('Error loading questions by IDs: $e');
      return {};
    }
  }

  /// Load question manifest file
  static Future<Map<String, dynamic>?> _loadQuestionManifest() async {
    try {
      final String content = await rootBundle
          .loadString('$_contentBasePath/question_manifest.json');
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading question manifest: $e');
      return null;
    }
  }

  /// Convert new question format to QuestionData
  static QuestionData _convertNewQuestionFormat(Map<String, dynamic> json) {
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
      exam: _mapExamType(json['exam_type']),
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

  /// Map exam type from string to enum
  static ExamType _mapExamType(String? examTypeStr) {
    switch (examTypeStr) {
      case 'jee_main':
        return ExamType.jeeMain;
      case 'jee_advanced':
        return ExamType.jeeAdvanced;
      case 'board':
        return ExamType.board;
      case 'foundation':
        return ExamType.foundation;
      default:
        return ExamType.jeeMain;
    }
  }
}