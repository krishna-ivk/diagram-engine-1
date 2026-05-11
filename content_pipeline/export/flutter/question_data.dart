/// Question Data Models for Diagram Engine Flutter App
/// Compatible with content pipeline export format

import 'dart:convert';

/// Main question data model
class QuestionData {
  final String id;
  final String questionText;
  final String questionType;
  final List<QuestionOption> options;
  final dynamic correctAnswer;
  final String primaryConcept;
  final List<String> secondaryConcepts;
  final String difficulty;
  final int estimatedTime;
  final List<SolutionStep> solutionSteps;
  final Map<String, String> whyWrongExplanations;
  final List<MistakePattern> mistakePatterns;
  final List<String> prerequisites;
  final List<String> rescueLadderIds;
  final bool diagramRequired;
  final DiagramSpec? diagramSpec;
  final int targetClass;
  final int classFloor;
  final int rescueStartLevel;
  final double learningObjectiveScore;
  final String reviewStatus;
  final ContentLineage lineage;
  
  QuestionData({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.options,
    required this.correctAnswer,
    required this.primaryConcept,
    this.secondaryConcepts = const [],
    required this.difficulty,
    required this.estimatedTime,
    required this.solutionSteps,
    this.whyWrongExplanations = const {},
    this.mistakePatterns = const [],
    this.prerequisites = const [],
    this.rescueLadderIds = const [],
    this.diagramRequired = false,
    this.diagramSpec,
    required this.targetClass,
    required this.classFloor,
    required this.rescueStartLevel,
    required this.learningObjectiveScore,
    required this.reviewStatus,
    required this.lineage,
  });
  
  factory QuestionData.fromJson(Map<String, dynamic> json) {
    return QuestionData(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      questionType: json['questionType'] as String,
      options: (json['options'] as List<dynamic>)
          .map((opt) => QuestionOption.fromJson(opt as Map<String, dynamic>))
          .toList(),
      correctAnswer: json['correctAnswer'],
      primaryConcept: json['primaryConcept'] as String,
      secondaryConcepts: (json['secondaryConcepts'] as List<dynamic>?)
          ?.map((s) => s as String)
          .toList() ?? [],
      difficulty: json['difficulty'] as String,
      estimatedTime: json['estimatedTime'] as int,
      solutionSteps: (json['solutionSteps'] as List<dynamic>)
          .map((step) => SolutionStep.fromJson(step as Map<String, dynamic>))
          .toList(),
      whyWrongExplanations: Map<String, String>.from(json['whyWrongExplanations'] ?? {}),
      mistakePatterns: (json['mistakePatterns'] as List<dynamic>?)
          ?.map((pattern) => MistakePattern.fromJson(pattern as Map<String, dynamic>))
          .toList() ?? [],
      prerequisites: (json['prerequisites'] as List<dynamic>?)
          ?.map((s) => s as String)
          .toList() ?? [],
      rescueLadderIds: (json['rescueLadderIds'] as List<dynamic>?)
          ?.map((s) => s as String)
          .toList() ?? [],
      diagramRequired: json['diagramRequired'] as bool? ?? false,
      diagramSpec: json['diagramSpec'] != null 
          ? DiagramSpec.fromJson(json['diagramSpec'] as Map<String, dynamic>)
          : null,
      targetClass: json['targetClass'] as int,
      classFloor: json['classFloor'] as int,
      rescueStartLevel: json['rescueStartLevel'] as int,
      learningObjectiveScore: (json['learningObjectiveScore'] as num).toDouble(),
      reviewStatus: json['reviewStatus'] as String,
      lineage: ContentLineage.fromJson(json['lineage'] as Map<String, dynamic>),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'questionType': questionType,
      'options': options.map((opt) => opt.toJson()).toList(),
      'correctAnswer': correctAnswer,
      'primaryConcept': primaryConcept,
      'secondaryConcepts': secondaryConcepts,
      'difficulty': difficulty,
      'estimatedTime': estimatedTime,
      'solutionSteps': solutionSteps.map((step) => step.toJson()).toList(),
      'whyWrongExplanations': whyWrongExplanations,
      'mistakePatterns': mistakePatterns.map((pattern) => pattern.toJson()).toList(),
      'prerequisites': prerequisites,
      'rescueLadderIds': rescueLadderIds,
      'diagramRequired': diagramRequired,
      'diagramSpec': diagramSpec?.toJson(),
      'targetClass': targetClass,
      'classFloor': classFloor,
      'rescueStartLevel': rescueStartLevel,
      'learningObjectiveScore': learningObjectiveScore,
      'reviewStatus': reviewStatus,
      'lineage': lineage.toJson(),
    };
  }
  
