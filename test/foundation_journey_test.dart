import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:diagram_engine/models/foundation_journey.dart';
import 'package:diagram_engine/models/journey_progression_engine.dart';
import 'package:diagram_engine/models/journey_state.dart';
import 'package:diagram_engine/models/practice_mode.dart';
import 'package:diagram_engine/models/question_attempt.dart';
import 'package:diagram_engine/models/student_profile.dart';
import 'package:diagram_engine/services/content_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FoundationJourney content', () {
    test('parses the checked-in snake_case journey asset', () {
      final file = File('content/journeys/geometry_foundation_journey.json');
      final journey = FoundationJourney.fromJson(
        json.decode(file.readAsStringSync()) as Map<String, dynamic>,
      );

      expect(journey.journeyId, 'geometry_foundation_journey');
      expect(journey.title, 'From Square to JEE Octagon');
      expect(
          journey.difficultyProgression, ['L0', 'L1', 'L2', 'L3', 'L4', 'L5']);
      expect(journey.levels, hasLength(6));
      expect(journey.levels.first.microLesson.visualHintIds, isNotEmpty);
      expect(journey.levels.last.questionIds.single, contains('jee_math'));
    });

    test('loads the journey through Flutter assets', () async {
      final engine = JourneyProgressionEngine();

      final journey = await engine.loadJourney('geometry_foundation_journey');

      expect(journey.levels.map((level) => level.level),
          containsAll(['L0', 'L5']));
    });

    test('loads all L0-L5 questions from geometry_foundation_journey_questions.json', () async {
      final questions = await ContentLoader.loadJourneyQuestions('geometry_foundation_journey');

      expect(questions, isNotEmpty);
      expect(questions.containsKey('class7_square_parts_001'), isTrue);
      expect(questions.containsKey('rescue_foundation_square_center_angle_001'), isTrue);
      expect(questions.containsKey('rescue_bridge_hexagon_center_angle_001'), isTrue);
      expect(questions.containsKey('rescue_intermediate_octagon_center_angle_001'), isTrue);
      expect(questions.containsKey('pre_jee_octagon_area_001'), isTrue);
      expect(questions.containsKey('jee_math_regular_polygon_001'), isTrue);
    });

    test('question text matches L0 title for first question', () async {
      final questions = await ContentLoader.loadJourneyQuestions('geometry_foundation_journey');
      final l0Question = questions['class7_square_parts_001'];

      expect(l0Question, isNotNull);
      expect(l0Question!.text, contains('square'));
      expect(l0Question.options, hasLength(4));
      expect(l0Question.correctIndex, 1);
    });
  });

  group('JourneyProgressionEngine', () {
    late JourneyProgressionEngine engine;
    late StudentJourneyState studentState;
    late FoundationJourney journey;

    setUp(() {
      engine = JourneyProgressionEngine();
      studentState = StudentJourneyState(
        journeyId: 'geometry_foundation_journey',
        studentId: 'test_student',
      );
      journey = _testJourney();
    });

    test('unlocks the next level after two correct answers', () {
      studentState.addAttempt(_attempt(questionId: 'q1', isCorrect: true));
      final latest = _attempt(questionId: 'q2', isCorrect: true);

      final nextStep = engine.getNextStep(
        state: studentState,
        latestAttempt: latest,
        journey: journey,
      );

      expect(nextStep.action, JourneyAction.proceedToNext);
      expect(nextStep.levelIndex, 1);
      expect(nextStep.message, contains('Level 1'));
    });

    test('shows the micro-lesson after a wrong low-confidence answer', () {
      final nextStep = engine.getNextStep(
        state: studentState,
        latestAttempt: _attempt(
          isCorrect: false,
          confidenceLevel: ConfidenceLevel.notSure,
        ),
        journey: journey,
      );

      expect(nextStep.action, JourneyAction.showMicroLesson);
      expect(nextStep.levelIndex, 0);
    });

    test('moves down a level after two wrong answers when possible', () {
      studentState.currentLevelIndex = 1;
      studentState.addAttempt(_attempt(
        questionId: 'q1',
        isCorrect: false,
        levelIndex: 1,
      ));

      final nextStep = engine.getNextStep(
        state: studentState,
        latestAttempt: _attempt(
          questionId: 'q2',
          isCorrect: false,
          levelIndex: 1,
        ),
        journey: journey,
      );

      expect(nextStep.action, JourneyAction.goToPrevious);
      expect(nextStep.levelIndex, 0);
    });

    test('jumps forward for fast correct answers with high confidence', () {
      final nextStep = engine.getNextStep(
        state: studentState,
        latestAttempt: _attempt(
          isCorrect: true,
          confidenceLevel: ConfidenceLevel.verySure,
          timeSpentSeconds: 15,
        ),
        journey: journey,
      );

      expect(nextStep.action, JourneyAction.jumpAhead);
      expect(nextStep.levelIndex, 2);
    });

    test('does not advance past the final level', () {
      studentState.currentLevelIndex = journey.levels.length - 1;

      final nextStep = engine.getNextStep(
        state: studentState,
        latestAttempt: _attempt(
          isCorrect: true,
          confidenceLevel: ConfidenceLevel.verySure,
          timeSpentSeconds: 15,
          levelIndex: studentState.currentLevelIndex,
        ),
        journey: journey,
      );

      expect(nextStep.action, JourneyAction.journeyComplete);
      expect(nextStep.levelIndex, journey.levels.length - 1);
    });

    test('repeats a similar question for slow correct answers', () {
      final nextStep = engine.getNextStep(
        state: studentState,
        latestAttempt: _attempt(isCorrect: true, timeSpentSeconds: 120),
        journey: journey,
      );

      expect(nextStep.action, JourneyAction.repeatSimilar);
    });
  });

  group('StudentProfile and Foundation Journey mode', () {
    test('recommends Foundation Journey for Class 7 beginners', () {
      final profile = StudentProfile(
        studentId: 'student1',
        name: 'Test Student',
        currentClass: 7,
        targetExam: TargetExam.jeeMain,
        comfortLevel: ComfortLevel.beginner,
      );

      expect(profile.getRecommendedMode(), PracticeMode.foundationJourney);
      expect(profile.shouldShowFoundationJourney(), isTrue);
    });

    test('keeps older students in learner mode', () {
      final profile = StudentProfile(
        studentId: 'student1',
        name: 'Test Student',
        currentClass: 11,
        targetExam: TargetExam.jeeMain,
        comfortLevel: ComfortLevel.advanced,
      );

      expect(profile.getRecommendedMode(), PracticeMode.learner);
      expect(profile.shouldShowFoundationJourney(), isFalse);
    });

    test('exposes the expected Foundation Journey capabilities', () {
      expect(PracticeMode.foundationJourney.allowHints, isTrue);
      expect(PracticeMode.foundationJourney.allowRevealSteps, isTrue);
      expect(PracticeMode.foundationJourney.allowConceptExplanation, isTrue);
      expect(PracticeMode.foundationJourney.adaptiveDifficulty, isTrue);
      expect(PracticeMode.foundationJourney.isProgressionBased, isTrue);
      expect(PracticeMode.foundationJourney.showMicroLessons, isTrue);
      expect(PracticeMode.foundationJourney.trackConfidence, isTrue);
    });
  });
}

