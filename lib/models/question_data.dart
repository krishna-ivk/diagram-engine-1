import 'diagram_data.dart';

class QuestionData {
  final String id;
  final String text;
  final DiagramData diagram;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final String subject;
  final String topic;

  const QuestionData({
    required this.id,
    required this.text,
    required this.diagram,
    required this.options,
    required this.correctIndex,
    this.explanation,
    required this.subject,
    required this.topic,
  });
}
