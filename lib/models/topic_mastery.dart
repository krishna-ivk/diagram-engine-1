class TopicMastery {
  final String topicId;
  final int totalAttempts;
  final int correctCount;
  final double masteryScore;
  final Map<String, int> misconceptionCounts;

  const TopicMastery({
    required this.topicId,
    required this.totalAttempts,
    required this.correctCount,
    required this.masteryScore,
    required this.misconceptionCounts,
  });

  Map<String, dynamic> toJson() {
    return {
      'topicId': topicId,
      'totalAttempts': totalAttempts,
      'correctCount': correctCount,
      'masteryScore': masteryScore,
      'misconceptionCounts': misconceptionCounts,
    };
  }

  factory TopicMastery.fromJson(Map<String, dynamic> json) {
    return TopicMastery(
      topicId: json['topicId'] as String,
      totalAttempts: json['totalAttempts'] as int,
      correctCount: json['correctCount'] as int,
      masteryScore: (json['masteryScore'] as num).toDouble(),
      misconceptionCounts: Map<String, int>.from(json['misconceptionCounts'] as Map),
    );
  }

  TopicMastery copyWith({
    String? topicId,
    int? totalAttempts,
    int? correctCount,
    double? masteryScore,
    Map<String, int>? misconceptionCounts,
  }) {
    return TopicMastery(
      topicId: topicId ?? this.topicId,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      correctCount: correctCount ?? this.correctCount,
      masteryScore: masteryScore ?? this.masteryScore,
      misconceptionCounts: misconceptionCounts ?? this.misconceptionCounts,
    );
  }

  // Convenience getters
  double get accuracy => totalAttempts > 0 ? correctCount / totalAttempts : 0.0;
  int get incorrectCount => totalAttempts - correctCount;
  int get totalMisconceptions => misconceptionCounts.values.fold(0, (sum, count) => sum + count);
  
  String get mostCommonMisconception {
    if (misconceptionCounts.isEmpty) return '';
    
    String mostCommon = '';
    int maxCount = 0;
    
    misconceptionCounts.forEach((misconception, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommon = misconception;
      }
    });
    
    return mostCommon;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TopicMastery &&
        other.topicId == topicId &&
        other.totalAttempts == totalAttempts &&
        other.correctCount == correctCount &&
        other.masteryScore == masteryScore &&
        other.misconceptionCounts == misconceptionCounts;
  }

  @override
  int get hashCode {
    return topicId.hashCode ^
        totalAttempts.hashCode ^
        correctCount.hashCode ^
        masteryScore.hashCode ^
        misconceptionCounts.hashCode;
  }

  @override
  String toString() {
    return 'TopicMastery(topicId: $topicId, masteryScore: $masteryScore, accuracy: ${(accuracy * 100).toStringAsFixed(1)}%)';
  }
}