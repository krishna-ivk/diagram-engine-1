import 'package:flutter/material.dart';
import '../models/performance_tracker.dart';
import '../models/premium_state.dart';
import '../models/foundation_journey.dart';
import '../models/journey_progression_engine.dart';
import '../models/journey_state.dart';
import '../models/question_data.dart';
import '../models/question_attempt.dart';
import '../models/practice_mode.dart';
import '../models/confidence_level.dart';
import 'question_screen.dart';

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
  State<FoundationJourneyQuestionScreen> createState() => _FoundationJourneyQuestionScreenState();
}

class _FoundationJourneyQuestionScreenState extends State<FoundationJourneyQuestionScreen> {
  int _currentQuestionIndex = 0;
  QuestionData? _currentQuestion;
  ConfidenceLevel _selectedConfidence = ConfidenceLevel.somewhatSure;
  bool _showConfidenceSelector = false;
  bool _isProcessingAnswer = false;
  List<QuestionAttempt> _attempts = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentQuestion();
  }

  void _loadCurrentQuestion() {
    // For now, we'll use mock question data
    // In a real implementation, this would load from the content pipeline
    _currentQuestion = _getMockQuestionForLevel(widget.level);
    _showConfidenceSelector = false;
    _selectedConfidence = ConfidenceLevel.somewhatSure;
  }

  QuestionData _getMockQuestionForLevel(JourneyLevel level) {
    // Create mock question based on level
    switch (level.level) {
      case 'L0':
        return QuestionData(
          id: 'class7_square_parts_001',
          questionText: 'A square is divided into 4 equal triangles by drawing lines from the center. What fraction of the square is each triangle?',
          diagram: DiagramData(
            title: 'Square Divided into Triangles',
            elements: [],
          ),
          options: [
            '1/2', '1/4', '1/3', '1/8'
          ],
          correctAnswer: 1, // 1/4
          explanation: 'A square divided into 4 equal parts means each part is 1/4 of the whole.',
          concept: 'square_fractions',
          difficulty: 'easy',
        );
      case 'L1':
        return QuestionData(
          id: 'rescue_foundation_square_center_angle_001',
          questionText: 'A square is divided from its center into 4 equal triangles. What is the measure of each central angle?',
          diagram: DiagramData(
            title: 'Square Central Angles',
            elements: [],
          ),
          options: [
            '45°', '90°', '180°', '360°'
          ],
          correctAnswer: 1, // 90°
          explanation: 'A full circle is 360°. Dividing by 4 equal parts: 360° ÷ 4 = 90°.',
          concept: 'square_center_angle',
          difficulty: 'easy',
        );
      default:
        return QuestionData(
          id: 'mock_question',
          questionText: 'What is the central angle of a regular hexagon?',
          diagram: DiagramData(
            title: 'Hexagon Central Angle',
            elements: [],
          ),
          options: [
            '45°', '60°', '90°', '120°'
          ],
          correctAnswer: 1, // 60°
          explanation: 'A hexagon has 6 sides. Central angle = 360° ÷ 6 = 60°.',
          concept: 'hexagon_center_angle',
          difficulty: 'medium',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_currentQuestion == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.level.title),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Question ${_currentQuestionIndex + 1}/${widget.level.questionIds.length}',
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
          // Level progress bar
          _LevelProgressBar(
            currentQuestion: _currentQuestionIndex + 1,
            totalQuestions: widget.level.questionIds.length,
            levelTitle: widget.level.title,
          ),
          
          // Confidence selector (shown before question)
          if (_showConfidenceSelector)
            _ConfidenceSelector(
              selectedConfidence: _selectedConfidence,
              onConfidenceChanged: (confidence) {
                setState(() {
                  _selectedConfidence = confidence;
                });
              },
              onConfirm: () {
                setState(() {
                  _showConfidenceSelector = false;
                });
              },
            )
          else
            // Question content
            Expanded(
              child: _QuestionContent(
                question: _currentQuestion!,
                level: widget.level,
                onAnswerSelected: _handleAnswerSelected,
                isProcessing: _isProcessingAnswer,
              ),
            ),
        ],
      ),
    );
  }

  void _handleAnswerSelected(int selectedIndex) async {
    if (_isProcessingAnswer) return;
    
    setState(() => _isProcessingAnswer = true);
    
    // Show confidence selector before processing answer
    setState(() {
      _showConfidenceSelector = true;
      _isProcessingAnswer = false;
    });
  }

  void _processAnswer(int selectedIndex) async {
    setState(() => _isProcessingAnswer = true);
    
    final isCorrect = selectedIndex == _currentQuestion!.correctAnswer;
    final attempt = QuestionAttempt(
      questionId: _currentQuestion!.id,
      selectedOptionIndex: selectedIndex,
      isCorrect: isCorrect,
      confidenceLevel: _selectedConfidence,
      timeSpentSeconds: 60, // Mock time
      timestamp: DateTime.now(),
      levelIndex: widget.levelIndex,
    );
    
    _attempts.add(attempt);
    
    // Get next step from progression engine
    final nextStep = widget.engine.getNextStep(
      state: widget.studentState,
      latestAttempt: attempt,
      journey: widget.journey,
    );
    
    // Update student state
    widget.engine.updateStudentState(widget.studentState, attempt, nextStep);
    
    // Show result dialog
    await _showResultDialog(isCorrect, nextStep);
    
    // Navigate based on next step
    if (mounted) {
      _handleNextStep(nextStep);
    }
  }

  Future<void> _showResultDialog(bool isCorrect, JourneyStep nextStep) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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
                  'The correct answer is: ${_currentQuestion!.options[_currentQuestion!.correctAnswer]}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(_currentQuestion!.explanation),
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
        // Move to next question or level
        if (_currentQuestionIndex < widget.level.questionIds.length - 1) {
          setState(() {
            _currentQuestionIndex++;
            _loadCurrentQuestion();
          });
        } else {
          // Level complete, go back to journey screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        break;
        
      case JourneyAction.showMicroLesson:
        // Show micro-lesson and repeat current question
        _showMicroLessonDialog();
        break;
        
      case JourneyAction.goToPrevious:
        // Go to previous level
        Navigator.of(context).pop();
        break;
        
      case JourneyAction.repeatCurrent:
      case JourneyAction.repeatSimilar:
        // Repeat current question
        setState(() {
          _loadCurrentQuestion();
        });
        break;
        
      case JourneyAction.journeyComplete:
        // Journey completed
        _showJourneyCompleteDialog();
        break;
        
      case JourneyAction.stayCurrent:
        // Continue with current level
        if (_currentQuestionIndex < widget.level.questionIds.length - 1) {
          setState(() {
            _currentQuestionIndex++;
            _loadCurrentQuestion();
          });
        }
        break;
    }
  }

  void _showMicroLessonDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.level.microLesson.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.level.microLesson.body),
                const SizedBox(height: 16),
                if (widget.level.microLesson.visualHintIds.isNotEmpty) ...[
                  Text(
                    'Key Points:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...widget.level.microLesson.visualHintIds.map((hint) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(hint.replaceAll('_', ' ').toUpperCase())),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _loadCurrentQuestion();
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  void _showJourneyCompleteDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber),
              const SizedBox(width: 8),
              const Text('Journey Complete!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Congratulations! You have completed the Foundation Journey.'),
              const SizedBox(height: 16),
              Text(
                'Total attempts: ${_attempts.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Accuracy: ${(_attempts.where((a) => a.isCorrect).length / _attempts.length * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
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
    final progress = currentQuestion / totalQuestions;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            levelTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Text(
            '$currentQuestion of $totalQuestions questions',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ConfidenceSelector extends StatelessWidget {
  final ConfidenceLevel selectedConfidence;
  final Function(ConfidenceLevel) onConfidenceChanged;
  final VoidCallback onConfirm;

  const _ConfidenceSelector({
    required this.selectedConfidence,
    required this.onConfidenceChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How confident are you?',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...ConfidenceLevel.values.map((confidence) => RadioListTile<ConfidenceLevel>(
            title: Text(confidence.displayName),
            subtitle: Text(confidence.description),
            value: confidence,
            groupValue: selectedConfidence,
            onChanged: (value) {
              if (value != null) {
                onConfidenceChanged(value);
              }
            },
          )),
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
  final JourneyLevel level;
  final Function(int) onAnswerSelected;
  final bool isProcessing;

  const _QuestionContent({
    required this.question,
    required this.level,
    required this.onAnswerSelected,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          Text(
            question.questionText,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          
          // Diagram placeholder
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
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
                  question.diagram.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Answer options
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isProcessing ? null : () => onAnswerSelected(index),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 24),
          
          // Hint button (if allowed)
          if (PracticeMode.foundationJourney.allowHints) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isProcessing ? null : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hint: Think about how many equal parts the shape is divided into.')),
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

extension ConfidenceLevelExtension on ConfidenceLevel {
  String get displayName {
    switch (this) {
      case ConfidenceLevel.notSure:
        return 'Not Sure';
      case ConfidenceLevel.somewhatSure:
        return 'Somewhat Sure';
      case ConfidenceLevel.verySure:
        return 'Very Sure';
    }
  }

  String get description {
    switch (this) {
      case ConfidenceLevel.notSure:
        return 'I\'m guessing or need help';
      case ConfidenceLevel.somewhatSure:
        return 'I think I know, but not 100%';
      case ConfidenceLevel.verySure:
        return 'I\'m confident in my answer';
    }
  }
}