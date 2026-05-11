import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

import '../tools/validate_content.dart';

void main() {
  group('Content pipeline schema', () {
    late JsonSchema questionSchema;

    setUpAll(() {
      final schemaFile = File('content_pipeline/schemas/question_item.json');
      final schemaJson = json.decode(schemaFile.readAsStringSync());
      questionSchema = JsonSchema.create(schemaJson);
    });

    test('validates every content pipeline sample question', () {
      final questionFiles = Directory('content_pipeline/questions')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      expect(questionFiles, isNotEmpty);

      for (final file in questionFiles) {
        final content = json.decode(file.readAsStringSync());
        final result = questionSchema.validate(content);

        expect(
          result.isValid,
          isTrue,
          reason: '${file.path} failed schema validation: ${result.errors}',
        );
      }
    });

    test('accepts integer answers without oneOf ambiguity', () {
      final content = json.decode(
        File('content_pipeline/questions/sample_foundation_2.json')
            .readAsStringSync(),
      );

      final result = questionSchema.validate(content);

      expect(result.isValid, isTrue, reason: result.errors.toString());
    });

    test('non-diagram questions can omit diagram_type', () {
      final content = json.decode(
        File('content_pipeline/questions/sample_jee_pattern_2.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;

      expect(content['diagram_requirements']['needs_diagram'], isFalse);
      expect(content['diagram_requirements'], isNot(contains('diagram_type')));

      final result = questionSchema.validate(content);
      expect(result.isValid, isTrue, reason: result.errors.toString());
    });
  });

  group('App content validator', () {
    test('pipeline completeness has all required files', () {
      final validator = ContentValidator();

      final result = validator.validatePipelineCompleteness();

      expect(result.isValid, isTrue, reason: result.errors.join('\n'));
    });

    test('sample question assets validate against app schema', () {
      final validator = ContentValidator();

      final result = validator.validateDirectory('content/sample_questions');

      expect(result.isValid, isTrue, reason: result.errors.join('\n'));
      expect(result.summary, contains('Validated'));
    });
  });
}
