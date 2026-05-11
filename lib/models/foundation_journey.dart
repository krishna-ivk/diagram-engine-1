import 'package:json_annotation/json_annotation.dart';

part 'foundation_journey.g.dart';

@JsonSerializable()
class FoundationJourney {
  final String journeyId;
  final String title;
  final String subtitle;
  final String targetGrade;
  final String targetExam;
  final String chapter;
  final int estimatedDurationMinutes;
  final List<String> difficultyProgression;
  final List<JourneyLevel> levels;
  final ProgressionRules progressionRules;
  final SuccessCriteria successCriteria;
  final ParentProgressSummary parentProgressSummary;

  FoundationJourney({
    required this.journeyId,
    required this.title,
    required this.subtitle,
    required this.targetGrade,
    required this.targetExam,
    required this.chapter,
    required this.estimatedDurationMinutes,
    required this.difficultyProgression,
    required this.levels,
    required this.progressionRules,
    required this.successCriteria,
    required this.parentProgressSummary,
  });

  factory FoundationJourney.fromJson(Map<String, dynamic> json) =>
      _$FoundationJourneyFromJson(json);

  Map<String, dynamic> toJson() => _$FoundationJourneyToJson(this);
}

@JsonSerializable()
class JourneyLevel {
  final String level;
  final String role;
  final String title;
  final String description;
  final String classLevel;
  final MicroLesson microLesson;
  final List<String> questionIds;
  final List<String> prerequisites;
  final UnlockThreshold unlockThreshold;
  final List<String> manipulatives;
  final int? expectedTimeSeconds;

  JourneyLevel({
    required this.level,
    required this.role,
    required this.title,
    required this.description,
    required this.classLevel,
    required this.microLesson,
    required this.questionIds,
    required this.prerequisites,
    required this.unlockThreshold,
    required this.manipulatives,
    this.expectedTimeSeconds,
  });

  factory JourneyLevel.fromJson(Map<String, dynamic> json) =>
      _$JourneyLevelFromJson(json);

  Map<String, dynamic> toJson() => _$JourneyLevelToJson(this);
}

@JsonSerializable()
class MicroLesson {
  final String title;
  final String body;
  final List<String> visualHintIds;

  MicroLesson({
    required this.title,
    required this.body,
    required this.visualHintIds,
  });

  factory MicroLesson.fromJson(Map<String, dynamic> json) =>
      _$MicroLessonFromJson(json);

  Map<String, dynamic> toJson() => _$MicroLessonToJson(this);
}

@JsonSerializable()
class UnlockThreshold {
  final int correctRequired;
  final String confidenceThreshold;

  UnlockThreshold({
    required this.correctRequired,
    required this.confidenceThreshold,
  });

  factory UnlockThreshold.fromJson(Map<String, dynamic> json) =>
      _$UnlockThresholdFromJson(json);

  Map<String, dynamic> toJson() => _$UnlockThresholdToJson(this);
}

@JsonSerializable()
class ProgressionRules {
  final String correctTwice;
  final String wrongOnceLowConfidence;
  final String wrongTwice;
  final String correctFastHighConfidence;
  final String correctSlow;

  ProgressionRules({
    required this.correctTwice,
    required this.wrongOnceLowConfidence,
    required this.wrongTwice,
    required this.correctFastHighConfidence,
    required this.correctSlow,
  });

  factory ProgressionRules.fromJson(Map<String, dynamic> json) =>
      _$ProgressionRulesFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressionRulesToJson(this);
}

@JsonSerializable()
class SuccessCriteria {
  final String journeyCompletion;
  final String masteryIndicator;
  final String timeEstimate;
  final bool retryAllowed;

  SuccessCriteria({
    required this.journeyCompletion,
    required this.masteryIndicator,
    required this.timeEstimate,
    required this.retryAllowed,
  });

  factory SuccessCriteria.fromJson(Map<String, dynamic> json) =>
      _$SuccessCriteriaFromJson(json);

  Map<String, dynamic> toJson() => _$SuccessCriteriaToJson(this);
}

@JsonSerializable()
class ParentProgressSummary {
  final List<String> conceptsMastered;
  final List<String> strugglingAreas;
  final String confidenceTrend;
  final String recommendedNext;

  ParentProgressSummary({
    required this.conceptsMastered,
    required this.strugglingAreas,
    required this.confidenceTrend,
    required this.recommendedNext,
  });

  factory ParentProgressSummary.fromJson(Map<String, dynamic> json) =>
      _$ParentProgressSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ParentProgressSummaryToJson(this);
}