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

  factory FoundationJourney.fromJson(Map<String, dynamic> json) {
    return FoundationJourney(
      journeyId: _string(json, 'journeyId', 'journey_id'),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      targetGrade: _string(json, 'targetGrade', 'target_grade'),
      targetExam: _string(json, 'targetExam', 'target_exam'),
      chapter: json['chapter'] as String,
      estimatedDurationMinutes:
          _int(json, 'estimatedDurationMinutes', 'estimated_duration_minutes'),
      difficultyProgression:
          (_value(json, 'difficultyProgression', 'difficulty_progression')
                  as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      levels: (json['levels'] as List<dynamic>)
          .map((e) => JourneyLevel.fromJson(e as Map<String, dynamic>))
          .toList(),
      progressionRules: ProgressionRules.fromJson(
        _map(json, 'progressionRules', 'progression_rules'),
      ),
      successCriteria: SuccessCriteria.fromJson(
        _map(json, 'successCriteria', 'success_criteria'),
      ),
      parentProgressSummary: ParentProgressSummary.fromJson(
        _map(json, 'parentProgressSummary', 'parent_progress_summary'),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'journeyId': journeyId,
      'title': title,
      'subtitle': subtitle,
      'targetGrade': targetGrade,
      'targetExam': targetExam,
      'chapter': chapter,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'difficultyProgression': difficultyProgression,
      'levels': levels.map((level) => level.toJson()).toList(),
      'progressionRules': progressionRules.toJson(),
      'successCriteria': successCriteria.toJson(),
      'parentProgressSummary': parentProgressSummary.toJson(),
    };
  }
}

dynamic _value(Map<String, dynamic> json, String camelKey, String snakeKey) =>
    json[camelKey] ?? json[snakeKey];

String _string(Map<String, dynamic> json, String camelKey, String snakeKey) =>
    _value(json, camelKey, snakeKey) as String;

int _int(Map<String, dynamic> json, String camelKey, String snakeKey) =>
    _value(json, camelKey, snakeKey) as int;

Map<String, dynamic> _map(
  Map<String, dynamic> json,
  String camelKey,
  String snakeKey,
) =>
    _value(json, camelKey, snakeKey) as Map<String, dynamic>;

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

  factory JourneyLevel.fromJson(Map<String, dynamic> json) {
    return JourneyLevel(
      level: json['level'] as String,
      role: json['role'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      classLevel: _string(json, 'classLevel', 'class_level'),
      microLesson: MicroLesson.fromJson(
        _map(json, 'microLesson', 'micro_lesson'),
      ),
      questionIds: (_value(json, 'questionIds', 'question_ids') as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      prerequisites: (json['prerequisites'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      unlockThreshold: UnlockThreshold.fromJson(
        _map(json, 'unlockThreshold', 'unlock_threshold'),
      ),
      manipulatives: (json['manipulatives'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      expectedTimeSeconds:
          _value(json, 'expectedTimeSeconds', 'expected_time_seconds') as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'role': role,
      'title': title,
      'description': description,
      'classLevel': classLevel,
      'microLesson': microLesson.toJson(),
      'questionIds': questionIds,
      'prerequisites': prerequisites,
      'unlockThreshold': unlockThreshold.toJson(),
      'manipulatives': manipulatives,
      'expectedTimeSeconds': expectedTimeSeconds,
    };
  }
}

class MicroLesson {
  final String title;
  final String body;
  final List<String> visualHintIds;

  MicroLesson({
    required this.title,
    required this.body,
    required this.visualHintIds,
  });

  factory MicroLesson.fromJson(Map<String, dynamic> json) {
    return MicroLesson(
      title: json['title'] as String,
      body: json['body'] as String,
      visualHintIds: (_value(json, 'visualHintIds', 'visual_hint_ids')
              as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'visualHintIds': visualHintIds,
    };
  }
}

class UnlockThreshold {
  final int correctRequired;
  final String confidenceThreshold;

  UnlockThreshold({
    required this.correctRequired,
    required this.confidenceThreshold,
  });

  factory UnlockThreshold.fromJson(Map<String, dynamic> json) {
    return UnlockThreshold(
      correctRequired: _int(json, 'correctRequired', 'correct_required'),
      confidenceThreshold:
          _string(json, 'confidenceThreshold', 'confidence_threshold'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'correctRequired': correctRequired,
      'confidenceThreshold': confidenceThreshold,
    };
  }
}

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

  factory ProgressionRules.fromJson(Map<String, dynamic> json) {
    return ProgressionRules(
      correctTwice: _string(json, 'correctTwice', 'correct_twice'),
      wrongOnceLowConfidence:
          _string(json, 'wrongOnceLowConfidence', 'wrong_once_low_confidence'),
      wrongTwice: _string(json, 'wrongTwice', 'wrong_twice'),
      correctFastHighConfidence: _string(
        json,
        'correctFastHighConfidence',
        'correct_fast_high_confidence',
      ),
      correctSlow: _string(json, 'correctSlow', 'correct_slow'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'correctTwice': correctTwice,
      'wrongOnceLowConfidence': wrongOnceLowConfidence,
      'wrongTwice': wrongTwice,
      'correctFastHighConfidence': correctFastHighConfidence,
      'correctSlow': correctSlow,
    };
  }
}

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

  factory SuccessCriteria.fromJson(Map<String, dynamic> json) {
    return SuccessCriteria(
      journeyCompletion:
          _string(json, 'journeyCompletion', 'journey_completion'),
      masteryIndicator: _string(json, 'masteryIndicator', 'mastery_indicator'),
      timeEstimate: _string(json, 'timeEstimate', 'time_estimate'),
      retryAllowed: _value(json, 'retryAllowed', 'retry_allowed') as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'journeyCompletion': journeyCompletion,
      'masteryIndicator': masteryIndicator,
      'timeEstimate': timeEstimate,
      'retryAllowed': retryAllowed,
    };
  }
}

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

  factory ParentProgressSummary.fromJson(Map<String, dynamic> json) {
    return ParentProgressSummary(
      conceptsMastered:
          (_value(json, 'conceptsMastered', 'concepts_mastered')
                  as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      strugglingAreas:
          (_value(json, 'strugglingAreas', 'struggling_areas')
                  as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      confidenceTrend: _string(json, 'confidenceTrend', 'confidence_trend'),
      recommendedNext: _string(json, 'recommendedNext', 'recommended_next'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conceptsMastered': conceptsMastered,
      'strugglingAreas': strugglingAreas,
      'confidenceTrend': confidenceTrend,
      'recommendedNext': recommendedNext,
    };
  }
}
