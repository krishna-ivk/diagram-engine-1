import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question_data.dart';
import '../models/student_attempt.dart';
import '../models/drill_session.dart';
import '../models/topic_capsule.dart';
import '../services/topic_content_loader.dart';
import '../services/attempt_tracker.dart';
import '../services/mastery_tracker.dart';
import '../services/reinforcement_selector.dart';
import '../widgets/question_panel.dart';

class QuickDrillScreen extends StatefulWidget {
  final String topicId;
  final DrillMode mode;

  const QuickDrillScreen({
    super.key,
    required this.topicId,
    this.mode = DrillMode.quickDrill,
  });

  @override
  State<QuickDrillScreen> createState() => _QuickDrillScreenState();
}

class _QuickDrillScreenState extends State<QuickDrillScreen>
    with TickerProviderStateMixin {
  DrillSession? _session;
  QuestionData? _currentQuestion;
  List<QuestionData> _questions = [];
  bool _isLoading = true;
  bool _showAnswer = false;
  int? _selectedOption;
  int _elapsedSeconds = 0;
  Timer? _timer;
  String? _errorMessage;
  String? _feedbackMessage;
  bool _isSubmitting = false;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startDrillSession();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  Future<void> _startDrillSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final topicCapsule = await TopicContentLoader.loadTopicCapsule(widget.topicId);
      List<String> questionIds;

      switch (widget.mode) {
        case DrillMode.quickDrill:
          // Mix of starter and practice questions
          questionIds = [
            ...topicCapsule.starterQuestionIds.take(3),
            ...topicCapsule.practiceQuestionIds.take(7),
          ];
          break;
        case DrillMode.revision:
          questionIds = topicCapsule.revisionQuestionIds.isNotEmpty
              ? topicCapsule.revisionQuestionIds
              : [...topicCapsule.starterQuestionIds, ...topicCapsule.practiceQuestionIds];
          break;
        case DrillMode.miniMock:
          questionIds = await ReinforcementSelector.selectMiniMockQuestions(
            topicId: widget.topicId,
            questionCount: 10,
          );
          break;
      }

      // Load questions
      _questions = await TopicContentLoader.loadQuestionsByIds(questionIds);

      // Create drill session
      _session = DrillSession(
        topicId: widget.topicId,
        questionIds: _questions.map((q) => q.id).toList(),
        currentIndex: 0,
        mode: widget.mode,
        startedAt: DateTime.now(),
        attempts: {},
      );

      _loadCurrentQuestion();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start drill session: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentQuestion() async {
    if (_session == null || _session!.currentIndex >= _questions.length) {
      _finishSession();
      return;
    }

    setState(() {
      _currentQuestion = _questions[_session!.currentIndex];
      _showAnswer = false;
      _selectedOption = null;
      _feedbackMessage = null;
      _isLoading = false;
    });

    _startTimer();
    _slideController.forward();
  }

  void _startTimer() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_showAnswer && mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _onOptionSelected(int index) {
    setState(() => _selectedOption = index);
  }

  Future<void> _submitAnswer() async {
    if (_currentQuestion == null || _selectedOption == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    _timer?.cancel();

    final isCorrect = _selectedOption == _currentQuestion!.correctIndex;
    final attempt = StudentAttempt(
      questionId: _currentQuestion!.id,
      topicId: widget.topicId,
      selectedIndex: _selectedOption!,
      isCorrect: isCorrect,
      timeTakenSeconds: _elapsedSeconds,
      misconceptionCode: isCorrect 
          ? null 
          : _currentQuestion!.misconceptionTags[_selectedOption!],
      attemptedAt: DateTime.now(),
    );

    // Record attempt
    await AttemptTracker.recordAttempt(attempt);
    await MasteryTracker.updateMasteryAfterAttempt(attempt);

    // Update session
    final updatedAttempts = Map<String, StudentAttempt>.from(_session!.attempts);
    updatedAttempts[_currentQuestion!.id] = attempt;
    _session = _session!.copyWith(attempts: updatedAttempts);

    // Generate feedback
    _generateFeedback(isCorrect);

    setState(() {
      _showAnswer = true;
      _isSubmitting = false;
    });

    // Auto-advance after delay
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _moveToNextQuestion();
      }
    });
  }

  void _generateFeedback(bool isCorrect) {
    if (isCorrect) {
      if (_elapsedSeconds <= (_currentQuestion!.estimatedSeconds ?? 60) * 0.7) {
        _feedbackMessage = 'Excellent! Correct and very fast! 🚀';
      } else if (_elapsedSeconds <= (_currentQuestion!.estimatedSeconds ?? 60) * 1.5) {
        _feedbackMessage = 'Good job! Correct answer! 👍';
      } else {
        _feedbackMessage = 'Correct! Try to be a bit faster next time. ⏱️';
      }
    } else {
      _feedbackMessage = _currentQuestion!.whyWrongExplanations?[_selectedOption!] ?? 
          'Not quite right. Let\'s try another approach.';
    }
  }

  Future<void> _moveToNextQuestion() async {
    if (_session == null) return;

    // Select next question based on performance
    String? nextQuestionId;
    if (!_showAnswer) {
      // This shouldn't happen, but just in case
      nextQuestionId = await ReinforcementSelector.selectNextQuestionAfterCorrect(
        currentQuestion: _currentQuestion!,
        timeTakenSeconds: _elapsedSeconds,
        topicId: widget.topicId,
      );
    } else {
      final isCorrect = _selectedOption == _currentQuestion!.correctIndex;
      if (isCorrect) {
        nextQuestionId = await ReinforcementSelector.selectNextQuestionAfterCorrect(
          currentQuestion: _currentQuestion!,
          timeTakenSeconds: _elapsedSeconds,
          topicId: widget.topicId,
        );
      } else {
        nextQuestionId = await ReinforcementSelector.selectNextQuestionAfterWrong(
          currentQuestion: _currentQuestion!,
          selectedOptionIndex: _selectedOption!,
          topicId: widget.topicId,
        );
      }
    }

    // Move to next index
    final nextIndex = _session!.currentIndex + 1;
    if (nextIndex < _questions.length) {
      _slideController.reset();
      setState(() {
        _session = _session!.copyWith(currentIndex: nextIndex);
      });
      _loadCurrentQuestion();
    } else {
      _finishSession();
    }
  }

  void _finishSession() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DrillResultsScreen(
          session: _session!,
          questions: _questions,
          mode: widget.mode,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_getModeTitle())),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading questions...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_getModeTitle())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _startDrillSession,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_currentQuestion == null || _session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_getModeTitle())),
        body: const Center(child: Text('No questions available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(_getModeTitle()),
            Text(
              'Q${_session!.currentIndex + 1} of ${_questions.length}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showExitConfirmation(),
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: (_session!.currentIndex + 1) / _questions.length,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),

              // Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time: ${_elapsedSeconds}s',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_currentQuestion!.estimatedSeconds != null)
                      Text(
                        'Target: ${_currentQuestion!.estimatedSeconds}s',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),

              // Question content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question text
                      Text(
                        _currentQuestion!.text,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Options
                      ...List.generate(
                        _currentQuestion!.options.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: _showAnswer ? null : () => _onOptionSelected(index),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _getOptionBorderColor(index),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: _getOptionBackgroundColor(index),
                              ),
                              child: Row(
                                children: [
                                  // Option indicator
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getOptionIndicatorColor(index),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + index), // A, B, C, D
                                        style: TextStyle(
                                          color: _getOptionTextColor(index),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Option text
                                  Expanded(
                                    child: Text(
                                      _currentQuestion!.options[index],
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: _getOptionTextColor(index),
                                        fontWeight: _selectedOption == index
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),

                                  // Result icon
                                  if (_showAnswer)
                                    Icon(
                                      index == _currentQuestion!.correctIndex
                                          ? Icons.check_circle
                                          : (_selectedOption == index
                                              ? Icons.cancel
                                              : null),
                                      color: index == _currentQuestion!.correctIndex
                                          ? Colors.green
                                          : (_selectedOption == index
                                              ? Colors.red
                                              : null),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Feedback message
                      if (_feedbackMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedOption == _currentQuestion!.correctIndex
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedOption == _currentQuestion!.correctIndex
                                  ? Colors.green.shade200
                                  : Colors.orange.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _selectedOption == _currentQuestion!.correctIndex
                                        ? Icons.check_circle
                                        : Icons.info,
                                    color: _selectedOption == _currentQuestion!.correctIndex
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedOption == _currentQuestion!.correctIndex
                                        ? 'Correct!'
                                        : 'Let\'s review',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: _selectedOption == _currentQuestion!.correctIndex
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(_feedbackMessage!),
                              if (_currentQuestion!.explanation != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _currentQuestion!.explanation!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Submit button
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_selectedOption == null || _isSubmitting)
                        ? null
                        : _submitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(_showAnswer ? 'Next Question' : 'Submit Answer'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getModeTitle() {
    switch (widget.mode) {
      case DrillMode.quickDrill:
        return 'Quick Drill';
      case DrillMode.revision:
        return 'Revision Drill';
      case DrillMode.miniMock:
        return 'Mini Mock Test';
    }
  }

  Color _getOptionBorderColor(int index) {
    if (!_showAnswer) {
      return _selectedOption == index
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.outline;
    }

    if (index == _currentQuestion!.correctIndex) {
      return Colors.green;
    }

    if (_selectedOption == index && index != _currentQuestion!.correctIndex) {
      return Colors.red;
    }

    return Theme.of(context).colorScheme.outline;
  }

  Color _getOptionBackgroundColor(int index) {
    if (!_showAnswer) {
      return _selectedOption == index
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.transparent;
    }

    if (index == _currentQuestion!.correctIndex) {
      return Colors.green.shade50;
    }

    if (_selectedOption == index && index != _currentQuestion!.correctIndex) {
      return Colors.red.shade50;
    }

    return Colors.transparent;
  }

  Color _getOptionIndicatorColor(int index) {
    if (!_showAnswer) {
      return _selectedOption == index
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.outline;
    }

    if (index == _currentQuestion!.correctIndex) {
      return Colors.green;
    }

    if (_selectedOption == index && index != _currentQuestion!.correctIndex) {
      return Colors.red;
    }

    return Theme.of(context).colorScheme.outline;
  }

  Color _getOptionTextColor(int index) {
    if (!_showAnswer) {
      return _selectedOption == index
          ? Theme.of(context).colorScheme.onPrimaryContainer
          : Theme.of(context).colorScheme.onSurface;
    }

    if (index == _currentQuestion!.correctIndex) {
      return Colors.green.shade800;
    }

    if (_selectedOption == index && index != _currentQuestion!.correctIndex) {
      return Colors.red.shade800;
    }

    return Theme.of(context).colorScheme.onSurface;
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Drill Session?'),
        content: Text(
          'You are on question ${_session!.currentIndex + 1} of ${_questions.length}. '
          'Your progress will be saved. Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class DrillResultsScreen extends StatelessWidget {
  final DrillSession session;
  final List<QuestionData> questions;
  final DrillMode mode;

  const DrillResultsScreen({
    super.key,
    required this.session,
    required this.questions,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = session.accuracy;
    final correctCount = session.correctAnswers;
    final totalCount = session.totalQuestions;
    final elapsedTime = session.elapsedTime;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getResultsTitle()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Circular progress indicator
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: accuracy,
                            strokeWidth: 8,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation(
                              accuracy >= 0.8
                                  ? Colors.green
                                  : accuracy >= 0.6
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${(accuracy * 100).toInt()}%',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Accuracy',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          'Correct',
                          '$correctCount',
                          Colors.green,
                        ),
                        _buildStatItem(
                          'Total',
                          '$totalCount',
                          theme.colorScheme.primary,
                        ),
                        _buildStatItem(
                          'Time',
                          '${elapsedTime.inMinutes}:${(elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}',
                          theme.colorScheme.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Performance message
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_getPerformanceMessage(accuracy)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Topics'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WeaknessReportScreen(
                            topicId: session.topicId,
                            session: session,
                          ),
                        ),
                      );
                    },
                    child: const Text('View Report'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _getResultsTitle() {
    switch (mode) {
      case DrillMode.quickDrill:
        return 'Quick Drill Results';
      case DrillMode.revision:
        return 'Revision Results';
      case DrillMode.miniMock:
        return 'Mock Test Results';
    }
  }

  String _getPerformanceMessage(double accuracy) {
    if (accuracy >= 0.9) {
      return 'Excellent work! You\'ve mastered this topic. Consider moving to more challenging questions.';
    } else if (accuracy >= 0.8) {
      return 'Great job! You have a strong understanding of this topic. Keep practicing to maintain your skills.';
    } else if (accuracy >= 0.6) {
      return 'Good effort! You\'re making progress. Focus on your weak areas and try some revision questions.';
    } else {
      return 'Keep practicing! This topic needs more work. Try the revision drill to strengthen your foundation.';
    }
  }
}

class WeaknessReportScreen extends StatelessWidget {
  final String topicId;
  final DrillSession session;

  const WeaknessReportScreen({
    super.key,
    required this.topicId,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weakness Report'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Weakness report will be implemented next'),
      ),
    );
  }
}