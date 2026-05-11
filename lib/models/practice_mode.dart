enum PracticeMode {
  learner,
  mockExam,
  revision,
  foundationJourney,
}

extension PracticeModeExtension on PracticeMode {
  String get displayName {
    switch (this) {
      case PracticeMode.learner:
        return 'Learner Mode';
      case PracticeMode.mockExam:
        return 'Mock Exam';
      case PracticeMode.revision:
        return 'Revision';
      case PracticeMode.foundationJourney:
        return 'Foundation Journey';
    }
  }

  String get description {
    switch (this) {
      case PracticeMode.learner:
        return 'Learn with hints, step-by-step guidance, and rescue questions';
      case PracticeMode.mockExam:
        return 'Test your readiness with timed, exam-like conditions';
      case PracticeMode.revision:
        return 'Strengthen weak concepts with spaced repetition';
      case PracticeMode.foundationJourney:
        return 'Build from Class 7 basics to JEE-level thinking step by step';
    }
  }

  bool get allowHints {
    return this == PracticeMode.learner || this == PracticeMode.foundationJourney;
  }

  bool get allowRevealSteps {
    return this == PracticeMode.learner || this == PracticeMode.foundationJourney;
  }

  bool get showTimer {
    return this == PracticeMode.mockExam;
  }

  bool get allowConceptExplanation {
    return this == PracticeMode.learner || this == PracticeMode.foundationJourney;
  }

  bool get adaptiveDifficulty {
    return this == PracticeMode.learner || this == PracticeMode.foundationJourney;
  }

  bool get isProgressionBased {
    return this == PracticeMode.foundationJourney;
  }

  bool get showMicroLessons {
    return this == PracticeMode.foundationJourney;
  }

  bool get trackConfidence {
    return this == PracticeMode.foundationJourney;
  }
}

class ExamResult {
  final int totalQuestions;
  final int correctAnswers;
  final int timeTakenSeconds;
  final Map<String, int> topicScores;
  final List<String> weakConcepts;
  final List<String> strongConcepts;
  final Map<String, List<String>> mistakePatterns;
  final DateTime examDate;
  final int examDurationMinutes;

  const ExamResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeTakenSeconds,
    required this.topicScores,
    required this.weakConcepts,
    required this.strongConcepts,
    required this.mistakePatterns,
    required this.examDate,
    required this.examDurationMinutes,
  });

  double get accuracy => totalQuestions > 0 ? correctAnswers / totalQuestions : 0;

  int get scorePercentage => (accuracy * 100).round();

  String get grade {
    final pct = scorePercentage;
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B';
    if (pct >= 60) return 'C';
    if (pct >= 50) return 'D';
    return 'F';
  }

  String get readinessLevel {
    final pct = scorePercentage;
    if (pct >= 70) return 'Ready for exam';
    if (pct >= 50) return 'Needs more practice';
    return 'Significant gaps to close';
  }

  List<String> get learningPrescription {
    final prescription = <String>[];
    if (weakConcepts.isNotEmpty) {
      prescription.add('Focus on: ${weakConcepts.take(3).join(", ")}');
    }
    if (accuracy < 0.7) {
      prescription.add('Complete 20+ questions in Learner Mode');
    }
    if (timeTakenSeconds > examDurationMinutes * 50) {
      prescription.add('Practice speed - aim for 2 min/question average');
    }
    return prescription;
  }
}