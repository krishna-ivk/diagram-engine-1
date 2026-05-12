import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Content validator for question files and topic structure
class ContentValidator {
  static const String questionsPath = 'content/questions';
  static const String topicsPath = 'content/topics';

  /// Main validation function
  static Future<void> validateContent() async {
    print('Starting content validation...');
    
    try {
      // Load question manifest
      final manifest = await _loadQuestionManifest();
      if (manifest == null) {
        print('ERROR: Could not load question manifest');
        exit(1);
      }

      // Validate all question files listed in manifest
      await _validateQuestionFiles(manifest);

      // Validate topic structure
      await _validateTopicStructure();

      print('Content validation completed successfully!');
    } catch (e) {
      print('ERROR: Validation failed - $e');
      exit(1);
    }
  }

  /// Load question manifest
  static Future<Map<String, dynamic>?> _loadQuestionManifest() async {
    try {
      final file = File(path.join(questionsPath, 'question_manifest.json'));
      if (!await file.exists()) {
        print('ERROR: question_manifest.json not found');
        return null;
      }
      
      final content = await file.readAsString();
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      print('ERROR: Failed to load question manifest - $e');
      return null;
    }
  }

  /// Validate all question files
  static Future<void> _validateQuestionFiles(Map<String, dynamic> manifest) async {
    final files = manifest['files'] as List<dynamic>? ?? [];
    final allQuestionIds = <String>{};
    
    for (final fileName in files) {
      final filePath = path.join(questionsPath, fileName);
      final file = File(filePath);
      
      if (!await file.exists()) {
        print('ERROR: Question file not found: $filePath');
        exit(1);
      }

      try {
        final content = await file.readAsString();
        final questions = json.decode(content) as List<dynamic>;
        
        for (final question in questions) {
          final questionData = question as Map<String, dynamic>;
          final questionId = questionData['question_id'] as String?;
          
          if (questionId == null || questionId.isEmpty) {
            print('ERROR: Question missing question_id in $fileName');
            exit(1);
          }
          
          if (allQuestionIds.contains(questionId)) {
            print('ERROR: Duplicate question ID: $questionId');
            exit(1);
          }
          
          allQuestionIds.add(questionId);
          
          // Validate question structure
          _validateQuestionStructure(questionData, fileName);
        }
        
        print('✓ Validated ${questions.length} questions in $fileName');
      } catch (e) {
        print('ERROR: Failed to validate $fileName - $e');
        exit(1);
      }
    }
    
    print('✓ Total unique questions: ${allQuestionIds.length}');
  }

  /// Validate individual question structure
  static void _validateQuestionStructure(Map<String, dynamic> question, String fileName) {
    final requiredFields = [
      'question_id',
      'question_text',
      'options',
      'correct_answer',
      'explanation'
    ];
    
    for (final field in requiredFields) {
      if (!question.containsKey(field)) {
        print('ERROR: Missing required field "$field" in question ${question['question_id']} in $fileName');
        exit(1);
      }
    }
    
    // Validate options
    final options = question['options'] as List<dynamic>?;
    if (options == null || options.length != 4) {
      print('ERROR: Question ${question['question_id']} must have exactly 4 options');
      exit(1);
    }
    
    // Validate correct_answer
    final correctAnswer = question['correct_answer'];
    if (correctAnswer is! int || correctAnswer < 0 || correctAnswer > 3) {
      print('ERROR: Question ${question['question_id']} has invalid correct_answer: $correctAnswer');
      exit(1);
    }
  }

  /// Validate topic structure and field references
  static Future<void> _validateTopicStructure() async {
    final topicsDir = Directory(topicsPath);
    if (!await topicsDir.exists()) {
      print('WARNING: topics directory not found, skipping topic validation');
      return;
    }
    
    await for (final entity in topicsDir.list()) {
      if (entity is File && entity.path.endsWith('_capsule.json')) {
        await _validateTopicCapsule(entity);
      }
    }
  }

  /// Validate individual topic capsule
  static Future<void> _validateTopicCapsule(File topicFile) async {
    try {
      final content = await topicFile.readAsString();
      final topicData = json.decode(content) as Map<String, dynamic>;
      
      final topicId = path.basenameWithoutExtension(topicFile.path).replaceAll('_capsule', '');
      
      // Validate topic fields that reference question IDs
      final idFields = [
        'starter_question_ids',
        'practice_question_ids', 
        'challenge_question_ids',
        'revision_question_ids',
        'jee_style_question_ids'
      ];
      
      for (final field in idFields) {
        if (topicData.containsKey(field)) {
          final ids = topicData[field] as List<dynamic>?;
          if (ids != null) {
            for (final id in ids) {
              if (id is! String || id.isEmpty) {
                print('ERROR: Invalid question ID in $field for topic $topicId');
                exit(1);
              }
              // TODO: Check if question ID exists in question files
              // This would require loading all questions first
            }
          }
        }
      }
      
      print('✓ Validated topic capsule: $topicId');
    } catch (e) {
      print('ERROR: Failed to validate topic capsule ${topicFile.path} - $e');
      exit(1);
    }
  }
}

/// Main entry point
void main(List<String> args) async {
  await ContentValidator.validateContent();
}