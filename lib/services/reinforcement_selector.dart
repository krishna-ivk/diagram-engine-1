import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/question_data.dart';
import '../models/student_attempt.dart';
import '../models/drill_session.dart';
import '../services/attempt_tracker.dart';
import '../services/topic_content_loader.dart';

/// Service for selecting reinforcement questions based on student performance
class ReinforcementSelector {
  /// Select next question after a wrong answer
  static Future<String?> selectNextQuestionAfterWrong({
    required QuestionData currentQuestion,
    required int selectedOptionIndex,
    required String topicId,
  }) async {
    // Priority 1: Use explicit next_if_wrong from question
    if (currentQuestion.nextIfWrong.isNotEmpty) {
      return currentQuestion.nextIfWrong.first;
    }

    // Priority 2: Find question with same misconception tag
    final misconceptionCode = currentQuestion.misconceptionTags[selectedOptionIndex];
    if (misconceptionCode != null) {
      final misconceptionQuestion = await _findQuestionWithMisconception(
        misconceptionCode,
        currentQuestion.id,
        topicId,
      );
      if (misconceptionQuestion != null) {
        return misconceptionQuestion;
      }
    }

    // Priority 3: Find question from same reinforcement group
    if (currentQuestion.reinforcementGroup != null) {
      final groupQuestion = await _findQuestionFromReinforcementGroup(
        currentQuestion.reinforcementGroup!,
        currentQuestion.id,
        topicId,
      );
      if (groupQuestion != null) {
        return groupQuestion;
      }
    }

    // Priority 4: Find question with similar concept tags
    if (currentQuestion.conceptTags.isNotEmpty) {
      final conceptQuestion = await _findQuestionWithConceptTags(
        currentQuestion.conceptTags,
        currentQuestion.id,
        topicId,
      );
      if (conceptQuestion != null) {
        return conceptQuestion;
      }
    }

    // Priority 5: Find easier question from same difficulty
    final easierQuestion = await _findEasierQuestion(
      currentQuestion.difficulty,
      currentQuestion.id,
      topicId,
    );
    if (easierQuestion != null) {
      return easierQuestion;
    }

    return null;
  }

  /// Select next question after a correct answer
  static Future<String?> selectNextQuestionAfterCorrect({
    required QuestionData currentQuestion,
    required int timeTakenSeconds,
    required String topicId,
  }) async {
    // Priority 1: Use explicit next_if_correct from question
    if (currentQuestion.nextIfCorrect.isNotEmpty) {
      return currentQuestion.nextIfCorrect.first;
    }

    final wasFast = timeTakenSeconds <= (currentQuestion.estimatedSeconds ?? 60) * 0.7;
    final wasSlow = timeTakenSeconds > (currentQuestion.estimatedSeconds ?? 60) * 1.5;

    if (wasFast) {
      // Fast and correct - move to harder question
      final harderQuestion = await _findHarderQuestion(
        currentQuestion.difficulty,
        currentQuestion.id,
        topicId,
      );
      if (harderQuestion != null) {
        return harderQuestion;
      }
    } else if (wasSlow) {
      // Slow but correct - give another similar practice question
      final similarQuestion = await _findSimilarQuestion(
        currentQuestion,
        topicId,
      );
      if (similarQuestion != null) {
        return similarQuestion;
      }
    }

    // Priority 2: Find question from same reinforcement group
    if (currentQuestion.reinforcementGroup != null) {
      final groupQuestion = await _findQuestionFromReinforcementGroup(
        currentQuestion.reinforcementGroup!,
        currentQuestion.id,
        topicId,
      );
      if (groupQuestion != null) {
        return groupQuestion;
      }
    }

    // Priority 3: Find question with similar concept tags
    if (currentQuestion.conceptTags.isNotEmpty) {
      final conceptQuestion = await _findQuestionWithConceptTags(
        currentQuestion.conceptTags,
        currentQuestion.id,
        topicId,
      );
      if (conceptQuestion != null) {
        return conceptQuestion;
      }
    }

    return null;
  }

  /// Select revision question based on weak areas
  static Future<String?> selectRevisionQuestion({
    required String topicId,
    List<String>? weakConcepts,
  }) async {
    final topicCapsule = await TopicContentLoader.loadTopicCapsule(topicId);
    final allRevisionIds = topicCapsule.revisionQuestionIds;

    if (allRevisionIds.isEmpty) return null;

    if (weakConcepts != null && weakConcepts.isNotEmpty) {
      // Try to find revision question that addresses weak concepts
      for (final concept in weakConcepts) {
        final conceptQuestion = await _findQuestionForConcept(
          concept,
          allRevisionIds,
        );
        if (conceptQuestion != null) {
          return conceptQuestion;
        }
      }
    }

    // Return random revision question
    return allRevisionIds[Random().nextInt(allRevisionIds.length)];
  }