  /// Check if this question is ready for use in the app
  bool get isAppReady {
    return learningObjectiveScore >= 85.0 &&
           reviewStatus == 'published' &&
           prerequisites.isNotEmpty &&
           (difficulty == 'foundation' || rescueLadderIds.isNotEmpty);
  }
  
  /// Get the appropriate rescue starting level for a given student level
  int getRescueLevelForStudent(int studentLevel) {
    if (studentLevel >= classFloor) {
      return classFloor;
    }
    return rescueStartLevel;
  }
}

/// Question option model
class QuestionOption {
  final String label;
  final String text;
  final bool isCorrect;
  final String? whyWrong;
  
  QuestionOption({
    required this.label,
    required this.text,
    required this.isCorrect,
    this.whyWrong,
  });
  
  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      label: json['label'] as String,
      text: json['text'] as String,
      isCorrect: json['isCorrect'] as bool,
      whyWrong: json['whyWrong'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'text': text,
      'isCorrect': isCorrect,
      if (whyWrong != null) 'whyWrong': whyWrong,
    };
  }
}

/// Solution step model
class SolutionStep {
  final int stepNumber;
  final String description;
  final String calculation;
  final String? diagramElementId;
  
  SolutionStep({
    required this.stepNumber,
    required this.description,
    required this.calculation,
    this.diagramElementId,
  });
  
  factory SolutionStep.fromJson(Map<String, dynamic> json) {
    return SolutionStep(
      stepNumber: json['stepNumber'] as int,
      description: json['description'] as String,
      calculation: json['calculation'] as String,
      diagramElementId: json['diagramElementId'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'description': description,
      'calculation': calculation,
      if (diagramElementId != null) 'diagramElementId': diagramElementId,
    };
  }
}

/// Mistake pattern model
class MistakePattern {
  final String pattern;
  final String whyWrong;
  final String frequency;
  final String? rescueConceptId;
  
  MistakePattern({
    required this.pattern,
    required this.whyWrong,
    required this.frequency,
    this.rescueConceptId,
  });
  
  factory MistakePattern.fromJson(Map<String, dynamic> json) {
    return MistakePattern(
      pattern: json['pattern'] as String,
      whyWrong: json['whyWrong'] as String,
      frequency: json['frequency'] as String,
      rescueConceptId: json['rescueConceptId'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern,
      'whyWrong': whyWrong,
      'frequency': frequency,
      if (rescueConceptId != null) 'rescueConceptId': rescueConceptId,
    };
  }
}

/// Content lineage model
class ContentLineage {
  final List<String> inspiredBy;
  final List<String> ncertAlignment;
  final String transformationType;
  final bool verbatimSourceUsed;
  final bool humanReviewRequired;
  
  ContentLineage({
    required this.inspiredBy,
    required this.ncertAlignment,
    required this.transformationType,
    required this.verbatimSourceUsed,
    required this.humanReviewRequired,
  });
  
  factory ContentLineage.fromJson(Map<String, dynamic> json) {
    return ContentLineage(
      inspiredBy: (json['inspiredBy'] as List<dynamic>?)
          ?.map((s) => s as String)
          .toList() ?? [],
      ncertAlignment: (json['ncertAlignment'] as List<dynamic>?)
          ?.map((s) => s as String)
          .toList() ?? [],
      transformationType: json['transformationType'] as String,
      verbatimSourceUsed: json['verbatimSourceUsed'] as bool,
      humanReviewRequired: json['humanReviewRequired'] as bool,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'inspiredBy': inspiredBy,
      'ncertAlignment': ncertAlignment,
      'transformationType': transformationType,
      'verbatimSourceUsed': verbatimSourceUsed,
      'humanReviewRequired': humanReviewRequired,
    };
  }
}

/// Concept graph model
class ConceptGraph {
  final Map<String, ConceptNode> concepts;
  final Map<String, List<String>> prerequisites;
  final MasteryTracking masteryTracking;
  
