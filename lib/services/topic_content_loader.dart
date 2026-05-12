import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/question_data.dart';
import '../models/diagram_data.dart';
import 'content_loader.dart';

/// Service for loading topic capsule content and questions
class TopicContentLoader {
  /// Load a topic capsule from JSON file
  static Future<TopicCapsule> loadTopicCapsule(String topicId) async {
    try {
      final String jsonString = await rootBundle
          .loadString('content/topics/${_extractTopicFileName(topicId)}.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      return TopicCapsule.fromJson(data);
    } catch (e) {
      debugPrint('Error loading topic capsule $topicId: $e');
      // Return fallback topic capsule
      return _createFallbackTopicCapsule(topicId);
    }
  }

  /// Load questions by their IDs from the journey questions file
  static Future<List<QuestionData>> loadQuestionsByIds(List<String> questionIds) async {
    try {
      // Load the geometry foundation journey questions which contains our question IDs
      final String jsonString = await rootBundle
          .loadString('content/journeys/geometry_foundation_journey_questions.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      final questionsMap = data['questions'] as Map<String, dynamic>?;
      if (questionsMap == null) return [];

      final List<QuestionData> questions = [];
      
      for (final questionId in questionIds) {
        if (questionsMap.containsKey(questionId)) {
          try {
            final questionData = ContentLoader._convertJourneyQuestion(
              questionsMap[questionId] as Map<String, dynamic>
            );
            questions.add(questionData);
          } catch (e) {
            debugPrint('Error loading question $questionId: $e');
            // Create a fallback question
            questions.add(_createFallbackQuestion(questionId));
          }
        } else {
          debugPrint('Question ID $questionId not found in content');
          // Create a fallback question
          questions.add(_createFallbackQuestion(questionId));
        }
      }
      
      return questions;
    } catch (e) {
      debugPrint('Error loading questions by IDs: $e');
      // Return fallback questions for each requested ID
      return questionIds.map(_createFallbackQuestion).toList();
    }
  }

  /// Extract topic file name from topic ID
  static String _extractTopicFileName(String topicId) {
    // Convert "math.geometry.central_angle_regular_polygon" 
    // to "central_angle_regular_polygon"
    final parts = topicId.split('.');
    return parts.isNotEmpty ? parts.last : topicId;
  }

  /// Create a fallback topic capsule for when content loading fails
  static TopicCapsule _createFallbackTopicCapsule(String topicId) {
    return TopicCapsule(
      topicId: topicId,
      title: 'Central Angle of a Regular Polygon',
      classLevel: 'Class 7-8',
      targetExamBridge: 'JEE Foundation',
      synopsisCards: [
        SynopsisCard(
          title: 'What is a central angle?',
          body: 'A full turn around a point is 360°. In a regular polygon, all central angles are equal.',
        ),
        SynopsisCard(
          title: 'Formula',
          body: 'Central angle = 360° ÷ number of sides',
        ),
      ],
      formulae: ['Central angle = 360° / n'],
      commonMistakes: [
        'Confusing central angle with interior angle',
        'Dividing by the wrong number of sides',
      ],
      starterQuestionIds: ['demo_001', 'demo_002'],
      practiceQuestionIds: ['demo_003', 'demo_004'],
      challengeQuestionIds: ['demo_005'],
      revisionQuestionIds: ['demo_006'],
      manipulatives: ['polygon_sides_slider'],
      estimatedDurationMinutes: 20,
    );
  }

  /// Create a fallback question for when content loading fails
  static QuestionData _createFallbackQuestion(String questionId) {
    final questionText = _getFallbackQuestionText(questionId);
    final correctAnswer = _getFallbackCorrectAnswer(questionId);
    
    return QuestionData(
      id: questionId,
      text: questionText,
      diagram: DiagramData(
        id: questionId,
        type: DiagramType.geometry,
        title: 'Central Angle Question',
        elements: [],
      ),
      options: ['45°', '60°', '90°', '120°'],
      correctIndex: correctAnswer,
      explanation: 'The central angle of a regular polygon is 360° divided by the number of sides.',
      subject: 'Mathematics',
      chapter: 'Geometry',
      topic: 'Central Angles',
      primaryConcept: 'central_angle',
      difficulty: Difficulty.medium,
      estimatedSeconds: 60,
      solutionSteps: [
        'Identify the number of sides',
        'Apply the formula: 360° ÷ n',
        'Calculate the result',
      ],
      whyWrongExplanations: {
        0: 'This would be correct for an octagon (8 sides).',
        1: 'This would be correct for a hexagon (6 sides).',
        3: 'This would be correct for a triangle (3 sides).',
      },
    );
  }

  /// Get fallback question text based on question ID
  static String _getFallbackQuestionText(String questionId) {
    if (questionId.contains('square')) {
      return 'A square is divided from its center into 4 equal triangles. What is the measure of each central angle?';
    } else if (questionId.contains('hexagon')) {
      return 'A regular hexagon has 6 equal sides. What is the measure of each central angle?';
    } else if (questionId.contains('octagon')) {
      return 'A regular octagon has 8 equal sides. What is the measure of each central angle?';
    } else {
      return 'A regular polygon has equal sides and angles. If it has 4 sides, what is the measure of each central angle?';
    }
  }

  /// Get fallback correct answer based on question ID
  static int _getFallbackCorrectAnswer(String questionId) {
    if (questionId.contains('square')) {
      return 2; // 90°
    } else if (questionId.contains('hexagon')) {
      return 1; // 60°
    } else if (questionId.contains('octagon')) {
      return 0; // 45°
    } else {
      return 2; // 90° (square)
    }
  }
}

/// Topic Capsule model
class TopicCapsule {
  final String topicId;
  final String title;
  final String classLevel;
  final String targetExamBridge;
  final List<SynopsisCard> synopsisCards;
  final List<String> formulae;
  final List<String> commonMistakes;
  final List<String> starterQuestionIds;
  final List<String> practiceQuestionIds;
  final List<String> challengeQuestionIds;
  final List<String> revisionQuestionIds;
  final List<String> manipulatives;
  final int estimatedDurationMinutes;

  TopicCapsule({
    required this.topicId,
    required this.title,
    required this.classLevel,
    required this.targetExamBridge,
    required this.synopsisCards,
    required this.formulae,
    required this.commonMistakes,
    required this.starterQuestionIds,
    required this.practiceQuestionIds,
    required this.challengeQuestionIds,
    required this.revisionQuestionIds,
    required this.manipulatives,
    required this.estimatedDurationMinutes,
  });

  factory TopicCapsule.fromJson(Map<String, dynamic> json) {
    return TopicCapsule(
      topicId: json['topic_id'] as String,
      title: json['title'] as String,
      classLevel: json['class_level'] as String,
      targetExamBridge: json['target_exam_bridge'] as String,
      synopsisCards: (json['synopsis_cards'] as List<dynamic>)
          .map((e) => SynopsisCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      formulae: (json['formulae'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      commonMistakes: (json['common_mistakes'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      starterQuestionIds: (json['starter_question_ids'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      practiceQuestionIds: (json['practice_question_ids'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      challengeQuestionIds: (json['challenge_question_ids'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      revisionQuestionIds: (json['revision_question_ids'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      manipulatives: (json['manipulatives'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int,
    );
  }
}

/// Synopsis Card model
class SynopsisCard {
  final String title;
  final String body;

  SynopsisCard({
    required this.title,
    required this.body,
  });

  factory SynopsisCard.fromJson(Map<String, dynamic> json) {
    return SynopsisCard(
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}