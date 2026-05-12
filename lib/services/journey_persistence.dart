import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/journey_state.dart';

/// Persists journey progress, student profile, attempts, and
/// confidence history to local storage via SharedPreferences.
class JourneyPersistence {
  static const _prefix = 'journey_';
  static const _profileKey = 'student_profile';
  static const _activeJourneyKey = 'active_journey_id';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // --- Student Profile ---

  Future<void> saveStudentProfile(LocalStudentProfile profile) async {
    final prefs = await _preferences;
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<LocalStudentProfile> loadStudentProfile() async {
    final prefs = await _preferences;
    final json = prefs.getString(_profileKey);
    if (json != null) {
      try {
        return LocalStudentProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Error loading student profile: $e');
      }
    }
    return LocalStudentProfile.defaultProfile();
  }

  // --- Journey State ---

  Future<void> saveJourneyState(StudentJourneyState state) async {
    final prefs = await _preferences;
    final key = '$_prefix${state.journeyId}';
    await prefs.setString(key, jsonEncode(state.toJson()));
    await prefs.setString(_activeJourneyKey, state.journeyId);
  }

  Future<StudentJourneyState?> loadJourneyState(String journeyId) async {
    final prefs = await _preferences;
    final key = '$_prefix$journeyId';
    final json = prefs.getString(key);
    if (json != null) {
      try {
        return StudentJourneyState.fromJson(
            jsonDecode(json) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Error loading journey state for $journeyId: $e');
      }
    }
    return null;
  }

  Future<String?> getActiveJourneyId() async {
    final prefs = await _preferences;
    return prefs.getString(_activeJourneyKey);
  }

  Future<List<String>> getSavedJourneyIds() async {
    final prefs = await _preferences;
    return prefs
        .getKeys()
        .where((k) => k.startsWith(_prefix))
        .map((k) => k.substring(_prefix.length))
        .toList();
  }

  // --- Clear ---

  Future<void> clearJourneyState(String journeyId) async {
    final prefs = await _preferences;
    await prefs.remove('$_prefix$journeyId');
  }

  Future<void> clearAll() async {
    final prefs = await _preferences;
    final keys = prefs.getKeys().where(
        (k) => k.startsWith(_prefix) || k == _profileKey || k == _activeJourneyKey);
    for (final key in keys.toList()) {
      await prefs.remove(key);
    }
  }
}

/// Locally-persisted student profile with session/attempt counters.
class LocalStudentProfile {
  final String studentId;
  final String name;
  final String classLevel;
  final DateTime createdAt;
  final int totalSessions;
  final int totalQuestionsAttempted;

  const LocalStudentProfile({
    required this.studentId,
    required this.name,
    required this.classLevel,
    required this.createdAt,
    this.totalSessions = 0,
    this.totalQuestionsAttempted = 0,
  });

  factory LocalStudentProfile.defaultProfile() {
    return LocalStudentProfile(
      studentId: 'student_local',
      name: 'Student',
      classLevel: 'Class 7',
      createdAt: DateTime.now(),
    );
  }

  LocalStudentProfile copyWith({
    int? totalSessions,
    int? totalQuestionsAttempted,
  }) {
    return LocalStudentProfile(
      studentId: studentId,
      name: name,
      classLevel: classLevel,
      createdAt: createdAt,
      totalSessions: totalSessions ?? this.totalSessions,
      totalQuestionsAttempted:
          totalQuestionsAttempted ?? this.totalQuestionsAttempted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'name': name,
      'classLevel': classLevel,
      'createdAt': createdAt.toIso8601String(),
      'totalSessions': totalSessions,
      'totalQuestionsAttempted': totalQuestionsAttempted,
    };
  }

  factory LocalStudentProfile.fromJson(Map<String, dynamic> json) {
    return LocalStudentProfile(
      studentId: json['studentId'] as String,
      name: json['name'] as String,
      classLevel: json['classLevel'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      totalSessions: json['totalSessions'] as int? ?? 0,
      totalQuestionsAttempted: json['totalQuestionsAttempted'] as int? ?? 0,
    );
  }
}
