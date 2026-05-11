import 'question_data.dart';
import 'performance_tracker.dart';
import 'concept_mastery.dart';

enum RecommendationType {
  weakConcept,
  practiceSimilar,
  revisionDue,
  examReadiness,
  newConcept,
  mixedPractice,
}

class Recommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final List<QuestionData> questions;
  final double priority;
  final String? conceptId;

  const Recommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.questions,
    required this.priority,
    this.conceptId,
  });
}

class QuestionRecommender {
  final PerformanceTracker tracker;
  final List<QuestionData> allQuestions;

  QuestionRecommender({
    required this.tracker,
    required this.allQuestions,
  });

  List<Recommendation> getRecommendations({int maxRecommendations = 5}) {
    final recommendations = <Recommendation>[];

    // 1. Weak concepts - highest priority
    final weakConcepts = tracker.getWeakConcepts();
    if (weakConcepts.isNotEmpty) {
      final weakConcept = weakConcepts.first;
      final questions = _getQuestionsForConcept(weakConcept.conceptId, difficulty: Difficulty.easy);
      if (questions.isNotEmpty) {
        recommendations.add(Recommendation(
          type: RecommendationType.weakConcept,
          title: 'Strengthen ${weakConcept.conceptName}',
          description: 'Your mastery is ${weakConcept.masteryScore.toInt()}%. Start with easy questions.',
          questions: questions.take(3).toList(),
          priority: 1.0,
          conceptId: weakConcept.conceptId,
        ));
      }
    }

    // 2. Concepts needing practice
    final developingConcepts = tracker.getConceptsNeedingPractice();
    for (final concept in developingConcepts.take(2)) {
      final questions = _getQuestionsForConcept(concept.conceptId);
      if (questions.isNotEmpty && !recommendations.any((r) => r.conceptId == concept.conceptId)) {
        recommendations.add(Recommendation(
          type: RecommendationType.newConcept,
          title: 'Practice ${concept.conceptName}',
          description: 'State: ${concept.state.displayName} - ${concept.state.action}',
          questions: questions.take(2).toList(),
          priority: 0.8,
          conceptId: concept.conceptId,
        ));
      }
    }

    // 3. Revision due
    final revisionQuestions = _getRevisionQuestions();
    if (revisionQuestions.isNotEmpty) {
      recommendations.add(Recommendation(
        type: RecommendationType.revisionDue,
        title: 'Review Weak Areas',
        description: '${revisionQuestions.length} questions from topics you\'re weak in',
        questions: revisionQuestions.take(3).toList(),
        priority: 0.7,
      ));
    }

    // 4. Exam readiness - mixed difficulty
    final examReadinessQuestions = _getMixedDifficultyQuestions();
    if (examReadinessQuestions.isNotEmpty) {
      recommendations.add(Recommendation(
        type: RecommendationType.examReadiness,
        title: 'Exam Simulation',
        description: 'Mixed difficulty questions to test overall readiness',
        questions: examReadinessQuestions.take(5).toList(),
        priority: 0.6,
      ));
    }

    // 5. Similar questions practice
    if (tracker.attempts.isNotEmpty) {
      final recentAttempt = tracker.attempts.last;
      final similar = _getSimilarQuestions(recentAttempt.questionId);
      if (similar.isNotEmpty) {
        recommendations.add(Recommendation(
          type: RecommendationType.practiceSimilar,
          title: 'More Like This',
          description: 'Similar to "${recentAttempt.topic}" you just attempted',
          questions: similar.take(3).toList(),
          priority: 0.5,
        ));
      }
    }

    // Sort by priority and return top N
    recommendations.sort((a, b) => b.priority.compareTo(a.priority));
    return recommendations.take(maxRecommendations).toList();
  }

  List<QuestionData> _getQuestionsForConcept(String conceptId, {Difficulty? difficulty}) {
    return allQuestions.where((q) {
      final matchesConcept = q.primaryConcept == conceptId ||
          q.coreConcept == conceptId ||
          q.topic == conceptId;
      final matchesDifficulty = difficulty == null || q.difficulty == difficulty;
      return matchesConcept && matchesDifficulty;
    }).toList();
  }

  List<QuestionData> _getRevisionQuestions() {
    final weakAreas = tracker.getWeakAreas();
    final weakTopics = weakAreas.map((p) => p.topic).toSet();

    return allQuestions.where((q) => weakTopics.contains(q.topic) || weakTopics.contains(q.primaryConcept)).toList();
  }

  List<QuestionData> _getMixedDifficultyQuestions() {
    final easy = allQuestions.where((q) => q.difficulty == Difficulty.easy).toList();
    final medium = allQuestions.where((q) => q.difficulty == Difficulty.medium).toList();
    final hard = allQuestions.where((q) => q.difficulty == Difficulty.hard).toList();

    final result = <QuestionData>[];
    result.addAll(easy.take(2));
    result.addAll(medium.take(2));
    result.addAll(hard.take(1));
    result.shuffle();
    return result;
  }

  List<QuestionData> _getSimilarQuestions(String questionId) {
    final question = allQuestions.where((q) => q.id == questionId).firstOrNull;
    if (question == null) return [];

    return allQuestions.where((q) {
      if (q.id == questionId) return false;
      return q.primaryConcept == question.primaryConcept ||
          q.topic == question.topic ||
          (question.similarQuestionIds.contains(q.id));
    }).toList();
  }

  // Get next best question for adaptive learning
  QuestionData? getNextQuestion({
    String? preferredSubject,
    Difficulty? targetDifficulty,
  }) {
    final concepts = tracker.getConceptsNeedingPractice();

    // Prioritize weakest concepts
    for (final concept in concepts) {
      final questions = _getQuestionsForConcept(
        concept.conceptId,
        difficulty: targetDifficulty,
      );

      // Filter by subject if needed
      final filtered = preferredSubject != null
          ? questions.where((q) => q.subject == preferredSubject).toList()
          : questions;

      if (filtered.isNotEmpty) {
        return filtered.first;
      }
    }

    // Fallback to any available question
    final available = allQuestions.where((q) {
      final mastery = tracker.getConceptMasteries()[q.primaryConcept];
      return mastery == null || mastery.state != MasteryState.mastered;
    }).toList();

    if (available.isEmpty) return allQuestions.first;
    available.shuffle();
    return available.first;
  }
}