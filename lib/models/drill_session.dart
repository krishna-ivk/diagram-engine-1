enum DrillMode {
  quickDrill,
  revision,
  miniMock,
}

class DrillSession {
  final String topicId;
  final List<String> questionIds;
  final int currentIndex;
  final DrillMode mode;
  final DateTime startedAt;
  final Map<String, StudentAttempt> attempts;
  final bool isCompleted;

  const DrillSession({
    required this.topicId,
    required this.questionIds,
    required this.currentIndex,
    required this.mode,
    required this.startedAt,
    required this.attempts,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'topicId': topicId,
      'questionIds': questionIds,
      'currentIndex': currentIndex,
      'mode': mode.name,
      'startedAt': startedAt.toIso8601String(),
      'attempts': attempts.map((key, value) => MapEntry(key, value.toJson())),
      'isCompleted': isCompleted,
    };
  }

  factory DrillSession.fromJson(Map<String, dynamic> json) {
    return DrillSession(
      topicId: json['topicId'] as String,
      questionIds: List<String>.from(json['questionIds'] as List),
      currentIndex: json['currentIndex'] as int,
      mode: DrillMode.values.firstWhere((m) => m.name == json['mode']),
      startedAt: DateTime.parse(json['startedAt'] as String),
      attempts: Map<String, StudentAttempt>.from(
        (json['attempts'] as Map).map(
          (key, value) => MapEntry(key, StudentAttempt.fromJson(value as Map<String, dynamic>)),
        ),
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  DrillSession copyWith({
    String? topicId,
    List<String>? questionIds,
    int? currentIndex,
    DrillMode? mode,
    DateTime? startedAt,
    Map<String, StudentAttempt>? attempts,
    bool? isCompleted,
  }) {
    return DrillSession(
      topicId: topicId ?? this.topicId,
      questionIds: questionIds ?? this.questionIds,
      currentIndex: currentIndex ?? this.currentIndex,
      mode: mode ?? this.mode,
      startedAt: startedAt ?? this.startedAt,
      attempts: attempts ?? this.attempts,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // Convenience getters
  String? get currentQuestionId {
    if (currentIndex >= 0 && currentIndex < questionIds.length) {
      return questionIds[currentIndex];
    }
    return null;
  }

  bool get hasNextQuestion => currentIndex < questionIds.length - 1;
  bool get hasPreviousQuestion => currentIndex > 0;
  
  int get completedQuestions => attempts.length;
  int get totalQuestions => questionIds.length;
  double get progress => totalQuestions > 0 ? completedQuestions / totalQuestions : 0.0;
  
  int get correctAnswers {
    return attempts.values.where((attempt) => attempt.isCorrect).length;
  }
  
  int get incorrectAnswers {
    return attempts.values.where((attempt) => !attempt.isCorrect).length;
  }
  
  double get accuracy {
    return completedQuestions > 0 ? correctAnswers / completedQuestions : 0.0;
  }

  Duration get elapsedTime => DateTime.now().difference(startedAt);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrillSession &&
        other.topicId == topicId &&
        other.questionIds == questionIds &&
        other.currentIndex == currentIndex &&
        other.mode == mode &&
        other.startedAt == startedAt &&
        other.attempts == attempts &&
        other.isCompleted == isCompleted;
  }

  @override
  int get hashCode {
    return topicId.hashCode ^
        questionIds.hashCode ^
        currentIndex.hashCode ^
        mode.hashCode ^
        startedAt.hashCode ^
        attempts.hashCode ^
        isCompleted.hashCode;
  }

  @override
  String toString() {
    return 'DrillSession(topicId: $topicId, mode: $mode, progress: ${(progress * 100).toStringAsFixed(1)}%, accuracy: ${(accuracy * 100).toStringAsFixed(1)}%)';
  }
}