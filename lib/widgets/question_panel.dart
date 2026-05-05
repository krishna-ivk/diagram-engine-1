import 'package:flutter/material.dart';

import '../models/question_data.dart';

class QuestionPanel extends StatefulWidget {
  final QuestionData question;
  final int? selectedIndex;
  final bool showAnswer;
  final ValueChanged<int> onOptionSelected;
  final VoidCallback onCheckAnswer;
  final int? elapsedSeconds;

  const QuestionPanel({
    super.key,
    required this.question,
    this.selectedIndex,
    required this.showAnswer,
    required this.onOptionSelected,
    required this.onCheckAnswer,
    this.elapsedSeconds,
  });

  @override
  State<QuestionPanel> createState() => _QuestionPanelState();
}

class _QuestionPanelState extends State<QuestionPanel> {
  bool _explanationExpanded = false;

  @override
  void didUpdateWidget(QuestionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _explanationExpanded = false;
    }
  }

  String _difficultyLabel(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  Color _difficultyColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.red;
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = widget.question;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject / topic / difficulty chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildChip(q.subject, theme.colorScheme.primary),
              _buildChip(q.topic, theme.colorScheme.secondary),
              _buildChip(
                _difficultyLabel(q.difficulty),
                _difficultyColor(q.difficulty),
              ),
              if (q.frequentlyAsked)
                _buildChip('Frequently Asked', Colors.purple),
              if (q.highWeightTopic)
                _buildChip('High Weight', Colors.red.shade700),
            ],
          ),

          // Core concept + time estimate row
          if (q.coreConcept != null || q.estimatedSeconds != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (q.coreConcept != null) ...[
                  Icon(Icons.lightbulb_outline,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      q.coreConcept!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                if (q.coreConcept != null && q.estimatedSeconds != null)
                  const SizedBox(width: 12),
                if (q.estimatedSeconds != null) ...[
                  Icon(Icons.timer_outlined,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '~${q.estimatedSeconds}s',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],

          // Timer display
          if (widget.elapsedSeconds != null && !widget.showAnswer) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: _timerColor),
                const SizedBox(width: 4),
                Text(
                  _formatTime(widget.elapsedSeconds!),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    color: _timerColor,
                  ),
                ),
                if (q.estimatedSeconds != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '/ ${_formatTime(q.estimatedSeconds!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ],

          // Time result after answering
          if (widget.showAnswer && widget.elapsedSeconds != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _timerResultColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: 14, color: _timerResultColor),
                  const SizedBox(width: 4),
                  Text(
                    'Solved in ${_formatTime(widget.elapsedSeconds!)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _timerResultColor,
                    ),
                  ),
                  if (q.estimatedSeconds != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      widget.elapsedSeconds! <= q.estimatedSeconds!
                          ? '(within target)'
                          : '(over target)',
                      style: TextStyle(
                        fontSize: 11,
                        color: _timerResultColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Common mistake warning
          if (q.commonMistake != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber,
                      size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      q.commonMistake!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Question text
          Text(
            q.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Options
          ...List.generate(q.options.length, (i) {
            final isSelected = widget.selectedIndex == i;
            final isCorrect = widget.showAnswer && i == q.correctIndex;
            final isWrong =
                widget.showAnswer && isSelected && !isCorrect;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OptionTile(
                label: String.fromCharCode(65 + i),
                text: q.options[i],
                isSelected: isSelected,
                isCorrect: isCorrect,
                isWrong: isWrong,
                showAnswer: widget.showAnswer,
                onTap: widget.showAnswer
                    ? null
                    : () => widget.onOptionSelected(i),
              ),
            );
          }),

          const SizedBox(height: 8),

          // Check answer button
          if (!widget.showAnswer && widget.selectedIndex != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onCheckAnswer,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Check Answer'),
              ),
            ),

          // Explanation (hidden by default, revealed on click)
          if (widget.showAnswer && q.explanation != null) ...[
            const SizedBox(height: 16),
            if (!_explanationExpanded)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _explanationExpanded = true),
                  icon: const Icon(Icons.lightbulb_outline, size: 18),
                  label: const Text('Show Explanation'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade300),
                  ),
                ),
              )
            else
              _ExplanationCard(explanation: q.explanation!),
          ],
        ],
      ),
    );
  }

  Color get _timerColor {
    final elapsed = widget.elapsedSeconds ?? 0;
    final target = widget.question.estimatedSeconds;
    if (target == null) return Colors.grey.shade700;
    if (elapsed <= target * 0.7) return Colors.green.shade700;
    if (elapsed <= target) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  Color get _timerResultColor {
    final elapsed = widget.elapsedSeconds ?? 0;
    final target = widget.question.estimatedSeconds;
    if (target == null) return Colors.blue;
    return elapsed <= target ? Colors.green : Colors.red;
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatefulWidget {
  final String explanation;

  const _ExplanationCard({required this.explanation});

  @override
  State<_ExplanationCard> createState() => _ExplanationCardState();
}

class _ExplanationCardState extends State<_ExplanationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Widget> _buildExplanationBody() {
    final lines = widget.explanation.split('\n');
    final widgets = <Widget>[];
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final isStep = line.trimLeft().startsWith('Step ');
      final isKey =
          line.trimLeft().startsWith('Key') ||
          line.trimLeft().startsWith('Answer:') ||
          line.trimLeft().startsWith('Verification:');
      if (isStep) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.arrow_right, size: 16, color: Colors.blue.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  line.trim(),
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ));
      } else if (isKey) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    line.trim(),
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
      } else {
        widgets.add(Text(
          line.trim(),
          style: TextStyle(
            color: Colors.blue.shade900,
            fontSize: 13,
            height: 1.4,
          ),
        ));
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text(
                  'Explanation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._buildExplanationBody(),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool showAnswer;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.showAnswer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;
    Color labelBg;

    if (isCorrect) {
      borderColor = Colors.green.shade400;
      bgColor = Colors.green.shade50;
      labelBg = Colors.green;
    } else if (isWrong) {
      borderColor = Colors.red.shade400;
      bgColor = Colors.red.shade50;
      labelBg = Colors.red;
    } else if (isSelected) {
      borderColor = Colors.blue.shade400;
      bgColor = Colors.blue.shade50;
      labelBg = Colors.blue;
    } else {
      borderColor = Colors.grey.shade300;
      bgColor = Colors.white;
      labelBg = Colors.grey.shade600;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: labelBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isCorrect)
                const Icon(Icons.check_circle, color: Colors.green, size: 22),
              if (isWrong)
                const Icon(Icons.cancel, color: Colors.red, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
