import 'package:flutter/material.dart';

import '../models/question_data.dart';

class RevealPanel extends StatefulWidget {
  final List<RevealStep> steps;
  final ValueChanged<RevealStep> onStepRevealed;

  const RevealPanel({
    super.key,
    required this.steps,
    required this.onStepRevealed,
  });

  @override
  State<RevealPanel> createState() => _RevealPanelState();
}

class _RevealPanelState extends State<RevealPanel> {
  int _revealedCount = 0;

  void _revealNext() {
    if (_revealedCount < widget.steps.length) {
      setState(() {
        _revealedCount++;
      });
      widget.onStepRevealed(widget.steps[_revealedCount - 1]);
    }
  }

  @override
  void didUpdateWidget(RevealPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.steps != widget.steps) {
      _revealedCount = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    final allRevealed = _revealedCount >= widget.steps.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.assistant, size: 18, color: Colors.amber.shade700),
              const SizedBox(width: 6),
              Text(
                'Guide Me',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.amber.shade900,
                ),
              ),
              const Spacer(),
              Text(
                '$_revealedCount / ${widget.steps.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_revealedCount > 0) ...[
            const SizedBox(height: 10),
            ...List.generate(_revealedCount, (i) {
              return _RevealedStepTile(
                index: i + 1,
                step: widget.steps[i],
              );
            }),
          ],
          if (!allRevealed) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _revealNext,
                icon: const Icon(Icons.visibility, size: 16),
                label: Text(
                  _revealedCount == 0
                      ? 'Guide Me'
                      : 'Next Step',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber.shade800,
                  side: BorderSide(color: Colors.amber.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RevealedStepTile extends StatefulWidget {
  final int index;
  final RevealStep step;

  const _RevealedStepTile({required this.index, required this.step});

  @override
  State<_RevealedStepTile> createState() => _RevealedStepTileState();
}

class _RevealedStepTileState extends State<_RevealedStepTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.amber.shade200,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${widget.index}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.step.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber.shade900,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
