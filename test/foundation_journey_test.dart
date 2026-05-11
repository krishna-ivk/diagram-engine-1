import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../lib/models/foundation_journey.dart';
import '../lib/models/journey_progression_engine.dart';
import '../lib/models/journey_state.dart';
import '../lib/models/student_profile.dart';
import '../lib/models/practice_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FoundationJourney', () {
    late FoundationJourney journey;

    setUp(() {
      final json = {
        'journeyId': 'geometry_foundation_journey',
        'title': 'From Square to JEE Octagon',
        'subtitle': 'Build JEE-level thinking step by step',
        'targetGrade': 'Class 7',
        'targetExam': 'JEE Main',
        'chapter': 'Geometry',
        'estimatedDurationMinutes': 45,
        'difficultyProgression': ['L0', 'L1', 'L2', 'L3', 'L4', 'L5'],
        'levels': [
          {
            'level': 'L0',
            'role': 'familiar',
            'title': 'Familiar: Square Parts',
            'description': 'Start with what you already know about squares',
            'classLevel': 'Class 7',
            'microLesson': {
              'title': 'Square Basics',
              'body': 'A square has 4 equal sides and 4 right angles.',
              'visualHintIds': ['center', 'triangles']
            },
            'questionIds': ['class7_square_parts_001'],
            'prerequisites': [],
            'unlockThreshold': {
              'correctRequired': 1,
              'confidenceThreshold': 'somewhat_sure'
            },
            'manipulatives': ['sides_slider']
          }
        ],
        'progressionRules': {
          'correctTwice': 'unlock_next_level',
          'wrongOnceLowConfidence': 'show_micro_lesson',
          'wrongTwice': 'go_one_level_down',
          'correctFastHighConfidence': 'jump_forward',
          'correctSlow': 'repeat_similar'
        },
        'successCriteria': {
          'journeyCompletion': 'complete_L5_with_confidence',
          'masteryIndicator': 'solve_original_JEE_question',
          'timeEstimate': '45-60_minutes',
          'retryAllowed': true
        },
        'parentProgressSummary': {
          'conceptsMastered': [],
          'strugglingAreas': [],
          'confidenceTrend': 'improving',
          'recommendedNext': 'algebra_foundation_journey'
        }
      };
      
      journey = FoundationJourney.fromJson(json);
    });

    test('should deserialize from JSON correctly', () {
      expect(journey.journeyId, equals('geometry_foundation_journey'));
      expect(journey.title, equals('From Square to JEE Octagon'));
      expect(journey.targetGrade, equals('Class 7'));
      expect(journey.targetExam, equals('JEE Main'));
      expect(journey.levels.length, equals(1));
      expect(journey.levels.first.level, equals('L0'));
      expect(journey.levels.first.role, equals('familiar'));
    });

    test('should validate required fields', () {
      expect(journey.journeyId, isNotNull);
      expect(journey.title, isNotNull);
      expect(journey.levels, isNotEmpty);
      expect(journey.progressionRules, isNotNull);
      expect(journey.successCriteria, isNotNull);
    });

    test('should calculate total duration correctly', () {
      expect(journey.estimatedDurationMinutes, equals(45));
    });

    test('should serialize back to JSON', () {
      final json = journey.toJson();
      expect(json['journeyId'], equals('geometry_foundation_journey'));
      expect(json['title'], equals('From Square to JEE Octagon'));
      expect(json['difficultyProgression'], contains('L0'));
      expect(json['difficultyProgression'], contains('L5'));
    });
  });

  group('JourneyProgressionEngine', () {
    late JourneyProgressionEngine engine;
    late StudentJourneyState studentState;
    late FoundationJourney journey;

    setUp(() {
      engine = JourneyProgressionEngine();
      
      final journeyJson = {
        'journeyId': 'geometry_foundation_journey',
        'levels': [
          {
            'level': 'L0',
            'expectedTimeSeconds': 60,
            'microLesson': {
              'title': 'Square Basics',
              'body': 'A square has 4 equal sides.',
            }
          }
        ]
      };
      
      journey = FoundationJourney.fromJson(journeyJson);
      studentState = StudentJourneyState(
        journeyId: 'geometry_foundation_journey',
        studentId: 'test_student',
      );
    });

    test('should unlock next level after 2 correct answers', () {
      final attempt1 = MockQuestionAttempt(
        questionId: 'q1',
        isCorrect: true,
        confidenceLevel: ConfidenceLevel.somewhatSure,
        timeSpentSeconds: 30,
        levelIndex: 0,
      );
      
      final attempt2 = MockQuestionAttempt(
        questionId: 'q2',
        isCorrect: true,
        confidenceLevel: ConfidenceLevel.verySure,
        timeSpentSeconds: 25,
        levelIndex: 0,
      );
      
      studentState.addAttempt(attempt1);
      studentState.addAttempt(attempt2);
      
      final nextStep = engine.getNextStep(
        state: studentState,
        latestAttempt: attempt2,
        journey: journey,
      );
      
      expect(nextStep.action, equals(JourneyAction.proceedToNext));
      expect(nextStep.levelIndex, equals(1));
      expect(nextStep.message, contains('Moving to'));
    });

    test('should show micro-lesson for wrong + low confidence', () {
      final attempt = MockQuestionAttempt(
        questionId: 'q1',
        isCorrect: false,
        confidenceLevel: ConfidenceLevel.notSure,
        timeSpentSeconds: 45,
        levelIndex: 0,
      );
      
      final nextStep = engine.getNextStep(
        state: studentState,
        latestAttempt: attempt,
        journey: journey,
      );
      
      expect(nextStep.action, equals(JourneyAction.showMicroLesson));
      expect(nextStep.message, contains('review the key concepts'));
    });

    test('should go down level after 2 wrong answers', () {
      final attempt1 = MockQuestionAttempt(
        questionId: 'q1',
        isCorrect: false,
        confidenceLevel: ConfidenceLevel.somewhatSure,
        timeSpentSeconds: 30,
        levelIndex: 0,
      );
      
      final attempt2 = MockQuestionAttempt(
        questionId: 'q2',
        isCorrect: false,
        confidenceLevel: ConfidenceLevel.verySure,
        timeSpentSeconds: 25,
        levelIndex: 0,
      );
      
      studentState.addAttempt(attempt1);
      studentState.addAttempt(attempt2);
      
      final nextStep = engine.getNextStep(
        state: studentState,
        latestAttempt: attempt2,
        journey: journey,
      );
      
      expect(nextStep.action, equals(JourneyAction.goToPrevious));
      expect(nextStep.levelIndex, equals(0)); // Can't go below 0, so stays
      expect(nextStep.message, contains('strengthen your foundation'));
    });

    test('should jump forward for correct fast + high confidence', () {
      final attempt = MockQuestionAttempt(
        questionId: 'q1',
        isCorrect: true,
        confidenceLevel: ConfidenceLevel.verySure,
        timeSpentSeconds: 15, // Very fast (less than 70% of expected 60s)
        levelIndex: 0,
      );
      
      final nextStep = engine.getNextStep(
        state: studentState,
        latestAttempt: attempt,
        journey: journey,
      );
      
      expect(nextStep.action, equals(JourneyAction.jumpAhead));
      expect(nextStep.message, contains('bigger challenge'));
    });

    test('should repeat similar for correct but slow', () {
      final attempt = MockQuestionAttempt(
        questionId: 'q1',
        isCorrect: true,
        confidenceLevel: ConfidenceLevel.somewhatSure,
        timeSpentSeconds: 100, // Slow (more than 150% of expected 60s)
        levelIndex: 0,
      );
      
      final nextStep = engine.getNextStep(
        state: studentState,
        latestAttempt: attempt,
        journey: journey,
      );
      
      expect(nextStep.action, equals(JourneyAction.repeatSimilar));
      expect(nextStep.message, contains('similar question'));
    });
  });

  group('StudentProfile', () {
    test('should recommend Foundation Journey for Class 7', () {
      final profile = StudentProfile(
        studentId: 'student1',
        name: 'Test Student',
        currentClass: 7,
        targetExam: TargetExam.jeeMain,
        comfortLevel: ComfortLevel.beginner,
      );
      
      expect(profile.getRecommendedMode(), equals(PracticeMode.foundationJourney));
    });

    test('should recommend Learner Mode for Class 10', () {
      final profile = StudentProfile(
        studentId: 'student1',
        name: 'Test Student',
        currentClass: 10,
        targetExam: TargetExam.jeeMain,
        comfortLevel: ComfortLevel.okay,
      );
      
      expect(profile.getRecommendedMode(), equals(PracticeMode.learner));
    });

    test('should recommend Learner Mode for Class 11', () {
      final profile = StudentProfile(
        studentId: 'student1',
        name: 'Test Student',
        currentClass: 11,
        targetExam: TargetExam.jeeMain,
        comfortLevel: ComfortLevel.advanced,
      );
      
      expect(profile.getRecommendedMode(), equals(PracticeMode.learner));
    });

    test('should show Foundation Journey prominently for Class 7', () {
      final profile = StudentProfile(
        studentId: 'student1',
        name: 'Test Student',
        currentClass: 7,
        targetExam: TargetExam.jeeMain,
        comfortLevel: ComfortLevel.beginner,
      );
      
      expect(profile.shouldShowFoundationJourney(), isTrue);
    });

    test('should not show Foundation Journey prominently for Class 11', () {
      final profile = StudentProfile(
        studentId: 'student1',
        name: 'Test Student',
        currentClass: 11,
        targetExam: TargetExam.jeeMain,
        comfortLevel: ComfortLevel.advanced,
      );
      
      expect(profile.shouldShowFoundationJourney(), isFalse);
    });
  });

  group('PracticeMode.foundationJourney', () {
    test('should allow hints in Foundation Journey mode', () {
      expect(PracticeMode.foundationJourney.allowHints, isTrue);
    });

    test('should allow reveal steps in Foundation Journey mode', () {
      expect(PracticeMode.foundationJourney.allowRevealSteps, isTrue);
    });

    test('should allow concept explanations in Foundation Journey mode', () {
      expect(PracticeMode.foundationJourney.allowConceptExplanation, isTrue);
    });

    test('should have adaptive difficulty in Foundation Journey mode', () {
      expect(PracticeMode.foundationJourney.adaptiveDifficulty, isTrue);
    });

    test('should be progression-based in Foundation Journey mode', () {
      expect(PracticeMode.foundationJourney.isProgressionBased, isTrue);
    });

    test('should show micro-lessons in Foundation Journey mode', () {
      expect(PracticeMode.foundationJourney.showMicroLessons, isTrue);
    });

    test('should track confidence in Foundation Journey mode', () {
      expect(PracticeMode.foundationJourney.trackConfidence, isTrue);
    });

    test('should have correct display name', () {
      expect(PracticeMode.foundationJourney.displayName, equals('Foundation Journey'));
    });

    test('should have correct description', () {
      expect(PracticeMode.foundationJourney.description, 
             contains('Class 7 basics'));
    });
  });
}

// Mock classes for testing
class MockQuestionAttempt {
  final String questionId;
  final bool isCorrect;
  final ConfidenceLevel confidenceLevel;
  final int timeSpentSeconds;
  final int levelIndex;

  MockQuestionAttempt({
    required this.questionId,
    required this.isCorrect,
    required this.confidenceLevel,
    required this.timeSpentSeconds,
    required this.levelIndex,
  });
}

enum ConfidenceLevel {
  notSure,
  somewhatSure,
  verySure,
}