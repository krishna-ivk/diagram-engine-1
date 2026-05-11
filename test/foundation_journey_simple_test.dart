import 'package:flutter_test/flutter_test.dart';
import '../lib/models/foundation_journey.dart';
import '../lib/models/journey_progression_engine.dart';
import '../lib/models/journey_state.dart';
import '../lib/models/student_profile.dart';
import '../lib/models/practice_mode.dart';
import '../lib/models/question_attempt.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FoundationJourney - Basic Tests', () {
    test('should create FoundationJourney with required fields', () {
      final journey = FoundationJourney(
        journeyId: 'test_journey',
        title: 'Test Journey',
        subtitle: 'Test Subtitle',
        targetGrade: 'Class 7',
        targetExam: 'JEE Main',
        chapter: 'Geometry',
        estimatedDurationMinutes: 30,
        difficultyProgression: ['L0', 'L1'],
        levels: [
          JourneyLevel(
            level: 'L0',
            role: 'familiar',
            title: 'Test Level',
            description: 'Test Description',
            classLevel: 'Class 7',
            microLesson: MicroLesson(
              title: 'Test Lesson',
              body: 'Test Body',
              visualHintIds: ['hint1', 'hint2'],
            ),
            questionIds: ['q1'],
            prerequisites: [],
            unlockThreshold: UnlockThreshold(
              correctRequired: 1,
              confidenceThreshold: 'somewhat_sure',
            ),
            manipulatives: ['slider'],
          ),
        ],
        progressionRules: ProgressionRules(
          correctTwice: 'unlock_next',
          wrongOnceLowConfidence: 'show_micro_lesson',
          wrongTwice: 'go_down',
          correctFastHighConfidence: 'jump_forward',
          correctSlow: 'repeat_similar',
        ),
        successCriteria: SuccessCriteria(
          journeyCompletion: 'complete_final',
          masteryIndicator: 'solve_target',
          timeEstimate: '30-45 min',
          retryAllowed: true,
        ),
        parentProgressSummary: ParentProgressSummary(
          conceptsMastered: ['concept1'],
          strugglingAreas: ['area1'],
          confidenceTrend: 'improving',
          recommendedNext: 'next_journey',
        ),
      );

      expect(journey.journeyId, equals('test_journey'));
      expect(journey.title, equals('Test Journey'));
      expect(journey.levels.length, equals(1));
      expect(journey.levels.first.level, equals('L0'));
    });

    test('should serialize to JSON and deserialize back', () {
      final journey = FoundationJourney(
        journeyId: 'test_journey',
        title: 'Test Journey',
        subtitle: 'Test Subtitle',
        targetGrade: 'Class 7',
        targetExam: 'JEE Main',
        chapter: 'Geometry',
        estimatedDurationMinutes: 30,
        difficultyProgression: ['L0', 'L1'],
        levels: [],
        progressionRules: ProgressionRules(
          correctTwice: 'unlock_next',
          wrongOnceLowConfidence: 'show_micro_lesson',
          wrongTwice: 'go_down',
          correctFastHighConfidence: 'jump_forward',
          correctSlow: 'repeat_similar',
        ),
        successCriteria: SuccessCriteria(
          journeyCompletion: 'complete_final',
          masteryIndicator: 'solve_target',
          timeEstimate: '30-45 min',
          retryAllowed: true,
        ),
        parentProgressSummary: ParentProgressSummary(
          conceptsMastered: ['concept1'],
          strugglingAreas: ['area1'],
          confidenceTrend: 'improving',
          recommendedNext: 'next_journey',
        ),
      );

      final json = journey.toJson();
      final deserializedJourney = FoundationJourney.fromJson(json);

      expect(deserializedJourney.journeyId, equals(journey.journeyId));
      expect(deserializedJourney.title, equals(journey.title));
      expect(deserializedJourney.levels.length, equals(journey.levels.length));
    });
  });

  group('StudentProfile - Basic Tests', () {
    test('should recommend Foundation Journey for Class 7', () {
      final profile = StudentProfile(
        studentId: 'test_student',
        name: 'Test Student',
        currentClass: 7,
        targetExam: TargetExam.jeeMain,
        comfortLevel: ComfortLevel.beginner,
      );

      expect(profile.getRecommendedMode(), equals(PracticeMode.foundationJourney));
      expect(profile.shouldShowFoundationJourney(), isTrue);
    });

    test('should recommend Learner Mode for Class 10', () {
      final profile = StudentProfile(
        studentId: 'test_student',
        name: 'Test Student',
        currentClass: 10,
        targetExam: TargetExam.jeeMain,
        comfortLevel: ComfortLevel.okay,
      );

      expect(profile.getRecommendedMode(), equals(PracticeMode.learner));
      expect(profile.shouldShowFoundationJourney(), isFalse);
    });
  });

  group('PracticeMode.foundationJourney - Properties', () {
    test('should allow hints', () {
      expect(PracticeMode.foundationJourney.allowHints, isTrue);
    });

    test('should allow reveal steps', () {
      expect(PracticeMode.foundationJourney.allowRevealSteps, isTrue);
    });

    test('should allow concept explanations', () {
      expect(PracticeMode.foundationJourney.allowConceptExplanation, isTrue);
    });

    test('should have adaptive difficulty', () {
      expect(PracticeMode.foundationJourney.adaptiveDifficulty, isTrue);
    });

    test('should be progression-based', () {
      expect(PracticeMode.foundationJourney.isProgressionBased, isTrue);
    });

    test('should show micro-lessons', () {
      expect(PracticeMode.foundationJourney.showMicroLessons, isTrue);
    });

    test('should track confidence', () {
      expect(PracticeMode.foundationJourney.trackConfidence, isTrue);
    });

    test('should have correct display name', () {
      expect(PracticeMode.foundationJourney.displayName, equals('Foundation Journey'));
    });

    test('should have correct description', () {
      expect(PracticeMode.foundationJourney.description, contains('Class 7 basics'));
    });
  });

  group('QuestionAttempt - Basic Tests', () {
    test('should create QuestionAttempt with required fields', () {
      final attempt = QuestionAttempt(
        questionId: 'test_q1',
        confidenceLevel: ConfidenceLevel.somewhatSure,
        isCorrect: true,
        timeSpentSeconds: 30,
        timestamp: DateTime.now(),
        levelIndex: 0,
      );

      expect(attempt.questionId, equals('test_q1'));
      expect(attempt.confidenceLevel, equals(ConfidenceLevel.somewhatSure));
      expect(attempt.isCorrect, isTrue);
      expect(attempt.timeSpentSeconds, equals(30));
      expect(attempt.levelIndex, equals(0));
    });

    test('should serialize to JSON and deserialize back', () {
      final attempt = QuestionAttempt(
        questionId: 'test_q1',
        confidenceLevel: ConfidenceLevel.verySure,
        isCorrect: false,
        timeSpentSeconds: 45,
        timestamp: DateTime.parse('2023-01-01T00:00:00Z'),
        levelIndex: 1,
      );

      final json = attempt.toJson();
      final deserializedAttempt = QuestionAttempt.fromJson(json);

      expect(deserializedAttempt.questionId, equals(attempt.questionId));
      expect(deserializedAttempt.confidenceLevel, equals(attempt.confidenceLevel));
      expect(deserializedAttempt.isCorrect, equals(attempt.isCorrect));
      expect(deserializedAttempt.timeSpentSeconds, equals(attempt.timeSpentSeconds));
      expect(deserializedAttempt.levelIndex, equals(attempt.levelIndex));
    });
  });

  group('StudentJourneyState - Basic Tests', () {
    test('should create StudentJourneyState with default values', () {
      final state = StudentJourneyState(
        journeyId: 'test_journey',
        studentId: 'test_student',
      );

      expect(state.journeyId, equals('test_journey'));
      expect(state.studentId, equals('test_student'));
      expect(state.currentLevelIndex, equals(0));
      expect(state.levelStates, isEmpty);
      expect(state.attempts, isEmpty);
      expect(state.isCompleted, isFalse);
      expect(state.completionDate, isNull);
      expect(state.startDate, isNull);
    });

    test('should add attempts correctly', () {
      final state = StudentJourneyState(
        journeyId: 'test_journey',
        studentId: 'test_student',
      );

      final attempt1 = QuestionAttempt(
        questionId: 'q1',
        confidenceLevel: ConfidenceLevel.somewhatSure,
        isCorrect: true,
        timeSpentSeconds: 30,
        timestamp: DateTime.now(),
        levelIndex: 0,
      );

      final attempt2 = QuestionAttempt(
        questionId: 'q2',
        confidenceLevel: ConfidenceLevel.verySure,
        isCorrect: false,
        timeSpentSeconds: 45,
        timestamp: DateTime.now(),
        levelIndex: 0,
      );

      state.addAttempt(attempt1);
      state.addAttempt(attempt2);

      expect(state.attempts.length, equals(2));
      expect(state.attemptsForLevel(0).length, equals(2));
      expect(state.recentAttemptsForLevel(0).length, equals(2));
    });
  });
}