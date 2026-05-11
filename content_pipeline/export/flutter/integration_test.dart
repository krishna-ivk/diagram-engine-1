/// End-to-End Integration Tests for Content Pipeline to Flutter App
/// Validates that content pipeline exports work correctly with QuestionData models

import 'dart:io';
import 'dart:convert';
import 'question_data_loader.dart';
import 'question_data.dart';

void main() async {
  print('🚀 Running Content Pipeline Integration Tests...\n');
  
  final testRunner = IntegrationTestRunner();
  await testRunner.runAllTests();
}

class IntegrationTestRunner {
  String pipelinePath = 'content_pipeline';
  String exportPath = 'content_pipeline/export/app';
  
  Future<void> runAllTests() async {
    final tests = [
      testQuestionDataSchema,
      testConceptGraphConsistency,
      testRescueLadderReferences,
      testDiagramReferences,
      testQualityThresholds,
      testCopyrightLineage,
      testClassFloorLogic,
      testAppReadyValidation,
      testEndToEndWorkflow,
    ];
    
    int passed = 0;
    int total = tests.length;
    
    for (final test in tests) {
      try {
        await test();
        print('✅ ${test.toString().split(':').last.trim()} PASSED');
        passed++;
      } catch (e) {
        print('❌ ${test.toString().split(':').last.trim()} FAILED: $e');
      }
    }
    
    print('\n📊 Test Results: $passed/$total tests passed');
    
    if (passed == total) {
      print('🎉 All integration tests passed! Content pipeline is ready for app integration.');
    } else {
      print('⚠️  Some tests failed. Review and fix issues before app integration.');
    }
  }
  
  /// Test 1: Question Data Schema Validation
  Future<void> testQuestionDataSchema() async {
    print('\n🧪 Testing Question Data Schema Validation...');
    
    // Load sample question export
    final questions = await QuestionDataLoader.loadQuestions('$exportPath/question_data_v1.json');
    
    if (questions.isEmpty) {
      throw Exception('No questions found in export');
    }
    
    // Validate each question
    for (final question in questions) {
      // Required fields
      if (question.id.isEmpty) throw Exception('Question missing ID');
      if (question.questionText.isEmpty) throw Exception('Question missing text');
      if (question.primaryConcept.isEmpty) throw Exception('Question missing primary concept');
      if (question.correctAnswer == null) throw Exception('Question missing correct answer');
      
      // Validate concept ID format
      if (!RegExp(r'^math\.[a-z_]+\.[a-z_]+$').hasMatch(question.primaryConcept)) {
        throw Exception('Invalid concept ID format: ${question.primaryConcept}');
      }
      
      // Validate solution steps
      if (question.solutionSteps.isEmpty) {
        throw Exception('Question ${question.id} missing solution steps');
      }
      
      // Validate options for MCQ
      if (question.questionType == 'multiple_choice') {
        if (question.options.length != 4) {
          throw Exception('MCQ must have exactly 4 options');
        }
        
        final correctOptions = question.options.where((opt) => opt.isCorrect).toList();
        if (correctOptions.length != 1) {
          throw Exception('MCQ must have exactly one correct option');
        }
        
        // Check why-wrong explanations for incorrect options
        final incorrectOptions = question.options.where((opt) => !opt.isCorrect);
        for (final option in incorrectOptions) {
          if (option.whyWrong == null || option.whyWrong!.isEmpty) {
            throw Exception('Incorrect option missing why-wrong explanation');
          }
        }
      }
    }
    
    print('   ✓ Validated ${questions.length} questions');
  }
  
  /// Test 2: Concept Graph Consistency
  Future<void> testConceptGraphConsistency() async {
    print('\n🧪 Testing Concept Graph Consistency...');
    
    // Load concept graph
    final conceptGraph = await QuestionDataLoader.loadConceptGraph('$exportPath/concept_graph_v1.json');
    
    if (conceptGraph.concepts.isEmpty) {
      throw Exception('No concepts found in concept graph');
    }
    
    // Validate concept structure
    for (final conceptId in conceptGraph.concepts.keys) {
      if (!RegExp(r'^math\.[a-z_]+\.[a-z_]+$').hasMatch(conceptId)) {
        throw Exception('Invalid concept ID format: $conceptId');
      }
      
      final concept = conceptGraph.concepts[conceptId]!;
      
      // Validate required fields
      if (concept.name.isEmpty) throw Exception('Concept $conceptId missing name');
      if (concept.subject.isEmpty) throw Exception('Concept $conceptId missing subject');
      
      // Validate class levels
      if (concept.classFloor < 6 || concept.classFloor > 12) {
        throw Exception('Invalid class floor for concept $conceptId: ${concept.classFloor}');
      }
      
      if (concept.classCeiling < concept.classFloor || concept.classCeiling > 12) {
        throw Exception('Invalid class ceiling for concept $conceptId');
      }
      
      // Validate prerequisites exist
      for (final prereq in concept.prerequisites) {
        if (!conceptGraph.concepts.containsKey(prereq)) {
          throw Exception('Prerequisite $prereq not found for concept $conceptId');
        }
      }
    }
    
    print('   ✓ Validated ${conceptGraph.concepts.length} concepts');
  }
  
