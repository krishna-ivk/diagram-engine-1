import 'concept_mastery.dart';

/// Analytics-focused attempt model used by PerformanceTracker.
/// New code should prefer [StudentAttemptEvent] from student_attempt_event.dart.
class QuestionAttempt {
  final String questionId;
  final String topic;
  final String coreConcept;
  final String primaryConcept;
  final String subject;
  final String chapter;
  final bool correct;
  final int timeSeconds;
  final int tapCount;
  final int hintsUsed;
  final int expectedTimeSeconds;
  final DateTime timestamp;
  final bool isRevision;
  final int confidenceLevel; // 1=low, 2=medium, 3=high
  final int? mistakeType; // enum index from MistakeType

  const QuestionAttempt({
    required this.questionId,
    required this.topic,
    required this.coreConcept,
    required this.primaryConcept,
    required this.subject,
    required this.chapter,
    required this.correct,
    required this.timeSeconds,
    required this.tapCount,
    required this.hintsUsed,
    required this.expectedTimeSeconds,
    required this.timestamp,
    this.isRevision = false,
    this.confidenceLevel = 2, // default medium
    this.mistakeType,
  });
}

class TopicPerformance {
  final String topic;
  final int totalAttempts;
  final int correctAttempts;
  final double avgTimeSeconds;
  final double avgHintsUsed;

  const TopicPerformance({
    required this.topic,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.avgTimeSeconds,
    required this.avgHintsUsed,
  });

  double get accuracy =>
      totalAttempts > 0 ? correctAttempts / totalAttempts : 0;
  bool get isWeak => accuracy < 0.5 && totalAttempts >= 2;
  bool get needsPractice => accuracy < 0.7 && totalAttempts >= 1;
}

class PerformanceTracker {
  final List<QuestionAttempt> _attempts = [];

  List<QuestionAttempt> get attempts => List.unmodifiable(_attempts);

  void recordAttempt(QuestionAttempt attempt) {
    _attempts.add(attempt);
  }

  Map<String, TopicPerformance> getTopicPerformance() {
    final byTopic = <String, List<QuestionAttempt>>{};
    for (final a in _attempts) {
      byTopic.putIfAbsent(a.topic, () => []).add(a);
    }

    return byTopic.map((topic, attempts) {
      final correct = attempts.where((a) => a.correct).length;
      final avgTime =
          attempts.map((a) => a.timeSeconds).reduce((a, b) => a + b) /
              attempts.length;
      final avgHints =
          attempts.map((a) => a.hintsUsed).reduce((a, b) => a + b) /
              attempts.length;
      return MapEntry(
        topic,
        TopicPerformance(
          topic: topic,
          totalAttempts: attempts.length,
          correctAttempts: correct,
          avgTimeSeconds: avgTime,
          avgHintsUsed: avgHints,
        ),
      );
    });
  }

  List<TopicPerformance> getWeakAreas() {
    return getTopicPerformance().values.where((p) => p.isWeak).toList()
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
  }

  List<TopicPerformance> getAreasNeedingPractice() {
    return getTopicPerformance().values.where((p) => p.needsPractice).toList()
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
  }

  String? getInsightForTopic(String topic) {
    final perf = getTopicPerformance()[topic];
    if (perf == null) return null;

    if (perf.isWeak) {
      return 'You struggle with $topic (${(perf.accuracy * 100).toInt()}% accuracy). Practice more!';
    }
    if (perf.needsPractice) {
      return '$topic needs attention (${(perf.accuracy * 100).toInt()}% accuracy).';
    }
    if (perf.avgHintsUsed > 2) {
      return 'You use many hints for $topic. Try solving without hints.';
    }
    return null;
  }

  // Concept-level mastery tracking
  Map<String, ConceptMastery> getConceptMasteries() {
    final byConcept = <String, List<QuestionAttempt>>{};
    for (final a in _attempts) {
      final conceptId =
          a.primaryConcept.isNotEmpty ? a.primaryConcept : a.coreConcept;
      byConcept.putIfAbsent(conceptId, () => []).add(a);
    }

    return byConcept.map((conceptId, attempts) {
      final correct = attempts.where((a) => a.correct).length;
      final hints = attempts.map((a) => a.hintsUsed).reduce((a, b) => a + b);
      final totalTime =
          attempts.map((a) => a.timeSeconds).reduce((a, b) => a + b);
      final expected =
          attempts.map((a) => a.expectedTimeSeconds).reduce((a, b) => a + b);
      final revisions = attempts.where((a) => a.isRevision).toList();
      final revisionCorrect = revisions.where((a) => a.correct).length;

      // Get recent accuracies for last 5 attempts
      final recent = attempts.length > 5
          ? attempts.sublist(attempts.length - 5)
          : attempts;
      final recentAccuracies =
          recent.map((a) => a.correct ? 1.0 : 0.0).toList();

      final mastery = ConceptMastery.calculate(
        conceptId: conceptId,
        conceptName: _getConceptDisplayName(conceptId),
        subject: attempts.first.subject,
        chapter: attempts.first.chapter,
        totalAttempts: attempts.length,
        correctAttempts: correct,
        totalHintsUsed: hints,
        expectedTimeSeconds: expected,
        totalTimeSpentSeconds: totalTime,
        revisionCount: revisions.length,
        revisionCorrectCount: revisionCorrect,
        recentAccuracies: recentAccuracies,
      );

      return MapEntry(conceptId, mastery);
    });
  }

