import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Content validation script for Topic Capsule MVP
/// Ensures all question IDs referenced in topic capsules exist in journey questions
class ContentValidator {
  static const String contentDir = 'content';
  static const String topicsDir = 'content/topics';
  static const String journeysDir = 'content/journeys';

  /// Validate all topic capsules and their question references
  static Future<ValidationResult> validateAllContent() async {
    final result = ValidationResult();
    
    try {
      // Load all journey questions
      final journeyQuestions = await _loadAllJourneyQuestions();
      
      // Validate all topic files
      final topicFiles = await _getTopicFiles();
      
      for (final topicFile in topicFiles) {
        await _validateTopicFile(topicFile, journeyQuestions, result);
      }
      
      // Validate journey question references
      await _validateJourneyReferences(journeyQuestions, result);
      
    } catch (e) {
      result.addError('Validation failed: $e');
    }
    
    return result;
  }

  /// Load all questions from journey files
  static Future<Map<String, dynamic>> _loadAllJourneyQuestions() async {
    final allQuestions = <String, dynamic>{};
    
    final journeyDir = Directory(journeysDir);
    if (!await journeyDir.exists()) {
      throw Exception('Journey directory not found: $journeysDir');
    }
    
    final files = await journeyDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('_questions.json'))
        .cast<File>()
        .toList();
    
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final data = json.decode(content) as Map<String, dynamic>;
        