  /// Test 3: Rescue Ladder References
  Future<void> testRescueLadderReferences() async {
    print('\n🧪 Testing Rescue Ladder References...');
    
    // Load questions and rescue ladders
    final questions = await QuestionDataLoader.loadQuestions('$exportPath/question_data_v1.json');
    final rescueLadders = await QuestionDataLoader.loadRescueLadders('$exportPath/rescue_ladders_v1.json');
    
    // Validate rescue ladder references in questions
    for (final question in questions) {
      for (final rescueId in question.rescueLadderIds) {
        if (!rescueLadders.containsKey(rescueId)) {
          throw Exception('Rescue ladder $rescueId not found for question ${question.id}');
        }
        
        // Validate rescue ladder structure
        final ladder = rescueLadders[rescueId]!;
        if (ladder.rescueSteps.isEmpty) {
          throw Exception('Rescue ladder $rescueId has no steps');
        }
        
        // Validate step sequence
        for (int i = 0; i < ladder.rescueSteps.length; i++) {
          if (ladder.rescueSteps[i].stepNumber != i + 1) {
            throw Exception('Invalid step number in rescue ladder $rescueId');
          }
        }
      }
    }
    
    print('   ✓ Validated rescue ladder references');
  }
  
  /// Test 4: Diagram References
  Future<void> testDiagramReferences() async {
    print('\n🧪 Testing Diagram References...');
    
    // Load questions and diagram specs
    final questions = await QuestionDataLoader.loadQuestions('$exportPath/question_data_v1.json');
    final diagramSpecs = await QuestionDataLoader.loadDiagramSpecs('$exportPath/diagram_specs_v1.json');
    
    // Validate diagram references
    for (final question in questions) {
      if (question.diagramRequired) {
        final diagramId = '${question.id}_diagram';
        
        if (!diagramSpecs.containsKey(diagramId)) {
          throw Exception('Diagram spec $diagramId not found for question ${question.id}');
        }
        
        final diagramSpec = diagramSpecs[diagramId]!;
        
        // Validate diagram elements
        if (diagramSpec.elements.isEmpty) {
          throw Exception('Diagram $diagramId has no elements');
        }
        
        // Check element IDs are unique
        final elementIds = diagramSpec.elements.map((e) => e.id).toSet();
        if (elementIds.length != diagramSpec.elements.length) {
          throw Exception('Duplicate element IDs in diagram $diagramId');
        }
        
        // Validate solution step diagram references
        for (final step in question.solutionSteps) {
          if (step.diagramElementId != null) {
            final elementExists = diagramSpec.elements.any((e) => e.id == step.diagramElementId);
            if (!elementExists) {
              throw Exception('Diagram element ${step.diagramElementId} not found in $diagramId');
            }
          }
        }
      }
    }
    
    print('   ✓ Validated diagram references');
  }
  
  /// Test 5: Quality Thresholds
  Future<void> testQualityThresholds() async {
    print('\n🧪 Testing Quality Thresholds...');
    
    // Load questions
    final questions = await QuestionDataLoader.loadQuestions('$exportPath/question_data_v1.json');
    
    int publishableCount = 0;
    int belowThresholdCount = 0;
    
    for (final question in questions) {
      // Check learning objective score
      if (question.learningObjectiveScore < 85.0) {
        belowThresholdCount++;
        if (question.reviewStatus == 'published') {
          throw Exception('Question ${question.id} published below quality threshold');
        }
      } else {
        publishableCount++;
      }
      
      // Check review status
      if (question.reviewStatus == 'published' && question.learningObjectiveScore < 85.0) {
        throw Exception('Published question below quality threshold: ${question.id}');
      }
    }
    
    if (publishableCount == 0) {
      throw Exception('No questions meet quality threshold');
    }
    
    print('   ✓ $publishableCount questions meet quality threshold');
    print('   ✓ $belowThresholdCount questions below threshold (not published)');
  }
  
  /// Test 6: Copyright Lineage
  Future<void> testCopyrightLineage() async {
    print('\n🧪 Testing Copyright Lineage...');
    
    // Load questions
    final questions = await QuestionDataLoader.loadQuestions('$exportPath/question_data_v1.json');
    
    for (final question in questions) {
      final lineage = question.lineage;
      
      // Validate required lineage fields
      if (lineage.transformationType.isEmpty) {
        throw Exception('Question ${question.id} missing transformation type');
      }
      
      if (lineage.verbatimSourceUsed && lineage.transformationType != 'original_content') {
        throw Exception('Question ${question.id} uses verbatim source but not marked as original');
      }
      
      // Validate transformation type
      final validTypes = [
        'original_content',
        'original_question_from_pattern', 
        'adapted_from_source',
        'concept_alignment_only'
      ];
      
      if (!validTypes.contains(lineage.transformationType)) {
        throw Exception('Invalid transformation type: ${lineage.transformationType}');
      }
      
      // Check human review requirement
      if (lineage.transformationType != 'original_content' && !lineage.humanReviewRequired) {
        throw Exception('Non-original content should require human review');
      }
    }
    
    print('   ✓ Validated copyright lineage for ${questions.length} questions');
  }
  
