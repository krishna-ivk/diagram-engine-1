import 'package:flutter/material.dart';

import '../models/question_data.dart';
import 'diagram_canvas.dart';
import 'layer_toggle.dart';

class FullscreenDiagram extends StatefulWidget {
  final QuestionData question;
  final Set<String> highlightedIds;
  final bool showValues;
  final bool showHints;
  final bool showLabels;
  final ValueChanged<String> onElementTap;
  final ValueChanged<bool> onValuesChanged;
  final ValueChanged<bool> onHintsChanged;
  final ValueChanged<bool> onLabelsChanged;

  const FullscreenDiagram({
    super.key,
    required this.question,
    required this.highlightedIds,
    required this.showValues,
    required this.showHints,
    required this.showLabels,
    required this.onElementTap,
    required this.onValuesChanged,
    required this.onHintsChanged,
    required this.onLabelsChanged,
  });

  @override
  State<FullscreenDiagram> createState() => _FullscreenDiagramState();
}

class _FullscreenDiagramState extends State<FullscreenDiagram> {
  bool _showQuestionOverlay = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Full diagram
            Positioned.fill(
              child: DiagramCanvas(
                diagram: widget.question.diagram,
                highlightedIds: widget.highlightedIds,
                showValues: widget.showValues,
                showHints: widget.showHints,
                showLabels: widget.showLabels,
                onElementTap: widget.onElementTap,
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.question.diagram.title ?? 'Diagram',
                        style: theme.textTheme.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showQuestionOverlay
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () => _showQuestionOverlay = !_showQuestionOverlay,
                      ),
                      tooltip: 'Toggle question overlay',
                    ),
                  ],
                ),
              ),
            ),

            // Layer toggles
            Positioned(
              top: 52,
              left: 0,
              right: 0,
              child: Center(
                child: LayerToggleBar(
                  showValues: widget.showValues,
                  showHints: widget.showHints,
                  showLabels: widget.showLabels,
                  onValuesChanged: widget.onValuesChanged,
                  onHintsChanged: widget.onHintsChanged,
                  onLabelsChanged: widget.onLabelsChanged,
                ),
              ),
            ),

            // Floating question overlay (bottom sheet style)
            if (_showQuestionOverlay)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.question.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
