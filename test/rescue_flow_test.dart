import 'package:flutter_test/flutter_test.dart';

import '../lib/models/concept_graph.dart';
import '../lib/models/diagram_data.dart';
import '../lib/models/question_data.dart';
import '../lib/models/rescue_system.dart';
import '../lib/services/content_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RescueSystem', () {
    late List<QuestionData> questions;
    late ConceptGraph conceptGraph;
    late RescueSystem rescueSystem;

    setUp(() {
      questions = [
        _question(
          id: 'main_hexagon_area',
          text: 'Find the area of a regular hexagon.',
          topic: 'Regular Polygons',
          primaryConcept: 'regular_hexagon_area',
          difficulty: Difficulty.hard,
          prerequisites: ['hexagon_center_angle', 'hexagon_perimeter'],
        ),
        _question(
          id: 'foundation_center_angle',
          text: 'What is the central angle of a regular hexagon?',
          topic: 'Regular Polygons',
          primaryConcept: 'hexagon_center_angle',
          difficulty: Difficulty.easy,
        ),
        _question(
          id: 'foundation_perimeter',
          text: 'What is the perimeter of a regular hexagon with side 2?',
          topic: 'Regular Polygons',
          primaryConcept: 'hexagon_perimeter',
          difficulty: Difficulty.easy,
        ),
      ];

      conceptGraph = const ConceptGraph(
        nodes: {
          'regular_hexagon_area': ConceptNode(
            id: 'regular_hexagon_area',
            name: 'Regular Hexagon Area',
            subject: 'Mathematics',
            chapter: 'Geometry',
            prerequisites: ['hexagon_center_angle', 'hexagon_perimeter'],
          ),
          'hexagon_center_angle': ConceptNode(
            id: 'hexagon_center_angle',
            name: 'Hexagon Center Angle',
            subject: 'Mathematics',
            chapter: 'Geometry',
          ),
          'hexagon_perimeter': ConceptNode(
            id: 'hexagon_perimeter',
            name: 'Hexagon Perimeter',
            subject: 'Mathematics',
            chapter: 'Geometry',
          ),
        },
      );

      rescueSystem = RescueSystem(
        allQuestions: questions,
        conceptGraph: conceptGraph,
      );
    });

    test('builds a rescue path from question prerequisites', () {
      final rescuePath = rescueSystem.getRescuePath(questions.first);

      expect(rescuePath, isNotEmpty);
      expect(
        rescuePath.map((rescue) => rescue.question.id),
        containsAll(['foundation_center_angle', 'foundation_perimeter']),
      );
      expect(
        rescuePath.map((rescue) => rescue.reason),
        contains(startsWith('Question prerequisite:')),
      );
    });

    test('falls back to concept graph prerequisites', () {
      final failedQuestion = _question(
        id: 'main_without_local_prereqs',
        text: 'Find the area of a regular hexagon.',
        topic: 'Regular Polygons',
        primaryConcept: 'regular_hexagon_area',
        difficulty: Difficulty.hard,
      );

      final rescuePath = rescueSystem.getRescuePath(failedQuestion);

      expect(rescuePath, isNotEmpty);
      expect(
        rescuePath.map((rescue) => rescue.question.id),
        contains('foundation_center_angle'),
      );
      expect(
        rescuePath.map((rescue) => rescue.reason),
        contains(startsWith('Prerequisite concept:')),
      );
    });

    test('returns no rescue questions when no easier support exists', () {
      final emptySystem = RescueSystem(
        allQuestions: [
          _question(
            id: 'isolated_question',
            text: 'Isolated hard question',
            topic: 'Unknown',
            primaryConcept: 'unknown_concept',
            difficulty: Difficulty.hard,
            prerequisites: ['missing_concept'],
          ),
        ],
        conceptGraph: const ConceptGraph(),
      );

      final rescuePath = emptySystem.getRescuePath(emptySystem.allQuestions.first);

      expect(rescuePath, isEmpty);
    });
  });

  group('ContentLoader', () {
    test('loads curated geometry rescue ladder from assets', () async {
      final rescueQuestions = await ContentLoader.loadGeometryRescueLadder();

      expect(rescueQuestions.length, 3);
      expect(rescueQuestions.first.id, isNotEmpty);
      expect(rescueQuestions.first.text, isNotEmpty);
      expect(rescueQuestions.first.primaryConcept, 'square_center_angle');
    });

    test('creates mock rescue questions with current QuestionData fields', () {
      final mockQuestion = ContentLoader.createMockRescueQuestion(
        id: 'mock_foundation_001',
        text: 'What is the central angle of a square?',
        primaryConcept: 'square_center_angle',
        correctIndex: 1,
        difficulty: 'easy',
      );

      expect(mockQuestion.id, 'mock_foundation_001');
      expect(mockQuestion.text, 'What is the central angle of a square?');
      expect(mockQuestion.primaryConcept, 'square_center_angle');
      expect(mockQuestion.correctIndex, 1);
      expect(mockQuestion.difficulty, Difficulty.easy);
      expect(mockQuestion.options.length, 4);
      expect(mockQuestion.isPublished, isTrue);
    });
  });
}

QuestionData _question({
  required String id,
  required String text,
  required String topic,
  required String primaryConcept,
  required Difficulty difficulty,
  List<String> prerequisites = const [],
}) {
  return QuestionData(
    id: id,
    text: text,
    diagram: DiagramData(
      id: '${id}_diagram',
      type: DiagramType.geometry,
      elements: const [],
    ),
    options: const ['A', 'B', 'C', 'D'],
    correctIndex: 0,
    explanation: 'Explanation',
    subject: 'Mathematics',
    chapter: 'Geometry',
    topic: topic,
    primaryConcept: primaryConcept,
    prerequisites: prerequisites,
    difficulty: difficulty,
    estimatedSeconds: 60,
    revealSteps: const [
      RevealStep(text: 'Read the known values.'),
    ],
    solutionSteps: const ['Read the known values.'],
    whyWrongExplanations: const {
      1: 'This option uses the wrong concept.',
      2: 'This option has a calculation slip.',
      3: 'This option confuses perimeter with area.',
    },
    coreConcept: primaryConcept,
  );
}
