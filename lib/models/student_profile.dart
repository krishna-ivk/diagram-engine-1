import 'package:json_annotation/json_annotation.dart';
import 'practice_mode.dart';

part 'student_profile.g.dart';

@JsonSerializable()
class StudentProfile {
  final String studentId;
  String name;
  int currentClass;
  TargetExam targetExam;
  ComfortLevel comfortLevel;
  PreferredLanguage preferredLanguage;
  DateTime createdAt;
  DateTime lastActiveAt;
  int totalSessions;
  int totalTimeSpentMinutes;
  Map<String, JourneyProgress> journeyProgress;
  List<String> completedJourneys;
  Map<String, double> conceptMastery;
  ParentSettings parentSettings;

  StudentProfile({
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
  }) : createdAt = createdAt ?? DateTime.now(),
       lastActiveAt = lastActiveAt ?? DateTime.now(),
       journeyProgress = journeyProgress ?? {},
       completedJourneys = completedJourneys ?? [],
       conceptMastery = conceptMastery ?? {},
       parentSettings = parentSettings ?? ParentSettings();

  factory StudentProfile.fromJson(Map<String, dynamic> json) =>
      _$StudentProfileFromJson(json);

  Map<String, dynamic> toJson() => _$StudentProfileToJson(this);

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
    
    // Class 11-12 students can use Learner + Mock Exam
    return PracticeMode.learner;
  }

  /// Check if student should see Foundation Journey prominently
  bool shouldShowFoundationJourney() {
    return currentClass <= 8 || comfortLevel == ComfortLevel.beginner;
  }

  /// Get personalized welcome message
  String getWelcomeMessage() {
    final className = currentClass <= 10 ? 'Class $currentClass' : 'Class $currentClass';
    
    if (shouldShowFoundationJourney()) {
      return 'Welcome $name! Start your JEE foundation journey from $className basics.';
    } else {
      return 'Welcome $name! Ready to excel in JEE preparation?';
    }
  }

  /// Update profile with session data
  void updateSessionData({
    required int sessionDurationMinutes,
    required Map<String, double> conceptUpdates,
    required String? completedJourney,
  }) {
    lastActiveAt = DateTime.now();
    totalSessions++;
    totalTimeSpentMinutes += sessionDurationMinutes;
    
    // Update concept mastery
    conceptUpdates.forEach((concept, mastery) {
      conceptMastery[concept] = (conceptMastery[concept] ?? 0.0) * 0.7 + mastery * 0.3;
    });
    
    // Add completed journey
    if (completedJourney != null && !completedJourneys.contains(completedJourney)) {
      completedJourneys.add(completedJourney);
    }
  }

  /// Get progress summary for parents
  ParentProgressSummary getParentSummary() {
    final recentJourneys = journeyProgress.entries
        .where((e) => e.value.lastAccessed.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();
    
    final conceptsMastered = conceptMastery.entries
        .where((e) => e.value >= 0.8)
        .map((e) => e.key)
        .toList();
    
    final strugglingConcepts = conceptMastery.entries
        .where((e) => e.value < 0.5)
        .map((e) => e.key)
        .toList();

    return ParentProgressSummary(
      studentName: name,
      currentClass: currentClass,
      totalSessions: totalSessions,
      totalTimeSpentMinutes: totalTimeSpentMinutes,
      conceptsMastered: conceptsMastered,
      strugglingConcepts: strugglingConcepts,
      completedJourneys: completedJourneys.length,
      recentActivity: recentJourneys.map((e) => e.key).toList(),
    );
  }
}

@JsonSerializable()
class JourneyProgress {
  final String journeyId;
  DateTime startedAt;
  DateTime? completedAt;
  int currentLevel;
  int totalLevels;
  double progressPercentage;
  DateTime lastAccessed;
  int attemptsCount;
  double accuracy;

  JourneyProgress({
    required this.journeyId,
    required this.startedAt,
    this.completedAt,
    required this.currentLevel,
    required this.totalLevels,
    required this.progressPercentage,
    required this.lastAccessed,
    required this.attemptsCount,
    required this.accuracy,
  });

  factory JourneyProgress.fromJson(Map<String, dynamic> json) =>
      _$JourneyProgressFromJson(json);

  Map<String, dynamic> toJson() => _$JourneyProgressToJson(this);

  bool get isCompleted => completedAt != null;
  
  Duration getTimeSpent() {
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt);
  }
}

@JsonSerializable()
class ParentSettings {
  bool weeklyProgressReports;
  bool emailNotifications;
  String? parentEmail;
  int dailyTimeLimitMinutes;
  bool allowWeekendAccess;
  List<String> allowedFeatures;

  ParentSettings({
    this.weeklyProgressReports = true,
    this.emailNotifications = false,
    this.parentEmail,
    this.dailyTimeLimitMinutes = 120,
    this.allowWeekendAccess = true,
    List<String>? allowedFeatures,
  }) : allowedFeatures = allowedFeatures ?? [
         'foundation_journey',
         'learner_mode',
         'revision',
         'mock_exam',
       ];

  factory ParentSettings.fromJson(Map<String, dynamic> json) =>
      _$ParentSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$ParentSettingsToJson(this);

  bool isFeatureAllowed(String feature) {
    return allowedFeatures.contains(feature);
  }
}

class ParentProgressSummary {
  final String studentName;
  final int currentClass;
  final int totalSessions;
  final int totalTimeSpentMinutes;
  final List<String> conceptsMastered;
  final List<String> strugglingConcepts;
  final int completedJourneys;
  final List<String> recentActivity;

  ParentProgressSummary({
    required this.studentName,
    required this.currentClass,
    required this.totalSessions,
    required this.totalTimeSpentMinutes,
    required this.conceptsMastered,
    required this.strugglingConcepts,
    required this.completedJourneys,
    required this.recentActivity,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentName': studentName,
      'currentClass': currentClass,
      'totalSessions': totalSessions,
      'totalTimeSpentMinutes': totalTimeSpentMinutes,
      'conceptsMastered': conceptsMastered,
      'strugglingConcepts': strugglingConcepts,
      'completedJourneys': completedJourneys,
      'recentActivity': recentActivity,
      'averageSessionMinutes': totalSessions > 0 ? totalTimeSpentMinutes / totalSessions : 0,
    };
  }
}

enum TargetExam {
  @JsonValue('jee_main')
  jeeMain,
  
  @JsonValue('jee_advanced')
  jeeAdvanced,
  
  @JsonValue('neet')
  neet,
  
  @JsonValue('board_exams')
  boardExams,
  
  @JsonValue('foundation')
  foundation,
}

enum ComfortLevel {
  @JsonValue('beginner')
  beginner,
  
  @JsonValue('okay')
  okay,
  
  @JsonValue('advanced')
  advanced,
}

enum PreferredLanguage {
  @JsonValue('english')
  english,
  
  @JsonValue('hindi')
  hindi,
  
  @JsonValue('telugu')
  telugu,
}