  String _getConceptDisplayName(String conceptId) {
    // Convert snake_case to Title Case
    return conceptId
        .split('_')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  List<ConceptMastery> getWeakConcepts() {
    return getConceptMasteries()
        .values
        .where((m) => m.state == MasteryState.weak)
        .toList()
      ..sort((a, b) => a.masteryScore.compareTo(b.masteryScore));
  }

  List<ConceptMastery> getConceptsNeedingPractice() {
    return getConceptMasteries()
        .values
        .where((m) =>
            m.state == MasteryState.weak || m.state == MasteryState.developing)
        .toList()
      ..sort((a, b) => a.state.priority.compareTo(b.state.priority));
  }

  List<ConceptMastery> getConceptsBySubject(String subject) {
    return getConceptMasteries()
        .values
        .where((m) => m.subject == subject)
        .toList()
      ..sort((a, b) => a.state.priority.compareTo(b.state.priority));
  }

  Map<String, double> getSubjectMasteries() {
    final concepts = getConceptMasteries();
    final bySubject = <String, List<ConceptMastery>>{};

    for (final mastery in concepts.values) {
      bySubject.putIfAbsent(mastery.subject, () => []).add(mastery);
    }

    return bySubject.map((subject, masteries) {
      final avg = masteries.map((m) => m.masteryScore).reduce((a, b) => a + b) /
          masteries.length;
      return MapEntry(subject, avg);
    });
  }

  double getOverallMastery() {
    final concepts = getConceptMasteryList();
    if (concepts.isEmpty) return 0.0;
    return concepts.map((m) => m.masteryScore).reduce((a, b) => a + b) /
        concepts.length;
  }

  List<ConceptMastery> getConceptMasteryList() {
    return getConceptMasteries().values.toList()
      ..sort((a, b) => a.state.priority.compareTo(b.state.priority));
  }

  // Study streak tracking
  int getStudyStreak() {
    if (_attempts.isEmpty) return 0;

    final sortedAttempts = List<QuestionAttempt>.from(_attempts)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    int streak = 0;
    DateTime? lastDate;

    for (final attempt in sortedAttempts) {
      final attemptDate = DateTime(
        attempt.timestamp.year,
        attempt.timestamp.month,
        attempt.timestamp.day,
      );

      if (lastDate == null) {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        if (attemptDate == todayDate ||
            attemptDate == todayDate.subtract(const Duration(days: 1))) {
          streak = 1;
          lastDate = attemptDate;
        } else {
          break;
        }
      } else {
        final diff = lastDate.difference(attemptDate).inDays;
        if (diff == 1) {
          streak++;
          lastDate = attemptDate;
        } else {
          break;
        }
      }
    }

    return streak;
  }

  // Time-based analytics
  Map<String, dynamic> getWeeklyProgress() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final thisWeek =
        _attempts.where((a) => a.timestamp.isAfter(weekAgo)).toList();
    final correctThisWeek = thisWeek.where((a) => a.correct).length;

    return {
      'attemptsThisWeek': thisWeek.length,
      'correctThisWeek': correctThisWeek,
      'accuracyThisWeek':
          thisWeek.isNotEmpty ? correctThisWeek / thisWeek.length : 0.0,
      'totalTimeThisWeek':
          thisWeek.map((a) => a.timeSeconds).fold(0, (a, b) => a + b),
    };
  }

  // Exam readiness score (0-100)
  int getExamReadinessScore() {
    final overallMastery = getOverallMastery();
    final streak = getStudyStreak();
    final weekly = getWeeklyProgress();

    // Weighted formula
    final masteryWeight = overallMastery * 0.5;
    final streakWeight = (streak.clamp(0, 7) / 7) * 100 * 0.2;
    final consistencyWeight =
        (weekly['accuracyThisWeek'] as double) * 100 * 0.3;

    return (masteryWeight + streakWeight + consistencyWeight)
        .round()
        .clamp(0, 100);
  }
}
