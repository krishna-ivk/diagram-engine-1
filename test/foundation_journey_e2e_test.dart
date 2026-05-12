import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diagram_engine/screens/foundation_journey_screen.dart';
import 'package:diagram_engine/screens/foundation_journey_question_screen.dart';
import 'package:diagram_engine/models/foundation_journey.dart';
import 'package:diagram_engine/models/journey_progression_engine.dart';
import 'package:diagram_engine/models/journey_state.dart';
import 'package:diagram_engine/models/performance_tracker.dart';
import 'package:diagram_engine/models/premium_state.dart';
import 'package:diagram_engine/models/student_profile.dart';
import 'package:diagram_engine/models/question_attempt.dart';
import 'package:diagram_engine/services/content_loader.dart';
import 'package:diagram_engine/services/journey_persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Foundation Journey End-to-End Test', () {
    late JourneyProgressionEngine engine;
    late PerformanceTracker tracker;
    late PremiumState premiumState;
    late JourneyPersistence persistence;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      engine = JourneyProgressionEngine();
      tracker = PerformanceTracker();
      premiumState = PremiumState();
      persistence = JourneyPersistence();
      
      // Load the journey content
      await engine.loadJourney('geometry_foundation_journey');
    });

    testWidgets('should complete full journey from L0 to L5', (tester) async {
      // Start the foundation journey
      await tester.pumpWidget(
        MaterialApp(
          home: FoundationJourneyScreen(
            journeyId: 'geometry_foundation_journey',
            tracker: tracker,
            premiumState: premiumState,
          ),
        ),
      );

      // Wait for journey to load
      await tester.pumpAndSettle();

      // Should show the first level (L0)
      expect(find.text('From Square to JEE Octagon'), findsOneWidget);
      expect(find.text('Familiar: Square Parts'), findsOneWidget);
      
      // Tap to start L0
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      // Should load first question
      expect(find.textContaining('square is divided into 4 equal triangles'), findsOneWidget);
      
      // Answer the first question correctly (option B = 1/4)
      await tester.tap(find.text('1/4'));
      await tester.pumpAndSettle();

      // Should show confidence selector
      expect(find.text('How confident are you?'), findsOneWidget);
      
      // Select high confidence
      await tester.tap(find.text('Very Sure'));
      await tester.pumpAndSettle();

      // Confirm answer
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Should show correct answer dialog
      expect(find.text('Correct!'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should load second question
      expect(find.textContaining('square has side length 4 cm'), findsOneWidget);
      
      // Answer correctly (option B = 8√2 cm)
      await tester.tap(find.text('8√2 cm'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Very Sure'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should load third question
      expect(find.textContaining('area of one triangle is 9 cm²'), findsOneWidget);
      
      // Answer correctly (option A = 24 cm)
      await tester.tap(find.text('24 cm'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Very Sure'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should complete L0 and show level complete
      expect(find.text('Level Complete!'), findsOneWidget);
      await tester.tap(find.text('Continue to Next Level'));
      await tester.pumpAndSettle();

      // Should now be on L1
      expect(find.text('Foundation: Central Angles'), findsOneWidget);
      
      // Continue through L1 questions
      for (int i = 0; i < 3; i++) {
        await tester.pumpAndSettle();
        
        // Find and tap an answer option
        final answerOption = find.byType(RadioListTile<int>).first;
        await tester.tap(answerOption);
        await tester.pumpAndSettle();
        
        // Confirm confidence and answer
        await tester.tap(find.text('Very Sure'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      // Should complete L1 and move to L2
      if (find.text('Level Complete!').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue to Next Level'));
        await tester.pumpAndSettle();
      }

      // Verify journey progress is saved
      final savedState = await persistence.loadJourneyState('geometry_foundation_journey');
      expect(savedState, isNotNull);
      expect(savedState!.journeyId, equals('geometry_foundation_journey'));
      expect(savedState.attempts.length, greaterThan(6)); // At least 6 attempts from L0+L1

      // Verify attempts are tracked in PerformanceTracker
      expect(tracker.attempts.length, greaterThan(6));
    });

    testWidgets('should handle incorrect answers with rescue flow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FoundationJourneyScreen(
            journeyId: 'geometry_foundation_journey',
            tracker: tracker,
            premiumState: premiumState,
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Start L0
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      // Answer incorrectly (option A = 1/2)
      await tester.tap(find.text('1/2'));
      await tester.pumpAndSettle();

      // Select low confidence
      await tester.tap(find.text('Not Sure'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Should show incorrect answer dialog with explanation
      expect(find.text('Not quite right'), findsOneWidget);
      expect(find.textContaining('1/2 would mean only 2 parts'), findsOneWidget);
      
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should still be on same level for another attempt
      expect(find.textContaining('square is divided into 4 equal triangles'), findsOneWidget);
    });

    testWidgets('should load saved progress when returning to journey', (tester) async {
      // First, create some saved progress
      final studentState = StudentJourneyState(
        journeyId: 'geometry_foundation_journey',
        studentId: 'test_student',
        currentLevelIndex: 2, // L2
        attempts: [
          QuestionAttempt(
            questionId: 'class7_square_parts_001',
            isCorrect: true,
            confidenceLevel: ConfidenceLevel.verySure,
            timeSpentSeconds: 30,
            timestamp: DateTime.now(),
            levelIndex: 0,
          ),
        ],
        levelProgress: {
          'L0': LevelProgress(isUnlocked: true, isCompleted: true),
          'L1': LevelProgress(isUnlocked: true, isCompleted: true),
          'L2': LevelProgress(isUnlocked: true, isCompleted: false),
        },
        journeyStartTime: DateTime.now().subtract(Duration(minutes: 10)),
        lastActivityTime: DateTime.now(),
      );

      await persistence.saveJourneyState(studentState);

      // Now start the journey
      await tester.pumpWidget(
        MaterialApp(
          home: FoundationJourneyScreen(
            journeyId: 'geometry_foundation_journey',
            tracker: tracker,
            premiumState: premiumState,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show saved progress - L2 should be unlocked
      expect(find.text('Bridge: Hexagon Challenge'), findsOneWidget);
      
      // L0 and L1 should be marked as completed
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('should validate all question content loads correctly', (tester) async {
      // Test that all 18 questions can be loaded
      final questions = await ContentLoader.loadJourneyQuestions('geometry_foundation_journey');
      expect(questions.length, equals(18));

      // Verify each level has 3 questions
      final journey = await engine.loadJourney('geometry_foundation_journey');
      for (final level in journey.levels) {
        expect(level.questionIds.length, equals(3));
        
        // Verify each question ID exists in content
        for (final questionId in level.questionIds) {
          expect(questions.containsKey(questionId), isTrue, 
                 reason: 'Question $questionId not found in content');
        }
      }
    });
  });
}