        if (data.containsKey('questions')) {
          final questions = data['questions'] as Map<String, dynamic>;
          allQuestions.addAll(questions);
        }
      } catch (e) {
        print('Warning: Could not load journey questions from ${file.path}: $e');
      }
    }
    
    return allQuestions;
  }

  /// Get all topic JSON files
  static Future<List<File>> _getTopicFiles() async {
    final topicDir = Directory(topicsDir);
    if (!await topicDir.exists()) {
      throw Exception('Topics directory not found: $topicsDir');
    }
    
    return await topicDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .cast<File>()
        .toList();
  }

  /// Validate a single topic file
  static Future<void> _validateTopicFile(
    File topicFile,
    Map<String, dynamic> journeyQuestions,
    ValidationResult result,
  ) async {
    try {
      final content = await topicFile.readAsString();
      final topicData = json.decode(content) as Map<String, dynamic>;
      
      final topicId = topicData['topic_id'] as String? ?? 'unknown';
      final topicName = path.basenameWithoutExtension(topicFile.path);
      
      // Validate required fields
      _validateRequiredFields(topicData, topicName, result);
      
      // Validate question ID references
      final allQuestionIds = <String>[];
      
      final questionLists = [
        'starter_question_ids',
        'practice_question_ids',
        'challenge_question_ids',
        'revision_question_ids',
      ];
      
      for (final listKey in questionLists) {
        final ids = (topicData[listKey] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        
        allQuestionIds.addAll(ids);
        
        for (final questionId in ids) {
          if (!journeyQuestions.containsKey(questionId)) {
            result.addError(
              'Topic "$topicName" references non-existent question ID: $questionId '
              '(in $listKey)'
            );
          }
        }
      }
      
      // Check for duplicate question IDs within topic
      final uniqueIds = allQuestionIds.toSet();
      if (uniqueIds.length != allQuestionIds.length) {
        final duplicates = allQuestionIds
            .where((id) => allQuestionIds.where((x) => x == id).length > 1)
            .toSet();
        
        for (final duplicate in duplicates) {
          result.addError(
            'Topic "$topicName" has duplicate question ID: $duplicate'
          );
        }
      }
      
      // Validate manipulatives
      final manipulatives = (topicData['manipulatives'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [];
      
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
      
      for (final manipulative in manipulatives) {
        if (!validManipulatives.contains(manipulative)) {
          result.addError(
            'Topic "$topicName" has invalid manipulative: $manipulative'
          );
        }
      }
      
      result.addSuccess('Topic "$topicName" validated successfully');
      
    } catch (e) {
      result.addError('Failed to validate topic ${topicFile.path}: $e');
    }
  }

  /// Validate journey file references
  static Future<void> _validateJourneyReferences(
    Map<String, dynamic> journeyQuestions,
    ValidationResult result,
  ) async {
    final journeyDir = Directory(journeysDir);
    if (!await journeyDir.exists()) return;
    
    final journeyFiles = await journeyDir
        .list()
        .where((entity) => entity is File && 
               entity.path.endsWith('.json') && 
               !entity.path.endsWith('_questions.json'))
        .cast<File>()
        .toList();
    
    for (final journeyFile in journeyFiles) {
      try {
        final content = await journeyFile.readAsString();
        final journeyData = json.decode(content) as Map<String, dynamic>;
        
        final journeyId = journeyData['journey_id'] as String? ?? 
                          journeyData['topic_id'] as String? ?? 
                          'unknown';
        final journeyName = path.basenameWithoutExtension(journeyFile.path);
        
        final levels = journeyData['levels'] as List<dynamic>? ?? [];
        
        for (final level in levels) {
          final questionIds = (level['question_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];
          
          for (final questionId in questionIds) {
            if (!journeyQuestions.containsKey(questionId)) {
              result.addError(
                'Journey "$journeyName" level references non-existent question ID: $questionId'
              );
            }
          }
        }
        
        result.addSuccess('Journey "$journeyName" references validated');
        
      } catch (e) {
        result.addError('Failed to validate journey ${journeyFile.path}: $e');
      }
    }
  }

  /// Validate required fields in topic data
  static void _validateRequiredFields(
    Map<String, dynamic> topicData,
    String topicName,
    ValidationResult result,
  ) {
    final requiredFields = [
      'topic_id',
      'title',
      'class_level',
      'target_exam_bridge',
      'synopsis_cards',
      'formulae',
      'common_mistakes',
      'estimated_duration_minutes',
    ];
    
    for (final field in requiredFields) {
      if (!topicData.containsKey(field) || topicData[field] == null) {
        result.addError('Topic "$topicName" missing required field: $field');
      }
    }
    
    // Validate synopsis cards
    final synopsisCards = topicData['synopsis_cards'] as List<dynamic>? ?? [];
    if (synopsisCards.isEmpty) {
      result.addError('Topic "$topicName" must have at least one synopsis card');
    } else {
      for (int i = 0; i < synopsisCards.length; i++) {
        final card = synopsisCards[i] as Map<String, dynamic>?;
        if (card == null) {
          result.addError('Topic "$topicName" has null synopsis card at index $i');
          continue;
        }
        
        if (!card.containsKey('title') || card['title'] == null) {
          result.addError('Topic "$topicName" synopsis card $i missing title');
        }
        
        if (!card.containsKey('body') || card['body'] == null) {
          result.addError('Topic "$topicName" synopsis card $i missing body');
        }
      }
    }
  }
}

/// Validation result container
class ValidationResult {
  final List<String> errors = [];
  final List<String> warnings = [];
  final List<String> successes = [];
  
  bool get isValid => errors.isEmpty;
  int get issueCount => errors.length + warnings.length;
  
  void addError(String message) {
    errors.add(message);
  }
  
  void addWarning(String message) {
    warnings.add(message);
  }
  
  void addSuccess(String message) {
    successes.add(message);
  }
  
  void printSummary() {
    print('\n=== Content Validation Summary ===');
    print('✅ Success: ${successes.length}');
    print('⚠️  Warnings: ${warnings.length}');
    print('❌ Errors: ${errors.length}');
    print('Issues: $issueCount');
    
    if (errors.isNotEmpty) {
      print('\n🚨 Errors:');
      for (final error in errors) {
        print('  ❌ $error');
      }
    }
    
    if (warnings.isNotEmpty) {
      print('\n⚠️  Warnings:');
      for (final warning in warnings) {
        print('  ⚠️  $warning');
      }
    }
    
    if (successes.isNotEmpty) {
      print('\n✅ Successes:');
      for (final success in successes) {
        print('  ✅ $success');
      }
    }
    
    print('\n${isValid ? '🎉 Validation PASSED' : '❌ Validation FAILED'}\n');
  }
}

/// Main function to run validation
void main() async {
  print('🔍 Starting content validation...\n');
  
  final result = await ContentValidator.validateAllContent();
  result.printSummary();
  
  // Exit with error code if validation failed
  if (!result.isValid) {
    exit(1);
  }
}