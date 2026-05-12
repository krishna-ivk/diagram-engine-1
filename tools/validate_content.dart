#!/usr/bin/env dart
// ignore_for_file: avoid_print

// Content Schema Validator for Diagram Engine Math Content.
// Validates content against schema and business rules.

import 'dart:convert';
import 'dart:io';
import 'package:json_schema/json_schema.dart';

class ContentValidator {
  final JsonSchema _schema;
  final List<String> _errors = [];
  final List<String> _warnings = [];

  ContentValidator() : _schema = _loadSchema();

  static JsonSchema _loadSchema() {
    final schemaFile = File('content_schema.json');
    if (!schemaFile.existsSync()) {
      throw Exception('content_schema.json not found');
    }

    final schemaContent = schemaFile.readAsStringSync();
    final schemaJson = json.decode(schemaContent);
    return JsonSchema.create(schemaJson);
  }

  /// Validate a single content file
  ValidationResult validateFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return ValidationResult(
        isValid: false,
        errors: ['File not found: $filePath'],
        warnings: [],
      );
    }

    try {
      final content = json.decode(file.readAsStringSync());
      if (content is Map<String, dynamic> &&
          content.containsKey('ladder_info') &&
          content['questions'] is List) {
        return _validateRescueLadder(content, filePath);
      }
      // Handle new content formats
      if (content is Map<String, dynamic>) {
        if (content.containsKey('topic_id') && content.containsKey('synopsis_cards')) {
          return _validateTopicCapsule(content, filePath);
        }
        if (content.containsKey('files') && content.containsKey('version')) {
          return _validateQuestionManifest(content, filePath);
        }
        if (content.containsKey('patterns') || content.containsKey('pattern_metadata')) {
          return _validatePatternFile(content, filePath);
        }
      }
      if (content is List) {
        return _validateQuestionList(content, filePath);
      }
      return _validateContent(content, filePath);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: ['Invalid JSON in $filePath: $e'],
        warnings: [],
      );
    }
  }

  /// Validate a rescue-ladder bundle by validating each embedded question.
  ValidationResult _validateRescueLadder(
    Map<String, dynamic> content,
    String filePath,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    final questions = content['questions'] as List;
    final ladderInfo = content['ladder_info'] as Map<String, dynamic>?;

    if (ladderInfo == null || ladderInfo['ladder_id'] == null) {
      errors.add('Missing ladder_info.ladder_id in $filePath');
    }

    final declaredCount = ladderInfo?['total_questions'];
    if (declaredCount is int && declaredCount != questions.length) {
      errors.add(
        'ladder_info.total_questions is $declaredCount but found ${questions.length} questions in $filePath',
      );
    }

    for (final question in questions) {
      if (question is! Map<String, dynamic>) {
        errors.add('Invalid embedded question in $filePath');
        continue;
      }

      final questionId = question['question_id'] ?? 'unknown_question';
      final result = _validateContent(question, '$filePath#$questionId');
      errors.addAll(result.errors);
      warnings.addAll(result.warnings);
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      summary: 'Validated rescue ladder with ${questions.length} questions',
    );
  }

  /// Validate content object against schema and business rules
  ValidationResult _validateContent(
      Map<String, dynamic> content, String filePath) {
    _errors.clear();
    _warnings.clear();

    // Schema validation
    final validationResult = _schema.validate(content);
    if (!validationResult.isValid) {
      _errors.addAll(validationResult.errors.map((e) => e.toString()));
    }

    // Business rule validation
    _validateBusinessRules(content, filePath);

    return ValidationResult(
      isValid: _errors.isEmpty,
      errors: List.from(_errors),
      warnings: List.from(_warnings),
    );
  }

  /// Validate business rules specific to Math content
  void _validateBusinessRules(Map<String, dynamic> content, String filePath) {
    // Rule 1: Every question must have primary_concept
    if (content['primary_concept'] == null ||
        content['primary_concept'].toString().isEmpty) {
      _errors.add('Missing primary_concept in $filePath');
    }

    // Rule 2: JEE-level questions must have prerequisites
    if (content['bridge_level'] == 'jee') {
      final prerequisites = content['prerequisites'] as List?;
      if (prerequisites == null || prerequisites.isEmpty) {
        _errors.add('JEE-level question must have prerequisites in $filePath');
      }
    }

    // Rule 3: Multiple choice questions must have why-wrong explanations
    if (content['question_type'] == 'multiple_choice') {
      final whyWrong = content['why_wrong_explanations'] as Map?;
      if (whyWrong == null || whyWrong.length < 3) {
        _errors.add(
            'MCQ must have why-wrong explanations for at least 3 incorrect options in $filePath');
      }
    }

    // Rule 4: Diagram questions must have valid diagram_id
    if (content['diagram_required'] == true) {
      if (content['diagram_id'] == null ||
          content['diagram_id'].toString().isEmpty) {
        _errors.add('Diagram required but no diagram_id provided in $filePath');
      }

      if (content['diagram_specification'] == null) {
        _warnings
            .add('Diagram required but no specification provided in $filePath');
      }
    }

    // Rule 5: Source must be traceable for JEE questions
    if (content['source_type'] == 'jee_previous_paper') {
      final metadata = content['source_metadata'] as Map?;
      if (metadata == null) {
        _errors.add('JEE question must have source_metadata in $filePath');
      } else {
        if (metadata['source_year'] == null) {
          _errors.add('JEE question must have source_year in $filePath');
        }
        if (metadata['source_session'] == null) {
          _errors.add('JEE question must have source_session in $filePath');
        }
      }
    }

    // Rule 6: No unpublished content should appear in student mode
    if (content['review_status'] == 'published') {
      // Check if all required reviews are complete
      final reviewHistory = content['review_history'] as List?;
      if (reviewHistory == null || reviewHistory.isEmpty) {
        _warnings
            .add('Published content should have review_history in $filePath');
      }
    }

    // Rule 7: Question ID format validation
    final questionId = content['question_id'] as String?;
    if (questionId != null) {
      final validPattern = RegExp(r'^[a-z_]+_[a-z]+_[a-z_]+_\d{3}$');
      if (!validPattern.hasMatch(questionId)) {
        _errors.add('Invalid question_id format: $questionId in $filePath');
      }
    }

    // Rule 8: Expected time validation
    final expectedTime = content['expected_time_seconds'] as int?;
    if (expectedTime != null) {
      if (expectedTime < 30 || expectedTime > 300) {
        _warnings.add(
            'Expected time $expectedTime seconds is outside recommended range (30-300) in $filePath');
      }
    }

    // Rule 9: Rescue question validation for JEE questions
    if (content['bridge_level'] == 'jee') {
      final rescueIds = content['rescue_question_ids'] as List?;
      if (rescueIds == null || rescueIds.length < 2) {
        _errors.add(
            'JEE question must have at least 2 rescue question IDs in $filePath');
      }

      // Validate rescue question ID format
      if (rescueIds != null) {
        for (final rescueId in rescueIds) {
          final validPattern = RegExp(r'^[a-z_]+_[a-z]+_[a-z_]+_\d{3}$');
          if (!validPattern.hasMatch(rescueId)) {
            _errors.add(
                'Invalid rescue question ID format: $rescueId in $filePath');
          }
        }
      }
    }

    // Rule 10: Class level and bridge level consistency
    final classLevel = content['class_level'] as String?;
    final bridgeLevel = content['bridge_level'] as String?;

    if (classLevel != null && bridgeLevel != null) {
      if (bridgeLevel == 'jee' &&
          !classLevel.contains('11') &&
          !classLevel.contains('12')) {
        _warnings.add(
            'JEE bridge level question should target Class 11-12 in $filePath');
      }

      if (bridgeLevel == 'foundation' &&
          (classLevel.contains('11') || classLevel.contains('12'))) {
        _warnings.add(
            'Foundation level question should target lower classes in $filePath');
      }
    }

    // Rule 11: Solution steps validation
    final solutionSteps = content['solution_steps'] as List?;
    if (solutionSteps == null || solutionSteps.isEmpty) {
      _errors.add('Question must have solution_steps in $filePath');
    } else {
      for (int i = 0; i < solutionSteps.length; i++) {
        final step = solutionSteps[i] as Map?;
        if (step == null) {
          _errors.add('Invalid solution step at index $i in $filePath');
          continue;
        }

        if (step['step_number'] == null) {
          _errors.add(
              'Solution step missing step_number at index $i in $filePath');
        }

        if (step['description'] == null ||
            step['description'].toString().isEmpty) {
          _errors.add(
              'Solution step missing description at index $i in $filePath');
        }
      }
    }
  }

  /// Validate all content files in a directory
  ValidationResult validateDirectory(String directoryPath) {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) {
      return ValidationResult(
        isValid: false,
        errors: ['Directory not found: $directoryPath'],
        warnings: [],
      );
    }

    final files = dir
        .listSync(recursive: true)
        .where((file) => file.path.endsWith('.json'))
        .cast<File>();

    final allErrors = <String>[];
    final allWarnings = <String>[];
    int validCount = 0;
    int totalCount = files.length;

    for (final file in files) {
      final result = validateFile(file.path);
      if (result.isValid) {
        validCount++;
      } else {
        allErrors.addAll(result.errors.map((e) => '${file.path}: $e'));
      }
      allWarnings.addAll(result.warnings.map((w) => '${file.path}: $w'));
    }

    return ValidationResult(
      isValid: allErrors.isEmpty,
      errors: allErrors,
      warnings: allWarnings,
      summary:
          'Validated $totalCount files: $validCount valid, ${totalCount - validCount} invalid',
    );
  }

  /// Validate content pipeline completeness
  ValidationResult validatePipelineCompleteness() {
    final allErrors = <String>[];
    final allWarnings = <String>[];

    // Check required files
    final requiredFiles = [
      'content_schema.json',
      'content/math/concepts.yaml',
      'content/ncert/math_class_7_map.yaml',
      'content/ncert/math_class_8_map.yaml',
      'content/ncert/math_class_9_map.yaml',
      'content/rescue_ladders/geometry_regular_polygon.yaml'
    ];

    for (final filePath in requiredFiles) {
      final file = File(filePath);
      if (!file.existsSync()) {
        allErrors.add('Required file missing: $filePath');
      }
    }

    // Check content directories
    final requiredDirectories = [
      'content/math',
      'content/sample_questions',
      'content/ncert',
      'content/rescue_ladders',
      'tools'
    ];

    for (final dirPath in requiredDirectories) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) {
        allErrors.add('Required directory missing: $dirPath');
      }
    }

    // Validate sample questions if they exist
    final sampleDir = Directory('content/sample_questions');
    if (sampleDir.existsSync()) {
      final sampleResult = validateDirectory('content/sample_questions');
      allErrors.addAll(sampleResult.errors);
      allWarnings.addAll(sampleResult.warnings);
    }

    return ValidationResult(
      isValid: allErrors.isEmpty,
      errors: allErrors,
      warnings: allWarnings,
      summary: 'Pipeline completeness validation finished',
    );
  }

  /// Generate validation report
  void generateReport(String outputPath) {
    final pipelineResult = validatePipelineCompleteness();
    final sampleResult = validateDirectory('content/sample_questions');

    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'pipeline_validation': {
        'is_valid': pipelineResult.isValid,
        'errors': pipelineResult.errors,
        'warnings': pipelineResult.warnings,
        'summary': pipelineResult.summary,
      },
      'sample_questions_validation': {
        'is_valid': sampleResult.isValid,
        'errors': sampleResult.errors,
        'warnings': sampleResult.warnings,
        'summary': sampleResult.summary,
      },
    };

    final outputFile = File(outputPath);
    outputFile.writeAsStringSync(json.encode(report));

    print('Validation report generated: $outputPath');
    print('Pipeline valid: ${pipelineResult.isValid}');
    print('Sample questions valid: ${sampleResult.isValid}');

    if (pipelineResult.errors.isNotEmpty) {
      print('\nPipeline errors:');
      for (final error in pipelineResult.errors) {
        print('  - $error');
      }
    }

    if (sampleResult.errors.isNotEmpty) {
      print('\nSample questions errors:');
      for (final error in sampleResult.errors) {
        print('  - $error');
      }
    }

    if (pipelineResult.warnings.isNotEmpty) {
      print('\nPipeline warnings:');
      for (final warning in pipelineResult.warnings) {
        print('  - $warning');
      }
    }

    if (sampleResult.warnings.isNotEmpty) {
      print('\nSample questions warnings:');
      for (final warning in sampleResult.warnings) {
        print('  - $warning');
      }
    }
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final String? summary;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    this.summary,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Validation Result: ${isValid ? "VALID" : "INVALID"}');

    if (summary != null) {
      buffer.writeln(summary);
    }

    if (errors.isNotEmpty) {
      buffer.writeln('\nErrors (${errors.length}):');
      for (final error in errors) {
        buffer.writeln('  - $error');
      }
    }

    if (warnings.isNotEmpty) {
      buffer.writeln('\nWarnings (${warnings.length}):');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }

    if (isValid && warnings.isEmpty) {
      buffer.writeln('\n✅ All validations passed!');
    }

    return buffer.toString();
  }

  /// Validate topic capsule content
  ValidationResult _validateTopicCapsule(
    Map<String, dynamic> content,
    String filePath,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check required fields for topic capsule
    final requiredFields = ['topic_id', 'title', 'synopsis_cards', 'formulae', 'common_mistakes'];
    for (final field in requiredFields) {
      if (!content.containsKey(field) || content[field] == null) {
        errors.add('Missing required field "$field" in $filePath');
      }
    }

    // Validate synopsis cards
    if (content['synopsis_cards'] is List) {
      final synopsisCards = content['synopsis_cards'] as List;
      for (int i = 0; i < synopsisCards.length; i++) {
        final card = synopsisCards[i];
        if (card is Map<String, dynamic>) {
          if (!card.containsKey('title') || card['title'] == null) {
            errors.add('Synopsis card $i missing title in $filePath');
          }
          if (!card.containsKey('body') || card['body'] == null) {
            errors.add('Synopsis card $i missing body in $filePath');
          }
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate question manifest
  ValidationResult _validateQuestionManifest(
    Map<String, dynamic> content,
    String filePath,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check required fields for question manifest
    if (!content.containsKey('files') || content['files'] == null) {
      errors.add('Missing "files" field in question manifest $filePath');
    }

    if (!content.containsKey('version') || content['version'] == null) {
      errors.add('Missing "version" field in question manifest $filePath');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate pattern file
  ValidationResult _validatePatternFile(
    Map<String, dynamic> content,
    String filePath,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // Basic validation for pattern files
    if (!content.containsKey('patterns') && !content.containsKey('pattern_metadata')) {
      warnings.add('Pattern file $filePath may not have expected structure');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate question list
  ValidationResult _validateQuestionList(
    List<dynamic> content,
    String filePath,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    for (int i = 0; i < content.length; i++) {
      final question = content[i];
      if (question is Map<String, dynamic>) {
        // Check required question fields
        final requiredFields = ['question_id', 'question_text', 'options', 'correct_answer'];
        for (final field in requiredFields) {
          if (!question.containsKey(field) || question[field] == null) {
            errors.add('Question $i missing required field "$field" in $filePath');
          }
        }

        // Validate options
        if (question['options'] is List) {
          final options = question['options'] as List;
          if (options.length != 4) {
            errors.add('Question $i must have exactly 4 options in $filePath');
          }
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}

void main(List<String> arguments) {
  final validator = ContentValidator();

  if (arguments.isEmpty) {
    print(
        'Usage: dart run tools/validate_content.dart [file_path|directory_path|pipeline]');
    print('Examples:');
    print(
        '  dart run tools/validate_content.dart content/sample_questions/question.json');
    print('  dart run tools/validate_content.dart content/sample_questions');
    print('  dart run tools/validate_content.dart pipeline');
    return;
  }

  final target = arguments[0];

  if (target == 'pipeline') {
    // Validate entire pipeline
    validator.generateReport('content/validation_report.json');
  } else if (Directory(target).existsSync()) {
    // Validate directory
    final result = validator.validateDirectory(target);
    print(result);
  } else {
    // Validate single file
    final result = validator.validateFile(target);
    print(result);
  }
}
