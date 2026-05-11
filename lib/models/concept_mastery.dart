class ConceptMastery {
  final String conceptId;
  final String conceptName;
  final String subject;
  final String chapter;

  // Raw metrics
  final int totalAttempts;
  final int correctAttempts;
  final int totalHintsUsed;
  final int expectedTimeSeconds;
  final int totalTimeSpentSeconds;
  final int revisionCount;
  final int revisionCorrectCount;

  // Derived metrics
  final double accuracy;
  final double speedRatio;
  final double hintDependency;
  final double revisionStrength;
  final double recentConsistency;

  // Computed mastery
  final double masteryScore;
  final MasteryState state;

  const ConceptMastery({
    required this.conceptId,
    required this.conceptName,
    required this.subject,
    required this.chapter,
    this.totalAttempts = 0,
    this.correctAttempts = 0,
    this.totalHintsUsed = 0,
    this.expectedTimeSeconds = 0,
    this.totalTimeSpentSeconds = 0,
    this.revisionCount = 0,
    this.revisionCorrectCount = 0,
    this.accuracy = 0.0,
    this.speedRatio = 1.0,
    this.hintDependency = 0.0,
    this.revisionStrength = 0.0,
    this.recentConsistency = 0.0,
    this.masteryScore = 0.0,
    this.state = MasteryState.unknown,
  });

  ConceptMastery copyWith({
    String? conceptId,
    String? conceptName,
    String? subject,
    String? chapter,
    int? totalAttempts,
    int? correctAttempts,
    int? totalHintsUsed,
    int? expectedTimeSeconds,
    int? totalTimeSpentSeconds,
    int? revisionCount,
    int? revisionCorrectCount,
    double? accuracy,
    double? speedRatio,
    double? hintDependency,
    double? revisionStrength,
    double? recentConsistency,
    double? masteryScore,
    MasteryState? state,
  }) {
    return ConceptMastery(
      conceptId: conceptId ?? this.conceptId,
      conceptName: conceptName ?? this.conceptName,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      correctAttempts: correctAttempts ?? this.correctAttempts,
      totalHintsUsed: totalHintsUsed ?? this.totalHintsUsed,
      expectedTimeSeconds: expectedTimeSeconds ?? this.expectedTimeSeconds,
      totalTimeSpentSeconds: totalTimeSpentSeconds ?? this.totalTimeSpentSeconds,
      revisionCount: revisionCount ?? this.revisionCount,
      revisionCorrectCount: revisionCorrectCount ?? this.revisionCorrectCount,
      accuracy: accuracy ?? this.accuracy,
      speedRatio: speedRatio ?? this.speedRatio,
      hintDependency: hintDependency ?? this.hintDependency,
      revisionStrength: revisionStrength ?? this.revisionStrength,
      recentConsistency: recentConsistency ?? this.recentConsistency,
      masteryScore: masteryScore ?? this.masteryScore,
      state: state ?? this.state,
    );
  }

  static ConceptMastery calculate({
    required String conceptId,
    required String conceptName,
    required String subject,
    required String chapter,
    required int totalAttempts,
    required int correctAttempts,
    required int totalHintsUsed,
    required int expectedTimeSeconds,
    required int totalTimeSpentSeconds,
    required int revisionCount,
    required int revisionCorrectCount,
    List<double> recentAccuracies = const [],
  }) {
    // Calculate accuracy (40% weight)
    final accuracy = totalAttempts > 0 ? correctAttempts / totalAttempts : 0.0;

    // Calculate speed ratio (20% weight)
    // If actual time > expected, ratio < 1 (slower)
    final speedRatio = expectedTimeSeconds > 0
        ? (expectedTimeSeconds / (totalTimeSpentSeconds / totalAttempts.clamp(1, 999)))
            .clamp(0.5, 2.0)
        : 1.0;

    // Calculate hint dependency (20% weight)
    // Lower is better - no hints = 1.0, all hints = 0.0
    final hintDependency = totalAttempts > 0
        ? 1.0 - (totalHintsUsed / totalAttempts).clamp(0.0, 1.0)
        : 0.0;

    // Calculate revision strength (10% weight)
    final revisionStrength = revisionCount > 0
        ? revisionCorrectCount / revisionCount
        : 0.0;

    // Calculate recent consistency (10% weight)
    double recentConsistency = 0.5;
    if (recentAccuracies.isNotEmpty) {
      recentConsistency = recentAccuracies.reduce((a, b) => a + b) / recentAccuracies.length;
    }

    // Mastery score formula
    final masteryScore = (accuracy * 0.40 +
            speedRatio * 0.20 +
            hintDependency * 0.20 +
            revisionStrength * 0.10 +
            recentConsistency * 0.10) *
        100;

    // Classify state
    MasteryState state;
    if (totalAttempts == 0) {
      state = MasteryState.unknown;
    } else if (masteryScore >= 85) {
      state = MasteryState.mastered;
    } else if (masteryScore >= 70) {
      state = MasteryState.good;
    } else if (masteryScore >= 40) {
      state = MasteryState.developing;
    } else {
      state = MasteryState.weak;
    }

    return ConceptMastery(
      conceptId: conceptId,
      conceptName: conceptName,
      subject: subject,
      chapter: chapter,
      totalAttempts: totalAttempts,
      correctAttempts: correctAttempts,
      totalHintsUsed: totalHintsUsed,
      expectedTimeSeconds: expectedTimeSeconds,
      totalTimeSpentSeconds: totalTimeSpentSeconds,
      revisionCount: revisionCount,
      revisionCorrectCount: revisionCorrectCount,
      accuracy: accuracy,
      speedRatio: speedRatio,
      hintDependency: hintDependency,
      revisionStrength: revisionStrength,
      recentConsistency: recentConsistency,
      masteryScore: masteryScore,
      state: state,
    );
  }

  Map<String, dynamic> toJson() => {
        'conceptId': conceptId,
        'conceptName': conceptName,
        'subject': subject,
        'chapter': chapter,
        'totalAttempts': totalAttempts,
        'correctAttempts': correctAttempts,
        'totalHintsUsed': totalHintsUsed,
        'expectedTimeSeconds': expectedTimeSeconds,
        'totalTimeSpentSeconds': totalTimeSpentSeconds,
        'revisionCount': revisionCount,
        'revisionCorrectCount': revisionCorrectCount,
        'accuracy': accuracy,
        'speedRatio': speedRatio,
        'hintDependency': hintDependency,
        'revisionStrength': revisionStrength,
        'recentConsistency': recentConsistency,
        'masteryScore': masteryScore,
        'state': state.name,
      };
}

