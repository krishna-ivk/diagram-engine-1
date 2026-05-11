import 'package:flutter/material.dart';

import '../models/diagram_data.dart';
import '../models/diagram_element.dart';
import 'diagram_painter.dart';

class DiagramCanvas extends StatefulWidget {
  final DiagramData diagram;
  final bool showValues;
  final bool showHints;
  final bool showLabels;
  final ValueChanged<String>? onElementTap;
  final Set<String> highlightedIds;

  const DiagramCanvas({
    super.key,
    required this.diagram,
    this.showValues = true,
    this.showHints = false,
    this.showLabels = true,
    this.onElementTap,
    this.highlightedIds = const {},
  });

  @override
  State<DiagramCanvas> createState() => _DiagramCanvasState();
}

class _DiagramCanvasState extends State<DiagramCanvas>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController =
      TransformationController();
  late final AnimationController _pulseController;
  late final AnimationController _drawController;
  bool _hasAnimatedDrawing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _drawController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(DiagramCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightedIds.isNotEmpty &&
        widget.highlightedIds != oldWidget.highlightedIds) {
      _pulseController.forward(from: 0.0);
    }
    if (!_hasAnimatedDrawing && widget.diagram.elements.isNotEmpty) {
      _hasAnimatedDrawing = true;
      _drawController.forward();
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    _pulseController.dispose();
    _drawController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onElementTap == null) return;

    final matrix = _transformController.value;
    final inverse = Matrix4.inverted(matrix);
    final localPoint = MatrixUtils.transformPoint(
      inverse,
      details.localPosition,
    );

    const hitRadius = 20.0;
    for (final element in widget.diagram.elements.reversed) {
      if (!element.interactive) continue;
      if (_hitTest(element, localPoint, hitRadius)) {
        widget.onElementTap!(element.id);
        return;
      }
    }
  }

  bool _hitTest(DiagramElement element, Offset point, double radius) {
    switch (element.type) {
      case ElementType.point:
        final pos = element.position;
        if (pos == null) return false;
        return (pos - point).distance <= radius;

      case ElementType.label:
      case ElementType.angle:
        final pos = element.position;
        if (pos == null) return false;
        return (pos - point).distance <= radius * 1.5;

      case ElementType.line:
      case ElementType.vector:
        final from = element.from;
        final to = element.to;
        if (from == null || to == null) return false;
        return _distanceToLine(point, from, to) <= radius;

      case ElementType.circle:
        final pos = element.position;
        final r = element.radius;
        if (pos == null || r == null) return false;
        final dist = (pos - point).distance;
        return (dist - r).abs() <= radius;

      case ElementType.polygon:
      case ElementType.region:
        final verts = element.vertices;
        if (verts.length < 3) return false;
        return _isPointInPolygon(point, verts);

      case ElementType.arc:
        final pos = element.position;
        if (pos == null) return false;
        return (pos - point).distance <= radius * 2;
    }
  }

  double _distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return (point - lineStart).distance;

    var t = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) /
        lenSq;
    t = t.clamp(0.0, 1.0);

    final projection = Offset(
      lineStart.dx + t * dx,
      lineStart.dy + t * dy,
    );
    return (point - projection).distance;
  }

  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
          point.dx <
              (polygon[j].dx - polygon[i].dx) *
                      (point.dy - polygon[i].dy) /
                      (polygon[j].dy - polygon[i].dy) +
                  polygon[i].dx) {
        inside = !inside;
      }
    }
    return inside;
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTapDown: _handleTapDown,
          child: InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.5,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(40),
            child: Center(
              child: AspectRatio(
                aspectRatio: widget.diagram.width / widget.diagram.height,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulseController, _drawController]),
                  builder: (context, _) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return CustomPaint(
                      painter: DiagramPainter(
                        elements: widget.diagram.elements,
                        highlightedIds: widget.highlightedIds,
                        showValues: widget.showValues,
                        showHints: widget.showHints,
                        showLabels: widget.showLabels,
                        pulseValue: _pulseController.value,
                        isDarkMode: isDark,
                        drawProgress: _drawController.value,
                        animateDrawing: true,
                      ),
                      size: Size(
                          widget.diagram.width, widget.diagram.height),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        // Reset zoom button
        Positioned(
          right: 8,
          bottom: 8,
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _resetZoom,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.fit_screen, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