FoundationJourney _testJourney() {
  return FoundationJourney(
    journeyId: 'geometry_foundation_journey',
    title: 'Test Journey',
    subtitle: 'Test Subtitle',
    targetGrade: 'Class 7',
    targetExam: 'JEE Main',
    chapter: 'Geometry',
    estimatedDurationMinutes: 45,
    difficultyProgression: ['L0', 'L1', 'L2'],
    levels: List.generate(
      3,
      (index) => JourneyLevel(
        level: 'L$index',
        role: 'test',
        title: 'Level $index',
        description: 'Level $index description',
        classLevel: 'Class 7',
        microLesson: MicroLesson(
          title: 'Lesson $index',
          body: 'Body $index',
          visualHintIds: ['hint_$index'],
        ),
        questionIds: ['q$index'],
        prerequisites: index == 0 ? [] : ['L${index - 1}'],
        unlockThreshold: UnlockThreshold(
          correctRequired: 2,
          confidenceThreshold: 'somewhat_sure',
        ),
        manipulatives: const [],
        expectedTimeSeconds: 60,
      ),
    ),
    progressionRules: ProgressionRules(
      correctTwice: 'unlock_next_level',
      wrongOnceLowConfidence: 'show_micro_lesson',
      wrongTwice: 'go_one_level_down',
      correctFastHighConfidence: 'jump_forward',
      correctSlow: 'repeat_similar',
    ),
    successCriteria: SuccessCriteria(
      journeyCompletion: 'complete_L2_with_confidence',
      masteryIndicator: 'solve_target_question',
      timeEstimate: '45-60 minutes',
      retryAllowed: true,
    ),
    parentProgressSummary: ParentProgressSummary(
      conceptsMastered: const [],
      strugglingAreas: const [],
      confidenceTrend: 'improving',
      recommendedNext: 'algebra_foundation_journey',
    ),
  );
}

QuestionAttempt _attempt({
  String questionId = 'q',
  required bool isCorrect,
  ConfidenceLevel confidenceLevel = ConfidenceLevel.somewhatSure,
  int timeSpentSeconds = 30,
  int levelIndex = 0,
}) {
  return QuestionAttempt(
    questionId: questionId,
    confidenceLevel: confidenceLevel,
    isCorrect: isCorrect,
    timeSpentSeconds: timeSpentSeconds,
    timestamp: DateTime(2026, 1, 1),
    levelIndex: levelIndex,
  );
}
