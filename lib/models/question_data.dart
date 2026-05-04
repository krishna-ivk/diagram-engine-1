import 'diagram_data.dart';

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
  });
}
