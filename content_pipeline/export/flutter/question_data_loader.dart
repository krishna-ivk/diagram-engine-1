/// Question Data Loader for Diagram Engine Flutter App
/// Converts content pipeline exports to QuestionData objects

import 'dart:convert';
import 'dart:io';
import 'question_data.dart';

class QuestionDataLoader {
  /// Load questions from content pipeline export
  static Future<List<QuestionData>> loadQuestions(String exportPath) async {
    final file = File(exportPath);
    if (!await file.exists()) {
      throw Exception('Question export file not found: $exportPath');
    }
    
    final content = await file.readAsString();
    final Map<String, dynamic> data = json.decode(content);
    
    final List<QuestionData> questions = [];
    
    // Handle different export formats
    if (data.containsKey('questions')) {
      // Batch export format
      final List<dynamic> questionsList = data['questions'];
      for (final questionJson in questionsList) {
        try {
          final question = QuestionData.fromJson(questionJson);
          questions.add(question);
        } catch (e) {
          print('Error loading question: $e');
        }
      }
    } else if (data.containsKey('id')) {
      // Single question format
      try {
        final question = QuestionData.fromJson(data);
        questions.add(question);
      } catch (e) {
        print('Error loading single question: $e');
      }
    }
    
    return questions;
  }
  
  /// Load concept graph from content pipeline export
  static Future<ConceptGraph> loadConceptGraph(String exportPath) async {
    final file = File(exportPath);
    if (!await file.exists()) {
      throw Exception('Concept graph export file not found: $exportPath');
    }
    
    final content = await file.readAsString();
    final Map<String, dynamic> data = json.decode(content);
    
    return ConceptGraph.fromJson(data);
  }
  
  /// Load rescue ladders from content pipeline export
  static Future<Map<String, RescueLadder>> loadRescueLadders(String exportPath) async {
    final file = File(exportPath);
    if (!await file.exists()) {
      throw Exception('Rescue ladders export file not found: $exportPath');
    }
    
    final content = await file.readAsString();
    final Map<String, dynamic> data = json.decode(content);
    
    final Map<String, RescueLadder> ladders = {};
    final Map<String, dynamic> laddersData = data['ladders'];
    
    laddersData.forEach((key, ladderJson) {
      try {
        ladders[key] = RescueLadder.fromJson(ladderJson);
      } catch (e) {
        print('Error loading rescue ladder $key: $e');
      }
    });
    
    return ladders;
  }
  
  /// Load diagram specifications from content pipeline export
  static Future<Map<String, DiagramSpec>> loadDiagramSpecs(String exportPath) async {
    final file = File(exportPath);
    if (!await file.exists()) {
      throw Exception('Diagram specs export file not found: $exportPath');
    }
    
    final content = await file.readAsString();
    final Map<String, dynamic> data = json.decode(content);
    
    final Map<String, DiagramSpec> diagrams = {};
    final Map<String, dynamic> diagramsData = data['diagrams'];
    
    diagramsData.forEach((key, diagramJson) {
      try {
        diagrams[key] = DiagramSpec.fromJson(diagramJson);
      } catch (e) {
        print('Error loading diagram spec $key: $e');
      }
    });
    
    return diagrams;
  }
  
  /// Validate that all questions have valid concept references
  static Future<ValidationResult> validateQuestionConcepts(
    List<QuestionData> questions,
    ConceptGraph conceptGraph,
  ) async {
    final List<String> errors = [];
    final List<String> warnings = [];
    
    for (final question in questions) {
      // Validate primary concept
      if (!conceptGraph.concepts.containsKey(question.primaryConcept)) {
        errors.add('Question ${question.id}: Primary concept "${question.primaryConcept}" not found in concept graph');
      }
      
      // Validate secondary concepts
      for (final concept in question.secondaryConcepts) {
        if (!conceptGraph.concepts.containsKey(concept)) {
          warnings.add('Question ${question.id}: Secondary concept "$concept" not found in concept graph');
        }
      }
      
      // Validate prerequisites
      for (final prereq in question.prerequisites) {
        if (!conceptGraph.concepts.containsKey(prereq)) {
          errors.add('Question ${question.id}: Prerequisite "$prereq" not found in concept graph');
        }
      }
      
      // Validate rescue ladder question references
      for (final rescueId in question.rescueLadderIds) {
        final rescueQuestion = questions.where((q) => q.id == rescueId).firstOrNull;
        if (rescueQuestion == null) {
          errors.add('Question ${question.id}: Rescue question "$rescueId" not found');
        }
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Validate that all diagram references are valid
  static Future<ValidationResult> validateDiagramReferences(
    List<QuestionData> questions,
    Map<String, DiagramSpec> diagramSpecs,
  ) async {
    final List<String> errors = [];
    final List<String> warnings = [];
    
    for (final question in questions) {
      if (question.diagramRequired) {
        // Check if diagram spec exists
        final diagramId = '${question.id}_diagram';
        if (!diagramSpecs.containsKey(diagramId)) {
          warnings.add('Question ${question.id}: Diagram required but no spec found for $diagramId');
        }
        
        // Check solution step diagram references
        for (final step in question.solutionSteps) {
          if (step.diagramElementId != null) {
            final diagramSpec = diagramSpecs[diagramId];
            if (diagramSpec != null) {
              final elementExists = diagramSpec.elements.any((e) => e.id == step.diagramElementId);
              if (!elementExists) {
                errors.add('Question ${question.id}: Diagram element "${step.diagramElementId}" not found in diagram spec');
              }
            }
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
  
  /// Export questions to Flutter-ready format
  static Future<void> exportForFlutter(
    List<QuestionData> questions,
    ConceptGraph conceptGraph,
    Map<String, RescueLadder> rescueLadders,
    Map<String, DiagramSpec> diagramSpecs,
    String outputPath,
  ) async {
    final exportData = {
      'version': '1.0',
      'generated_at': DateTime.now().toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'concepts': conceptGraph.toJson(),
      'rescue_ladders': rescueLadders.map((k, v) => MapEntry(k, v.toJson())),
      'diagram_specs': diagramSpecs.map((k, v) => MapEntry(k, v.toJson())),
    };
    
    final file = File(outputPath);
    await file.writeAsString(json.encode(exportData));
  }
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  
  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Validation Result: ${isValid ? "VALID" : "INVALID"}');
    
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
}