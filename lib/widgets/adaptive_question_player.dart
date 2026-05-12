import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question_data.dart';
import '../models/question_attempt.dart';
import '../services/learning_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/question_panel.dart';
import '../widgets/diagram_canvas.dart';

class AdaptiveQuestionPlayer extends StatefulWidget {
  final String topicId;
  final String? requestedDifficulty;
  final String sessionType;
  final Function(QuestionData)? onQuestionLoaded;
  final Function(QuestionAttempt)? onAttemptRecorded;

  const AdaptiveQuestionPlayer({
    Key? key,
    required this.topicId,
    this.requestedDifficulty,
    this.sessionType = 'practice',
    this.onQuestionLoaded,
    this.onAttemptRecorded,
  }) : super(key: key);

  @override
  State<AdaptiveQuestionPlayer> createState() => _AdaptiveQuestionPlayerState();
}

class _AdaptiveQuestionPlayerState extends State<AdaptiveQuestionPlayer> {
  QuestionData? _currentQuestion;
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _questionStartTime;
  int _selectedOptionIndex = -1;
  ConfidenceLevel _confidenceLevel = ConfidenceLevel.somewhatSure;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadNextQuestion();
  }

  Future<void> _loadNextQuestion() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedOptionIndex = -1;
      _confidenceLevel = ConfidenceLevel.somewhatSure;
    });

    try {
      final learningService = Provider.of<LearningService>(context, listen: false);
      final question = await learningService.getNextAdaptiveQuestion(
        topicId: widget.topicId,
        requestedDifficulty: widget.requestedDifficulty,
        sessionType: widget.sessionType,
      );

      setState(() {
        _currentQuestion = question;
        _questionStartTime = DateTime.now();
        _isLoading = false;
      });

      widget.onQuestionLoaded?.call(question);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load question: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (_currentQuestion == null || _selectedOptionIndex == -1) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final timeSpent = DateTime.now().difference(_questionStartTime!).inSeconds;
      final isCorrect = _selectedOptionIndex == _currentQuestion!.correctIndex;

      // Create attempt record
      final attempt = QuestionAttempt(
        questionId: _currentQuestion!.id,
        confidenceLevel: _confidenceLevel,
        isCorrect: isCorrect,
        timeSpentSeconds: timeSpent,
        timestamp: DateTime.now(),
        levelIndex: 0, // This would come from session context
      );

      // Record attempt (handles offline sync automatically)
      final learningService = Provider.of<LearningService>(context, listen: false);
      await learningService.recordAttempt(attempt);

      widget.onAttemptRecorded?.call(attempt);

      // Show feedback and load next question
      await _showAnswerFeedback(isCorrect);

      // Load next question after a short delay
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          _loadNextQuestion();
        }
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit answer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showAnswerFeedback(bool isCorrect) async {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final isOnline = connectivityService.isOnline;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
            ),
            SizedBox(width: 8),
            Text(isCorrect ? 'Correct!' : 'Incorrect'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentQuestion!.explanation ?? 'Great job!'),
            SizedBox(height: 8),
            if (!isOnline)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sync_problem, size: 16, color: Colors.orange),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Answer saved locally. Will sync when online.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final isOnline = connectivityService.isOnline;

    return Column(
      children: [
        // Connectivity indicator
        if (!isOnline)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.shade100,
            child: Row(
              children: [
                Icon(Icons.sync_problem, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Offline mode - answers will sync when connected',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                ),
              ],
            ),
          ),

        // Main content
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading adaptive question...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(_errorMessage!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNextQuestion,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_currentQuestion == null) {
      return Center(
        child: Text('No question available'),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question metadata
          _buildQuestionMetadata(),
          SizedBox(height: 16),

          // Question text
          Text(
            _currentQuestion!.text,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),

          // Diagram if available
          if (_currentQuestion!.diagram.elements.isNotEmpty) ...[
            Container(
              height: 200,
              child: DiagramCanvas(diagramData: _currentQuestion!.diagram),
            ),
            SizedBox(height: 16),
          ],

          // Options
          _buildOptions(),
          SizedBox(height: 16),

          // Confidence selector
          _buildConfidenceSelector(),
          SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedOptionIndex == -1 || _isSubmitting) 
                  ? null 
                  : _submitAnswer,
              child: _isSubmitting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Submitting...'),
                      ],
                    )
                  : Text('Submit Answer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionMetadata() {
    return Row(
      children: [
        Chip(
          label: Text(_currentQuestion!.difficulty.name),
          backgroundColor: _getDifficultyColor(_currentQuestion!.difficulty),
        ),
        SizedBox(width: 8),
        Chip(
          label: Text('${_currentQuestion!.estimatedSeconds}s'),
          avatar: Icon(Icons.timer, size: 16),
        ),
        Spacer(),
        if (_currentQuestion!.frequentlyAsked)
          Chip(
            label: Text('Frequent'),
            backgroundColor: Colors.blue.shade100,
            avatar: Icon(Icons.star, size: 16, color: Colors.blue),
          ),
      ],
    );
  }

  Widget _buildOptions() {
    return Column(
      children: List.generate(
        _currentQuestion!.options.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => _selectedOptionIndex = index),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedOptionIndex == index
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
                color: _selectedOptionIndex == index
                    ? Theme.of(context).primaryColor.shade50
                    : null,
              ),
              child: Row(
                children: [
                  Radio<int>(
                    value: index,
                    groupValue: _selectedOptionIndex,
                    onChanged: (value) => setState(() => _selectedOptionIndex = value!),
                  ),
                  Expanded(
                    child: Text(
                      _currentQuestion!.options[index],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How confident are you?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Row(
          children: ConfidenceLevel.values.map((level) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _confidenceLevel = level),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _confidenceLevel == level
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _confidenceLevel == level
                          ? Theme.of(context).primaryColor.shade50
                          : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getConfidenceIcon(level),
                          color: _confidenceLevel == level
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        SizedBox(height: 4),
                        Text(
                          _getConfidenceText(level),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: _confidenceLevel == level
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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

  IconData _getConfidenceIcon(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.notSure:
        return Icons.help_outline;
      case ConfidenceLevel.somewhatSure:
        return Icons.thumbs_up_down;
      case ConfidenceLevel.verySure:
        return Icons.thumbs_up_down;
    }
  }

  String _getConfidenceText(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.notSure:
        return 'Not Sure';
      case ConfidenceLevel.somewhatSure:
        return 'Somewhat Sure';
      case ConfidenceLevel.verySure:
        return 'Very Sure';
    }
  }
}