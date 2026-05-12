import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Topic mastery levels
enum TopicMasteryLevel {
  notStarted,
  beginner,
  developing,
  proficient,
  mastered,
}

/// Topic mastery data model
class TopicMastery {
  final String topicId;
  final TopicMasteryLevel level;
  final int totalQuestionsAttempted;
  final int correctAnswers;
  final double averageTimePerQuestion;
  final DateTime lastAttemptedAt;
  final List<String> weakQuestionIds;
  final List<String> masteredQuestionIds;

  TopicMastery({
    required this.topicId,
    required this.level,
    required this.totalQuestionsAttempted,
    required this.correctAnswers,
    required this.averageTimePerQuestion,
    required this.lastAttemptedAt,
    required this.weakQuestionIds,
    required this.masteredQuestionIds,
  });

  /// Calculate accuracy percentage
  double get accuracy {
    if (totalQuestionsAttempted == 0) return 0.0;
    return correctAnswers / totalQuestionsAttempted;
  }

  /// Check if topic needs practice
  bool get needsPractice {
    return level.index < TopicMasteryLevel.proficient.index ||
        weakQuestionIds.isNotEmpty ||
        accuracy < 0.8;
  }

  factory TopicMastery.fromJson(Map<String, dynamic> json) {
    return TopicMastery(
      topicId: json['topicId'] as String,
      level: TopicMasteryLevel.values[json['level'] as int],
      totalQuestionsAttempted: json['totalQuestionsAttempted'] as int,
      correctAnswers: json['correctAnswers'] as int,
      averageTimePerQuestion: json['averageTimePerQuestion'] as double,
      lastAttemptedAt: DateTime.parse(json['lastAttemptedAt'] as String),
      weakQuestionIds: List<String>.from(json['weakQuestionIds'] as List),
      masteredQuestionIds: List<String>.from(json['masteredQuestionIds'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topicId': topicId,
      'level': level.index,
      'totalQuestionsAttempted': totalQuestionsAttempted,
      'correctAnswers': correctAnswers,
      'averageTimePerQuestion': averageTimePerQuestion,
      'lastAttemptedAt': lastAttemptedAt.toIso8601String(),
      'weakQuestionIds': weakQuestionIds,
      'masteredQuestionIds': masteredQuestionIds,
    };
  }

  /// Create initial mastery for a new topic
  factory TopicMastery.initial(String topicId) {
    return TopicMastery(
      topicId: topicId,
      level: TopicMasteryLevel.notStarted,
      totalQuestionsAttempted: 0,
      correctAnswers: 0,
      averageTimePerQuestion: 0.0,
      lastAttemptedAt: DateTime.now(),
      weakQuestionIds: [],
      masteredQuestionIds: [],
    );
  }
}

/// Service for tracking topic mastery
class TopicMasteryTracker {
  static const String _masteryKey = 'topic_mastery_data';
  static SharedPreferences? _prefs;

  /// Initialize the tracker
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get mastery data for all topics
  static Map<String, TopicMastery> getAllMastery() {
    if (_prefs == null) return {};

    final masteryData = _prefs!.getString(_masteryKey);
    if (masteryData == null) return {};

    try {
      final Map<String, dynamic> data = json.decode(masteryData);
      return data.map((key, value) => 
        MapEntry(key, TopicMastery.fromJson(value as Map<String, dynamic>)));
    } catch (e) {
      debugPrint('Error loading mastery data: $e');
      return {};
    }
  }

  /// Get mastery data for a specific topic
  static TopicMastery? getMastery(String topicId) {
    return getAllMastery()[topicId];
  }

  /// Update mastery data after answering questions
  static Future<void> updateMastery({
    required String topicId,
    required List<QuestionAttempt> attempts,
  }) async {
    if (_prefs == null) await initialize();

    final allMastery = getAllMastery();
    final currentMastery = allMastery[topicId] ?? TopicMastery.initial(topicId);

    // Calculate new mastery metrics
    final totalAttempted = currentMastery.totalQuestionsAttempted + attempts.length;
    final correctAnswers = currentMastery.correctAnswers + 
        attempts.where((a) => a.isCorrect).length;
    
    // Calculate average time per question
    final totalTime = attempts.fold<double>(0, (sum, attempt) => 
        sum + attempt.timeTaken.inSeconds.toDouble());
    final newAverageTime = totalTime / totalAttempted;

    // Update weak and mastered question lists
    final weakQuestions = <String>[];
    final masteredQuestions = <String>[...currentMastery.masteredQuestionIds];

    for (final attempt in attempts) {
      if (attempt.isCorrect && !masteredQuestions.contains(attempt.questionId)) {
        masteredQuestions.add(attempt.questionId);
      } else if (!attempt.isCorrect && !weakQuestions.contains(attempt.questionId)) {
        weakQuestions.add(attempt.questionId);
      }
    }

    // Determine mastery level based on performance
    final accuracy = correctAnswers / totalAttempted;
    final newLevel = _calculateMasteryLevel(
      accuracy: accuracy,
      totalQuestions: totalAttempted,
      averageTime: newAverageTime,
      weakQuestionsCount: weakQuestions.length,
    );

    // Create updated mastery
    final updatedMastery = TopicMastery(
      topicId: topicId,
      level: newLevel,
      totalQuestionsAttempted: totalAttempted,
      correctAnswers: correctAnswers,
      averageTimePerQuestion: newAverageTime,
      lastAttemptedAt: DateTime.now(),
      weakQuestionIds: weakQuestions,
      masteredQuestionIds: masteredQuestions,
    );

    // Save updated data
    allMastery[topicId] = updatedMastery;
    await _saveMasteryData(allMastery);
  }

  /// Calculate mastery level based on metrics
  static TopicMasteryLevel _calculateMasteryLevel({
    required double accuracy,
    required int totalQuestions,
    required double averageTime,
    required int weakQuestionsCount,
  }) {
    // High performance: >90% accuracy, good time, few weak questions
    if (accuracy >= 0.9 && 
        weakQuestionsCount <= 2 && 
        totalQuestions >= 10) {
      return TopicMasteryLevel.mastered;
    }

    // Good performance: >80% accuracy, reasonable time
    if (accuracy >= 0.8 && 
        weakQuestionsCount <= 5 && 
        totalQuestions >= 6) {
      return TopicMasteryLevel.proficient;
    }

    // Developing: >60% accuracy
    if (accuracy >= 0.6 && totalQuestions >= 3) {
      return TopicMasteryLevel.developing;
    }

    // Beginner: Some attempts made
    if (totalQuestions >= 1) {
      return TopicMasteryLevel.beginner;
    }

    return TopicMasteryLevel.notStarted;
  }

  /// Save mastery data to preferences
  static Future<void> _saveMasteryData(Map<String, TopicMastery> mastery) async {
    if (_prefs == null) return;

    final data = mastery.map((key, value) => MapEntry(key, value.toJson()));
    await _prefs!.setString(_masteryKey, json.encode(data));
  }

  /// Get topics that need practice
  static List<String> getTopicsNeedingPractice() {
    return getAllMastery()
        .entries
        .where((entry) => entry.value.needsPractice)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get mastered topics
  static List<String> getMasteredTopics() {
    return getAllMastery()
        .entries
        .where((entry) => entry.value.level == TopicMasteryLevel.mastered)
        .map((entry) => entry.key)
        .toList();
  }

  /// Reset mastery for a topic
  static Future<void> resetTopicMastery(String topicId) async {
    if (_prefs == null) await initialize();

    final allMastery = getAllMastery();
    allMastery[topicId] = TopicMastery.initial(topicId);
    await _saveMasteryData(allMastery);
  }

  /// Get progress summary for a topic
  static Map<String, dynamic> getProgressSummary(String topicId) {
    final mastery = getMastery(topicId);
    if (mastery == null) {
      return {
        'level': 'Not Started',
        'accuracy': 0.0,
        'questionsAttempted': 0,
        'needsPractice': true,
      };
    }

    return {
      'level': mastery.level.name,
      'accuracy': mastery.accuracy,
      'questionsAttempted': mastery.totalQuestionsAttempted,
      'averageTime': mastery.averageTimePerQuestion,
      'needsPractice': mastery.needsPractice,
      'weakQuestionsCount': mastery.weakQuestionIds.length,
      'masteredQuestionsCount': mastery.masteredQuestionIds.length,
    };
  }
}

/// Question attempt data model
class QuestionAttempt {
  final String questionId;
  final bool isCorrect;
  final Duration timeTaken;
  final DateTime attemptedAt;
  final int? selectedOption;
  final String? difficulty;

  QuestionAttempt({
    required this.questionId,
    required this.isCorrect,
    required this.timeTaken,
    required this.attemptedAt,
    this.selectedOption,
    this.difficulty,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'isCorrect': isCorrect,
      'timeTaken': timeTaken.inSeconds,
      'attemptedAt': attemptedAt.toIso8601String(),
      'selectedOption': selectedOption,
      'difficulty': difficulty,
    };
  }

  factory QuestionAttempt.fromJson(Map<String, dynamic> json) {
    return QuestionAttempt(
      questionId: json['questionId'] as String,
      isCorrect: json['isCorrect'] as bool,
      timeTaken: Duration(seconds: json['timeTaken'] as int),
      attemptedAt: DateTime.parse(json['attemptedAt'] as String),
      selectedOption: json['selectedOption'] as int?,
      difficulty: json['difficulty'] as String?,
    );
  }
}