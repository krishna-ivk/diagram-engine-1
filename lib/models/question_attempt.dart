enum ConfidenceLevel {
  notSure,
  somewhatSure,
  verySure,
}

class QuestionAttempt {
  final String questionId;
  final ConfidenceLevel confidenceLevel;
  final bool isCorrect;
  final int timeSpentSeconds;
  final DateTime timestamp;
  final int levelIndex;

  const QuestionAttempt({
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

  factory QuestionAttempt.fromJson(Map<String, dynamic> json) {
    return QuestionAttempt(
      questionId: json['questionId'] as String,
      confidenceLevel: _parseConfidenceLevel(json['confidenceLevel'] as String?),
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