#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

/// Question Validator - Content QA Pipeline
/// 
/// Validates question structure, content quality, and ensures compliance
/// with the original content requirements (no direct copying from external sources).

class QuestionValidator {
  static const String questionsDir = 'content/questions';
  static const String qaChecklistDir = 'content';

  /// Validate all question files
  Future<void> validateAllQuestions() async {
    print('🔍 Question Validation Started');
    print('📋 Content QA Pipeline Active');
    
    final questionsDir = Directory(QuestionValidator.questionsDir);
    if (!questionsDir.existsSync()) {
      print('❌ Questions directory not found: ${questionsDir.path}');
      return;
    }
    
    final questionFiles = questionsDir
        .listSync()
        .where((file) => file.path.endsWith('_questions.json'))
        .cast<File>();
    
    print('📊 Found ${questionFiles.length} question files to validate');
    
    for (final file in questionFiles) {
      await validateQuestionFile(file);
    }
    
    print('✅ Question Validation Complete');
  }

  /// Validate a single question file
  Future<void> validateQuestionFile(File file) async {
    print('\n🔍 Validating: ${file.path}');
    
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      
      // Validate metadata
      validateMetadata(data);
      
      // Validate questions
      final questions = data['questions'] as List;
      final validationResults = <String, List<String>>{};
      
      for (final question in questions) {
        final questionId = question['question_id'] as String;
        final errors = validateQuestion(question);
        validationResults[questionId] = errors;
      }
      
      // Generate QA checklist
      await generateQAChecklist(file.path, questions, validationResults);
      
      // Report results
      final totalErrors = validationResults.values
          .fold(0, (sum, errors) => sum + errors.length);
      
      if (totalErrors == 0) {
        print('✅ All ${questions.length} questions passed validation');
      } else {
        print('⚠️  Found $totalErrors validation issues across ${questions.length} questions');
      }
      
    } catch (e) {
      print('❌ Error validating ${file.path}: $e');
    }
  }

  /// Validate file metadata
  void validateMetadata(Map<String, dynamic> data) {
    final metadata = data['metadata'] as Map<String, dynamic>?;
    
    if (metadata == null) {
      throw Exception('Missing metadata section');
    }
    
    final requiredFields = ['topic', 'generated_date', 'total_questions', 'source_patterns'];
    for (final field in requiredFields) {
      if (!metadata.containsKey(field)) {
        throw Exception('Missing required metadata field: $field');
      }
    }
    
    // Verify no direct copying disclaimer
    final note = metadata['note'] as String?;
    if (note == null || !note.contains('original content')) {
      throw Exception('Missing or invalid original content disclaimer');
    }
  }

  /// Validate individual question structure and content
  List<String> validateQuestion(Map<String, dynamic> question) {
    final errors = <String>[];
    final questionId = question['question_id'] as String? ?? 'unknown';
    
    // Required fields validation
    final requiredFields = [
      'question_id', 'source_type', 'source_pattern', 'class_level',
      'topic', 'primary_concept', 'question_role', 'question_text',
      'options', 'correct_answer', 'formulae_used', 'why_wrong_explanations',
      'difficulty', 'estimated_time_seconds', 'diagram_required',
      'manipulative', 'review_status'
    ];
    
    for (final field in requiredFields) {
      if (!question.containsKey(field)) {
        errors.add('Missing required field: $field');
      }
    }
    
    // Source type validation
    final sourceType = question['source_type'] as String?;
    if (sourceType != null && 
        !['original_recreated', 'original_authored'].contains(sourceType)) {
      errors.add('Invalid source_type: $sourceType. Must be original_recreated or original_authored');
    }
    
    // Options validation
    final options = question['options'] as List?;
    if (options != null) {
      if (options.length < 2) {
        errors.add('Question must have at least 2 options');
      }
      
      // Check for duplicate options
      final uniqueOptions = options.toSet();
      if (uniqueOptions.length != options.length) {
        errors.add('Duplicate options found');
      }
    }
    
    // Correct answer validation
    final correctAnswer = question['correct_answer'] as int?;
    if (correctAnswer != null && options != null) {
      if (correctAnswer < 0 || correctAnswer >= options.length) {
        errors.add('correct_answer index $correctAnswer is out of range (0-${options.length - 1})');
      }
    }
    
    // Why wrong explanations validation
    final whyWrong = question['why_wrong_explanations'] as Map<String, String>?;
    if (whyWrong != null && correctAnswer != null && options != null) {
      // Check that correct answer is not in wrong explanations
      if (whyWrong.containsKey(correctAnswer.toString())) {
        errors.add('correct_answer should not be in why_wrong_explanations');
      }
      
      // Check that all wrong answers have explanations
      for (int i = 0; i < options.length; i++) {
        if (i != correctAnswer && !whyWrong.containsKey(i.toString())) {
          errors.add('Missing explanation for wrong option $i');
        }
      }
    }
    
    // Question role validation
    final questionRole = question['question_role'] as String?;
    if (questionRole != null && 
        !['starter', 'practice', 'challenge', 'jee_style'].contains(questionRole)) {
      errors.add('Invalid question_role: $questionRole');
    }
    
    // Difficulty validation
    final difficulty = question['difficulty'] as String?;
    if (difficulty != null && 
        !['easy', 'medium', 'hard', 'very_hard'].contains(difficulty)) {
      errors.add('Invalid difficulty: $difficulty');
    }
    
    // Time estimation validation
    final timeSeconds = question['estimated_time_seconds'] as int?;
    if (timeSeconds != null) {
      if (timeSeconds <= 0) {
        errors.add('estimated_time_seconds must be positive');
      }
      if (timeSeconds > 600) { // 10 minutes max
        errors.add('estimated_time_seconds exceeds 10 minutes (600 seconds)');
      }
    }
    
    // Content quality checks
    validateContentQuality(question, errors);
    
    return errors;
  }

  /// Validate content quality requirements
  void validateContentQuality(Map<String, dynamic> question, List<String> errors) {
    final questionText = question['question_text'] as String?;
    final questionRole = question['question_role'] as String?;
    final classLevel = question['class_level'] as String?;
    
    if (questionText == null) return;
    
    // Check for age-appropriate wording based on class level
    if (classLevel == 'Class 7' && questionText.length > 200) {
      errors.add('Class 7 question text should be concise (< 200 characters)');
    }
    
    // Check for unnecessary JEE jargon in lower levels
    if (classLevel == 'Class 7' || classLevel == 'Class 8') {
      final jeeTerms = ['dodecagon', 'icosagon', 'trigonometric', 'calculus', 'derivative'];
      for (final term in jeeTerms) {
        if (questionText.toLowerCase().contains(term.toLowerCase())) {
          errors.add('Question contains advanced JEE terminology inappropriate for $classLevel');
        }
      }
    }
    
    // Check for single concept focus
    final concepts = question['primary_concept'] as String?;
    if (concepts != null && concepts.contains(' ')) {
      // If multiple concepts listed, ensure it's appropriate for the role
      if (questionRole == 'starter') {
        errors.add('Starter questions should focus on single concept');
      }
    }
    
    // Check formula count
    final formulae = question['formulae_used'] as List?;
    if (formulae != null && questionRole == 'starter' && formulae.length > 1) {
      errors.add('Starter questions should use only one formula');
    }
    
    // Check for manipulative appropriateness
    final manipulative = question['manipulative'] as String?;
    if (manipulative == 'none' && question['diagram_required'] == true) {
      errors.add('Questions requiring diagrams should have appropriate manipulatives');
    }
  }

  /// Generate QA checklist for each question
  Future<void> generateQAChecklist(
    String filePath,
    List questions,
    Map<String, List<String>> validationResults
  ) async {
    final fileName = filePath.split('/').last;
    final checklistName = fileName.replaceAll('_questions.json', '_qa_checklist.md');
    final checklistFile = File('$qaChecklistDir/$checklistName');
    
    final buffer = StringBuffer();
    
    buffer.writeln('# Content QA Checklist');
    buffer.writeln('');
    buffer.writeln('**File:** $fileName');
    buffer.writeln('**Generated:** ${DateTime.now().toIso8601String()}');
    buffer.writeln('**Total Questions:** ${questions.length}');
    buffer.writeln('');
    
    buffer.writeln('## Validation Summary');
    
    final totalErrors = validationResults.values
        .fold(0, (sum, errors) => sum + errors.length);
    final passedQuestions = validationResults.entries
        .where((entry) => entry.value.isEmpty)
        .length;
    
    buffer.writeln('- ✅ **Passed:** $passedQuestions/${questions.length}');
    buffer.writeln('- ⚠️ **Issues Found:** $totalErrors');
    buffer.writeln('');
    
    buffer.writeln('## Question-by-Question Review');
    buffer.writeln('');
    
    for (final question in questions) {
      final questionId = question['question_id'] as String;
      final questionRole = question['question_role'] as String;
      final difficulty = question['difficulty'] as String;
      final errors = validationResults[questionId] ?? [];
      
      buffer.writeln('### Question: $questionId');
      buffer.writeln('- **Role:** $questionRole');
      buffer.writeln('- **Difficulty:** $difficulty');
      buffer.writeln('- **Status:** ${errors.isEmpty ? '✅ PASS' : '⚠️ NEEDS REVIEW'}');
      
      if (errors.isNotEmpty) {
        buffer.writeln('- **Issues:**');
        for (final error in errors) {
          buffer.writeln('  - $error');
        }
      }
      
      buffer.writeln('');
      buffer.writeln('**Manual Review Checklist:**');
      buffer.writeln('- [ ] Question text is clear and age-appropriate');
      buffer.writeln('- [ ] Options are plausible and distinct');
      buffer.writeln('- [ ] Correct answer is accurate');
      buffer.writeln('- [ ] Wrong explanations teach the concept');
      buffer.writeln('- [ ] Formula application is correct');
      buffer.writeln('- [ ] Diagram/manipulative supports learning');
      buffer.writeln('- [ ] Time estimation is reasonable');
      buffer.writeln('- [ ] Content is original (no copying)');
      buffer.writeln('');
    }
    
    buffer.writeln('## Content Quality Standards');
    buffer.writeln('');
    buffer.writeln('Each question must satisfy:');
    buffer.writeln('- ✅ One concept only (starter questions)');
    buffer.writeln('- ✅ Age-appropriate wording');
    buffer.writeln('- ✅ No unnecessary JEE jargon (Class 7-8)');
    buffer.writeln('- ✅ One clear formula (starter questions)');
    buffer.writeln('- ✅ All wrong options map to real misconceptions');
    buffer.writeln('- ✅ Why-wrong explanations teach');
    buffer.writeln('- ✅ Diagram/manipulative support available');
    buffer.writeln('- ✅ Correct answer verified manually');
    buffer.writeln('- ✅ Source type is original_recreated or original_authored');
    buffer.writeln('');
    
    buffer.writeln('## Original Content Verification');
    buffer.writeln('');
    buffer.writeln('⚠️ **CRITICAL:** Verify that no content was copied directly from external sources.');
    buffer.writeln('');
    buffer.writeln('For each question:');
    buffer.writeln('- [ ] Question text is original wording');
    buffer.writeln('- [ ] Options are original choices');
    buffer.writeln('- [ ] Explanations are original teaching content');
    buffer.writeln('- [ ] No copyrighted material included');
    buffer.writeln('- [ ] Pattern-based creation only (not direct copying)');
    buffer.writeln('');
    
    await checklistFile.writeAsString(buffer.toString());
    print('📋 QA Checklist generated: ${checklistFile.path}');
  }
}

void main() async {
  final validator = QuestionValidator();
  await validator.validateAllQuestions();
}