import 'diagram_data.dart';

enum Difficulty { easy, medium, hard }

class RevealStep {
  final String text;
  final List<String>? highlightIds;
  final bool? showHints;

  const RevealStep({
    required this.text,
    this.highlightIds,
    this.showHints,
  });
}

class QuestionData {
  final String id;
  final String text;
  final DiagramData diagram;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final String subject;
  final String topic;
  final List<RevealStep> revealSteps;

  // Concept tagging
  final String? coreConcept;
  final Difficulty difficulty;
  final int? estimatedSeconds;

  // Exam relevance
  final bool frequentlyAsked;
  final bool highWeightTopic;
  final String? commonMistake;

  // Practice reinforcement
  final List<String> similarQuestionIds;

  const QuestionData({
    required this.id,
    required this.text,
    required this.diagram,
    required this.options,
    required this.correctIndex,
    this.explanation,
    required this.subject,
    required this.topic,
    this.revealSteps = const [],
    this.coreConcept,
    this.difficulty = Difficulty.medium,
    this.estimatedSeconds,
    this.frequentlyAsked = false,
    this.highWeightTopic = false,
    this.commonMistake,
    this.similarQuestionIds = const [],
  });
}
