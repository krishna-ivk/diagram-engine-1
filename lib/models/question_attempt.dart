// Re-export unified model for backward compatibility.
// All new code should import student_attempt_event.dart directly.
import 'student_attempt_event.dart';
export 'student_attempt_event.dart' show ConfidenceLevel;

/// Backward-compatible alias for Foundation Journey attempt tracking.
/// New code should use [StudentAttemptEvent] from student_attempt_event.dart.
typedef QuestionAttempt = JourneyQuestionAttempt;

class JourneyQuestionAttempt {
  final String questionId;
  final ConfidenceLevel confidenceLevel;
  final bool isCorrect;
  final int timeSpentSeconds;
  final DateTime timestamp;
  final int levelIndex;

  const JourneyQuestionAttempt({
    required this.questionId,
    required this.confidenceLevel,
    required this.isCorrect,
    required this.timeSpentSeconds,
    required this.timestamp,
    required this.levelIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'confidenceLevel': confidenceLevel.name,
      'isCorrect': isCorrect,
      'timeSpentSeconds': timeSpentSeconds,
      'timestamp': timestamp.toIso8601String(),
      'levelIndex': levelIndex,
    };
  }

  factory JourneyQuestionAttempt.fromJson(Map<String, dynamic> json) {
    return JourneyQuestionAttempt(
      questionId: json['questionId'] as String,
      confidenceLevel:
          _parseConfidenceLevel(json['confidenceLevel'] as String?),
      isCorrect: json['isCorrect'] as bool,
      timeSpentSeconds: json['timeSpentSeconds'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      levelIndex: json['levelIndex'] as int,
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
