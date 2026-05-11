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
      journeyId: json['journeyId'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      targetGrade: json['targetGrade'] as String,
      targetExam: json['targetExam'] as String,
      chapter: json['chapter'] as String,
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int,
      difficultyProgression: (json['difficultyProgression'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      levels: (json['levels'] as List<dynamic>)
          .map((e) => JourneyLevel.fromJson(e as Map<String, dynamic>))
          .toList(),
      progressionRules: ProgressionRules.fromJson(json['progressionRules'] as Map<String, dynamic>),
      successCriteria: SuccessCriteria.fromJson(json['successCriteria'] as Map<String, dynamic>),
      parentProgressSummary: ParentProgressSummary.fromJson(json['parentProgressSummary'] as Map<String, dynamic>),
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
      classLevel: json['classLevel'] as String,
      microLesson: MicroLesson.fromJson(json['microLesson'] as Map<String, dynamic>),
      questionIds: (json['questionIds'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      prerequisites: (json['prerequisites'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      unlockThreshold: UnlockThreshold.fromJson(json['unlockThreshold'] as Map<String, dynamic>),
      manipulatives: (json['manipulatives'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      expectedTimeSeconds: json['expectedTimeSeconds'] as int?,
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
      visualHintIds: (json['visualHintIds'] as List<dynamic>?)
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
      correctRequired: json['correctRequired'] as int,
      confidenceThreshold: json['confidenceThreshold'] as String,
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
      correctTwice: json['correctTwice'] as String,
      wrongOnceLowConfidence: json['wrongOnceLowConfidence'] as String,
      wrongTwice: json['wrongTwice'] as String,
      correctFastHighConfidence: json['correctFastHighConfidence'] as String,
      correctSlow: json['correctSlow'] as String,
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
      journeyCompletion: json['journeyCompletion'] as String,
      masteryIndicator: json['masteryIndicator'] as String,
      timeEstimate: json['timeEstimate'] as String,
      retryAllowed: json['retryAllowed'] as bool,
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
      conceptsMastered: (json['conceptsMastered'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      strugglingAreas: (json['strugglingAreas'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      confidenceTrend: json['confidenceTrend'] as String,
      recommendedNext: json['recommendedNext'] as String,
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