  /// Select challenge question after 3 correct in a row
  static Future<String?> selectChallengeQuestion({
    required String topicId,
    required List<String> excludedIds,
  }) async {
    final topicCapsule = await TopicContentLoader.loadTopicCapsule(topicId);
    final challengeIds = topicCapsule.challengeQuestionIds;

    // Filter out already attempted questions
    final availableChallenges = challengeIds
        .where((id) => !excludedIds.contains(id))
        .toList();

    if (availableChallenges.isEmpty) return null;

    return availableChallenges[Random().nextInt(availableChallenges.length)];
  }

  /// Select questions for mini mock test
  static Future<List<String>> selectMiniMockQuestions({
    required String topicId,
    int questionCount = 10,
  }) async {
    final topicCapsule = await TopicContentLoader.loadTopicCapsule(topicId);
    
    // Mix questions from different difficulty levels
    final starterIds = topicCapsule.starterQuestionIds;
    final practiceIds = topicCapsule.practiceQuestionIds;
    final challengeIds = topicCapsule.challengeQuestionIds;

    final selectedQuestions = <String>[];
    final random = Random();

    // 30% starter, 50% practice, 20% challenge
    final starterCount = (questionCount * 0.3).round();
    final practiceCount = (questionCount * 0.5).round();
    final challengeCount = questionCount - starterCount - practiceCount;

    // Add starter questions
    selectedQuestions.addAll(_selectRandomItems(starterIds, starterCount, random));
    
    // Add practice questions
    selectedQuestions.addAll(_selectRandomItems(practiceIds, practiceCount, random));
    
    // Add challenge questions
    selectedQuestions.addAll(_selectRandomItems(challengeIds, challengeCount, random));

    // Shuffle for random order
    selectedQuestions.shuffle(random);
    
    return selectedQuestions.take(questionCount).toList();
  }

  /// Find question with specific misconception code
  static Future<String?> _findQuestionWithMisconception(
    String misconceptionCode,
    String excludeId,
    String topicId,
  ) async {
    final topicCapsule = await TopicContentLoader.loadTopicCapsule(topicId);
    final allQuestionIds = [
      ...topicCapsule.starterQuestionIds,
      ...topicCapsule.practiceQuestionIds,
      ...topicCapsule.challengeQuestionIds,
      ...topicCapsule.revisionQuestionIds,
    ];

    for (final questionId in allQuestionIds) {
      if (questionId == excludeId) continue;

      try {
        final questions = await TopicContentLoader.loadQuestionsByIds([questionId]);
        if (questions.isEmpty) continue;

        final question = questions.first;
        // Check if this question addresses the misconception
        for (final misconception in question.misconceptionTags.values) {
          if (misconception == misconceptionCode) {
            return questionId;
          }
        }
      } catch (e) {
        debugPrint('Error loading question $questionId: $e');
      }
    }

    return null;
  }

  /// Find question from same reinforcement group
  static Future<String?> _findQuestionFromReinforcementGroup(
    String reinforcementGroup,
    String excludeId,
    String topicId,
  ) async {
    final topicCapsule = await TopicContentLoader.loadTopicCapsule(topicId);
    final allQuestionIds = [
      ...topicCapsule.starterQuestionIds,
      ...topicCapsule.practiceQuestionIds,
      ...topicCapsule.challengeQuestionIds,
      ...topicCapsule.revisionQuestionIds,
    ];

    for (final questionId in allQuestionIds) {
      if (questionId == excludeId) continue;

      try {
        final questions = await TopicContentLoader.loadQuestionsByIds([questionId]);
        if (questions.isEmpty) continue;

        final question = questions.first;
        if (question.reinforcementGroup == reinforcementGroup) {
          return questionId;
        }
      } catch (e) {
        debugPrint('Error loading question $questionId: $e');
      }
    }

    return null;
  }

  /// Find question with similar concept tags
  static Future<String?> _findQuestionWithConceptTags(
    List<String> conceptTags,
    String excludeId,
    String topicId,
  ) async {
    final topicCapsule = await TopicContentLoader.loadTopicCapsule(topicId);
    final allQuestionIds = [
      ...topicCapsule.starterQuestionIds,
      ...topicCapsule.practiceQuestionIds,
      ...topicCapsule.challengeQuestionIds,
      ...topicCapsule.revisionQuestionIds,
    ];

    String? bestMatch;
    int maxOverlap = 0;

    for (final questionId in allQuestionIds) {
      if (questionId == excludeId) continue;

      try {
        final questions = await TopicContentLoader.loadQuestionsByIds([questionId]);
        if (questions.isEmpty) continue;

        final question = questions.first;
        final overlap = conceptTags
            .where((tag) => question.conceptTags.contains(tag))
            .length;

        if (overlap > maxOverlap) {
          maxOverlap = overlap;
          bestMatch = questionId;
        }
      } catch (e) {
        debugPrint('Error loading question $questionId: $e');
      }
    }

    return maxOverlap > 0 ? bestMatch : null;
  }