  ConceptGraph({
    required this.concepts,
    required this.prerequisites,
    required this.masteryTracking,
  });
  
  factory ConceptGraph.fromJson(Map<String, dynamic> json) {
    final conceptsData = json['concepts'] as Map<String, dynamic>;
    final concepts = conceptsData.map((key, value) => 
      MapEntry(key, ConceptNode.fromJson(value as Map<String, dynamic>)));
    
    final prerequisitesData = json['prerequisites'] as Map<String, dynamic>;
    final prerequisites = prerequisitesData.map((key, value) => 
      MapEntry(key, (value as List<dynamic>).map((s) => s as String).toList()));
    
    return ConceptGraph(
      concepts: concepts,
      prerequisites: prerequisites,
      masteryTracking: MasteryTracking.fromJson(json['masteryTracking'] as Map<String, dynamic>),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'concepts': concepts.map((key, value) => MapEntry(key, value.toJson())),
      'prerequisites': prerequisites,
      'masteryTracking': masteryTracking.toJson(),
    };
  }
}

/// Concept node model
class ConceptNode {
  final String id;
  final String name;
  final String displayName;
  final String subject;
  final String chapter;
  final int classFloor;
  final int classCeiling;
  final String jeeRelevance;
  final List<String> prerequisites;
  final List<String> learningOutcomes;
  final List<String> commonMisconceptions;
  final EstimatedTime estimatedMasteryTime;
  final bool diagramRequired;
  final List<String> diagramTypes;
  
  ConceptNode({
    required this.id,
    required this.name,
    required this.displayName,
    required this.subject,
    required this.chapter,
    required this.classFloor,
    required this.classCeiling,
    required this.jeeRelevance,
    required this.prerequisites,
    required this.learningOutcomes,
    required this.commonMisconceptions,
    required this.estimatedMasteryTime,
    required this.diagramRequired,
    required this.diagramTypes,
  });
  
  factory ConceptNode.fromJson(Map<String, dynamic> json) {
    return ConceptNode(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      subject: json['subject'] as String,
      chapter: json['chapter'] as String,
      classFloor: json['classFloor'] as int,
      classCeiling: json['classCeiling'] as int,
      jeeRelevance: json['jeeRelevance'] as String,
      prerequisites: (json['prerequisites'] as List<dynamic>)
          .map((s) => s as String)
          .toList(),
      learningOutcomes: (json['learningOutcomes'] as List<dynamic>)
          .map((s) => s as String)
          .toList(),
      commonMisconceptions: (json['commonMisconceptions'] as List<dynamic>)
          .map((s) => s as String)
          .toList(),
      estimatedMasteryTime: EstimatedTime.fromJson(json['estimatedMasteryTime'] as Map<String, dynamic>),
      diagramRequired: json['diagramRequired'] as bool,
      diagramTypes: (json['diagramTypes'] as List<dynamic>)
          .map((s) => s as String)
          .toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'subject': subject,
      'chapter': chapter,
      'classFloor': classFloor,
      'classCeiling': classCeiling,
      'jeeRelevance': jeeRelevance,
      'prerequisites': prerequisites,
      'learningOutcomes': learningOutcomes,
      'commonMisconceptions': commonMisconceptions,
      'estimatedMasteryTime': estimatedMasteryTime.toJson(),
      'diagramRequired': diagramRequired,
      'diagramTypes': diagramTypes,
    };
  }
}

/// Estimated time model
class EstimatedTime {
  final int averageMinutes;
  final int strugglingStudentMinutes;
  
  EstimatedTime({
    required this.averageMinutes,
    required this.strugglingStudentMinutes,
  });
  
  factory EstimatedTime.fromJson(Map<String, dynamic> json) {
    return EstimatedTime(
      averageMinutes: json['averageMinutes'] as int,
      strugglingStudentMinutes: json['strugglingStudentMinutes'] as int,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'averageMinutes': averageMinutes,
      'strugglingStudentMinutes': strugglingStudentMinutes,
    };
  }
}

/// Mastery tracking model
class MasteryTracking {
  final Map<String, ConceptLevels> conceptLevels;
  
