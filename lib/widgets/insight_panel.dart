import 'package:flutter/material.dart';

import '../models/diagram_element.dart';

class InsightPanel extends StatefulWidget {
  final DiagramElement element;
  final VoidCallback onDismiss;

  const InsightPanel({
    super.key,
    required this.element,
    required this.onDismiss,
  });

  @override
  State<InsightPanel> createState() => _InsightPanelState();
}

class _InsightPanelState extends State<InsightPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(InsightPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.id != widget.element.id) {
      _controller.reset();
      _controller.forward();
    }
  }

  IconData _iconForType(ElementType type) {
    switch (type) {
      case ElementType.point:
        return Icons.place;
      case ElementType.line:
      case ElementType.vector:
        return Icons.timeline;
      case ElementType.circle:
      case ElementType.arc:
        return Icons.circle_outlined;
      case ElementType.polygon:
      case ElementType.region:
        return Icons.change_history;
      case ElementType.angle:
        return Icons.architecture;
      case ElementType.label:
        return Icons.label_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final insight = widget.element.insight;
    if (insight == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.indigo.shade50,
              Colors.blue.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.indigo.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.indigo.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconForType(widget.element.type),
                size: 16,
                color: Colors.indigo.shade700,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.element.id,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.indigo.shade400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    insight,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.indigo.shade900,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: widget.onDismiss,
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.indigo.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
