import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/question_data.dart';
import '../models/journey_state.dart';
import '../models/foundation_journey.dart';
import '../models/question_attempt.dart';

class JourneyProgressionEngine {
  final Map<String, FoundationJourney> _journeyCache = {};
  final Map<String, StudentJourneyState> _studentStates = {};

  /// Load journey from content JSON
  Future<FoundationJourney> loadJourney(String journeyId) async {
    if (_journeyCache.containsKey(journeyId)) {
      return _journeyCache[journeyId]!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'content/journeys/${journeyId}.json'
      );
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final journey = FoundationJourney.fromJson(json);
      _journeyCache[journeyId] = journey;
      return journey;
    } catch (e) {
      throw JourneyLoadException('Failed to load journey $journeyId: $e');
    }
  }

  /// Get or create student state for a journey
  StudentJourneyState getStudentState(String studentId, String journeyId) {
    final key = '${studentId}_${journeyId}';
    return _studentStates.putIfAbsent(
      key, 
      () => StudentJourneyState(journeyId: journeyId, studentId: studentId)
    );
  }

  /// Calculate next step based on current state and latest attempt
  JourneyStep getNextStep({
    required StudentJourneyState state,
    required QuestionAttempt latestAttempt,
    required FoundationJourney journey,
  }) {
    final currentLevel = journey.levels[state.currentLevelIndex];
    
    // Apply progression rules
    final rule = _applyProgressionRule(currentLevel, latestAttempt, state);
    
    switch (rule.action) {
      case ProgressionAction.unlockNext:
        if (state.currentLevelIndex < journey.levels.length - 1) {
          return JourneyStep(
            levelIndex: state.currentLevelIndex + 1,
            action: JourneyAction.proceedToNext,
            message: 'Great! Moving to ${journey.levels[state.currentLevelIndex + 1].title}',
          );
        }
        return JourneyStep(
          levelIndex: state.currentLevelIndex,
          action: JourneyAction.journeyComplete,
          message: 'Congratulations! You completed the Foundation Journey!',
        );
        
      case ProgressionAction.showMicroLesson:
        return JourneyStep(
          levelIndex: state.currentLevelIndex,
          action: JourneyAction.showMicroLesson,
          message: 'Let\'s review the key concepts before trying again',
        );
        
      case ProgressionAction.goLevelDown:
        if (state.currentLevelIndex > 0) {
          return JourneyStep(
            levelIndex: state.currentLevelIndex - 1,
            action: JourneyAction.goToPrevious,
            message: 'Let\'s strengthen your foundation with ${journey.levels[state.currentLevelIndex - 1].title}',
          );
        }
        return JourneyStep(
          levelIndex: state.currentLevelIndex,
          action: JourneyAction.repeatCurrent,
          message: 'Let\'s try this level again with more practice',
        );
        
      case ProgressionAction.repeatSimilar:
        return JourneyStep(
          levelIndex: state.currentLevelIndex,
          action: JourneyAction.repeatSimilar,
          message: 'Good attempt! Let\'s try a similar question',
        );
        
      case ProgressionAction.jumpForward:
        // Optional jump forward if student is excelling
        if (state.currentLevelIndex < journey.levels.length - 2) {
          return JourneyStep(
            levelIndex: state.currentLevelIndex + 2,
            action: JourneyAction.jumpAhead,
            message: 'Excellent! You\'re ready for a bigger challenge!',
          );
        }
        // Fall through to next level if jump not possible
        return JourneyStep(
          levelIndex: state.currentLevelIndex + 1,
          action: JourneyAction.proceedToNext,
          message: 'Great! Moving to ${journey.levels[state.currentLevelIndex + 1].title}',
        );
        
      case ProgressionAction.stayCurrent:
        return JourneyStep(
          levelIndex: state.currentLevelIndex,
          action: JourneyAction.stayCurrent,
          message: 'Keep practicing! You\'re making progress',
        );
    }
  }

  /// Apply progression rules to determine next action
  ProgressionRule _applyProgressionRule(
    JourneyLevel currentLevel,
    QuestionAttempt attempt,
    StudentJourneyState state,
  ) {
    final isCorrect = attempt.isCorrect;
    final confidence = attempt.confidenceLevel;
    final timeSpent = attempt.timeSpentSeconds;
    final expectedTime = currentLevel.expectedTimeSeconds ?? 90;
    
    // Track consecutive correct/incorrect
    final recentAttempts = state.recentAttemptsForLevel(state.currentLevelIndex);
    final consecutiveCorrect = _countConsecutiveCorrect(recentAttempts);
    final consecutiveWrong = _countConsecutiveWrong(recentAttempts);
    
    // Rule 1: Correct twice at current level → unlock next level
    if (isCorrect && consecutiveCorrect >= 2) {
      return ProgressionRule(
        action: ProgressionAction.unlockNext,
        reason: 'Correct twice consecutively',
      );
    }
    
    // Rule 2: Wrong once with low confidence → show micro-lesson
    if (!isCorrect && confidence == ConfidenceLevel.notSure) {
      return ProgressionRule(
        action: ProgressionAction.showMicroLesson,
        reason: 'Wrong answer with low confidence',
      );
    }
    
    // Rule 3: Wrong twice → go one level down
    if (!isCorrect && consecutiveWrong >= 2) {
      return ProgressionRule(
        action: ProgressionAction.goLevelDown,
        reason: 'Wrong twice consecutively',
      );
    }
    
    // Rule 4: Correct but slow → repeat similar question
    if (isCorrect && timeSpent > expectedTime * 1.5) {
      return ProgressionRule(
        action: ProgressionAction.repeatSimilar,
        reason: 'Correct but slow',
      );
    }
    
    // Rule 5: Correct fast + high confidence → jump forward
    if (isCorrect && 
        timeSpent < expectedTime * 0.7 && 
        confidence == ConfidenceLevel.verySure) {
      return ProgressionRule(
        action: ProgressionAction.jumpForward,
        reason: 'Correct fast with high confidence',
      );
    }
    
    // Default: stay current
    return ProgressionRule(
      action: ProgressionAction.stayCurrent,
      reason: 'Continue current level',
    );
  }

  int _countConsecutiveCorrect(List<QuestionAttempt> attempts) {
    int count = 0;
    for (final attempt in attempts.reversed) {
      if (attempt.isCorrect) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  int _countConsecutiveWrong(List<QuestionAttempt> attempts) {
    int count = 0;
    for (final attempt in attempts.reversed) {
      if (!attempt.isCorrect) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// Update student state with new attempt
  void updateStudentState(
    StudentJourneyState state,
    QuestionAttempt attempt,
    JourneyStep nextStep,
  ) {
    state.addAttempt(attempt);
    
    switch (nextStep.action) {
      case JourneyAction.proceedToNext:
      case JourneyAction.jumpAhead:
        state.currentLevelIndex = nextStep.levelIndex;
        state.levelStates[nextStep.levelIndex] = LevelState.inProgress;
        break;
        
      case JourneyAction.goToPrevious:
        state.currentLevelIndex = nextStep.levelIndex;
        state.levelStates[nextStep.levelIndex] = LevelState.needsPractice;
        break;
        
      case JourneyAction.journeyComplete:
        state.levelStates[state.currentLevelIndex] = LevelState.mastered;
        state.isCompleted = true;
        state.completionDate = DateTime.now();
        break;
        
      case JourneyAction.repeatCurrent:
      case JourneyAction.repeatSimilar:
      case JourneyAction.showMicroLesson:
      case JourneyAction.stayCurrent:
        // Stay at current level
        break;
    }
  }

  /// Get progress summary for parent/teacher view
  ProgressSummary getProgressSummary(StudentJourneyState state) {
    final journey = _journeyCache[state.journeyId];
    if (journey == null) {
      return ProgressSummary.empty();
    }

    final conceptsMastered = <String>[];
    final strugglingAreas = <String>[];
    final confidenceTrend = _calculateConfidenceTrend(state);

    for (int i = 0; i < journey.levels.length; i++) {
      final level = journey.levels[i];
      final levelState = state.levelStates[i] ?? LevelState.notStarted;
      final attempts = state.attemptsForLevel(i);
      
      if (levelState == LevelState.mastered) {
        conceptsMastered.add(level.title);
      } else if (attempts.isNotEmpty && _calculateLevelAccuracy(attempts) < 0.5) {
        strugglingAreas.add(level.title);
      }
    }

    return ProgressSummary(
      conceptsMastered: conceptsMastered,
      strugglingAreas: strugglingAreas,
      confidenceTrend: confidenceTrend,
      recommendedNext: _recommendNextJourney(state),
    );
  }

  double _calculateLevelAccuracy(List<QuestionAttempt> attempts) {
    if (attempts.isEmpty) return 0.0;
    final correct = attempts.where((a) => a.isCorrect).length;
    return correct / attempts.length;
  }

  ConfidenceTrend _calculateConfidenceTrend(StudentJourneyState state) {
    final attempts = state.allAttempts;
    if (attempts.length < 3) return ConfidenceTrend.insufficientData;
    
    final recent = attempts.skip(attempts.length - 3).toList();
    final older = attempts.skip(attempts.length - 6).take(3).toList();
    
    if (older.isEmpty) return ConfidenceTrend.insufficientData;
    
    final recentAvg = _averageConfidence(recent);
    final olderAvg = _averageConfidence(older);
    
    if (recentAvg > olderAvg + 0.2) return ConfidenceTrend.improving;
    if (recentAvg < olderAvg - 0.2) return ConfidenceTrend.declining;
    return ConfidenceTrend.stable;
  }

  double _averageConfidence(List<QuestionAttempt> attempts) {
    if (attempts.isEmpty) return 0.0;
    
    double sum = 0.0;
    for (final attempt in attempts) {
      switch (attempt.confidenceLevel) {
        case ConfidenceLevel.notSure:
          sum += 0.33;
          break;
        case ConfidenceLevel.somewhatSure:
          sum += 0.67;
          break;
        case ConfidenceLevel.verySure:
          sum += 1.0;
          break;
      }
    }
    return sum / attempts.length;
  }

  String _recommendNextJourney(StudentJourneyState state) {
    // Simple recommendation logic - can be made more sophisticated
    if (state.isCompleted) {
      return 'algebra_foundation_journey';
    } else if (state.currentLevelIndex >= 3) {
      return 'continue_current_journey';
    } else {
      return 'practice_foundation_skills';
    }
  }
}

// Supporting classes and enums

enum ProgressionAction {
  unlockNext,
  showMicroLesson,
  goLevelDown,
  repeatSimilar,
  jumpForward,
  stayCurrent,
}

enum JourneyAction {
  proceedToNext,
  goToPrevious,
  repeatCurrent,
  repeatSimilar,
  showMicroLesson,
  jumpAhead,
  journeyComplete,
  stayCurrent,
}

enum LevelState {
  notStarted,
  inProgress,
  needsPractice,
  mastered,
}

enum ConfidenceTrend {
  improving,
  stable,
  declining,
  insufficientData,
}

class ProgressionRule {
  final ProgressionAction action;
  final String reason;

  ProgressionRule({required this.action, required this.reason});
}

class JourneyStep {
  final int levelIndex;
  final JourneyAction action;
  final String message;

  JourneyStep({
    required this.levelIndex,
    required this.action,
    required this.message,
  });
}

class ProgressSummary {
  final List<String> conceptsMastered;
  final List<String> strugglingAreas;
  final ConfidenceTrend confidenceTrend;
  final String recommendedNext;

  ProgressSummary({
    required this.conceptsMastered,
    required this.strugglingAreas,
    required this.confidenceTrend,
    required this.recommendedNext,
  });

  static ProgressSummary empty() {
    return ProgressSummary(
      conceptsMastered: [],
      strugglingAreas: [],
      confidenceTrend: ConfidenceTrend.insufficientData,
      recommendedNext: 'start_foundation_journey',
    );
  }
}

class JourneyLoadException implements Exception {
  final String message;
  JourneyLoadException(this.message);
  
  @override
  String toString() => 'JourneyLoadException: $message';
}