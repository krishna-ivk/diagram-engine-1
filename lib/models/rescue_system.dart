import 'question_data.dart';
import 'concept_graph.dart';
import 'practice_mode.dart';

class RescueQuestion {
  final QuestionData question;
  final String reason;
  final int difficulty; // -2 to 0 (easier than original)

  const RescueQuestion({
    required this.question,
    required this.reason,
    required this.difficulty,
  });
}

class RescueSystem {
  final List<QuestionData> allQuestions;
  final ConceptGraph conceptGraph;

  const RescueSystem({
    required this.allQuestions,
    required this.conceptGraph,
  });

  List<RescueQuestion> getRescuePath(QuestionData failedQuestion) {
    final rescueQuestions = <RescueQuestion>[];

    // Get prerequisites for this concept
    final conceptId = failedQuestion.primaryConcept.isNotEmpty
        ? failedQuestion.primaryConcept
        : failedQuestion.coreConcept ?? failedQuestion.topic;

    final prerequisites = conceptGraph.getPrerequisites(conceptId);

    // Get easier questions on prerequisites
    for (final prereq in prerequisites) {
      final prereqQuestions = allQuestions
          .where((q) =>
              q.primaryConcept == prereq.id ||
              q.coreConcept == prereq.id ||
              q.topic == prereq.id)
          .where((q) => q.difficulty == Difficulty.easy)
          .toList();

      if (prereqQuestions.isNotEmpty) {
        rescueQuestions.add(RescueQuestion(
          question: prereqQuestions.first,
          reason: 'Prerequisite concept: ${prereq.name}',
          difficulty: -2,
        ));
      }
    }

    // Add simpler version of same topic if available
    final sameTopicEasier = allQuestions
        .where((q) => q.topic == failedQuestion.topic)
        .where((q) => q.difficulty == Difficulty.easy)
        .where((q) => q.id != failedQuestion.id)
        .toList();

    if (sameTopicEasier.isNotEmpty) {
      rescueQuestions.insert(
        0,
        RescueQuestion(
          question: sameTopicEasier.first,
          reason: 'Simpler version of same topic',
          difficulty: -1,
        ),
      );
    }

    // Add foundational concept questions
    final foundationalQuestions = _getFoundationalQuestions(conceptId);
    rescueQuestions.addAll(foundationalQuestions);

    return rescueQuestions.take(4).toList();
  }

  List<RescueQuestion> _getFoundationalQuestions(String conceptId) {
    final foundational = <RescueQuestion>[];

    // Map of concepts to their foundational prerequisites
    final foundationalMap = {
      'parabola': ['quadratic_equation'],
      'derivative': ['limit_concept', 'function_basics'],
      'integral': ['derivative'],
      'circle_equation': ['circle_basic', 'distance_formula'],
      'trig_identities': ['trig_basics'],
      'vector': ['coordinate_geometry'],
      'matrices': ['determinants'],
      'complex_numbers': ['quadratic_equation'],
    };

    final foundationalIds = foundationalMap[conceptId] ?? [];

    for (final fid in foundationalIds) {
      final fQuestions = allQuestions
          .where((q) =>
              q.primaryConcept == fid ||
              q.coreConcept == fid)
          .where((q) => q.difficulty == Difficulty.easy)
          .take(1)
          .toList();

      if (fQuestions.isNotEmpty) {
        foundational.add(RescueQuestion(
          question: fQuestions.first,
          reason: 'Foundational: builds basic understanding',
          difficulty: -2,
        ));
      }
    }

    return foundational;
  }

  QuestionData? getAdaptiveNextQuestion({
    required String currentTopic,
    required bool wasCorrect,
    required int streakCount,
    required PracticeMode mode,
  }) {
    if (mode != PracticeMode.learner) return null;

    // If struggling (wrong + low streak), go easier
    if (!wasCorrect && streakCount < 2) {
      final easier = allQuestions
          .where((q) => q.topic == currentTopic)
          .where((q) => q.difficulty == Difficulty.easy)
          .toList();

      if (easier.isNotEmpty) {
        easier.shuffle();
        return easier.first;
      }

      // Fall back to rescue path
      final currentQ = allQuestions
          .where((q) => q.topic == currentTopic)
          .firstOrNull;

      if (currentQ != null) {
        final rescue = getRescuePath(currentQ);
        if (rescue.isNotEmpty) {
          return rescue.first.question;
        }
      }
    }

    // If acing (right + high streak), go harder
    if (wasCorrect && streakCount > 3) {
      final harder = allQuestions
          .where((q) => q.topic == currentTopic)
          .where((q) => q.difficulty == Difficulty.hard)
          .toList();

      if (harder.isNotEmpty) {
        harder.shuffle();
        return harder.first;
      }
    }

    return null;
  }
}