  /// Test 7: Class Floor Logic
  Future<void> testClassFloorLogic() async {
    print('\n🧪 Testing Class Floor Logic...');
    
    // Load questions and concepts
    final questions = await QuestionDataLoader.loadQuestions('$exportPath/question_data_v1.json');
    final conceptGraph = await QuestionDataLoader.loadConceptGraph('$exportPath/concept_graph_v1.json');
    
    for (final question in questions) {
      // Validate class floor logic
      if (question.classFloor > question.targetClass) {
        throw Exception('Class floor (${question.classFloor}) cannot be higher than target class (${question.targetClass})');
      }
      
      if (question.rescueStartLevel > question.classFloor) {
        throw Exception('Rescue start level (${question.rescueStartLevel}) cannot be higher than class floor (${question.classFloor})');
      }
      
      // Validate concept class alignment
      final concept = conceptGraph.concepts[question.primaryConcept];
      if (concept != null) {
        if (question.targetClass < concept.classFloor || question.targetClass > concept.classCeiling) {
          throw Exception('Question target class ${question.targetClass} outside concept range ${concept.classFloor}-${concept.classCeiling}');
        }
      }
      
      // Validate difficulty-appropriate class levels
      if (question.difficulty == 'foundation' && question.targetClass > 10) {
        throw Exception('Foundation question should not target class > 10');
      }
      
      if (question.difficulty == 'mock_exam' && question.targetClass < 11) {
        throw Exception('Mock exam question should target class >= 11');
      }
    }
    
    print('   ✓ Validated class floor logic');
  }
  
  /// Test 8: App Ready Validation
  Future<void> testAppReadyValidation() async {
    print('\n🧪 Testing App Ready Validation...');
    
    // Load questions
    final questions = await QuestionDataLoader.loadQuestions('$exportPath/question_data_v1.json');
    
    int appReadyCount = 0;
    int notReadyCount = 0;
    
    for (final question in questions) {
      if (question.isAppReady) {
        appReadyCount++;
        
        // Additional app-ready validations
        if (question.prerequisites.isEmpty) {
          throw Exception('App-ready question should have prerequisites');
        }
        
        if (question.difficulty != 'foundation' && question.rescueLadderIds.isEmpty) {
          throw Exception('Non-foundation app-ready question should have rescue ladders');
        }
        
      } else {
        notReadyCount++;
      }
    }
    
    if (appReadyCount == 0) {
      throw Exception('No questions are app-ready');
    }
    
    print('   ✓ $appReadyCount questions are app-ready');
    print('   ✓ $notReadyCount questions need more work');
  }
  
  /// Test 9: End-to-End Workflow
  Future<void> testEndToEndWorkflow() async {
    print('\n🧪 Testing End-to-End Workflow...');
    
    // Load all content
    final questions = await QuestionDataLoader.loadQuestions('$exportPath/question_data_v1.json');
    final conceptGraph = await QuestionDataLoader.loadConceptGraph('$exportPath/concept_graph_v1.json');
    final rescueLadders = await QuestionDataLoader.loadRescueLadders('$exportPath/rescue_ladders_v1.json');
    final diagramSpecs = await QuestionDataLoader.loadDiagramSpecs('$exportPath/diagram_specs_v1.json');
    
    // Validate cross-references
    final conceptValidation = await QuestionDataLoader.validateQuestionConcepts(questions, conceptGraph);
    if (!conceptValidation.isValid) {
      throw Exception('Concept validation failed: ${conceptValidation.errors.join(', ')}');
    }
    
    final diagramValidation = await QuestionDataLoader.validateDiagramReferences(questions, diagramSpecs);
    if (!diagramValidation.isValid) {
      throw Exception('Diagram validation failed: ${diagramValidation.errors.join(', ')}');
    }
    
    // Test export for Flutter
    final tempExportPath = '$pipelinePath/export/flutter_test.json';
    await QuestionDataLoader.exportForFlutter(
      questions,
      conceptGraph,
      rescueLadders,
      diagramSpecs,
      tempExportPath,
    );
    
    // Validate export file
    final exportFile = File(tempExportPath);
    if (!await exportFile.exists()) {
      throw Exception('Flutter export file not created');
    }
    
    final exportContent = await exportFile.readAsString();
    final exportData = json.decode(exportContent) as Map<String, dynamic>;
    
    // Validate export structure
    if (!exportData.containsKey('questions')) throw Exception('Export missing questions');
    if (!exportData.containsKey('concepts')) throw Exception('Export missing concepts');
    if (!exportData.containsKey('rescue_ladders')) throw Exception('Export missing rescue ladders');
    if (!exportData.containsKey('diagram_specs')) throw Exception('Export missing diagram specs');
    
    // Clean up
    await exportFile.delete();
    
    print('   ✓ End-to-end workflow validated');
    print('   ✓ Flutter export generated successfully');
  }
}