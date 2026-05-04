class QuestionAttempt {
  final String questionId;
  final String topic;
  final String coreConcept;
  final bool correct;
  final int timeSeconds;
  final int tapCount;
  final int hintsUsed;
  final DateTime timestamp;

  const QuestionAttempt({
    required this.questionId,
    required this.topic,
    required this.coreConcept,
    required this.correct,
    required this.timeSeconds,
    required this.tapCount,
    required this.hintsUsed,
    required this.timestamp,
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
    return getTopicPerformance()
        .values
        .where((p) => p.isWeak)
        .toList()
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
  }

  List<TopicPerformance> getAreasNeedingPractice() {
    return getTopicPerformance()
        .values
        .where((p) => p.needsPractice)
        .toList()
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
}
