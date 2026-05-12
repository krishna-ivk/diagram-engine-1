enum TopicMasteryLevel {
  notStarted,
  beginner,
  developing,
  proficient,
  mastered,
}

class TopicCapsule {
  final String topicId;
  final String title;
  final String classLevel;
  final String targetExamBridge;
  final List<SynopsisCard> synopsisCards;
  final List<String> formulae;
  final List<String> commonMistakes;
  final List<String> starterQuestionIds;
  final List<String> practiceQuestionIds;
  final List<String> challengeQuestionIds;
  final List<String> jeeStyleQuestionIds;
  final List<String> revisionQuestionIds;
  final List<String> manipulatives;
  final int estimatedDurationMinutes;

  TopicCapsule({
    required this.topicId,
    required this.title,
    required this.classLevel,
    required this.targetExamBridge,
    required this.synopsisCards,
    required this.formulae,
    required this.commonMistakes,
    required this.starterQuestionIds,
    required this.practiceQuestionIds,
    required this.challengeQuestionIds,
    this.jeeStyleQuestionIds = const [],
    required this.revisionQuestionIds,
    required this.manipulatives,
    required this.estimatedDurationMinutes,
  });

  factory TopicCapsule.fromJson(Map<String, dynamic> json) {
    return TopicCapsule(
      topicId: json['topic_id'] as String,
      title: json['title'] as String,
      classLevel: json['class_level'] as String,
      targetExamBridge: json['target_exam_bridge'] as String,
      synopsisCards: (json['synopsis_cards'] as List<dynamic>)
          .map((e) => SynopsisCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      formulae:
          (json['formulae'] as List<dynamic>).map((e) => e.toString()).toList(),
      commonMistakes: (json['common_mistakes'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      starterQuestionIds: (json['starter_question_ids'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      practiceQuestionIds: (json['practice_question_ids'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      challengeQuestionIds: (json['challenge_question_ids'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      jeeStyleQuestionIds: (json['jee_style_question_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      revisionQuestionIds: (json['revision_question_ids'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      manipulatives: (json['manipulatives'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int,
    );
  }
}

class SynopsisCard {
  final String title;
  final String body;

  SynopsisCard({
    required this.title,
    required this.body,
  });

  factory SynopsisCard.fromJson(Map<String, dynamic> json) {
    return SynopsisCard(
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}
