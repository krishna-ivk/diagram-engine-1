import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_engine/services/attempt_tracker.dart';
import 'package:diagram_engine/services/mastery_tracker.dart';
import 'package:diagram_engine/services/reinforcement_selector.dart';
import 'package:diagram_engine/models/student_attempt.dart';
import 'package:diagram_engine/models/topic_mastery.dart';
import 'package:diagram_engine/models/drill_session.dart';
import 'package:diagram_engine/models/question_data.dart';

void main() {
  group('Adaptive QA System Tests', () {
    late StudentAttempt testAttempt;
    late String testTopicId;

    setUp(() async {
      testTopicId = 'math.geometry.central_angle_regular_polygon';
      testAttempt = StudentAttempt(
        questionId: 'fundamental_central_angle_square_001',
        topicId: testTopicId,
        selectedIndex: 0,
        isCorrect: false,
        timeTakenSeconds: 45,
        misconceptionCode: 'confuses_with_octagon',
        attemptedAt: DateTime.now(),
      );
      
      // Initialize services
      await AttemptTracker.initialize();
      await MasteryTracker.initialize();
    });

    tearDown(() async {
      // Clean up test data
      await AttemptTracker.clearAllAttempts();
    });

    group('AttemptTracker Tests', () {
      test('should record attempt successfully', () async {
        await AttemptTracker.recordAttempt(testAttempt);
        
        final attempts = await AttemptTracker.getAllAttempts();
        expect(attempts.length, 1);
        expect(attempts.first.questionId, testAttempt.questionId);
        expect(attempts.first.isCorrect, testAttempt.isCorrect);
      });

      test('should get attempts for topic', () async {
        await AttemptTracker.recordAttempt(testAttempt);
        
        final topicAttempts = await AttemptTracker.getAttemptsForTopic(testTopicId);
        expect(topicAttempts.length, 1);
        expect(topicAttempts.first.topicId, testTopicId);
      });

      test('should track misconceptions correctly', () async {
        // Record multiple attempts with same misconception
        await AttemptTracker.recordAttempt(testAttempt);
        await AttemptTracker.recordAttempt(testAttempt.copyWith(
          questionId: 'fundamental_central_angle_square_002',
          attemptedAt: DateTime.now().add(const Duration(seconds: 1)),
        ));
        
        final misconceptions = await AttemptTracker.getMisconceptionsForTopic(testTopicId);
        expect(misconceptions['confuses_with_octagon'], 2);
      });

      test('should identify repeated misconceptions', () async {
        // Record 3 attempts with same misconception
        for (int i = 0; i < 3; i++) {
          await AttemptTracker.recordAttempt(testAttempt.copyWith(
            questionId: 'question_$i',
            attemptedAt: DateTime.now().add(Duration(seconds: i)),
          ));
        }
        
        final repeated = await AttemptTracker.getRepeatedMisconceptions();
        expect(repeated['confuses_with_octagon'], 3);
      });

      test('should calculate topic statistics', () async {
        // Record mixed attempts
        await AttemptTracker.recordAttempt(testAttempt);
        await AttemptTracker.recordAttempt(testAttempt.copyWith(
          questionId: 'question_2',
          isCorrect: true,
          selectedIndex: 2,
          misconceptionCode: null,
          attemptedAt: DateTime.now().add(const Duration(seconds: 1)),
        ));
        
        final stats = await AttemptTracker.getTopicStats(testTopicId);
        expect(stats['totalAttempts'], 2);
        expect(stats['correctCount'], 1);
        expect(stats['accuracy'], 0.5);
        expect(stats['misconceptionCounts']['confuses_with_octagon'], 1);
      });
    });

    group('MasteryTracker Tests', () {
      test('should calculate mastery score correctly', () async {
        // Create attempts with 75% accuracy
        final attempts = [
          testAttempt.copyWith(isCorrect: true, misconceptionCode: null),
          testAttempt.copyWith(isCorrect: true, misconceptionCode: null),
          testAttempt.copyWith(isCorrect: true, misconceptionCode: null),
          testAttempt.copyWith(isCorrect: false, misconceptionCode: 'some_error'),
        ];
        
        final score = MasteryTracker.calculateMasteryScore(attempts);
        expect(score, closeTo(0.75, 0.01));
      });

      test('should update mastery after attempt', () async {
        await AttemptTracker.recordAttempt(testAttempt);
        await MasteryTracker.updateMasteryAfterAttempt(testAttempt);
        
        final mastery = await MasteryTracker.getTopicMastery(testTopicId);
        expect(mastery, isNotNull);
        expect(mastery!.topicId, testTopicId);
        expect(mastery.totalAttempts, 1);
        expect(mastery.correctCount, 0); // testAttempt is incorrect
      });

      test('should identify weak concepts', () async {
        // Create attempts with repeated misconception
        for (int i = 0; i < 3; i++) {
          await AttemptTracker.recordAttempt(testAttempt.copyWith(
            questionId: 'question_$i',
            attemptedAt: DateTime.now().add(Duration(seconds: i)),
          ));
        }
        await MasteryTracker.updateMasteryAfterAttempt(testAttempt);
        
        final weakConcepts = await MasteryTracker.getWeakConcepts(testTopicId);
        expect(weakConcepts, contains('confuses_with_octagon'));
      });

      test('should get topics needing practice', () async {
        // Create low-performing attempts
        for (int i = 0; i < 5; i++) {
          await AttemptTracker.recordAttempt(testAttempt.copyWith(
            questionId: 'question_$i',
            isCorrect: i < 2, // 40% accuracy
            attemptedAt: DateTime.now().add(Duration(seconds: i)),
          ));
        }
        await MasteryTracker.updateMasteryAfterAttempt(testAttempt);
        
        final topicsNeedingPractice = await MasteryTracker.getTopicsNeedingPractice();
        expect(topicsNeedingPractice, contains(testTopicId));
      });

      test('should get mastered topics', () async {
        // Create high-performing attempts
        for (int i = 0; i < 10; i++) {
          await AttemptTracker.recordAttempt(testAttempt.copyWith(
            questionId: 'question_$i',
            isCorrect: i < 9, // 90% accuracy
            misconceptionCode: i < 9 ? null : 'some_error',
            attemptedAt: DateTime.now().add(Duration(seconds: i)),
          ));
        }
        await MasteryTracker.updateMasteryAfterAttempt(testAttempt);
        
        final masteredTopics = await MasteryTracker.getMasteredTopics();
        expect(masteredTopics, contains(testTopicId));
      });
    });

    group('ReinforcementSelector Tests', () {
      late QuestionData testQuestion;

      setUp(() {
        testQuestion = QuestionData(
          id: 'test_question_001',
          text: 'Test question',
          diagram: const DiagramData(
            id: 'test_diagram',
            type: DiagramType.geometry,
            elements: [],
          ),
          options: ['A', 'B', 'C', 'D'],
          correctIndex: 2,
          subject: 'Mathematics',
          topic: 'Central Angle',
          primaryConcept: 'central_angle',
          difficulty: Difficulty.medium,
          estimatedSeconds: 60,
          misconceptionTags: {
            0: 'confuses_with_octagon',
            1: 'confuses_with_hexagon',
            3: 'confuses_with_triangle',
          },
          reinforcementGroup: 'central_angle_basic',
          nextIfWrong: ['repair_question_001'],
          nextIfCorrect: ['challenge_question_001'],
          conceptTags: ['central_angle', 'division'],
        );
      });

      test('should select next question after wrong answer', () async {
        final nextId = await ReinforcementSelector.selectNextQuestionAfterWrong(
          currentQuestion: testQuestion,
          selectedOptionIndex: 0,
          topicId: testTopicId,
        );
        
        // Should use explicit next_if_wrong
        expect(nextId, 'repair_question_001');
      });

      test('should select next question after correct answer', () async {
        final nextId = await ReinforcementSelector.selectNextQuestionAfterCorrect(
          currentQuestion: testQuestion,
          timeTakenSeconds: 30, // Fast answer
          topicId: testTopicId,
        );
        
        // Should use explicit next_if_correct
        expect(nextId, 'challenge_question_001');
      });

      test('should select revision question for weak concepts', () async {
        final revisionId = await ReinforcementSelector.selectRevisionQuestion(
          topicId: testTopicId,
          weakConcepts: ['central_angle'],
        );
        
        expect(revisionId, isNotNull);
        expect(revisionId!.isNotEmpty, true);
      });

      test('should select mini mock questions', () async {
        final mockQuestions = await ReinforcementSelector.selectMiniMockQuestions(
          topicId: testTopicId,
          questionCount: 5,
        );
        
        expect(mockQuestions.length, 5);
        expect(mockQuestions, isNotEmpty);
      });

      test('should select challenge question after correct streak', () async {
        final challengeId = await ReinforcementSelector.selectChallengeQuestion(
          topicId: testTopicId,
          excludedIds: ['question_1', 'question_2'],
        );
        
        expect(challengeId, isNotNull);
        expect(challengeId!.isNotEmpty, true);
      });
    });

    group('DrillSession Tests', () {
      test('should create drill session correctly', () {
        final session = DrillSession(
          topicId: testTopicId,
          questionIds: ['q1', 'q2', 'q3'],
          currentIndex: 0,
          mode: DrillMode.quickDrill,
          startedAt: DateTime.now(),
          attempts: {},
        );

        expect(session.topicId, testTopicId);
        expect(session.questionIds.length, 3);
        expect(session.currentIndex, 0);
        expect(session.mode, DrillMode.quickDrill);
        expect(session.totalQuestions, 3);
        expect(session.completedQuestions, 0);
        expect(session.progress, 0.0);
      });

      test('should calculate progress correctly', () {
        final session = DrillSession(
          topicId: testTopicId,
          questionIds: ['q1', 'q2', 'q3', 'q4'],
          currentIndex: 1,
          mode: DrillMode.quickDrill,
          startedAt: DateTime.now(),
          attempts: {
            'q1': testAttempt,
          },
        );

        expect(session.currentIndex, 1);
        expect(session.currentQuestionId, 'q2');
        expect(session.completedQuestions, 1);
        expect(session.progress, 0.25); // 1/4
        expect(session.accuracy, 0.0); // 0 correct out of 1 attempt
      });

      test('should track accuracy correctly', () {
        final session = DrillSession(
          topicId: testTopicId,
          questionIds: ['q1', 'q2', 'q3'],
          currentIndex: 2,
          mode: DrillMode.quickDrill,
          startedAt: DateTime.now(),
          attempts: {
            'q1': testAttempt.copyWith(isCorrect: true),
            'q2': testAttempt.copyWith(isCorrect: false),
          },
        );

        expect(session.correctAnswers, 1);
        expect(session.incorrectAnswers, 1);
        expect(session.accuracy, 0.5);
      });
    });

    group('Integration Tests', () {
      test('should complete adaptive drill flow', () async {
        // 1. Start with incorrect attempt
        await AttemptTracker.recordAttempt(testAttempt);
        await MasteryTracker.updateMasteryAfterAttempt(testAttempt);

        // 2. Check mastery updated
        final mastery = await MasteryTracker.getTopicMastery(testTopicId);
        expect(mastery, isNotNull);
        expect(mastery!.totalAttempts, 1);
        expect(mastery.correctCount, 0);

        // 3. Get reinforcement recommendation
        final nextId = await ReinforcementSelector.selectNextQuestionAfterWrong(
          currentQuestion: QuestionData(
            id: testAttempt.questionId,
            text: 'Test',
            diagram: const DiagramData(
              id: 'test',
              type: DiagramType.geometry,
              elements: [],
            ),
            options: ['A', 'B', 'C', 'D'],
            correctIndex: 2,
            subject: 'Math',
            topic: 'Test',
            primaryConcept: 'test',
            difficulty: Difficulty.medium,
          ),
          selectedOptionIndex: testAttempt.selectedIndex,
          topicId: testTopicId,
        );

        // 4. Record correct attempt on reinforcement question
        final correctAttempt = testAttempt.copyWith(
          questionId: nextId ?? 'reinforcement_001',
          isCorrect: true,
          selectedIndex: 2,
          misconceptionCode: null,
          attemptedAt: DateTime.now().add(const Duration(seconds: 1)),
        );
        await AttemptTracker.recordAttempt(correctAttempt);
        await MasteryTracker.updateMasteryAfterAttempt(correctAttempt);

        // 5. Verify mastery improved
        final updatedMastery = await MasteryTracker.getTopicMastery(testTopicId);
        expect(updatedMastery, isNotNull);
        expect(updatedMastery!.totalAttempts, 2);
        expect(updatedMastery.correctCount, 1);
        expect(updatedMastery.masteryScore, greaterThan(mastery.masteryScore));
      });

      test('should handle mini mock completion', () async {
        // Simulate mini mock with mixed performance
        final mockQuestions = ['q1', 'q2', 'q3', 'q4', 'q5'];
        final session = DrillSession(
          topicId: testTopicId,
          questionIds: mockQuestions,
          currentIndex: mockQuestions.length,
          mode: DrillMode.miniMock,
          startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          attempts: {
            'q1': testAttempt.copyWith(questionId: 'q1', isCorrect: true),
            'q2': testAttempt.copyWith(questionId: 'q2', isCorrect: true),
            'q3': testAttempt.copyWith(questionId: 'q3', isCorrect: false),
            'q4': testAttempt.copyWith(questionId: 'q4', isCorrect: true),
            'q5': testAttempt.copyWith(questionId: 'q5', isCorrect: true),
          },
        );

        expect(session.isCompleted, false); // Not explicitly marked as completed
        expect(session.currentIndex, mockQuestions.length);
        expect(session.accuracy, 0.8); // 4/5 correct
        expect(session.totalQuestions, 5);
        expect(session.correctAnswers, 4);
        expect(session.incorrectAnswers, 1);

        // Verify mastery reflects mock performance
        for (final attempt in session.attempts.values) {
          await AttemptTracker.recordAttempt(attempt);
          await MasteryTracker.updateMasteryAfterAttempt(attempt);
        }

        final finalMastery = await MasteryTracker.getTopicMastery(testTopicId);
        expect(finalMastery, isNotNull);
        expect(finalMastery!.masteryScore, greaterThan(0.7));
      });
    });

    group('Error Handling Tests', () {
      test('should handle empty attempts gracefully', () async {
        final score = MasteryTracker.calculateMasteryScore([]);
        expect(score, 0.0);
      });

      test('should handle missing question data gracefully', () async {
        final nextId = await ReinforcementSelector.selectNextQuestionAfterWrong(
          currentQuestion: QuestionData(
            id: 'unknown',
            text: 'Unknown',
            diagram: const DiagramData(
              id: 'unknown',
              type: DiagramType.geometry,
              elements: [],
            ),
            options: ['A', 'B', 'C', 'D'],
            correctIndex: 0,
            subject: 'Math',
            topic: 'Unknown',
            primaryConcept: 'unknown',
            difficulty: Difficulty.medium,
            misconceptionTags: {}, // Empty misconception tags
          ),
          selectedOptionIndex: 1,
          topicId: 'unknown_topic',
        );

        // Should not crash and return null gracefully
        expect(nextId, isNull);
      });

      test('should handle invalid topic IDs gracefully', () async {
        final stats = await AttemptTracker.getTopicStats('invalid_topic');
        expect(stats['totalAttempts'], 0);
        expect(stats['accuracy'], 0.0);
      });
    });

    group('Performance Tests', () {
      test('should handle large number of attempts efficiently', () async {
        final stopwatch = Stopwatch()..start();
        
        // Record 100 attempts
        for (int i = 0; i < 100; i++) {
          await AttemptTracker.recordAttempt(testAttempt.copyWith(
            questionId: 'bulk_question_$i',
            attemptedAt: DateTime.now().add(Duration(milliseconds: i)),
          ));
        }
        
        stopwatch.stop();
        
        // Should complete within reasonable time (adjust threshold as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        
        final attempts = await AttemptTracker.getAllAttempts();
        expect(attempts.length, 100);
      });

      test('should calculate mastery score efficiently for many attempts', () async {
        final attempts = List.generate(1000, (i) => testAttempt.copyWith(
          questionId: 'perf_question_$i',
          isCorrect: i % 2 == 0, // 50% accuracy
          attemptedAt: DateTime.now().add(Duration(milliseconds: i)),
        ));
        
        final stopwatch = Stopwatch()..start();
        final score = MasteryTracker.calculateMasteryScore(attempts);
        stopwatch.stop();
        
        expect(score, closeTo(0.5, 0.01));
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}