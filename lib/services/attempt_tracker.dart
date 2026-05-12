import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_attempt.dart';

/// Service for tracking student attempts locally
class AttemptTracker {
  static const String _attemptsKey = 'student_attempts';
  static SharedPreferences? _prefs;

  /// Initialize the tracker
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Record a new attempt
  static Future<void> recordAttempt(StudentAttempt attempt) async {
    if (_prefs == null) await initialize();

    final attempts = await getAllAttempts();
    attempts.add(attempt);
    
    // Keep only last 1000 attempts to prevent storage bloat
    if (attempts.length > 1000) {
      attempts.removeRange(0, attempts.length - 1000);
    }

    await _saveAttempts(attempts);
  }

  /// Get all attempts
  static Future<List<StudentAttempt>> getAllAttempts() async {
    if (_prefs == null) await initialize();

    final attemptsData = _prefs!.getString(_attemptsKey);
    if (attemptsData == null) return [];

    try {
      final List<dynamic> data = json.decode(attemptsData);
      return data.map((json) => StudentAttempt.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading attempts: $e');
      return [];
    }
  }

  /// Get attempts for a specific topic
  static Future<List<StudentAttempt>> getAttemptsForTopic(String topicId) async {
    final allAttempts = await getAllAttempts();
    return allAttempts.where((attempt) => attempt.topicId == topicId).toList();
  }

  /// Get attempts for a specific question
  static Future<List<StudentAttempt>> getAttemptsForQuestion(String questionId) async {
    final allAttempts = await getAllAttempts();
    return allAttempts.where((attempt) => attempt.questionId == questionId).toList();
  }

  /// Get recent attempts (last N)
  static Future<List<StudentAttempt>> getRecentAttempts(int count) async {
    final allAttempts = await getAllAttempts();
    
    // Sort by attemptedAt descending
    allAttempts.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
    
    return allAttempts.take(count).toList();
  }

  /// Get attempts in the last N days
  static Future<List<StudentAttempt>> getAttemptsInLastDays(int days) async {
    final allAttempts = await getAllAttempts();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    return allAttempts.where((attempt) => attempt.attemptedAt.isAfter(cutoffDate)).toList();
  }

  /// Get misconceptions for a topic
  static Future<Map<String, int>> getMisconceptionsForTopic(String topicId) async {
    final topicAttempts = await getAttemptsForTopic(topicId);
    final misconceptions = <String, int>{};

    for (final attempt in topicAttempts) {
      if (!attempt.isCorrect && attempt.misconceptionCode != null) {
        final code = attempt.misconceptionCode!;
        misconceptions[code] = (misconceptions[code] ?? 0) + 1;
      }
    }

    return misconceptions;
  }

  /// Get repeated misconceptions (appearing 3+ times)
  static Future<Map<String, int>> getRepeatedMisconceptions() async {
    final allAttempts = await getAllAttempts();
    final misconceptionCounts = <String, int>{};

    for (final attempt in allAttempts) {
      if (!attempt.isCorrect && attempt.misconceptionCode != null) {
        final code = attempt.misconceptionCode!;
        misconceptionCounts[code] = (misconceptionCounts[code] ?? 0) + 1;
      }
    }

    // Filter for repeated misconceptions (3+ occurrences)
    return misconceptionCounts.map((key, value) => MapEntry(key, value))
      ..removeWhere((key, value) => value < 3);
  }

  /// Clear all attempts
  static Future<void> clearAllAttempts() async {
    if (_prefs == null) await initialize();
    await _prefs!.remove(_attemptsKey);
  }

  /// Clear attempts for a specific topic
  static Future<void> clearTopicAttempts(String topicId) async {
    final allAttempts = await getAllAttempts();
    final filteredAttempts = allAttempts.where((attempt) => attempt.topicId != topicId).toList();
    await _saveAttempts(filteredAttempts);
  }

  /// Get attempt statistics for a topic
  static Future<Map<String, dynamic>> getTopicStats(String topicId) async {
    final topicAttempts = await getAttemptsForTopic(topicId);
    
    if (topicAttempts.isEmpty) {
      return {
        'totalAttempts': 0,
        'correctCount': 0,
        'accuracy': 0.0,
        'averageTime': 0.0,
        'misconceptionCounts': <String, int>{},
      };
    }

    final correctCount = topicAttempts.where((a) => a.isCorrect).length;
    final totalTime = topicAttempts.fold<int>(0, (sum, attempt) => sum + attempt.timeTakenSeconds);
    final misconceptionCounts = <String, int>{};

    for (final attempt in topicAttempts) {
      if (!attempt.isCorrect && attempt.misconceptionCode != null) {
        final code = attempt.misconceptionCode!;
        misconceptionCounts[code] = (misconceptionCounts[code] ?? 0) + 1;
      }
    }

    return {
      'totalAttempts': topicAttempts.length,
      'correctCount': correctCount,
      'accuracy': correctCount / topicAttempts.length,
      'averageTime': totalTime / topicAttempts.length,
      'misconceptionCounts': misconceptionCounts,
    };
  }

  /// Save attempts to preferences
  static Future<void> _saveAttempts(List<StudentAttempt> attempts) async {
    if (_prefs == null) return;

    final data = attempts.map((attempt) => attempt.toJson()).toList();
    await _prefs!.setString(_attemptsKey, json.encode(data));
  }

  /// Export attempts for backup/sync
  static Future<String> exportAttempts() async {
    final attempts = await getAllAttempts();
    return json.encode(attempts.map((a) => a.toJson()).toList());
  }

  /// Import attempts from backup
  static Future<void> importAttempts(String jsonData) async {
    try {
      final List<dynamic> data = json.decode(jsonData);
      final attempts = data.map((json) => StudentAttempt.fromJson(json as Map<String, dynamic>)).toList();
      await _saveAttempts(attempts);
    } catch (e) {
      debugPrint('Error importing attempts: $e');
      throw Exception('Failed to import attempts: $e');
    }
  }
}