enum MasteryState {
  unknown,
  weak,
  developing,
  good,
  mastered,
}

extension MasteryStateExtension on MasteryState {
  String get displayName {
    switch (this) {
      case MasteryState.unknown:
        return 'Not Attempted';
      case MasteryState.weak:
        return 'Needs Practice';
      case MasteryState.developing:
        return 'Learning';
      case MasteryState.good:
        return 'Good';
      case MasteryState.mastered:
        return 'Mastered';
    }
  }

  String get action {
    switch (this) {
      case MasteryState.unknown:
        return 'Start learning';
      case MasteryState.weak:
        return 'Teach + Easy questions';
      case MasteryState.developing:
        return 'Medium practice + hints';
      case MasteryState.good:
        return 'Mixed practice';
      case MasteryState.mastered:
        return 'Spaced revision only';
    }
  }

  int get priority {
    switch (this) {
      case MasteryState.weak:
        return 0;
      case MasteryState.developing:
        return 1;
      case MasteryState.unknown:
        return 2;
      case MasteryState.good:
        return 3;
      case MasteryState.mastered:
        return 4;
    }
  }
}

class MistakePattern {
  final String patternId;
  final String displayName;
  final int occurrenceCount;
  final List<String> affectedConcepts;

  const MistakePattern({
    required this.patternId,
    required this.displayName,
    this.occurrenceCount = 0,
    this.affectedConcepts = const [],
  });
}

enum MistakeType {
  formula,
  calculation,
  conceptMisunderstanding,
  diagramInterpretation,
  signError,
  unitConversion,
  substitution,
  logic,
  other,
}

extension MistakeTypeExtension on MistakeType {
  String get displayName {
    switch (this) {
      case MistakeType.formula:
        return 'Formula Error';
      case MistakeType.calculation:
        return 'Calculation Error';
      case MistakeType.conceptMisunderstanding:
        return 'Concept Misunderstanding';
      case MistakeType.diagramInterpretation:
        return 'Diagram Interpretation';
      case MistakeType.signError:
        return 'Sign Error';
      case MistakeType.unitConversion:
        return 'Unit Conversion';
      case MistakeType.substitution:
        return 'Substitution Error';
      case MistakeType.logic:
        return 'Logical Error';
      case MistakeType.other:
        return 'Other';
    }
  }
}