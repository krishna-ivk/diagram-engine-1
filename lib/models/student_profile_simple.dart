import 'practice_mode.dart';

enum TargetExam {
  jeeMain,
  jeeAdvanced,
  neet,
  boardExams,
  foundation,
}

enum ComfortLevel {
  beginner,
  okay,
  advanced,
}

enum PreferredLanguage {
  english,
  hindi,
  telugu,
}

class StudentProfile {
  final String studentId;
  final String name;
  final int currentClass;
  final TargetExam targetExam;
  final ComfortLevel comfortLevel;
  final PreferredLanguage preferredLanguage;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final int totalSessions;
  final int totalTimeSpentMinutes;
  final Map<String, JourneyProgress> journeyProgress;
  final List<String> completedJourneys;
  final Map<String, double> conceptMastery;
  final ParentSettings parentSettings;

  const StudentProfile({
    required this.studentId,
    required this.name,
    required this.currentClass,
    required this.targetExam,
    required this.comfortLevel,
    this.preferredLanguage = PreferredLanguage.english,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    this.totalSessions = 0,
    this.totalTimeSpentMinutes = 0,
    Map<String, JourneyProgress>? journeyProgress,
    List<String>? completedJourneys,
    Map<String, double>? conceptMastery,
    ParentSettings? parentSettings,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      studentId: json['studentId'] as String,
      name: json['name'] as String,
      currentClass: json['currentClass'] as int,
      targetExam: _parseTargetExam(json['targetExam'] as String),
      comfortLevel: _parseComfortLevel(json['comfortLevel'] as String),
      preferredLanguage: _parsePreferredLanguage(json['preferredLanguage'] as String),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      lastActiveAt: json['lastActiveAt'] != null ? DateTime.parse(json['lastActiveAt'] as String) : null,
      totalSessions: json['totalSessions'] as int? ?? 0,
      totalTimeSpentMinutes: json['totalTimeSpentMinutes'] as int? ?? 0,
      journeyProgress: (json['journeyProgress'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          key: key,
          value: _parseJourneyProgress(value as Map<String, dynamic>),
        ),
      ) ?? {},
      completedJourneys: (json['completedJourneys'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      conceptMastery: (json['conceptMastery'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          key: key,
          value: (value as num).toDouble(),
        ),
      ) ?? {},
      parentSettings: json['parentSettings'] != null 
          ? ParentSettings.fromJson(json['parentSettings'] as Map<String, dynamic>)
          : ParentSettings(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'name': name,
      'currentClass': currentClass,
      'targetExam': targetExam.name,
      'comfortLevel': comfortLevel.name,
      'preferredLanguage': preferredLanguage.name,
      'createdAt': createdAt?.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'totalSessions': totalSessions,
      'totalTimeSpentMinutes': totalTimeSpentMinutes,
      'journeyProgress': journeyProgress.map((key, value) => MapEntry(
        key: key,
        value: value,
      )),
      'completedJourneys': completedJourneys,
      'conceptMastery': conceptMastery,
      'parentSettings': parentSettings.toJson(),
    };
  }

  TargetExam _parseTargetExam(String value) {
    switch (value) {
      case 'jee_main':
        return TargetExam.jeeMain;
      case 'jee_advanced':
        return TargetExam.jeeAdvanced;
      case 'neet':
        return TargetExam.neet;
      case 'board_exams':
        return TargetExam.boardExams;
      case 'foundation':
        return TargetExam.foundation;
      default:
        return TargetExam.jeeMain;
    }
  }

  ComfortLevel _parseComfortLevel(String value) {
    switch (value) {
      case 'beginner':
        return ComfortLevel.beginner;
      case 'okay':
        return ComfortLevel.okay;
      case 'advanced':
        return ComfortLevel.advanced;
      default:
        return ComfortLevel.beginner;
    }
  }

  PreferredLanguage _parsePreferredLanguage(String value) {
    switch (value) {
      case 'english':
        return PreferredLanguage.english;
      case 'hindi':
        return PreferredLanguage.hindi;
      case 'telugu':
        return PreferredLanguage.telugu;
      default:
        return PreferredLanguage.english;
    }
  }

  JourneyProgress _parseJourneyProgress(Map<String, dynamic> json) {
    return JourneyProgress(
      journeyId: json['journeyId'] as String,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      lastAccessedAt: json['lastAccessedAt'] != null ? DateTime.parse(json['lastAccessedAt'] as String) : null,
    );
  }

  ParentSettings _parseParentSettings(Map<String, dynamic> json) {
    return ParentSettings(
      weeklyProgressReports: json['weeklyProgressReports'] as bool? ?? false,
      emailNotifications: json['emailNotifications'] as bool? ?? false,
      parentEmail: json['parentEmail'] as String?,
      dailyTimeLimitMinutes: json['dailyTimeLimitMinutes'] as int? ?? 120,
      allowWeekendAccess: json['allowWeekendAccess'] as bool? ?? true,
      allowedFeatures: (json['allowedFeatures'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? ['foundation_journey', 'learner_mode', 'revision', 'mock_exam'],
    );
  }

  /// Get recommended default practice mode based on profile
  PracticeMode getRecommendedMode() {
    // Class 7 students should start with Foundation Journey
    if (currentClass <= 7) {
      return PracticeMode.foundationJourney;
    }
    
    // Class 8-10 students can use Learner Mode
    if (currentClass <= 10) {
      return PracticeMode.learner;
    }
    
    // Default to Learner Mode
    return PracticeMode.learner;
  }

  /// Check if Foundation Journey should be shown prominently
  bool shouldShowFoundationJourney() {
    return currentClass <= 8 || comfortLevel == ComfortLevel.beginner;
  }
}