import 'package:flutter/material.dart';

import '../models/diagram_data.dart';
import '../models/foundation_journey.dart';
import '../models/journey_progression_engine.dart';
import '../models/journey_state.dart';
import '../models/performance_tracker.dart' hide QuestionAttempt;
import '../models/premium_state.dart';
import '../models/practice_mode.dart';
import '../models/question_attempt.dart';
import '../models/question_data.dart';
import '../services/content_loader.dart';
import '../widgets/polygon_manipulative.dart';

class FoundationJourneyQuestionScreen extends StatefulWidget {
  final JourneyLevel level;
  final int levelIndex;
  final FoundationJourney journey;
  final StudentJourneyState studentState;
  final JourneyProgressionEngine engine;
  final PerformanceTracker tracker;
  final PremiumState premiumState;

  const FoundationJourneyQuestionScreen({
    super.key,
    required this.level,
    required this.levelIndex,
    required this.journey,
    required this.studentState,
    required this.engine,
    required this.tracker,
    required this.premiumState,
  });

  @override
  State<FoundationJourneyQuestionScreen> createState() =>
      _FoundationJourneyQuestionScreenState();
}

class _FoundationJourneyQuestionScreenState
    extends State<FoundationJourneyQuestionScreen> {
  int _currentQuestionIndex = 0;
  QuestionData? _currentQuestion;
  ConfidenceLevel _selectedConfidence = ConfidenceLevel.somewhatSure;
  bool _showConfidenceSelector = false;
  bool _isProcessingAnswer = false;
  int? _pendingSelectedIndex;
  final List<QuestionAttempt> _attempts = [];
  Map<String, QuestionData> _contentQuestions = {};
  bool _isLoadingQuestions = true;

  @override
  void initState() {
    super.initState();
    _loadContentQuestions();
  }

  Future<void> _loadContentQuestions() async {
    final questions =
        await ContentLoader.loadJourneyQuestions(widget.journey.journeyId);
    setState(() {
      _contentQuestions = questions;
      _isLoadingQuestions = false;
      _loadCurrentQuestion();
    });
  }

  void _loadCurrentQuestion() {
    _currentQuestion = _getQuestionForLevel(widget.level);
    _selectedConfidence = ConfidenceLevel.somewhatSure;
    _showConfidenceSelector = false;
    _pendingSelectedIndex = null;
  }

  QuestionData _getQuestionForLevel(JourneyLevel level) {
    // Load question from content by question ID
    for (final qId in level.questionIds) {
      final question = _contentQuestions[qId];
      if (question != null) {
        return question;
      }
    }

    // Fallback: create a placeholder question if content not found
    final questionId = level.questionIds.isNotEmpty
        ? level.questionIds.first
        : 'foundation_journey_${level.level}';
    return _fallbackQuestion(questionId, level);
  }

  QuestionData _fallbackQuestion(String id, JourneyLevel level) {
    return QuestionData(
      id: id,
      text:
          'Question for ${level.title} (content loading...)',
      diagram: DiagramData(
        id: '${id}_diagram',
        type: DiagramType.geometry,
        title: level.title,
        elements: const [],
      ),
      options: const ['Option A', 'Option B', 'Option C', 'Option D'],
      correctIndex: 0,
      explanation: 'Content for this question is being loaded.',
      subject: 'Mathematics',
      chapter: widget.journey.chapter,
      topic: 'Geometry',
      primaryConcept: level.level,
      coreConcept: level.level,
      difficulty: Difficulty.medium,
      estimatedSeconds: level.expectedTimeSeconds ?? 60,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingQuestions || _currentQuestion == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.level.title),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = _currentQuestion!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.level.title),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Question ${_currentQuestionIndex + 1}/$_questionCount',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _LevelProgressBar(
            currentQuestion: _currentQuestionIndex + 1,
            totalQuestions: _questionCount,
            levelTitle: widget.level.title,
          ),
          if (_showConfidenceSelector)
            _ConfidenceSelector(
              selectedConfidence: _selectedConfidence,
              onConfidenceChanged: (confidence) {
                setState(() => _selectedConfidence = confidence);
              },
              onConfirm: () {
                final selectedIndex = _pendingSelectedIndex;
                if (selectedIndex == null) return;
                setState(() => _showConfidenceSelector = false);
                _processAnswer(selectedIndex);
              },
            )
          else
            Expanded(
              child: _QuestionContent(
                question: question,
                manipulatives: widget.level.manipulatives,
                onAnswerSelected: _handleAnswerSelected,
                isProcessing: _isProcessingAnswer,
              ),
            ),
        ],
      ),
    );
  }

  int get _questionCount => widget.level.questionIds.isEmpty
      ? 1
      : widget.level.questionIds.length;

  void _handleAnswerSelected(int selectedIndex) {
    if (_isProcessingAnswer) return;
    setState(() {
      _pendingSelectedIndex = selectedIndex;
      _showConfidenceSelector = true;
    });
  }

  Future<void> _processAnswer(int selectedIndex) async {
    setState(() => _isProcessingAnswer = true);

    final question = _currentQuestion!;
    final isCorrect = selectedIndex == question.correctIndex;
    final attempt = QuestionAttempt(
      questionId: question.id,
      isCorrect: isCorrect,
      confidenceLevel: _selectedConfidence,
      timeSpentSeconds: widget.level.expectedTimeSeconds ?? 60,
      timestamp: DateTime.now(),
      levelIndex: widget.levelIndex,
    );

    _attempts.add(attempt);

    final nextStep = widget.engine.getNextStep(
      state: widget.studentState,
      latestAttempt: attempt,
      journey: widget.journey,
    );
    widget.engine.updateStudentState(widget.studentState, attempt, nextStep);

    if (!mounted) return;
    await _showResultDialog(isCorrect, nextStep);
    if (mounted) {
      _isProcessingAnswer = false;
      _handleNextStep(nextStep);
    }
  }

  Future<void> _showResultDialog(bool isCorrect, JourneyStep nextStep) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.error,
                color: isCorrect ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(isCorrect ? 'Correct!' : 'Not quite'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isCorrect) ...[
                Text(
                  'Correct answer: ${_currentQuestion!.options[_currentQuestion!.correctIndex]}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(_currentQuestion!.explanation ?? ''),
              ],
              const SizedBox(height: 16),
              Text(nextStep.message),
              if (_selectedConfidence != ConfidenceLevel.somewhatSure) ...[
                const SizedBox(height: 8),
                Text(
                  'Your confidence: ${_selectedConfidence.displayName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _handleNextStep(JourneyStep nextStep) {
    switch (nextStep.action) {
      case JourneyAction.proceedToNext:
      case JourneyAction.jumpAhead:
      case JourneyAction.stayCurrent:
        if (_currentQuestionIndex < _questionCount - 1) {
          setState(() {
            _currentQuestionIndex++;
            _loadCurrentQuestion();
          });
        } else {
          Navigator.of(context).pop();
        }
        break;
      case JourneyAction.showMicroLesson:
        _showMicroLessonDialog();
        break;
      case JourneyAction.goToPrevious:
      case JourneyAction.repeatCurrent:
      case JourneyAction.repeatSimilar:
        setState(_loadCurrentQuestion);
        break;
      case JourneyAction.journeyComplete:
        _showJourneyCompleteDialog();
        break;
    }
  }

  void _showMicroLessonDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.level.microLesson.title),
          content: Text(widget.level.microLesson.body),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(_loadCurrentQuestion);
              },
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  void _showJourneyCompleteDialog() {
    final accuracy = _attempts.isEmpty
        ? 0
        : (_attempts.where((a) => a.isCorrect).length / _attempts.length * 100)
            .round();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber),
              SizedBox(width: 8),
              Text('Journey Complete!'),
            ],
          ),
          content: Text(
            'Total attempts: ${_attempts.length}\nAccuracy: $accuracy%',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }
}

