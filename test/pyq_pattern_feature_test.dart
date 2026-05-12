import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diagram_engine/models/question_data.dart';
import 'package:diagram_engine/services/topic_content_loader.dart';

/// Tests for PYQ Pattern → Fundamental Question Generator feature
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PYQ Pattern Feature Tests', () {
    test('TopicContentLoader loads new questions from content/questions/',
        () async {
      // Test that new questions are loaded properly
      final questionIds = [
        'fundamental_central_angle_square_001',
        'fundamental_central_angle_triangle_002',
        'fundamental_central_angle_hexagon_003'
      ];

      final questions =
          await TopicContentLoader.loadQuestionsByIds(questionIds);

      expect(questions.length, equals(3));
      expect(questions[0].id, equals('fundamental_central_angle_square_001'));
      expect(questions[1].id, equals('fundamental_central_angle_triangle_002'));
      expect(questions[2].id, equals('fundamental_central_angle_hexagon_003'));

      // Verify question content
      expect(questions[0].text, contains('square is divided from the center'));
      expect(questions[1].text, contains('equilateral triangle'));
      expect(questions[2].text, contains('regular hexagon'));

      // Verify source types
      for (final question in questions) {
        expect(question.sourceType,
            isIn(['original_recreated', 'original_authored']));
        expect(question.reviewStatus, equals('draft'));
      }
    });

    test('Content validator validates new question format', () async {
      final content = jsonDecode(
        File('content/questions/central_angle_regular_polygon_questions.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;

      expect(content['metadata'], isA<Map<String, dynamic>>());
      expect(content['questions'], isA<List>());
      expect(content['questions'], hasLength(16));
    });

    test('PYQ pattern content keeps generated questions available', () async {
      expect(
          File('content/questions/central_angle_regular_polygon_questions.json')
              .existsSync(),
          isTrue);
    });

    test('Topic capsule integrates new fundamental questions', () async {
      // Test that topic capsule loads new questions
      final topicCapsule = await TopicContentLoader.loadTopicCapsule(
          'central_angle_regular_polygon');

      // Verify new question IDs are present
      expect(topicCapsule.starterQuestionIds,
          contains('fundamental_central_angle_square_001'));
      expect(topicCapsule.practiceQuestionIds,
          contains('practice_central_angle_octagon_001'));
      expect(topicCapsule.challengeQuestionIds,
          contains('challenge_central_angle_dodecagon_001'));
      expect(topicCapsule.jeeStyleQuestionIds,
          contains('jee_central_angle_diagonal_mixed_001'));

      // Verify total question count
      final totalQuestions = topicCapsule.starterQuestionIds.length +
          topicCapsule.practiceQuestionIds.length +
          topicCapsule.challengeQuestionIds.length +
          topicCapsule.jeeStyleQuestionIds.length;

      expect(totalQuestions, greaterThan(15),
          reason: 'Should have at least 16 questions');
    });

    test('Question manifest is properly structured', () async {
      // Test that question manifest exists and is valid
      expect(File('content/questions/question_manifest.json').existsSync(),
          isTrue);

      final manifestContent = await rootBundle
          .loadString('content/questions/question_manifest.json');
      final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;

      expect(manifest.containsKey('version'), isTrue);
      expect(manifest.containsKey('files'), isTrue);
      expect(manifest['total_questions'], 16);
    });

    test('Pattern index follows required format', () async {
      // Test that pattern index is properly structured
      expect(
          File('content/patterns/regular_polygon_patterns.json').existsSync(),
          isTrue);

      final patternContent = await rootBundle
          .loadString('content/patterns/regular_polygon_patterns.json');
      final patterns = jsonDecode(patternContent) as Map<String, dynamic>;

      expect(patterns.containsKey('pattern_metadata'), isTrue);
      expect(patterns.containsKey('patterns'), isTrue);
      expect(patterns['patterns'], isA<List>());

      // Verify pattern structure
      final firstPattern = patterns['patterns'][0] as Map<String, dynamic>;
      expect(firstPattern.containsKey('pattern_id'), isTrue);
      expect(firstPattern.containsKey('observed_in'), isTrue);
      expect(firstPattern.containsKey('skills_required'), isTrue);
      expect(firstPattern.containsKey('target_topic_capsule'), isTrue);
      expect(patterns['pattern_metadata']['do_not_copy_source_text'], isTrue);
    });

    test('Original content compliance is maintained', () async {
      // Test that all generated questions are marked as original
      final questions = await TopicContentLoader.loadQuestionsByIds([
        'fundamental_central_angle_square_001',
        'fundamental_central_angle_triangle_002',
        'fundamental_central_angle_hexagon_003'
      ]);

      // All questions should have original source types
      for (final question in questions) {
        expect(question.sourceType,
            isIn(['original_recreated', 'original_authored']),
            reason: 'Question ${question.id} should have original source type');
      }
    });

    test('Quality standards are enforced', () async {
      // Test that questions meet quality standards
      final questions = await TopicContentLoader.loadQuestionsByIds([
        'fundamental_central_angle_square_001',
        'fundamental_central_angle_triangle_002'
      ]);

      // Verify age-appropriate content
      for (final question in questions) {
        expect(question.text.length, lessThan(200),
            reason: 'Question ${question.id} should be concise for Class 7');
        expect(question.difficulty, isIn([Difficulty.easy, Difficulty.medium]),
            reason:
                'Question ${question.id} should be easy or medium for Class 7-8');
      }

      // Verify one concept focus for starter questions
      final starterQuestions =
          questions.where((q) => q.questionRole == 'starter');
      for (final question in starterQuestions) {
        expect(question.formulaeUsed.length, lessThanOrEqualTo(1),
            reason: 'Starter question ${question.id} should use one formula');
      }
    });

    test('Error handling works correctly', () async {
      // Test error handling when question files are missing
      final invalidQuestionIds = [
        'non_existent_question_001',
        'invalid_question_002'
      ];

      final questions =
          await TopicContentLoader.loadQuestionsByIds(invalidQuestionIds);

      // Should return fallback questions for missing IDs
      expect(questions.length, equals(2));
      expect(questions[0].id, equals('non_existent_question_001'));
      expect(questions[1].id, equals('invalid_question_002'));

      // Should not crash
      expect(questions[0].text, isNotEmpty);
      expect(questions[1].text, isNotEmpty);
    });
  });
}
