import 'package:flutter/material.dart';

import '../models/diagram_element.dart';
import '../models/question_data.dart';
import '../widgets/diagram_canvas.dart';
import '../widgets/fullscreen_diagram.dart';
import '../widgets/insight_panel.dart';
import '../widgets/layer_toggle.dart';
import '../widgets/question_panel.dart';
import '../widgets/reveal_panel.dart';

class QuestionScreen extends StatefulWidget {
  final List<QuestionData> questions;

  const QuestionScreen({super.key, required this.questions});

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

  QuestionData get _currentQuestion => widget.questions[_currentIndex];

  void _onElementTap(String id) {
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
    setState(() => _selectedOption = index);
  }

  void _checkAnswer() {
    setState(() => _showAnswer = true);
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _showAnswer = false;
        _highlightedIds.clear();
        _showHints = false;
        _lastTappedElement = null;
      });
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _selectedOption = null;
        _showAnswer = false;
        _highlightedIds.clear();
        _showHints = false;
        _lastTappedElement = null;
      });
    }
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
    setState(() {
      if (step.highlightIds != null) {
        _highlightedIds.addAll(step.highlightIds!);
      }
      if (step.showHints == true) {
        _showHints = true;
      }
    });
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
        // Diagram area (top ~45%)
        Expanded(
          flex: 45,
          child: _buildDiagramSection(theme),
        ),

        // Divider with drag handle
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

        // Question area (bottom ~55%)
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
        // Diagram (left half)
        Expanded(
          child: _buildDiagramSection(theme),
        ),

        // Vertical divider
        VerticalDivider(width: 1, color: Colors.grey.shade300),

        // Question (right half)
        Expanded(
          child: _buildQuestionSection(),
        ),
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
          ),
        ),
        if (_currentQuestion.revealSteps.isNotEmpty && !_showAnswer)
          RevealPanel(
            steps: _currentQuestion.revealSteps,
            onStepRevealed: _onRevealStep,
          ),
      ],
    );
  }

  Widget _buildDiagramSection(ThemeData theme) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Layer toggles + expand button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: LayerToggleBar(
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

          // Diagram canvas
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: DiagramCanvas(
                diagram: _currentQuestion.diagram,
                highlightedIds: _highlightedIds,
                showValues: _showValues,
                showHints: _showHints,
                showLabels: _showLabels,
                onElementTap: _onElementTap,
              ),
            ),
          ),

          // Insight panel (shows when element with insight is tapped)
          if (_lastTappedElement != null &&
              _lastTappedElement!.insight != null)
            InsightPanel(
              element: _lastTappedElement!,
              onDismiss: () => setState(() => _lastTappedElement = null),
            ),

          // Highlighted elements info
          if (_highlightedIds.isNotEmpty && _lastTappedElement?.insight == null)
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
