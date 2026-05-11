import 'diagram_data.dart';

enum Difficulty { easy, medium, hard }

enum ExamType { jeeMain, jeeAdvanced, neet, cbse, olympiad, custom }

enum QuestionType { mcq, integer, multipleCorrect, assertionReason, comprehension }

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
  // Core identification
  final String id;
  final String text;
  final DiagramData diagram;

  // Answer data
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  // Content taxonomy
  final String subject;
  final String chapter;
  final String topic;
  final String primaryConcept;
  final List<String> secondaryConcepts;
  final List<String> prerequisites;

  // Exam metadata
  final ExamType exam;
  final String classLevel;
  final QuestionType questionType;
  final Difficulty difficulty;
  final int? estimatedSeconds;

  // Learning metadata
  final List<RevealStep> revealSteps;
  final List<String> solutionSteps;
  final String? commonMistake;
  final List<String> mistakePatterns;

  // Exam relevance
  final bool frequentlyAsked;
  final bool highWeightTopic;
  final int? yearAsked;
  final String? source;

  // Content management
  final List<String> tags;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Cross-references
  final List<String> similarQuestionIds;

  // Backward compatibility getter
  String get effectivePrimaryConcept =>
      primaryConcept.isNotEmpty ? primaryConcept : (coreConcept ?? topic);

  const QuestionData({
    required this.id,
    required this.text,
    required this.diagram,
    required this.options,
    required this.correctIndex,
    this.explanation,

    // Content taxonomy
    required this.subject,
    this.chapter = '',
    required this.topic,
    this.primaryConcept = '',
    this.secondaryConcepts = const [],
    this.prerequisites = const [],

    // Exam metadata
    this.exam = ExamType.jeeMain,
    this.classLevel = 'Class 9-12',
    this.questionType = QuestionType.mcq,
    this.difficulty = Difficulty.medium,
    this.estimatedSeconds,

    // Learning metadata
    this.revealSteps = const [],
    this.solutionSteps = const [],
    this.commonMistake,
    this.mistakePatterns = const [],

    // Exam relevance
    this.frequentlyAsked = false,
    this.highWeightTopic = false,
    this.yearAsked,
    this.source,

    // Content management
    this.tags = const [],
    this.isPublished = true,
    this.createdAt,
    this.updatedAt,

    // Cross-references
    this.similarQuestionIds = const [],
  });
}

// Legacy alias for backward compatibility
typedef ConceptCore = String;
