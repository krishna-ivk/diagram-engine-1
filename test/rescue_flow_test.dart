import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/models/question.dart';
import '../lib/services/content_loader.dart';
import '../lib/services/rescue_system.dart';
import '../lib/services/concept_graph.dart';
import '../lib/screens/question_screen.dart';

void main() {
  group('Rescue Flow Integration Tests', () {
    late List<Question> testQuestions;
    late ConceptGraph conceptGraph;
    late RescueSystem rescueSystem;
    
    setUp(() async {
      // Setup test data
      testQuestions = [
        // Main JEE question
        Question(
          id: 'jee_main_001',
          questionText: 'Find the area of a regular hexagon with side length 4 cm.',
          primaryConcept: 'regular_hexagon_area',
          difficulty: Difficulty.jee,
          questionRole: QuestionRole.main,
          correctAnswer: 'D',
          options: [
            Option(label: 'A', text: '16√3 cm²', isCorrect: false),
            Option(label: 'B', text: '24√3 cm²', isCorrect: false),
            Option(label: 'C', text: '32√3 cm²', isCorrect: false),
            Option(label: 'D', text: '48√3 cm²', isCorrect: true),
          ],
          explanation: 'Area = (3√3/2) × side² = (3√3/2) × 16 = 24√3 cm²',
          prerequisites: ['regular_polygon_basics', 'area_formula'],
          rescueQuestionIds: ['foundation_001', 'bridge_001'],
          diagramRequired: true,
          diagramId: 'hexagon_area',
          reviewStatus: 'published',
        ),
        // Foundation rescue question
        Question(
          id: 'foundation_001',
          questionText: 'What is the central angle of a regular hexagon?',
          primaryConcept: 'hexagon_center_angle',
          difficulty: Difficulty.foundation,
          questionRole: QuestionRole.foundation,
          correctAnswer: 'B',
          options: [
            Option(label: 'A', text: '45°', isCorrect: false),
            Option(label: 'B', text: '60°', isCorrect: true),
            Option(label: 'C', text: '90°', isCorrect: false),
            Option(label: 'D', text: '120°', isCorrect: false),
          ],
          explanation: 'Central angle = 360° ÷ number of sides = 360° ÷ 6 = 60°',
          prerequisites: ['regular_polygon_basics'],
          rescueQuestionIds: [],
          diagramRequired: true,
          diagramId: 'hexagon_center_angle',
          reviewStatus: 'published',
        ),
        // Bridge rescue question
        Question(
          id: 'bridge_001',
          questionText: 'A regular hexagon has side length 2 cm. Find its perimeter.',
          primaryConcept: 'hexagon_perimeter',
          difficulty: Difficulty.bridge,
          questionRole: QuestionRole.bridge,
          correctAnswer: 'C',
          options: [
            Option(label: 'A', text: '8 cm', isCorrect: false),
            Option(label: 'B', text: '10 cm', isCorrect: false),
            Option(label: 'C', text: '12 cm', isCorrect: true),
            Option(label: 'D', text: '14 cm', isCorrect: false),
          ],
          explanation: 'Perimeter = 6 × side length = 6 × 2 = 12 cm',
          prerequisites: ['regular_polygon_basics', 'hexagon_center_angle'],
          rescueQuestionIds: ['foundation_001'],
          diagramRequired: true,
          diagramId: 'hexagon_perimeter',
          reviewStatus: 'published',
        ),
      ];
      
      // Setup concept graph
      conceptGraph = ConceptGraph();
      conceptGraph.addConcept('regular_polygon_basics', 'Basic polygon properties');
      conceptGraph.addConcept('hexagon_center_angle', 'Central angle of hexagon');
      conceptGraph.addConcept('hexagon_perimeter', 'Perimeter of hexagon');
      conceptGraph.addConcept('regular_hexagon_area', 'Area of regular hexagon');
      
      conceptGraph.addPrerequisite('hexagon_center_angle', 'regular_polygon_basics');
      conceptGraph.addPrerequisite('hexagon_perimeter', 'regular_polygon_basics');
      conceptGraph.addPrerequisite('regular_hexagon_area', 'hexagon_center_angle');
      conceptGraph.addPrerequisite('regular_hexagon_area', 'hexagon_perimeter');
      
      // Setup rescue system
      rescueSystem = RescueSystem(
        allQuestions: testQuestions,
        conceptGraph: conceptGraph,
      );
    });
    
    testWidgets('Complete Rescue Flow Test', (WidgetTester tester) async {
      // Create test widget
      await tester.pumpWidget(
        MaterialApp(
          home: QuestionScreen(
            questions: testQuestions,
            sessionType: SessionType.practice,
            onSessionComplete: (results) {},
            onExit: () {},
          ),
        ),
      );
      
      // Verify initial state
      expect(find.text('Find the area of a regular hexagon with side length 4 cm.'), findsOneWidget);
      expect(find.text('Smart Rescue'), findsOneWidget);
      
      // Step 1: Answer incorrectly to trigger rescue
      await tester.tap(find.text('A')); // Wrong answer
      await tester.pumpAndSettle();
      
      // Step 2: Verify rescue dialog appears
      expect(find.text('Smart Rescue Available'), findsOneWidget);
      expect(find.text('Let\'s build up to this with easier questions'), findsOneWidget);
      
      // Step 3: Accept rescue
      await tester.tap(find.text('Start Rescue'));
      await tester.pumpAndSettle();
      
      // Step 4: Verify foundation question is loaded
      expect(find.text('What is the central angle of a regular hexagon?'), findsOneWidget);
      expect(find.text('Foundation Question'), findsOneWidget);
      
      // Step 5: Answer foundation question correctly
      await tester.tap(find.text('B')); // Correct answer
      await tester.pumpAndSettle();
      
      // Step 6: Verify bridge question is loaded
      expect(find.text('A regular hexagon has side length 2 cm. Find its perimeter.'), findsOneWidget);
      expect(find.text('Bridge Question'), findsOneWidget);
      
      // Step 7: Answer bridge question correctly
      await tester.tap(find.text('C')); // Correct answer
      await tester.pumpAndSettle();
      
      // Step 8: Verify return to original question
      expect(find.text('Find the area of a regular hexagon with side length 4 cm.'), findsOneWidget);
      expect(find.text('Ready to try the original question again?'), findsOneWidget);
      
      // Step 9: Answer original question correctly
      await tester.tap(find.text('D')); // Correct answer
      await tester.pumpAndSettle();
      
      // Step 10: Verify success
      expect(find.text('Correct!'), findsOneWidget);
      expect(find.text('48√3 cm²'), findsOneWidget);
    });
    
    test('Rescue System Logic', () async {
      final mainQuestion = testQuestions.first;
      
      // Test rescue question generation
      final rescueQuestions = rescueSystem.generateRescueQuestions(mainQuestion);
      
      expect(rescueQuestions.length, 2, reason: 'Should generate 2 rescue questions');
      expect(rescueQuestions[0].questionRole, QuestionRole.foundation, reason: 'First should be foundation');
      expect(rescueQuestions[1].questionRole, QuestionRole.bridge, reason: 'Second should be bridge');
      
      // Test concept gap analysis
      final gaps = rescueSystem.analyzeConceptGaps(mainQuestion);
      expect(gaps.isNotEmpty, reason: 'Should identify concept gaps');
      expect(gaps.contains('regular_polygon_basics'), reason: 'Should identify missing prerequisite');
    });
    
    test('Content Loader Integration', () async {
      final loader = ContentLoader();
      
      // Test loading geometry rescue ladder
      final rescueLadder = await loader.loadGeometryRescueLadder();
      
      expect(rescueLadder.isNotEmpty, reason: 'Should load rescue ladder');
      expect(rescueLadder.length, 3, reason: 'Should have 3 questions in ladder');
      
      // Verify ladder progression
      expect(rescueLadder[0].questionRole, QuestionRole.foundation, reason: 'First should be foundation');
      expect(rescueLadder[1].questionRole, QuestionRole.bridge, reason: 'Second should be bridge');
      expect(rescueLadder[2].questionRole, QuestionRole.jee, reason: 'Third should be JEE pattern');
      
      // Verify concept progression
      expect(rescueLadder[0].primaryConcept, 'square_center_angle', reason: 'Foundation should be basic');
      expect(rescueLadder[1].primaryConcept, 'hexagon_center_angle', reason: 'Bridge should be intermediate');
      expect(rescueLadder[2].primaryConcept, 'octagon_center_angle', reason: 'JEE should be advanced');
    });
    
    test('Mock Exam Mode Disables Rescue', (WidgetTester tester) async {
      // Create test widget in mock exam mode
      await tester.pumpWidget(
        MaterialApp(
          home: QuestionScreen(
            questions: testQuestions,
            sessionType: SessionType.mockExam,
            onSessionComplete: (results) {},
            onExit: () {},
          ),
        ),
      );
      
      // Verify rescue is disabled in mock exam mode
      expect(find.text('Smart Rescue'), findsNothing, reason: 'Rescue should be disabled in mock exam');
      
      // Answer incorrectly
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      
      // Verify no rescue dialog appears
      expect(find.text('Smart Rescue Available'), findsNothing, reason: 'No rescue dialog in mock exam');
      expect(find.text('Incorrect!'), findsOneWidget, reason: 'Should show incorrect feedback');
    });
    
    test('Rescue Progress Tracking', () async {
      final mainQuestion = testQuestions.first;
      
      // Test progress tracking
      final progress = rescueSystem.trackRescueProgress(mainQuestion, []);
      expect(progress.currentLevel, 0, reason: 'Should start at level 0');
      expect(progress.totalLevels, 2, reason: 'Should have 2 rescue levels');
      expect(progress.isComplete, false, reason: 'Should not be complete initially');
      
      // Simulate completing foundation question
      final progress2 = rescueSystem.trackRescueProgress(mainQuestion, ['foundation_001']);
      expect(progress2.currentLevel, 1, reason: 'Should advance to level 1');
      expect(progress2.isComplete, false, reason: 'Should not be complete yet');
      
      // Simulate completing both rescue questions
      final progress3 = rescueSystem.trackRescueProgress(mainQuestion, ['foundation_001', 'bridge_001']);
      expect(progress3.currentLevel, 2, reason: 'Should advance to level 2');
      expect(progress3.isComplete, true, reason: 'Should be complete');
    });
    
    test('Rescue Question Quality Validation', () async {
      final loader = ContentLoader();
      
      // Test mock rescue question creation
      final mockRescue = loader.createMockRescueQuestion(
        id: 'mock_test_001',
        text: 'What is the sum of interior angles of a triangle?',
        primaryConcept: 'triangle_interior_sum',
        correctAnswer: 'C',
        difficulty: 'foundation',
        questionRole: 'foundation',
      );
      
      expect(mockRescue.id, 'mock_test_001');
      expect(mockRescue.questionText, 'What is the sum of interior angles of a triangle?');
      expect(mockRescue.primaryConcept, 'triangle_interior_sum');
      expect(mockRescue.correctAnswer, 'C');
      expect(mockRescue.difficulty, Difficulty.foundation);
      expect(mockRescue.questionRole, QuestionRole.foundation);
      expect(mockRescue.options.length, 4, reason: 'Should have 4 options');
      expect(mockRescue.explanation.isNotEmpty, reason: 'Should have explanation');
      expect(mockRescue.reviewStatus, 'published', reason: 'Should be published');
    });
    
    test('Rescue System Error Handling', () async {
      // Test with missing rescue questions
      final incompleteQuestions = [
        Question(
          id: 'incomplete_001',
          questionText: 'Question without rescue',
          primaryConcept: 'test_concept',
          difficulty: Difficulty.jee,
          questionRole: QuestionRole.main,
          correctAnswer: 'A',
          options: [Option(label: 'A', text: 'Answer', isCorrect: true)],
          explanation: 'Explanation',
          rescueQuestionIds: ['missing_001', 'missing_002'], // Non-existent rescue questions
          reviewStatus: 'published',
        ),
      ];
      
      final incompleteRescueSystem = RescueSystem(
        allQuestions: incompleteQuestions,
        conceptGraph: conceptGraph,
      );
      
      final rescueQuestions = incompleteRescueSystem.generateRescueQuestions(incompleteQuestions.first);
      expect(rescueQuestions.isEmpty, reason: 'Should handle missing rescue questions gracefully');
    });
  });
  
  group('Rescue Flow Performance Tests', () {
    test('Large Question Set Performance', () async {
      // Create large question set
      final largeQuestionSet = <Question>[];
      for (int i = 0; i < 100; i++) {
        largeQuestionSet.add(Question(
          id: 'large_test_$i',
          questionText: 'Test question $i',
          primaryConcept: 'test_concept_$i',
          difficulty: Difficulty.foundation,
          questionRole: QuestionRole.main,
          correctAnswer: 'A',
          options: [Option(label: 'A', text: 'Answer', isCorrect: true)],
          explanation: 'Explanation $i',
          reviewStatus: 'published',
        ));
      }
      
      final stopwatch = Stopwatch()..start();
      
      final rescueSystem = RescueSystem(
        allQuestions: largeQuestionSet,
        conceptGraph: ConceptGraph(),
      );
      
      // Test rescue question generation performance
      for (final question in largeQuestionSet.take(10)) {
        rescueSystem.generateRescueQuestions(question);
      }
      
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds < 1000, reason: 'Rescue generation should be fast');
    });
  });
}