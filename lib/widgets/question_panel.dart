import 'package:flutter/material.dart';

import '../models/question_data.dart';

enum Confidence { low, medium, high }

class QuestionPanel extends StatefulWidget {
  final QuestionData question;
  final int? selectedIndex;
  final bool showAnswer;
  final ValueChanged<int> onOptionSelected;
  final VoidCallback onCheckAnswer;
  final int? elapsedSeconds;
  final Confidence? confidence;
  final ValueChanged<Confidence>? onConfidenceChanged;

  const QuestionPanel({
    super.key,
    required this.question,
    this.selectedIndex,
    required this.showAnswer,
    required this.onOptionSelected,
    required this.onCheckAnswer,
    this.elapsedSeconds,
    this.confidence,
    this.onConfidenceChanged,
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
                color: _timerResultColor.withOpacity(0.1),
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
            final isWrong = widget.showAnswer && isSelected && !isCorrect;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OptionTile(
                label: String.fromCharCode(65 + i),
                text: q.options[i],
                isSelected: isSelected,
                isCorrect: isCorrect,
                isWrong: isWrong,
                showAnswer: widget.showAnswer,
                onTap:
                    widget.showAnswer ? null : () => widget.onOptionSelected(i),
                index: i,
              ),
            );
          }),

          const SizedBox(height: 8),

          // Check answer button
          if (!widget.showAnswer && widget.selectedIndex != null) ...[
            // Confidence selector
            const SizedBox(height: 8),
            Text(
              'How confident are you?',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildConfidenceButton(
                    Confidence.low, 'Low', Colors.red.shade300),
                const SizedBox(width: 8),
                _buildConfidenceButton(
                    Confidence.medium, 'Medium', Colors.orange.shade300),
                const SizedBox(width: 8),
                _buildConfidenceButton(
                    Confidence.high, 'High', Colors.green.shade300),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    widget.confidence != null ? widget.onCheckAnswer : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Check Answer'),
              ),
            ),
          ],

          // Explanation (hidden by default, revealed on click)
          if (widget.showAnswer) ...[
            const SizedBox(height: 16),
            if (q.correctReason != null || q.explanation != null) ...[
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Why correct
                    if (q.correctReason != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 16, color: Colors.green.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  'Why correct:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              q.correctReason!,
                              style: TextStyle(
                                color: Colors.green.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Why wrong
                    if (widget.selectedIndex != null &&
                        q.whyWrongExplanations != null &&
                        q.whyWrongExplanations!
                            .containsKey(widget.selectedIndex)) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber,
                                    size: 16, color: Colors.red.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  'Why your answer is wrong:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              q.whyWrongExplanations![widget.selectedIndex]!,
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Common mistake
                    if (q.commonMistake != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                q.commonMistake!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Visual solution steps
                    if (q.solutionSteps.isNotEmpty) ...[
                      ExpansionTile(
                        title: Text(
                          'Visual Solution Steps',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children:
                                  List.generate(q.solutionSteps.length, (i) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${i + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          q.solutionSteps[i],
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
            ],
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
        color: color.withOpacity(0.12),
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

  Widget _buildConfidenceButton(Confidence level, String label, Color color) {
    final isSelected = widget.confidence == level;
    return Expanded(
      child: GestureDetector(
        onTap: widget.onConfidenceChanged != null
            ? () => widget.onConfidenceChanged!(level)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
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
      final isKey = line.trimLeft().startsWith('Key') ||
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

class _OptionTile extends StatefulWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool showAnswer;
  final VoidCallback? onTap;
  final int index;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.showAnswer,
    this.onTap,
    this.index = 0,
  });

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _bounceController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(_OptionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.isCorrect || widget.isWrong) &&
        !oldWidget.showAnswer &&
        widget.showAnswer) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;
    Color labelBg;

    if (widget.isCorrect) {
      borderColor = Colors.green.shade400;
      bgColor = Colors.green.shade50;
      labelBg = Colors.green;
    } else if (widget.isWrong) {
      borderColor = Colors.red.shade400;
      bgColor = Colors.red.shade50;
      labelBg = Colors.red;
    } else if (widget.isSelected) {
      borderColor = Colors.blue.shade400;
      bgColor = Colors.blue.shade50;
      labelBg = Colors.blue;
    } else {
      borderColor = Colors.grey.shade300;
      bgColor = Colors.white;
      labelBg = Colors.grey.shade600;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _bounceController]),
      builder: (context, child) {
        final bounceOffset =
            (widget.isCorrect || widget.isWrong) && widget.showAnswer
                ? _bounceAnimation.value
                : 0.0;
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value + bounceOffset),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: labelBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.label,
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
                    widget.text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (widget.isCorrect)
                  const Icon(Icons.check_circle, color: Colors.green, size: 22),
                if (widget.isWrong)
                  const Icon(Icons.cancel, color: Colors.red, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