class _LevelProgressBar extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final String levelTitle;

  const _LevelProgressBar({
    required this.currentQuestion,
    required this.totalQuestions,
    required this.levelTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalQuestions == 0 ? 0.0 : currentQuestion / totalQuestions;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(levelTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
          const SizedBox(height: 4),
          Text('$currentQuestion of $totalQuestions questions'),
        ],
      ),
    );
  }
}

class _ConfidenceSelector extends StatelessWidget {
  final ConfidenceLevel selectedConfidence;
  final ValueChanged<ConfidenceLevel> onConfidenceChanged;
  final VoidCallback onConfirm;

  const _ConfidenceSelector({
    required this.selectedConfidence,
    required this.onConfidenceChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('How confident are you?', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          ...ConfidenceLevel.values.map(
            (confidence) => RadioListTile<ConfidenceLevel>(
              title: Text(confidence.displayName),
              subtitle: Text(confidence.description),
              value: confidence,
              groupValue: selectedConfidence,
              onChanged: (value) {
                if (value != null) onConfidenceChanged(value);
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onConfirm,
              child: const Text('Submit Answer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionContent extends StatelessWidget {
  final QuestionData question;
  final List<String> manipulatives;
  final ValueChanged<int> onAnswerSelected;
  final bool isProcessing;

  const _QuestionContent({
    required this.question,
    required this.manipulatives,
    required this.onAnswerSelected,
    required this.isProcessing,
  });

  bool get _hasPolygonManipulative =>
      manipulatives.any((m) =>
          m.contains('sides') ||
          m.contains('polygon') ||
          m.contains('hexagon') ||
          m.contains('octagon') ||
          m == 'full_toolset');

  int _initialSidesForQuestion() {
    final concept = question.primaryConcept;
    if (concept.contains('hexagon')) return 6;
    if (concept.contains('octagon')) return 8;
    if (concept.contains('pentagon')) return 5;
    if (concept.contains('triangle')) return 3;
    return 4; // default to square
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.text, style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          if (_hasPolygonManipulative)
            PolygonManipulative(
              initialSides: _initialSidesForQuestion(),
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schema,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.diagram.title ?? 'Diagram',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      isProcessing ? null : () => onAnswerSelected(index),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Text(entry.value)),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (PracticeMode.foundationJourney.allowHints) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isProcessing
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Hint: Think about how many equal parts the shape is divided into.',
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Get Hint'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ConfidenceLevel.displayName and .description are now defined
// directly on the enum in student_attempt_event.dart.
