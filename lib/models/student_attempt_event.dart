/// Unified attempt event model for all practice modes.
///
/// Combines fields from the previous journey-specific QuestionAttempt
/// and the analytics QuestionAttempt into one model.
class StudentAttemptEvent {
  final String questionId;
  final bool isCorrect;
  final int timeSpentSeconds;
  final DateTime timestamp;

  // Confidence tracking (Foundation Journey / Learner mode)
  final ConfidenceLevel confidenceLevel;

  // Journey-specific fields (optional for non-journey modes)
  final int? levelIndex;
  final String? journeyId;
  final String? mode;

  // Analytics fields (optional for journey-only contexts)
  final String topic;
  final String primaryConcept;
  final String coreConcept;
  final String subject;
  final String chapter;
  final int tapCount;
  final int hintsUsed;
  final int expectedTimeSeconds;
  final bool isRevision;
  final int? selectedOptionIndex;
  final int? mistakeType;

  const StudentAttemptEvent({
    required this.questionId,
    required this.isCorrect,
    required this.timeSpentSeconds,
    required this.timestamp,
    this.confidenceLevel = ConfidenceLevel.somewhatSure,
    this.levelIndex,
    this.journeyId,
    this.mode,
    this.topic = '',
    this.primaryConcept = '',
    this.coreConcept = '',
    this.subject = '',
    this.chapter = '',
    this.tapCount = 0,
    this.hintsUsed = 0,
    this.expectedTimeSeconds = 120,
    this.isRevision = false,
    this.selectedOptionIndex,
    this.mistakeType,
  });

  /// Numeric confidence (1=low, 2=medium, 3=high) for analytics compatibility.
  int get confidenceAsInt {
    switch (confidenceLevel) {
      case ConfidenceLevel.notSure:
        return 1;
      case ConfidenceLevel.somewhatSure:
        return 2;
      case ConfidenceLevel.verySure:
        return 3;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'isCorrect': isCorrect,
      'timeSpentSeconds': timeSpentSeconds,
      'timestamp': timestamp.toIso8601String(),
      'confidenceLevel': confidenceLevel.name,
      'levelIndex': levelIndex,
      'journeyId': journeyId,
      'mode': mode,
      'topic': topic,
      'primaryConcept': primaryConcept,
      'coreConcept': coreConcept,
      'subject': subject,
      'chapter': chapter,
      'tapCount': tapCount,
      'hintsUsed': hintsUsed,
      'expectedTimeSeconds': expectedTimeSeconds,
      'isRevision': isRevision,
      'selectedOptionIndex': selectedOptionIndex,
      'mistakeType': mistakeType,
    };
  }

  factory StudentAttemptEvent.fromJson(Map<String, dynamic> json) {
    return StudentAttemptEvent(
      questionId: json['questionId'] as String,
      isCorrect: json['isCorrect'] as bool,
      timeSpentSeconds: json['timeSpentSeconds'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      confidenceLevel:
          _parseConfidenceLevel(json['confidenceLevel'] as String?),
      levelIndex: json['levelIndex'] as int?,
      journeyId: json['journeyId'] as String?,
      mode: json['mode'] as String?,
      topic: json['topic'] as String? ?? '',
      primaryConcept: json['primaryConcept'] as String? ?? '',
      coreConcept: json['coreConcept'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      chapter: json['chapter'] as String? ?? '',
      tapCount: json['tapCount'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      expectedTimeSeconds: json['expectedTimeSeconds'] as int? ?? 120,
      isRevision: json['isRevision'] as bool? ?? false,
      selectedOptionIndex: json['selectedOptionIndex'] as int?,
      mistakeType: json['mistakeType'] as int?,
    );
  }

  static ConfidenceLevel _parseConfidenceLevel(String? value) {
    switch (value) {
      case 'notSure':
        return ConfidenceLevel.notSure;
      case 'somewhatSure':
        return ConfidenceLevel.somewhatSure;
      case 'verySure':
        return ConfidenceLevel.verySure;
      default:
        return ConfidenceLevel.somewhatSure;
    }
  }
}

enum ConfidenceLevel {
  notSure,
  somewhatSure,
  verySure;

  String get displayName {
    switch (this) {
      case ConfidenceLevel.notSure:
        return 'Not sure';
      case ConfidenceLevel.somewhatSure:
        return 'Somewhat sure';
      case ConfidenceLevel.verySure:
        return 'Very sure';
    }
  }

  String get description {
    switch (this) {
      case ConfidenceLevel.notSure:
        return 'I guessed or need help';
      case ConfidenceLevel.somewhatSure:
        return 'I think I understand';
      case ConfidenceLevel.verySure:
        return 'I can explain this';
    }
  }
}
