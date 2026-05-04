import 'dart:async';

import 'package:flutter/material.dart';

import '../models/diagram_element.dart';
import '../models/performance_tracker.dart';
import '../models/question_data.dart';
import '../widgets/diagram_canvas.dart';
import '../widgets/drawing_overlay.dart';
import '../widgets/fullscreen_diagram.dart';
import '../widgets/insight_panel.dart';
import '../widgets/layer_toggle.dart';
import '../widgets/question_panel.dart';
import '../widgets/reveal_panel.dart';

class QuestionScreen extends StatefulWidget {
  final List<QuestionData> questions;
  final PerformanceTracker tracker;

  const QuestionScreen({
    super.key,
    required this.questions,
    required this.tracker,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int _currentIndex = 0;
  int? _selectedOption;
  bool _showAnswer = false;

  bool _showValues = true;
  bool _showHints = false;
  bool _showLabels = true;

  final Set<String> _highlightedIds = {};
  DiagramElement? _lastTappedElement;

  // Timer
  Timer? _timer;
  int _elapsedSeconds = 0;

  // Smart auto-highlight
  Timer? _inactivityTimer;
  bool _autoHighlighted = false;

  // Drawing tools
  bool _drawingEnabled = false;
  DrawingTool _activeTool = DrawingTool.none;
  List<DrawnElement> _drawnElements = [];

  // Hints tracking
  int _hintsUsed = 0;
  int _tapCount = 0;

  QuestionData get _currentQuestion => widget.questions[_currentIndex];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_showAnswer) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _autoHighlighted = false;
    _inactivityTimer = Timer(const Duration(seconds: 10), () {
      if (!_showAnswer && _highlightedIds.isEmpty && mounted) {
        _autoHighlightRelevant();
      }
    });
  }

  void _autoHighlightRelevant() {
    final interactive = _currentQuestion.diagram.elements
        .where((e) => e.interactive && e.insight != null)
        .take(2);
    if (interactive.isNotEmpty) {
      setState(() {
        for (final el in interactive) {
          _highlightedIds.add(el.id);
        }
        _lastTappedElement = interactive.first;
        _autoHighlighted = true;
      });
    }
  }

  void _onElementTap(String id) {
    _tapCount++;
    _resetInactivityTimer();
    setState(() {
      if (_highlightedIds.contains(id)) {
        _highlightedIds.remove(id);
        _lastTappedElement = null;
      } else {
        _highlightedIds.add(id);
        _lastTappedElement = _currentQuestion.diagram.elements
            .where((e) => e.id == id)
            .firstOrNull;
      }
    });
  }

  void _onOptionSelected(int index) {
    _resetInactivityTimer();
    setState(() => _selectedOption = index);
  }

