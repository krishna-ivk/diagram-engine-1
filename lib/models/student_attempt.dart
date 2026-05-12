class StudentAttempt {
  final String questionId;
  final String topicId;
  final int selectedIndex;
  final bool isCorrect;
  final int timeTakenSeconds;
  final String? misconceptionCode;
  final DateTime attemptedAt;

  const StudentAttempt({
    required this.questionId,
    required this.topicId,
    required this.selectedIndex,
    required this.isCorrect,
    required this.timeTakenSeconds,
    this.misconceptionCode,
    required this.attemptedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'topicId': topicId,
      'selectedIndex': selectedIndex,
      'isCorrect': isCorrect,
      'timeTakenSeconds': timeTakenSeconds,
      'misconceptionCode': misconceptionCode,
      'attemptedAt': attemptedAt.toIso8601String(),
    };
  }

  factory StudentAttempt.fromJson(Map<String, dynamic> json) {
    return StudentAttempt(
      questionId: json['questionId'] as String,
      topicId: json['topicId'] as String,
      selectedIndex: json['selectedIndex'] as int,
      isCorrect: json['isCorrect'] as bool,
      timeTakenSeconds: json['timeTakenSeconds'] as int,
      misconceptionCode: json['misconceptionCode'] as String?,
      attemptedAt: DateTime.parse(json['attemptedAt'] as String),
    );
  }

  StudentAttempt copyWith({
    String? questionId,
    String? topicId,
    int? selectedIndex,
    bool? isCorrect,
    int? timeTakenSeconds,
    String? misconceptionCode,
    DateTime? attemptedAt,
  }) {
    return StudentAttempt(
      questionId: questionId ?? this.questionId,
      topicId: topicId ?? this.topicId,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isCorrect: isCorrect ?? this.isCorrect,
      timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
      misconceptionCode: misconceptionCode ?? this.misconceptionCode,
      attemptedAt: attemptedAt ?? this.attemptedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentAttempt &&
        other.questionId == questionId &&
        other.topicId == topicId &&
        other.selectedIndex == selectedIndex &&
        other.isCorrect == isCorrect &&
        other.timeTakenSeconds == timeTakenSeconds &&
        other.misconceptionCode == misconceptionCode &&
        other.attemptedAt == attemptedAt;
  }

  @override
  int get hashCode {
    return questionId.hashCode ^
        topicId.hashCode ^
        selectedIndex.hashCode ^
        isCorrect.hashCode ^
        timeTakenSeconds.hashCode ^
        misconceptionCode.hashCode ^
        attemptedAt.hashCode;
  }

  @override
  String toString() {
    return 'StudentAttempt(questionId: $questionId, topicId: $topicId, isCorrect: $isCorrect, timeTakenSeconds: $timeTakenSeconds)';
  }
}