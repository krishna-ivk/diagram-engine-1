import 'question_data.dart';
import 'diagram_data.dart';
import 'performance_tracker.dart';

class ExamDiagnosis {
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final int skippedQuestions;
  final int totalTimeSeconds;
  final List<ConceptPerformance> weakConcepts;
  final List<ConceptPerformance> strongConcepts;
  final List<WrongAnswerDetail> wrongAnswersByConcept;
  final List<TimePressureDetail> timePressureQuestions;
  final List<RescueRecommendation> rescueRecommendations;
  final double scorePercentage;
  final String grade;

  const ExamDiagnosis({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.skippedQuestions,
    required this.totalTimeSeconds,
    required this.weakConcepts,
    required this.strongConcepts,
    required this.wrongAnswersByConcept,
    required this.timePressureQuestions,
    required this.rescueRecommendations,
    required this.scorePercentage,
    required this.grade,
  });
}

class ConceptPerformance {
  final String conceptId;
  final String conceptName;
  final int totalAttempts;
  final int correctAttempts;
  final double accuracy;

  const ConceptPerformance({
    required this.conceptId,
    required this.conceptName,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.accuracy,
  });
}

class WrongAnswerDetail {
  final String questionId;
  final String questionText;
  final String conceptId;
  final String conceptName;
  final int selectedOption;
  final int correctOption;
  final String? whyWrong;

  const WrongAnswerDetail({
    required this.questionId,
    required this.questionText,
    required this.conceptId,
    required this.conceptName,
    required this.selectedOption,
    required this.correctOption,
    this.whyWrong,
  });
}

class TimePressureDetail {
  final String questionId;
  final String questionText;
  final String conceptName;
  final int timeSpent;
  final int expectedTime;

  const TimePressureDetail({
    required this.questionId,
    required this.questionText,
    required this.conceptName,
    required this.timeSpent,
    required this.expectedTime,
  });
}

class RescueRecommendation {
  final String conceptId;
  final String conceptName;
  final int weakQuestionCount;
  final String recommendation;
  final List<QuestionData> recommendedQuestions;

  const RescueRecommendation({
    required this.conceptId,
    required this.conceptName,
    required this.weakQuestionCount,
    required this.recommendation,
    required this.recommendedQuestions,
  });
}