  /// Find easier question
  static Future<String?> _findEasierQuestion(
    Difficulty currentDifficulty,
    String excludeId,
    String topicId,
  ) async {
    final topicCapsule = await TopicContentLoader.loadTopicCapsule(topicId);
    List<String> candidateIds;

    switch (currentDifficulty) {
      case Difficulty.hard:
        candidateIds = [...topicCapsule.practiceQuestionIds, ...topicCapsule.starterQuestionIds];
        break;
      case Difficulty.medium:
        candidateIds = topicCapsule.starterQuestionIds;
        break;
      case Difficulty.easy:
        return null; // No easier questions available
    }

    // Filter out excluded ID and load candidates
    candidateIds = candidateIds.where((id) => id != excludeId).toList();
    if (candidateIds.isEmpty) return null;

    // Try to find an easier question
    for (final questionId in candidateIds) {
      try {
        final questions = await TopicContentLoader.loadQuestionsByIds([questionId]);
        if (questions.isEmpty) continue;

        final question = questions.first;
        if (question.difficulty.index < currentDifficulty.index) {
          return questionId;
        }
      } catch (e) {
        debugPrint('Error loading question $questionId: $e');
      }
    }

    return candidateIds.isNotEmpty ? candidateIds.first : null;
  }

  /// Find harder question
  static Future<String?> _findHarderQuestion(
    Difficulty currentDifficulty,
    String excludeId,
    String topicId,
  ) async {
    final topicCapsule = await TopicContentLoader.loadTopicCapsule(topicId);
    List<String> candidateIds;

    switch (currentDifficulty) {
      case Difficulty.easy:
        candidateIds = [...topicCapsule.practiceQuestionIds, ...topicCapsule.challengeQuestionIds];
        break;
      case Difficulty.medium:
        candidateIds = topicCapsule.challengeQuestionIds;
        break;
      case Difficulty.hard:
        return null; // No harder questions available
    }

    // Filter out excluded ID and load candidates
    candidateIds = candidateIds.where((id) => id != excludeId).toList();
    if (candidateIds.isEmpty) return null;

    // Try to find a harder question
    for (final questionId in candidateIds) {
      try {
        final questions = await TopicContentLoader.loadQuestionsByIds([questionId]);
        if (questions.isEmpty) continue;

        final question = questions.first;
        if (question.difficulty.index > currentDifficulty.index) {
          return questionId;
        }
      } catch (e) {
        debugPrint('Error loading question $questionId: $e');
      }
    }

    return candidateIds.isNotEmpty ? candidateIds.first : null;
  }

  /// Find similar question
  static Future<String?> _findSimilarQuestion(
    QuestionData currentQuestion,
    String topicId,
  ) async {
    // First try similar question IDs
    if (currentQuestion.similarQuestionIds.isNotEmpty) {
      for (final similarId in currentQuestion.similarQuestionIds) {
        if (similarId != currentQuestion.id) {
          return similarId;
        }
      }
    }

    // Fall back to same reinforcement group
    if (currentQuestion.reinforcementGroup != null) {
      return await _findQuestionFromReinforcementGroup(
        currentQuestion.reinforcementGroup!,
        currentQuestion.id,
        topicId,
      );
    }

    return null;
  }

  /// Find question for specific concept
  static Future<String?> _findQuestionForConcept(
    String concept,
    List<String> candidateIds,
  ) async {
    for (final questionId in candidateIds) {
      try {
        final questions = await TopicContentLoader.loadQuestionsByIds([questionId]);
        if (questions.isEmpty) continue;

        final question = questions.first;
        if (question.conceptTags.contains(concept) ||
            question.primaryConcept.contains(concept)) {
          return questionId;
        }
      } catch (e) {
        debugPrint('Error loading question $questionId: $e');
      }
    }

    return null;
  }

  /// Select random items from list
  static List<String> _selectRandomItems(
    List<String> items,
    int count,
    Random random,
  ) {
    if (count >= items.length) {
      return List.from(items);
    }

    final shuffled = List<String>.from(items)..shuffle(random);
    return shuffled.take(count).toList();
  }
}