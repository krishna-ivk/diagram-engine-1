import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question_data.dart';
import '../models/student_attempt.dart';
import '../models/drill_session.dart';
import '../services/topic_content_loader.dart';
import '../services/attempt_tracker.dart';
import '../services/mastery_tracker.dart';
import '../services/reinforcement_selector.dart';

class MiniMockScreen extends StatefulWidget {
  final String topicId;

  const MiniMockScreen({
    super.key,
    required this.topicId,
  });

  @override
  State<MiniMockScreen> createState() => _MiniMockScreenState();
}

class _MiniMockScreenState extends State<MiniMockScreen>
    with TickerProviderStateMixin {
  DrillSession? _session;
  List<QuestionData> _questions = [];
  bool _isLoading = true;
  bool _showAnswer = false;
  int? _selectedOption;
  int _elapsedSeconds = 0;
  Timer? _timer;
  String? _errorMessage;

  // Animation controllers
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startMockTest();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _startMockTest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Select 10 mixed-difficulty questions for mini mock
      final questionIds = await ReinforcementSelector.selectMiniMockQuestions(
        topicId: widget.topicId,
        questionCount: 10,
      );

      // Load questions
      _questions = await TopicContentLoader.loadQuestionsByIds(questionIds);

      // Create mock session
      _session = DrillSession(
        topicId: widget.topicId,
        questionIds: _questions.map((q) => q.id).toList(),
        currentIndex: 0,
        mode: DrillMode.miniMock,
        startedAt: DateTime.now(),
        attempts: {},
      );

      _loadCurrentQuestion();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start mock test: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentQuestion() async {
    if (_session == null || _session!.currentIndex >= _questions.length) {
      _finishMockTest();
      return;
    }

    setState(() {
      _showAnswer = false;
      _selectedOption = null;
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
    if (_currentQuestion == null || _selectedOption == null) return;

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

    setState(() {
      _showAnswer = true;
    });

    // Auto-advance after delay
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _moveToNextQuestion();
      }
    });
  }

  Future<void> _moveToNextQuestion() async {
    if (_session == null) return;

    final nextIndex = _session!.currentIndex + 1;
    if (nextIndex < _questions.length) {
      _slideController.reset();
      setState(() {
        _session = _session!.copyWith(currentIndex: nextIndex);
      });
      _loadCurrentQuestion();
    } else {
      _finishMockTest();
    }
  }

  void _finishMockTest() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MockTestResultsScreen(
          session: _session!,
          questions: _questions,
          topicId: widget.topicId,
        ),
      ),
    );
  }

  QuestionData? get _currentQuestion {
    if (_session == null || _session!.currentIndex >= _questions.length) {
      return null;
    }
    return _questions[_session!.currentIndex];
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mini Mock Test')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing mock test...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mini Mock Test')),
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
                  onPressed: _startMockTest,
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
        appBar: AppBar(title: const Text('Mini Mock Test')),
        body: const Center(child: Text('No questions available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Mini Mock Test'),
            Text(
              'Q${_session!.currentIndex + 1} of ${_questions.length}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${Duration(seconds: _elapsedSeconds).inMinutes}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_session!.currentIndex + 1) / _questions.length,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),

            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question metadata
                    Row(
                      children: [
                        Chip(
                          label: Text(_currentQuestion!.difficulty.name),
                          backgroundColor: _getDifficultyColor(_currentQuestion!.difficulty),
                        ),
                        const SizedBox(width: 8),
                        if (_currentQuestion!.frequentlyAsked)
                          Chip(
                            label: const Text('Frequent'),
                            backgroundColor: Colors.blue.shade100,
                            avatar: const Icon(Icons.star, size: 16, color: Colors.blue),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

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
                                  width: 32,
                                  height: 32,
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
                                        fontSize: 14,
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
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Explanation (shown after answer)
                    if (_showAnswer && _currentQuestion!.explanation != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Explanation',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentQuestion!.explanation!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  onPressed: (_selectedOption == null) ? null : _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: Text(_showAnswer ? 'Next Question' : 'Submit Answer'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return Colors.green.shade100;
      case Difficulty.medium:
        return Colors.orange.shade100;
      case Difficulty.hard:
        return Colors.red.shade100;
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
}

class MockTestResultsScreen extends StatelessWidget {
  final DrillSession session;
  final List<QuestionData> questions;
  final String topicId;

  const MockTestResultsScreen({
    super.key,
    required this.session,
    required this.questions,
    required this.topicId,
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
        title: const Text('Mock Test Results'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Circular progress indicator
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: accuracy,
                            strokeWidth: 10,
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
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Score',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Stats grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          'Correct',
                          '$correctCount',
                          Colors.green,
                          Icons.check_circle,
                        ),
                        _buildStatItem(
                          'Wrong',
                          '${totalCount - correctCount}',
                          Colors.red,
                          Icons.cancel,
                        ),
                        _buildStatItem(
                          'Time',
                          '${elapsedTime.inMinutes}:${(elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}',
                          theme.colorScheme.primary,
                          Icons.timer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Grade and recommendation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Grade: ${_getGrade(accuracy)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getGradeColor(accuracy),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getGradeColor(accuracy).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getPerformanceLevel(accuracy),
                            style: TextStyle(
                              color: _getGradeColor(accuracy),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getRecommendation(accuracy),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Question breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question Breakdown',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(
                      questions.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: session.attempts.containsKey(questions[index].id)
                                    ? (session.attempts[questions[index].id]!.isCorrect
                                        ? Colors.green.shade100
                                        : Colors.red.shade100)
                                    : Colors.grey.shade100,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: session.attempts.containsKey(questions[index].id)
                                        ? (session.attempts[questions[index].id]!.isCorrect
                                            ? Colors.green.shade800
                                            : Colors.red.shade800)
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Q${index + 1}: ${questions[index].difficulty.name}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            if (session.attempts.containsKey(questions[index].id))
                              Icon(
                                session.attempts[questions[index].id]!.isCorrect
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: session.attempts[questions[index].id]!.isCorrect
                                    ? Colors.green
                                    : Colors.red,
                                size: 20,
                              )
                            else
                              Icon(
                                Icons.remove_circle_outline,
                                color: Colors.grey,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Topics'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WeaknessReportScreen(
                            topicId: topicId,
                            session: session,
                          ),
                        ),
                      );
                    },
                    child: const Text('View Report'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MiniMockScreen(topicId: topicId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                    ),
                    child: const Text('Retest'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
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

  String _getGrade(double accuracy) {
    if (accuracy >= 0.9) return 'A+';
    if (accuracy >= 0.8) return 'A';
    if (accuracy >= 0.7) return 'B+';
    if (accuracy >= 0.6) return 'B';
    if (accuracy >= 0.5) return 'C';
    return 'D';
  }

  Color _getGradeColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getPerformanceLevel(double accuracy) {
    if (accuracy >= 0.9) return 'Excellent';
    if (accuracy >= 0.8) return 'Good';
    if (accuracy >= 0.6) return 'Average';
    return 'Needs Work';
  }

  String _getRecommendation(double accuracy) {
    if (accuracy >= 0.9) {
      return 'Outstanding performance! You have mastered this topic. Consider moving to more advanced topics or challenging questions.';
    } else if (accuracy >= 0.8) {
      return 'Great work! You have a strong understanding. Practice a bit more to achieve mastery level.';
    } else if (accuracy >= 0.6) {
      return 'Good effort! You\'re on the right track. Focus on your weak areas and try revision questions.';
    } else {
      return 'Keep practicing! This topic needs more work. Start with easier questions and gradually increase difficulty.';
    }
  }
}