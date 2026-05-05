import 'package:flutter/foundation.dart';

/// A question scheduled for revision with spaced repetition intervals.
class RevisionItem {
  final String questionId;
  final String topic;
  final String coreConcept;
  final DateTime addedAt;
  DateTime nextReviewAt;
  int interval; // in days: 1, 3, 7, 14, 30
  int streak; // consecutive correct reviews
  bool lastReviewCorrect;

  RevisionItem({
    required this.questionId,
    required this.topic,
    required this.coreConcept,
    required this.addedAt,
    DateTime? nextReviewAt,
    this.interval = 1,
    this.streak = 0,
    this.lastReviewCorrect = false,
  }) : nextReviewAt = nextReviewAt ?? addedAt;

  bool get isDueToday {
    final now = DateTime.now();
    return !nextReviewAt.isAfter(now);
  }

  bool get isDueSoon {
    final now = DateTime.now();
    return nextReviewAt.isBefore(now.add(const Duration(hours: 24)));
  }

  /// Advance interval on correct review (spaced repetition).
  void markCorrect() {
    streak++;
    lastReviewCorrect = true;
    // Intervals: 1 → 3 → 7 → 14 → 30 → done (mastered)
    if (interval < 3) {
      interval = 3;
    } else if (interval < 7) {
      interval = 7;
    } else if (interval < 14) {
      interval = 14;
    } else if (interval < 30) {
      interval = 30;
    }
    nextReviewAt = DateTime.now().add(Duration(days: interval));
  }

  /// Reset interval on wrong review.
  void markWrong() {
    streak = 0;
    lastReviewCorrect = false;
    interval = 1;
    nextReviewAt = DateTime.now().add(const Duration(days: 1));
  }

  bool get isMastered => interval >= 30 && streak >= 3;

  String get statusLabel {
    if (isMastered) return 'Mastered';
    if (isDueToday) return 'Due today';
    if (isDueSoon) return 'Due soon';
    return 'Scheduled';
  }
}

/// Manages the revision queue with spaced repetition logic.
class RevisionManager extends ChangeNotifier {
  final Map<String, RevisionItem> _items = {};

  List<RevisionItem> get allItems => _items.values.toList();

  List<RevisionItem> get dueItems =>
      _items.values.where((item) => item.isDueToday).toList()
        ..sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));

  List<RevisionItem> get dueSoonItems =>
      _items.values.where((item) => item.isDueSoon).toList();

  List<RevisionItem> get masteredItems =>
      _items.values.where((item) => item.isMastered).toList();

  int get dueCount => dueItems.length;

  int get estimatedMinutes => (dueCount * 2).clamp(0, 60);

  bool isMarkedForRevision(String questionId) =>
      _items.containsKey(questionId);

  void addToRevision({
    required String questionId,
    required String topic,
    required String coreConcept,
  }) {
    if (_items.containsKey(questionId)) return;
    _items[questionId] = RevisionItem(
      questionId: questionId,
      topic: topic,
      coreConcept: coreConcept,
      addedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void removeFromRevision(String questionId) {
    _items.remove(questionId);
    notifyListeners();
  }

  void toggleRevision({
    required String questionId,
    required String topic,
    required String coreConcept,
  }) {
    if (_items.containsKey(questionId)) {
      removeFromRevision(questionId);
    } else {
      addToRevision(
        questionId: questionId,
        topic: topic,
        coreConcept: coreConcept,
      );
    }
  }

  /// Called after answering a revision question.
  void recordReviewResult(String questionId, bool correct) {
    final item = _items[questionId];
    if (item == null) return;
    if (correct) {
      item.markCorrect();
    } else {
      item.markWrong();
    }
    notifyListeners();
  }

  /// Auto-add wrong answers to revision queue.
  void autoAddWrongAnswer({
    required String questionId,
    required String topic,
    required String coreConcept,
  }) {
    addToRevision(
      questionId: questionId,
      topic: topic,
      coreConcept: coreConcept,
    );
  }

  /// Get questions due for a given topic.
  List<RevisionItem> getDueForTopic(String topic) =>
      dueItems.where((item) => item.topic == topic).toList();

  /// Summary for display.
  Map<String, int> getTopicBreakdown() {
    final breakdown = <String, int>{};
    for (final item in dueItems) {
      breakdown[item.topic] = (breakdown[item.topic] ?? 0) + 1;
    }
    return breakdown;
  }
}
