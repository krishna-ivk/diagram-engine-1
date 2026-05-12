import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/topic_mastery.dart';
import '../models/student_attempt.dart';
import 'attempt_tracker.dart';

/// Service for tracking and calculating topic mastery
class MasteryTracker {
  static const String _masteryKey = 'topic_mastery_v2';
  static SharedPreferences? _prefs;

  /// Initialize the tracker
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Calculate mastery score for a topic based on attempts
  static double calculateMasteryScore(List<StudentAttempt> attempts) {
    if (attempts.isEmpty) return 0.0;

    final correctCount = attempts.where((a) => a.isCorrect).length;
    final totalCount = attempts.length;
    
    // Basic accuracy calculation for Phase 1
    double baseScore = correctCount / totalCount;
    
    // Bonus for recent correct attempts (recency factor)
    final recentAttempts = attempts.where((a) => 
      a.attemptedAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))
    ).toList();
    
    if (recentAttempts.isNotEmpty) {
      final recentCorrect = recentAttempts.where((a) => a.isCorrect).length;
      final recentScore = recentCorrect / recentAttempts.length;
      baseScore = (baseScore * 0.7) + (recentScore * 0.3); // Weight recent performance
    }

    // Penalty for repeated misconceptions
    final misconceptions = <String, int>{};
    for (final attempt in attempts) {
      if (!attempt.isCorrect && attempt.misconceptionCode != null) {
        final code = attempt.misconceptionCode!;
        misconceptions[code] = (misconceptions[code] ?? 0) + 1;
      }
    }
    
    final repeatedMisconceptions = misconceptions.values.where((count) => count >= 3).length;
    if (repeatedMisconceptions > 0) {
      baseScore *= (1.0 - (repeatedMisconceptions * 0.1)); // 10% penalty per repeated misconception
    }

    return baseScore.clamp(0.0, 1.0);
  }

  /// Update mastery after an attempt
  static Future<void> updateMasteryAfterAttempt(StudentAttempt attempt) async {
    if (_prefs == null) await initialize();

    final topicAttempts = await AttemptTracker.getAttemptsForTopic(attempt.topicId);
    final masteryScore = calculateMasteryScore(topicAttempts);
    
    // Calculate misconception counts
    final misconceptionCounts = <String, int>{};
    for (final a in topicAttempts) {
      if (!a.isCorrect && a.misconceptionCode != null) {
        final code = a.misconceptionCode!;
        misconceptionCounts[code] = (misconceptionCounts[code] ?? 0) + 1;
      }
    }

    final topicMastery = TopicMastery(
      topicId: attempt.topicId,
      totalAttempts: topicAttempts.length,
      correctCount: topicAttempts.where((a) => a.isCorrect).length,
      masteryScore: masteryScore,
      misconceptionCounts: misconceptionCounts,
    );

    await saveTopicMastery(topicMastery);
  }

  /// Get mastery data for a topic
  static Future<TopicMastery?> getTopicMastery(String topicId) async {
    if (_prefs == null) await initialize();

    final masteryData = _prefs!.getString(_masteryKey);
    if (masteryData == null) return null;

    try {
      final Map<String, dynamic> data = json.decode(masteryData);
      final topicData = data[topicId];
      if (topicData == null) return null;

      return TopicMastery.fromJson(topicData as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error loading mastery for $topicId: $e');
      return null;
    }
  }

  /// Save mastery data for a topic
  static Future<void> saveTopicMastery(TopicMastery mastery) async {
    if (_prefs == null) await initialize();

    final masteryData = _prefs!.getString(_masteryKey) ?? '{}';
    final Map<String, dynamic> data = json.decode(masteryData);
    
    data[mastery.topicId] = mastery.toJson();
    
    await _prefs!.setString(_masteryKey, json.encode(data));
  }

  /// Get all topic mastery data
  static Future<Map<String, TopicMastery>> getAllMastery() async {
    if (_prefs == null) await initialize();

    final masteryData = _prefs!.getString(_masteryKey);
    if (masteryData == null) return {};

    try {
      final Map<String, dynamic> data = json.decode(masteryData);
      return data.map((key, value) => 
        MapEntry(key, TopicMastery.fromJson(value as Map<String, dynamic>)));
    } catch (e) {
      debugPrint('Error loading all mastery data: $e');
      return {};
    }
  }

  /// Get weak concepts for a topic
  static Future<List<String>> getWeakConcepts(String topicId) async {
    final mastery = await getTopicMastery(topicId);
    if (mastery == null) return [];

    // Concepts with 3+ misconceptions are considered weak
    return mastery.misconceptionCounts.entries
        .where((entry) => entry.value >= 3)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get repeated misconceptions across all topics
  static Future<Map<String, int>> getRepeatedMisconceptions() async {
    final allMastery = await getAllMastery();
    final allMisconceptions = <String, int>{};

    for (final mastery in allMastery.values) {
      for (final entry in mastery.misconceptionCounts.entries) {
        if (entry.value >= 3) { // Only count repeated misconceptions
          allMisconceptions[entry.key] = 
            (allMisconceptions[entry.key] ?? 0) + entry.value;
        }
      }
    }

    return allMisconceptions;
  }

  /// Get topics that need practice (mastery score < 0.8)
  static Future<List<String>> getTopicsNeedingPractice() async {
    final allMastery = await getAllMastery();
    
    return allMastery.entries
        .where((entry) => entry.value.masteryScore < 0.8)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get mastered topics (mastery score >= 0.9)
  static Future<List<String>> getMasteredTopics() async {
    final allMastery = await getAllMastery();
    
    return allMastery.entries
        .where((entry) => entry.value.masteryScore >= 0.9)
        .map((entry) => entry.key)
        .toList();
  }

  /// Reset mastery for a topic
  static Future<void> resetTopicMastery(String topicId) async {
    if (_prefs == null) await initialize();

    final masteryData = _prefs!.getString(_masteryKey);
    if (masteryData == null) return;

    final Map<String, dynamic> data = json.decode(masteryData);
    data.remove(topicId);
    
    await _prefs!.setString(_masteryKey, json.encode(data));
  }

  /// Get mastery level based on score
  static String getMasteryLevel(double score) {
    if (score >= 0.9) return 'Mastered';
    if (score >= 0.8) return 'Proficient';
    if (score >= 0.6) return 'Developing';
    if (score >= 0.3) return 'Beginner';
    return 'Not Started';
  }

  /// Get mastery level color
  static String getMasteryLevelColor(double score) {
    if (score >= 0.9) return '#4CAF50'; // Green
    if (score >= 0.8) return '#8BC34A'; // Light Green
    if (score >= 0.6) return '#FF9800'; // Orange
    if (score >= 0.3) return '#FF5722'; // Deep Orange
    return '#9E9E9E'; // Grey
  }

  /// Batch update mastery for multiple topics
  static Future<void> batchUpdateMastery(List<String> topicIds) async {
    for (final topicId in topicIds) {
      final attempts = await AttemptTracker.getAttemptsForTopic(topicId);
      if (attempts.isNotEmpty) {
        final masteryScore = calculateMasteryScore(attempts);
        
        final misconceptionCounts = <String, int>{};
        for (final attempt in attempts) {
          if (!attempt.isCorrect && attempt.misconceptionCode != null) {
            final code = attempt.misconceptionCode!;
            misconceptionCounts[code] = (misconceptionCounts[code] ?? 0) + 1;
          }
        }

        final topicMastery = TopicMastery(
          topicId: topicId,
          totalAttempts: attempts.length,
          correctCount: attempts.where((a) => a.isCorrect).length,
          masteryScore: masteryScore,
          misconceptionCounts: misconceptionCounts,
        );

        await saveTopicMastery(topicMastery);
      }
    }
  }

  /// Export mastery data for backup
  static Future<String> exportMastery() async {
    final allMastery = await getAllMastery();
    final data = allMastery.map((key, value) => MapEntry(key, value.toJson()));
    return json.encode(data);
  }

  /// Import mastery data from backup
  static Future<void> importMastery(String jsonData) async {
    try {
      final Map<String, dynamic> data = json.decode(jsonData);
      if (_prefs == null) await initialize();
      await _prefs!.setString(_masteryKey, json.encode(data));
    } catch (e) {
      debugPrint('Error importing mastery: $e');
      throw Exception('Failed to import mastery data: $e');
    }
  }
}