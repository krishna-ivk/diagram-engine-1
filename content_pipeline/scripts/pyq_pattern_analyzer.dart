import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

/// PYQ (Previous Year Questions) Pattern Analyzer
/// Analyzes question patterns and generates topic-based question lists
class PyqPatternAnalyzer {
  static const String outputPath = 'content/analysis';
  static const String questionsPath = 'content/questions';

  /// Main analysis function
  static Future<void> analyzePatterns() async {
    print('Starting PYQ pattern analysis...');
    
    try {
      // Load all questions
      final allQuestions = await _loadAllQuestions();
      if (allQuestions.isEmpty) {
        print('WARNING: No questions found for analysis');
        return;
      }

      // Group questions by topic
      final topicGroups = _groupQuestionsByTopic(allQuestions);
      
      // Process each topic
      for (final entry in topicGroups.entries) {
        final topic = entry.key;
        final questions = entry.value;
        
        // Skip empty question lists
        if (questions.isEmpty) {
          print('WARNING: No questions found for topic: $topic');
          continue;
        }
        
        // Generate analysis for this topic
        final analysis = _generateTopicAnalysis(topic, questions);
        
        // Save to file (once per topic)
        await _saveTopicAnalysis(topic, analysis);
        
        print('✓ Analyzed ${questions.length} questions for topic: $topic');
      }
      
      print('PYQ pattern analysis completed successfully!');
    } catch (e) {
      print('ERROR: Pattern analysis failed - $e');
      exit(1);
    }
  }

  /// Load all questions from question manifest
  static Future<List<Map<String, dynamic>>> _loadAllQuestions() async {
    final questions = <Map<String, dynamic>>[];
    
    try {
      // Load question manifest
      final manifestFile = File(path.join(questionsPath, 'question_manifest.json'));
      if (!await manifestFile.exists()) {
        print('ERROR: question_manifest.json not found');
        return questions;
      }
      
      final manifestContent = await manifestFile.readAsString();
      final manifest = json.decode(manifestContent) as Map<String, dynamic>;
      final files = manifest['files'] as List<dynamic>? ?? [];
      
      // Load each question file
      for (final fileName in files) {
        final filePath = path.join(questionsPath, fileName);
        final file = File(filePath);
        
        if (await file.exists()) {
          try {
            final content = await file.readAsString();
            final questionList = json.decode(content) as List<dynamic>;
            
            for (final question in questionList) {
              if (question is Map<String, dynamic>) {
                questions.add(question);
              }
            }
          } catch (e) {
            print('WARNING: Failed to load questions from $fileName - $e');
          }
        }
      }
    } catch (e) {
      print('ERROR: Failed to load questions - $e');
    }
    
    return questions;
  }

  /// Group questions by topic
  static Map<String, List<Map<String, dynamic>>> _groupQuestionsByTopic(
      List<Map<String, dynamic>> questions) {
    final topicGroups = <String, List<Map<String, dynamic>>>{};
    
    for (final question in questions) {
      final topic = question['topic'] as String? ?? 'Unknown';
      
      if (!topicGroups.containsKey(topic)) {
        topicGroups[topic] = [];
      }
      
      // Avoid duplicate IDs by checking if question already exists
      final questionId = question['question_id'] as String?;
      if (questionId != null) {
        final exists = topicGroups[topic]!.any((q) => 
            q['question_id'] as String? == questionId);
        
        if (!exists) {
          topicGroups[topic]!.add(question);
        }
      }
    }
    
    return topicGroups;
  }

  /// Generate analysis for a specific topic
  static Map<String, dynamic> _generateTopicAnalysis(
      String topic, List<Map<String, dynamic>> questions) {
    final analysis = <String, dynamic>{
      'topic': topic,
      'total_questions': questions.length,
      'analysis_date': DateTime.now().toIso8601String(),
      'questions': <Map<String, dynamic>>[]
    };
    
    // Analyze patterns and add questions
    for (final question in questions) {
      final questionAnalysis = _analyzeQuestion(question);
      analysis['questions'].add(questionAnalysis);
    }
    
    return analysis;
  }

  /// Analyze individual question
  static Map<String, dynamic> _analyzeQuestion(Map<String, dynamic> question) {
    return {
      'question_id': question['question_id'],
      'difficulty': question['difficulty'] ?? 'medium',
      'exam_type': question['exam_type'] ?? 'foundation',
      'primary_concept': question['primary_concept'] ?? '',
      'estimated_time': question['expected_time_seconds'] ?? 120,
      'frequently_asked': question['frequently_asked'] ?? false,
      'high_weight': question['high_weight'] ?? false,
    };
  }

  /// Save topic analysis to file (once per topic)
  static Future<void> _saveTopicAnalysis(
      String topic, Map<String, dynamic> analysis) async {
    try {
      // Create output directory if it doesn't exist
      final outputDir = Directory(outputPath);
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      
      // Generate filename (avoid duplicate IDs like *_fixed)
      final sanitizedTopic = topic.toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      
      final fileName = '${sanitizedTopic}_analysis.json';
      final filePath = path.join(outputPath, fileName);
      
      // Save analysis
      final file = File(filePath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(analysis)
      );
      
      print('✓ Saved analysis: $fileName');
    } catch (e) {
      print('ERROR: Failed to save analysis for topic $topic - $e');
    }
  }
}

/// Main entry point
void main(List<String> args) async {
  await PyqPatternAnalyzer.analyzePatterns();
}