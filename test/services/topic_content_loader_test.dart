import 'package:flutter_test/flutter_test.dart';
import 'package:diagram_engine/services/topic_content_loader.dart';
import 'package:diagram_engine/models/question_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('TopicContentLoader Tests', () {
    group('loadTopicCapsule', () {
      test('should load topic capsule successfully', () async {
        final topicCapsule = await TopicContentLoader.loadTopicCapsule(
          'math.geometry.central_angle_regular_polygon',
        );

        expect(topicCapsule.topicId,
            'math.geometry.central_angle_regular_polygon');
        expect(topicCapsule.title, 'Central Angle of a Regular Polygon');
        expect(topicCapsule.classLevel, 'Class 7-8');
        expect(topicCapsule.targetExamBridge, 'JEE Foundation');
        expect(topicCapsule.synopsisCards.length, 3);
        expect(topicCapsule.formulae.length, 1);
        expect(topicCapsule.commonMistakes.length, 3);
        expect(topicCapsule.starterQuestionIds.length, 5);
        expect(topicCapsule.practiceQuestionIds.length, 7);
        expect(topicCapsule.challengeQuestionIds.length, 3);
        expect(topicCapsule.jeeStyleQuestionIds.length, 1);
        expect(topicCapsule.manipulatives.length, 2);
        expect(topicCapsule.estimatedDurationMinutes, 45);
      });

      test('should return fallback capsule for invalid topic', () async {
        final topicCapsule = await TopicContentLoader.loadTopicCapsule(
          'invalid.topic.id',
        );

        expect(topicCapsule.topicId, 'invalid.topic.id');
        expect(topicCapsule.title, 'Central Angle of a Regular Polygon');
        expect(topicCapsule.synopsisCards.length, 2); // Fallback has 2 cards
      });
    });

    group('loadQuestionsByIds', () {
      test('should load questions by valid IDs', () async {
        final questionIds = [
          'fundamental_central_angle_square_001',
          'fundamental_central_angle_triangle_002',
          'fundamental_central_angle_hexagon_003',
        ];

        final questions =
            await TopicContentLoader.loadQuestionsByIds(questionIds);

        expect(questions.length, 3);

        // Check first question
        final firstQuestion = questions.firstWhere(
          (q) => q.id == 'fundamental_central_angle_square_001',
        );
        expect(firstQuestion.id, 'fundamental_central_angle_square_001');
        expect(firstQuestion.subject, 'Mathematics');
        expect(firstQuestion.topic, 'Central Angle of Regular Polygon');
        expect(firstQuestion.primaryConcept, 'central_angle_regular_polygon');
        expect(firstQuestion.classLevel, 'Class 7');
        expect(firstQuestion.difficulty, Difficulty.easy);
        expect(firstQuestion.options.length, 4);
        expect(firstQuestion.correctIndex, 2); // 90° is option C
        expect(firstQuestion.whyWrongExplanations?.isNotEmpty, true);
      });

      test('should handle missing question IDs gracefully', () async {
        final questionIds = [
          'fundamental_central_angle_square_001',
          'non_existent_question_id',
          'fundamental_central_angle_hexagon_003',
        ];

        final questions =
            await TopicContentLoader.loadQuestionsByIds(questionIds);

        expect(questions.length, 3); // Should create fallback for missing

        // Check that fallback question was created
        final fallbackQuestion = questions.firstWhere(
          (q) => q.id == 'non_existent_question_id',
        );
        expect(fallbackQuestion.id, 'non_existent_question_id');
        expect(fallbackQuestion.text, contains('regular polygon'));
        expect(fallbackQuestion.options, ['45°', '60°', '90°', '120°']);
      });

      test('should return empty list for empty input', () async {
        final questions = await TopicContentLoader.loadQuestionsByIds([]);
        expect(questions, isEmpty);
      });

      test('should create appropriate fallback questions', () async {
        final squareQuestions =
            await TopicContentLoader.loadQuestionsByIds(['demo_square_001']);
        final hexagonQuestions =
            await TopicContentLoader.loadQuestionsByIds(['demo_hexagon_001']);
        final octagonQuestions =
            await TopicContentLoader.loadQuestionsByIds(['demo_octagon_001']);

        // Square fallback
        final squareQuestion = squareQuestions.first;
        expect(squareQuestion.text, contains('square'));
        expect(squareQuestion.correctIndex, 2); // 90°

        // Hexagon fallback
        final hexagonQuestion = hexagonQuestions.first;
        expect(hexagonQuestion.text, contains('hexagon'));
        expect(hexagonQuestion.correctIndex, 1); // 60°

        // Octagon fallback
        final octagonQuestion = octagonQuestions.first;
        expect(octagonQuestion.text, contains('octagon'));
        expect(octagonQuestion.correctIndex, 0); // 45°
      });
    });

    group('Topic Capsule Content Validation', () {
      test('should have valid question ID structure', () async {
        final topicCapsule = await TopicContentLoader.loadTopicCapsule(
          'math.geometry.central_angle_regular_polygon',
        );

        // Check that all question ID lists are properly formatted
        final allQuestionIds = [
          ...topicCapsule.starterQuestionIds,
          ...topicCapsule.practiceQuestionIds,
          ...topicCapsule.challengeQuestionIds,
          ...topicCapsule.jeeStyleQuestionIds,
        ];

        for (final questionId in allQuestionIds) {
          expect(questionId, isNotEmpty);
          expect(questionId, matches(RegExp(r'^[a-zA-Z0-9_]+$')));
        }

        // Check for duplicates
        final uniqueIds = allQuestionIds.toSet();
        expect(uniqueIds.length, allQuestionIds.length,
            reason: 'Question IDs should be unique');
      });

      test('should have valid manipulative identifiers', () async {
        final topicCapsule = await TopicContentLoader.loadTopicCapsule(
          'math.geometry.central_angle_regular_polygon',
        );

        final validManipulatives = [
          'polygon_sides_slider',
          'angle_calculator',
          'sides_slider',
          'hexagon_slider',
          'triangle_area_calculator',
          'octagon_slider',
          'cosine_calculator',
          'area_calculator',
          'shape_subtraction',
        ];

        for (final manipulative in topicCapsule.manipulatives) {
          expect(validManipulatives, contains(manipulative),
              reason: 'Invalid manipulative: $manipulative');
        }
      });

      test('should have valid synopsis cards', () async {
        final topicCapsule = await TopicContentLoader.loadTopicCapsule(
          'math.geometry.central_angle_regular_polygon',
        );

        expect(topicCapsule.synopsisCards, isNotEmpty);

        for (final card in topicCapsule.synopsisCards) {
          expect(card.title, isNotEmpty);
          expect(card.body, isNotEmpty);
          expect(card.body.length, lessThan(200), // Keep it concise
              reason: 'Synopsis cards should be concise');
        }
      });
    });

    group('Error Handling', () {
      test('should handle malformed JSON gracefully', () async {
        // This test would require mocking the rootBundle to return malformed JSON
        // For now, we test the fallback behavior
        final topicCapsule = await TopicContentLoader.loadTopicCapsule(
          'non_existent_topic',
        );

        expect(topicCapsule.topicId, 'non_existent_topic');
        expect(topicCapsule.synopsisCards, isNotEmpty);
        expect(topicCapsule.formulae, isNotEmpty);
      });
    });

    group('Question Content Integration', () {
      test('should load questions with complete metadata', () async {
        final questions = await TopicContentLoader.loadQuestionsByIds([
          'fundamental_central_angle_square_001',
        ]);

        expect(questions.length, 1);
        final question = questions.first;

        // Verify all required fields are present
        expect(question.id, isNotEmpty);
        expect(question.text, isNotEmpty);
        expect(question.options, isNotEmpty);
        expect(question.correctIndex, greaterThanOrEqualTo(0));
        expect(question.correctIndex, lessThan(question.options.length));
        expect(question.subject, isNotEmpty);
        expect(question.topic, isNotEmpty);
        expect(question.primaryConcept, isNotEmpty);
        expect(question.difficulty, isNotNull);
        expect(question.classLevel, isNotEmpty);
        expect(question.estimatedSeconds, greaterThan(0));

        // Verify learning features
        expect(question.explanation, isNotEmpty);
        expect(question.solutionSteps, isNotEmpty);
        expect(question.whyWrongExplanations, isNotNull);
        if (question.whyWrongExplanations != null) {
          expect(question.whyWrongExplanations!.length,
              greaterThan(0)); // At least one wrong explanation
          expect(question.whyWrongExplanations!.length,
              lessThanOrEqualTo(4)); // Max 4 options
        }
      });

      test('should maintain question-answer consistency', () async {
        final questions = await TopicContentLoader.loadQuestionsByIds([
          'fundamental_central_angle_square_001',
          'fundamental_central_angle_triangle_002',
        ]);

        for (final question in questions) {
          // Verify correct answer is within options range
          expect(question.correctIndex, greaterThanOrEqualTo(0));
          expect(question.correctIndex, lessThan(question.options.length));

          // Verify explanation makes sense for the correct answer
          expect(question.explanation, isNotEmpty);

          // Verify why-wrong explanations exist for all wrong options
          if (question.whyWrongExplanations != null) {
            for (int i = 0; i < question.options.length; i++) {
              if (i != question.correctIndex) {
                expect(question.whyWrongExplanations!.containsKey(i), true,
                    reason: 'Missing why-wrong explanation for option $i');
                expect(question.whyWrongExplanations![i], isNotEmpty,
                    reason: 'Empty why-wrong explanation for option $i');
              }
            }
          }
        }
      });
    });
  });
}