class DiagnosisEngine {
  static ExamDiagnosis analyze({
    required List<QuestionAttempt> attempts,
    required List<QuestionData> questions,
  }) {
    final totalQuestions = attempts.length;
    final correctAnswers = attempts.where((a) => a.correct).length;
    final incorrectAnswers = attempts.where((a) => !a.correct).length;
    final totalTimeSeconds = attempts.fold(0, (sum, a) => sum + a.timeSeconds);
    
    final scorePercentage = totalQuestions > 0 
        ? (correctAnswers / totalQuestions) * 100 
        : 0.0;
    
    final grade = _calculateGrade(scorePercentage);

    // Analyze by concept
    final conceptStats = <String, ConceptPerformance>{};
    for (final attempt in attempts) {
      final conceptId = attempt.primaryConcept.isNotEmpty 
          ? attempt.primaryConcept 
          : attempt.coreConcept;
      
      final existing = conceptStats[conceptId];
      if (existing == null) {
        conceptStats[conceptId] = ConceptPerformance(
          conceptId: conceptId,
          conceptName: _formatConceptName(conceptId),
          totalAttempts: 1,
          correctAttempts: attempt.correct ? 1 : 0,
          accuracy: attempt.correct ? 1.0 : 0.0,
        );
      } else {
        conceptStats[conceptId] = ConceptPerformance(
          conceptId: conceptId,
          conceptName: existing.conceptName,
          totalAttempts: existing.totalAttempts + 1,
          correctAttempts: existing.correctAttempts + (attempt.correct ? 1 : 0),
          accuracy: (existing.correctAttempts + (attempt.correct ? 1 : 0)) / 
              (existing.totalAttempts + 1),
        );
      }
    }

    // Weak concepts (< 50% accuracy)
    final weakConcepts = conceptStats.values
        .where((c) => c.accuracy < 0.5 && c.totalAttempts >= 1)
        .toList()
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    // Strong concepts (> 70% accuracy)
    final strongConcepts = conceptStats.values
        .where((c) => c.accuracy >= 0.7 && c.totalAttempts >= 2)
        .toList()
      ..sort((a, b) => b.accuracy.compareTo(a.accuracy));

    // Wrong answers grouped by concept
    final wrongAnswersByConcept = <WrongAnswerDetail>[];
    for (final attempt in attempts.where((a) => !a.correct)) {
      final question = questions.firstWhere(
        (q) => q.id == attempt.questionId,
        orElse: () => QuestionData(
          id: attempt.questionId,
          text: 'Unknown question',
          diagram: DiagramData(id: '', type: DiagramType.geometry, elements: []),
          options: [],
          correctIndex: 0,
          subject: '',
          topic: '',
        ),
      );
      
      final conceptId = attempt.primaryConcept.isNotEmpty 
          ? attempt.primaryConcept 
          : attempt.coreConcept;
      
      wrongAnswersByConcept.add(WrongAnswerDetail(
        questionId: attempt.questionId,
        questionText: question.text.length > 100 
            ? '${question.text.substring(0, 100)}...' 
            : question.text,
        conceptId: conceptId,
        conceptName: _formatConceptName(conceptId),
        selectedOption: attempt.tapCount,
        correctOption: question.correctIndex,
        whyWrong: question.whyWrongExplanations?[attempt.tapCount],
      ));
    }

    // Time pressure detection (took > 80% of expected time but still wrong or guessed)
    final timePressureQuestions = <TimePressureDetail>[];
    for (final attempt in attempts) {
      if (attempt.timeSeconds > (attempt.expectedTimeSeconds * 0.8) && 
          !attempt.correct) {
        final question = questions.firstWhere(
          (q) => q.id == attempt.questionId,
          orElse: () => QuestionData(
            id: attempt.questionId,
            text: 'Unknown question',
            diagram: DiagramData(id: '', type: DiagramType.geometry, elements: []),
            options: [],
            correctIndex: 0,
            subject: '',
            topic: '',
          ),
        );
        
        timePressureQuestions.add(TimePressureDetail(
          questionId: attempt.questionId,
          questionText: question.text.length > 80 
              ? '${question.text.substring(0, 80)}...' 
              : question.text,
          conceptName: _formatConceptName(attempt.primaryConcept.isNotEmpty 
              ? attempt.primaryConcept 
              : attempt.coreConcept),
          timeSpent: attempt.timeSeconds,
          expectedTime: attempt.expectedTimeSeconds,
        ));
      }
    }

    // Rescue recommendations for weak concepts
    final rescueRecommendations = <RescueRecommendation>[];
    for (final weak in weakConcepts.take(3)) {
      // Find questions for this concept
      final conceptQuestions = questions
          .where((q) => (q.primaryConcept.isNotEmpty && q.primaryConcept == weak.conceptId) ||
                       (q.coreConcept?.contains(weak.conceptId) ?? false))
          .where((q) => q.difficulty == Difficulty.easy || q.difficulty == Difficulty.medium)
          .take(3)
          .toList();
      
      if (conceptQuestions.isNotEmpty) {
        rescueRecommendations.add(RescueRecommendation(
          conceptId: weak.conceptId,
          conceptName: weak.conceptName,
          weakQuestionCount: weak.totalAttempts - weak.correctAttempts,
          recommendation: 'Practice ${weak.totalAttempts - weak.correctAttempts} questions to improve ${weak.conceptName}',
          recommendedQuestions: conceptQuestions,
        ));
      }
    }

    return ExamDiagnosis(
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      skippedQuestions: 0, // Could add if we track skipped
      totalTimeSeconds: totalTimeSeconds,
      weakConcepts: weakConcepts,
      strongConcepts: strongConcepts,
      wrongAnswersByConcept: wrongAnswersByConcept,
      timePressureQuestions: timePressureQuestions,
      rescueRecommendations: rescueRecommendations,
      scorePercentage: scorePercentage,
      grade: grade,
    );
  }

  static String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 40) return 'D';
    return 'F';
  }

  static String _formatConceptName(String conceptId) {
    // Convert snake_case to Title Case
    return conceptId
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1)}' 
            : '')
        .join(' ');
  }
}