  MasteryTracking({
    required this.conceptLevels,
  });
  
  factory MasteryTracking.fromJson(Map<String, dynamic> json) {
    final levelsData = json['conceptLevels'] as Map<String, dynamic>;
    final conceptLevels = levelsData.map((key, value) => 
      MapEntry(key, ConceptLevels.fromJson(value as Map<String, dynamic>)));
    
    return MasteryTracking(conceptLevels: conceptLevels);
  }
  
  Map<String, dynamic> toJson() {
    return {
      'conceptLevels': conceptLevels.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

/// Concept levels model
class ConceptLevels {
  final List<String> foundation;
  final List<String> developing;
  final List<String> proficient;
  final List<String> advanced;
  
  ConceptLevels({
    required this.foundation,
    required this.developing,
    required this.proficient,
    required this.advanced,
  });
  
  factory ConceptLevels.fromJson(Map<String, dynamic> json) {
    return ConceptLevels(
      foundation: (json['foundation'] as List<dynamic>).map((s) => s as String).toList(),
      developing: (json['developing'] as List<dynamic>).map((s) => s as String).toList(),
      proficient: (json['proficient'] as List<dynamic>).map((s) => s as String).toList(),
      advanced: (json['advanced'] as List<dynamic>).map((s) => s as String).toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'foundation': foundation,
      'developing': developing,
      'proficient': proficient,
      'advanced': advanced,
    };
  }
}

/// Rescue ladder model
class RescueLadder {
  final String id;
  final String targetConcept;
  final String? targetQuestionId;
  final List<RescueStep> rescueSteps;
  final EntryCriteria? entryCriteria;
  final ExitCriteria? exitCriteria;
  
  RescueLadder({
    required this.id,
    required this.targetConcept,
    this.targetQuestionId,
    required this.rescueSteps,
    this.entryCriteria,
    this.exitCriteria,
  });
  
  factory RescueLadder.fromJson(Map<String, dynamic> json) {
    return RescueLadder(
      id: json['id'] as String,
      targetConcept: json['targetConcept'] as String,
      targetQuestionId: json['targetQuestionId'] as String?,
      rescueSteps: (json['rescueSteps'] as List<dynamic>)
          .map((step) => RescueStep.fromJson(step as Map<String, dynamic>))
          .toList(),
      entryCriteria: json['entryCriteria'] != null
          ? EntryCriteria.fromJson(json['entryCriteria'] as Map<String, dynamic>)
          : null,
      exitCriteria: json['exitCriteria'] != null
          ? ExitCriteria.fromJson(json['exitCriteria'] as Map<String, dynamic>)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetConcept': targetConcept,
      if (targetQuestionId != null) 'targetQuestionId': targetQuestionId,
      'rescueSteps': rescueSteps.map((step) => step.toJson()).toList(),
      if (entryCriteria != null) 'entryCriteria': entryCriteria!.toJson(),
      if (exitCriteria != null) 'exitCriteria': exitCriteria!.toJson(),
    };
  }
}

/// Rescue step model
class RescueStep {
  final int stepNumber;
  final String stepType;
  final String title;
  final String description;
  final String? questionId;
  final String? conceptId;
  final String? hintText;
  final String? diagramSpecification;
  final int? estimatedTime;
  final String? successCriteria;
  
  RescueStep({
    required this.stepNumber,
    required this.stepType,
    required this.title,
    required this.description,
    this.questionId,
    this.conceptId,
    this.hintText,
    this.diagramSpecification,
    this.estimatedTime,
    this.successCriteria,
  });
  
  factory RescueStep.fromJson(Map<String, dynamic> json) {
    return RescueStep(
      stepNumber: json['stepNumber'] as int,
      stepType: json['stepType'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      questionId: json['questionId'] as String?,
      conceptId: json['conceptId'] as String?,
      hintText: json['hintText'] as String?,
      diagramSpecification: json['diagramSpecification'] as String?,
      estimatedTime: json['estimatedTime'] as int?,
      successCriteria: json['successCriteria'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'stepType': stepType,
      'title': title,
      'description': description,
      if (questionId != null) 'questionId': questionId,
      if (conceptId != null) 'conceptId': conceptId,
      if (hintText != null) 'hintText': hintText,
      if (diagramSpecification != null) 'diagramSpecification': diagramSpecification,
      if (estimatedTime != null) 'estimatedTime': estimatedTime,
      if (successCriteria != null) 'successCriteria': successCriteria,
    };
  }
}

/// Entry criteria model
class EntryCriteria {
  final String? failedQuestionId;
  final List<String> mistakePatterns;
  final int? consecutiveFailures;
  
  EntryCriteria({
    this.failedQuestionId,
    required this.mistakePatterns,
    this.consecutiveFailures,
  });
  
  factory EntryCriteria.fromJson(Map<String, dynamic> json) {
    return EntryCriteria(
      failedQuestionId: json['failedQuestionId'] as String?,
      mistakePatterns: (json['mistakePatterns'] as List<dynamic>)
          .map((s) => s as String)
          .toList(),
      consecutiveFailures: json['consecutiveFailures'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (failedQuestionId != null) 'failedQuestionId': failedQuestionId,
      'mistakePatterns': mistakePatterns,
      if (consecutiveFailures != null) 'consecutiveFailures': consecutiveFailures,
    };
  }
}

/// Exit criteria model
class ExitCriteria {
  final bool mustCompleteAllSteps;
  final double? minimumSuccessRate;
  final String? finalAssessmentQuestion;
  
  ExitCriteria({
    required this.mustCompleteAllSteps,
    this.minimumSuccessRate,
    this.finalAssessmentQuestion,
  });
  
  factory ExitCriteria.fromJson(Map<String, dynamic> json) {
    return ExitCriteria(
      mustCompleteAllSteps: json['mustCompleteAllSteps'] as bool,
      minimumSuccessRate: (json['minimumSuccessRate'] as num?)?.toDouble(),
      finalAssessmentQuestion: json['finalAssessmentQuestion'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'mustCompleteAllSteps': mustCompleteAllSteps,
      if (minimumSuccessRate != null) 'minimumSuccessRate': minimumSuccessRate,
      if (finalAssessmentQuestion != null) 'finalAssessmentQuestion': finalAssessmentQuestion,
    };
  }
}

/// Diagram specification model
class DiagramSpec {
  final String id;
  final String type;
  final String? title;
  final String? description;
  final String? associatedQuestionId;
  final String? associatedConceptId;
  final List<DiagramElement> elements;
  final DiagramLayout? layout;
  final DiagramAnimation? animation;
  final DiagramInteraction? interaction;
  final List<String> learningObjectives;
  
  DiagramSpec({
    required this.id,
    required this.type,
    this.title,
    this.description,
    this.associatedQuestionId,
    this.associatedConceptId,
    required this.elements,
    this.layout,
    this.animation,
    this.interaction,
    required this.learningObjectives,
  });
  
  factory DiagramSpec.fromJson(Map<String, dynamic> json) {
    return DiagramSpec(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      associatedQuestionId: json['associatedQuestionId'] as String?,
      associatedConceptId: json['associatedConceptId'] as String?,
      elements: (json['elements'] as List<dynamic>)
          .map((el) => DiagramElement.fromJson(el as Map<String, dynamic>))
          .toList(),
      layout: json['layout'] != null
          ? DiagramLayout.fromJson(json['layout'] as Map<String, dynamic>)
          : null,
      animation: json['animation'] != null
          ? DiagramAnimation.fromJson(json['animation'] as Map<String, dynamic>)
          : null,
      interaction: json['interaction'] != null
          ? DiagramInteraction.fromJson(json['interaction'] as Map<String, dynamic>)
          : null,
      learningObjectives: (json['learningObjectives'] as List<dynamic>)
          .map((s) => s as String)
          .toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (associatedQuestionId != null) 'associatedQuestionId': associatedQuestionId,
      if (associatedConceptId != null) 'associatedConceptId': associatedConceptId,
      'elements': elements.map((el) => el.toJson()).toList(),
      if (layout != null) 'layout': layout!.toJson(),
      if (animation != null) 'animation': animation!.toJson(),
      if (interaction != null) 'interaction': interaction!.toJson(),
      'learningObjectives': learningObjectives,
    };
  }
}

/// Diagram element model
class DiagramElement {
  final String id;
  final String elementType;
  final Map<String, dynamic> properties;
  final String? label;
  final bool isInteractive;
  final int? animationSequence;
  
  DiagramElement({
    required this.id,
    required this.elementType,
    required this.properties,
    this.label,
    this.isInteractive = false,
    this.animationSequence,
  });
  
  factory DiagramElement.fromJson(Map<String, dynamic> json) {
    return DiagramElement(
      id: json['id'] as String,
      elementType: json['elementType'] as String,
      properties: Map<String, dynamic>.from(json['properties'] as Map<String, dynamic>),
      label: json['label'] as String?,
      isInteractive: json['isInteractive'] as bool? ?? false,
      animationSequence: json['animationSequence'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'elementType': elementType,
      'properties': properties,
      if (label != null) 'label': label,
      'isInteractive': isInteractive,
      if (animationSequence != null) 'animationSequence': animationSequence,
    };
  }
}

/// Diagram layout model
class DiagramLayout {
  final double? width;
  final double? height;
  final String? backgroundColor;
  final bool? gridVisible;
  final CoordinateSystem? coordinateSystem;
  
  DiagramLayout({
    this.width,
    this.height,
    this.backgroundColor,
    this.gridVisible,
    this.coordinateSystem,
  });
  
  factory DiagramLayout.fromJson(Map<String, dynamic> json) {
    return DiagramLayout(
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      backgroundColor: json['backgroundColor'] as String?,
      gridVisible: json['gridVisible'] as bool?,
      coordinateSystem: json['coordinateSystem'] != null
          ? CoordinateSystem.fromJson(json['coordinateSystem'] as Map<String, dynamic>)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (gridVisible != null) 'gridVisible': gridVisible,
      if (coordinateSystem != null) 'coordinateSystem': coordinateSystem!.toJson(),
    };
  }
}

/// Coordinate system model
class CoordinateSystem {
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;
  final bool originVisible;
  
  CoordinateSystem({
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.originVisible,
  });
  
  factory CoordinateSystem.fromJson(Map<String, dynamic> json) {
    return CoordinateSystem(
      xMin: (json['xMin'] as num).toDouble(),
      xMax: (json['xMax'] as num).toDouble(),
      yMin: (json['yMin'] as num).toDouble(),
      yMax: (json['yMax'] as num).toDouble(),
      originVisible: json['originVisible'] as bool,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'xMin': xMin,
      'xMax': xMax,
      'yMin': yMin,
      'yMax': yMax,
      'originVisible': originVisible,
    };
  }
}

/// Diagram animation model
class DiagramAnimation {
  final bool hasAnimation;
  final int? totalFrames;
  final int? frameDurationMs;
  final String? animationType;
  final String? description;
  
  DiagramAnimation({
    required this.hasAnimation,
    this.totalFrames,
    this.frameDurationMs,
    this.animationType,
    this.description,
  });
  
  factory DiagramAnimation.fromJson(Map<String, dynamic> json) {
    return DiagramAnimation(
      hasAnimation: json['hasAnimation'] as bool,
      totalFrames: json['totalFrames'] as int?,
      frameDurationMs: json['frameDurationMs'] as int?,
      animationType: json['animationType'] as String?,
      description: json['description'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'hasAnimation': hasAnimation,
      if (totalFrames != null) 'totalFrames': totalFrames,
      if (frameDurationMs != null) 'frameDurationMs': frameDurationMs,
      if (animationType != null) 'animationType': animationType,
      if (description != null) 'description': description,
    };
  }
}

/// Diagram interaction model
class DiagramInteraction {
  final bool isInteractive;
  final String? interactionType;
  final String? instructions;
  
  DiagramInteraction({
    required this.isInteractive,
    this.interactionType,
    this.instructions,
  });
  
  factory DiagramInteraction.fromJson(Map<String, dynamic> json) {
    return DiagramInteraction(
      isInteractive: json['isInteractive'] as bool,
      interactionType: json['interactionType'] as String?,
      instructions: json['instructions'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'isInteractive': isInteractive,
      if (interactionType != null) 'interactionType': interactionType,
      if (instructions != null) 'instructions': instructions,
    };
  }
}