  void _checkAnswer() {
    _timer?.cancel();
    _inactivityTimer?.cancel();

    final isCorrect = _selectedOption == _currentQuestion.correctIndex;
    widget.tracker.recordAttempt(QuestionAttempt(
      questionId: _currentQuestion.id,
      topic: _currentQuestion.topic,
      coreConcept: _currentQuestion.coreConcept ?? _currentQuestion.topic,
      correct: isCorrect,
      timeSeconds: _elapsedSeconds,
      tapCount: _tapCount,
      hintsUsed: _hintsUsed,
      timestamp: DateTime.now(),
    ));

    setState(() {
      _showAnswer = true;
      // Auto-highlight after wrong answer
      if (!isCorrect) {
        _autoHighlightRelevant();
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      _navigateToQuestion(_currentIndex + 1);
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      _navigateToQuestion(_currentIndex - 1);
    }
  }

  void _navigateToQuestion(int index) {
    setState(() {
      _currentIndex = index;
      _selectedOption = null;
      _showAnswer = false;
      _highlightedIds.clear();
      _showHints = false;
      _lastTappedElement = null;
      _drawingEnabled = false;
      _activeTool = DrawingTool.none;
      _drawnElements = [];
      _autoHighlighted = false;
      _hintsUsed = 0;
      _tapCount = 0;
    });
    _startTimer();
    _resetInactivityTimer();
  }

  void _openFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenDiagram(
          question: _currentQuestion,
          highlightedIds: _highlightedIds,
          showValues: _showValues,
          showHints: _showHints,
          showLabels: _showLabels,
          onElementTap: _onElementTap,
          onValuesChanged: (v) => setState(() => _showValues = v),
          onHintsChanged: (v) => setState(() => _showHints = v),
          onLabelsChanged: (v) => setState(() => _showLabels = v),
        ),
      ),
    );
  }

  void _onRevealStep(RevealStep step) {
    _hintsUsed++;
    setState(() {
      if (step.highlightIds != null) {
        _highlightedIds.addAll(step.highlightIds!);
      }
      if (step.showHints == true) {
        _showHints = true;
      }
    });
  }

  void _practiceSimilar() {
    final similar = _currentQuestion.similarQuestionIds;
    if (similar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No similar questions available yet.')),
      );
      return;
    }
    final similarQuestions = widget.questions
        .where((q) => similar.contains(q.id))
        .toList();
    if (similarQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Similar questions not found.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionScreen(
          questions: similarQuestions,
          tracker: widget.tracker,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Q${_currentIndex + 1} of ${widget.questions.length}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: _currentIndex > 0 ? _prevQuestion : null,
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: _currentIndex < widget.questions.length - 1
                ? _nextQuestion
                : null,
          ),
        ],
      ),
      body: isWide ? _buildWideLayout(theme) : _buildMobileLayout(theme),
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          flex: 45,
          child: _buildDiagramSection(theme),
        ),
        Container(
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Expanded(
          flex: 55,
          child: _buildQuestionSection(),
        ),
      ],
    );
  }

  Widget _buildWideLayout(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _buildDiagramSection(theme)),
        VerticalDivider(width: 1, color: Colors.grey.shade300),
        Expanded(child: _buildQuestionSection()),
      ],
    );
  }

  Widget _buildQuestionSection() {
    return Column(
      children: [
        Expanded(
          child: QuestionPanel(
            question: _currentQuestion,
            selectedIndex: _selectedOption,
            showAnswer: _showAnswer,
            onOptionSelected: _onOptionSelected,
            onCheckAnswer: _checkAnswer,
            elapsedSeconds: _elapsedSeconds,
          ),
        ),
        if (_currentQuestion.revealSteps.isNotEmpty && !_showAnswer)
          RevealPanel(
            steps: _currentQuestion.revealSteps,
            onStepRevealed: _onRevealStep,
          ),
        // Practice similar + performance after answering
        if (_showAnswer) ...[
          _buildPostAnswerActions(),
        ],
      ],
    );
  }

  Widget _buildPostAnswerActions() {
    final insight =
        widget.tracker.getInsightForTopic(_currentQuestion.topic);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Weak area insight
          if (insight != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_down,
                      size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      insight,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Practice similar button
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _practiceSimilar,
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('2 More Like This'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    side: const BorderSide(color: Colors.indigo),
                  ),
                ),
              ),
              if (_currentIndex < widget.questions.length - 1) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _nextQuestion,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Next Question'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagramSection(ThemeData theme) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Layer toggles + drawing tools + expand button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        LayerToggleBar(
                          showValues: _showValues,
                          showHints: _showHints,
                          showLabels: _showLabels,
                          onValuesChanged: (v) =>
                              setState(() => _showValues = v),
                          onHintsChanged: (v) =>
                              setState(() => _showHints = v),
                          onLabelsChanged: (v) =>
                              setState(() => _showLabels = v),
                        ),
                        const SizedBox(width: 8),
                        DrawingToolbar(
                          activeTool: _activeTool,
                          drawingEnabled: _drawingEnabled,
                          onToggleDrawing: () {
                            setState(() {
                              _drawingEnabled = !_drawingEnabled;
                              _activeTool = _drawingEnabled
                                  ? DrawingTool.line
                                  : DrawingTool.none;
                            });
                          },
                          onToolSelected: (tool) =>
                              setState(() => _activeTool = tool),
                          onUndo: () {
                            if (_drawnElements.isNotEmpty) {
                              setState(() {
                                _drawnElements = _drawnElements.sublist(
                                    0, _drawnElements.length - 1);
                              });
                            }
                          },
                          onClearAll: () =>
                              setState(() => _drawnElements = []),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: _openFullscreen,
                  tooltip: 'Fullscreen',
                ),
              ],
            ),
          ),

          // Diagram title
          if (_currentQuestion.diagram.title != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _currentQuestion.diagram.title!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),

          // Auto-highlight hint
          if (_autoHighlighted && !_showAnswer)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: Colors.purple.shade50,
              child: Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 14, color: Colors.purple.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Auto-highlighted key elements to help you get started',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.purple.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Diagram canvas + drawing overlay
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  DiagramCanvas(
                    diagram: _currentQuestion.diagram,
                    highlightedIds: _highlightedIds,
                    showValues: _showValues,
                    showHints: _showHints,
                    showLabels: _showLabels,
                    onElementTap:
                        _drawingEnabled ? null : _onElementTap,
                  ),
                  DrawingOverlay(
                    enabled: _drawingEnabled,
                    activeTool: _activeTool,
                    drawnElements: _drawnElements,
                    onElementsChanged: (elements) =>
                        setState(() => _drawnElements = elements),
                  ),
                ],
              ),
            ),
          ),

          // Insight panel
          if (_lastTappedElement != null &&
              _lastTappedElement!.insight != null)
            InsightPanel(
              element: _lastTappedElement!,
              onDismiss: () => setState(() => _lastTappedElement = null),
            ),

          // Highlighted elements info
          if (_highlightedIds.isNotEmpty &&
              _lastTappedElement?.insight == null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.amber.shade50,
              child: Row(
                children: [
                  Icon(Icons.touch_app,
                      size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Selected: ${_highlightedIds.join(", ")}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _highlightedIds.clear();
                      _lastTappedElement = null;
                    }),
                    child: Icon(Icons.clear,
                        size: 16, color: Colors.amber.shade700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
