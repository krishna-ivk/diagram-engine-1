import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum DrawingTool { none, line, point, extend }

class DrawnElement {
  final DrawingTool tool;
  final List<Offset> points;

  const DrawnElement({required this.tool, required this.points});
}

class DrawingOverlay extends StatefulWidget {
  final bool enabled;
  final DrawingTool activeTool;
  final List<DrawnElement> drawnElements;
  final ValueChanged<List<DrawnElement>> onElementsChanged;

  const DrawingOverlay({
    super.key,
    required this.enabled,
    required this.activeTool,
    required this.drawnElements,
    required this.onElementsChanged,
  });

  @override
  State<DrawingOverlay> createState() => _DrawingOverlayState();
}

class _DrawingOverlayState extends State<DrawingOverlay> {
  Offset? _startPoint;
  Offset? _currentPoint;

  void _handlePanStart(DragStartDetails details) {
    if (!widget.enabled || widget.activeTool == DrawingTool.none) return;
    setState(() {
      _startPoint = details.localPosition;
      _currentPoint = details.localPosition;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.enabled || widget.activeTool == DrawingTool.none) return;
    setState(() {
      _currentPoint = details.localPosition;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!widget.enabled || widget.activeTool == DrawingTool.none) return;
    if (_startPoint == null || _currentPoint == null) return;

    final newElement = DrawnElement(
      tool: widget.activeTool,
      points: [_startPoint!, _currentPoint!],
    );

    widget.onElementsChanged([...widget.drawnElements, newElement]);
    setState(() {
      _startPoint = null;
      _currentPoint = null;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.activeTool != DrawingTool.point) return;

    final newElement = DrawnElement(
      tool: DrawingTool.point,
      points: [details.localPosition],
    );

    widget.onElementsChanged([...widget.drawnElements, newElement]);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return CustomPaint(
        painter: _DrawnElementsPainter(elements: widget.drawnElements),
        size: Size.infinite,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onTapDown: _handleTapDown,
      child: CustomPaint(
        painter: _DrawnElementsPainter(
          elements: widget.drawnElements,
          activeStart: _startPoint,
          activeCurrent: _currentPoint,
          activeTool: widget.activeTool,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _DrawnElementsPainter extends CustomPainter {
  final List<DrawnElement> elements;
  final Offset? activeStart;
  final Offset? activeCurrent;
  final DrawingTool? activeTool;

  _DrawnElementsPainter({
    required this.elements,
    this.activeStart,
    this.activeCurrent,
    this.activeTool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.blue.shade600
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.red.shade600
      ..style = PaintingStyle.fill;

    final dashPaint = Paint()
      ..color = Colors.blue.shade400
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final el in elements) {
      switch (el.tool) {
        case DrawingTool.line:
        case DrawingTool.extend:
          if (el.points.length >= 2) {
            canvas.drawLine(el.points[0], el.points[1], linePaint);
          }
        case DrawingTool.point:
          if (el.points.isNotEmpty) {
            canvas.drawCircle(el.points[0], 5, pointPaint);
            // Label
            final builder = ui.ParagraphBuilder(
              ui.ParagraphStyle(fontSize: 10, fontWeight: FontWeight.bold),
            )
              ..pushStyle(ui.TextStyle(color: Colors.red.shade800))
              ..addText('P${elements.indexOf(el) + 1}');
            final paragraph = builder.build()
              ..layout(const ui.ParagraphConstraints(width: 40));
            canvas.drawParagraph(
              paragraph,
              Offset(el.points[0].dx + 8, el.points[0].dy - 14),
            );
          }
        case DrawingTool.none:
          break;
      }
    }

    // Draw active stroke preview
    if (activeStart != null && activeCurrent != null) {
      if (activeTool == DrawingTool.line || activeTool == DrawingTool.extend) {
        _drawDashedLine(canvas, activeStart!, activeCurrent!, dashPaint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final length = (Offset(dx, dy)).distance;
    if (length == 0) return;
    final ux = dx / length;
    final uy = dy / length;

    var d = 0.0;
    while (d < length) {
      final start = Offset(from.dx + ux * d, from.dy + uy * d);
      d += dashWidth;
      if (d > length) d = length;
      final end = Offset(from.dx + ux * d, from.dy + uy * d);
      canvas.drawLine(start, end, paint);
      d += dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DrawnElementsPainter oldDelegate) {
    return oldDelegate.elements != elements ||
        oldDelegate.activeStart != activeStart ||
        oldDelegate.activeCurrent != activeCurrent;
  }
}

class DrawingToolbar extends StatelessWidget {
  final DrawingTool activeTool;
  final bool drawingEnabled;
  final VoidCallback onToggleDrawing;
  final ValueChanged<DrawingTool> onToolSelected;
  final VoidCallback onUndo;
  final VoidCallback onClearAll;

  const DrawingToolbar({
    super.key,
    required this.activeTool,
    required this.drawingEnabled,
    required this.onToggleDrawing,
    required this.onToolSelected,
    required this.onUndo,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: drawingEnabled
            ? Colors.blue.shade50
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: drawingEnabled
              ? Colors.blue.shade300
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolButton(
            icon: Icons.edit,
            label: 'Draw',
            isActive: drawingEnabled,
            onTap: onToggleDrawing,
          ),
          if (drawingEnabled) ...[
            const SizedBox(width: 4),
            _ToolButton(
              icon: Icons.timeline,
              label: 'Line',
              isActive: activeTool == DrawingTool.line,
              onTap: () => onToolSelected(DrawingTool.line),
            ),
            const SizedBox(width: 4),
            _ToolButton(
              icon: Icons.circle,
              label: 'Point',
              isActive: activeTool == DrawingTool.point,
              onTap: () => onToolSelected(DrawingTool.point),
            ),
            const SizedBox(width: 4),
            _ToolButton(
              icon: Icons.open_in_full,
              label: 'Extend',
              isActive: activeTool == DrawingTool.extend,
              onTap: () => onToolSelected(DrawingTool.extend),
            ),
            const SizedBox(width: 8),
            _ToolButton(
              icon: Icons.undo,
              label: 'Undo',
              isActive: false,
              onTap: onUndo,
            ),
            const SizedBox(width: 4),
            _ToolButton(
              icon: Icons.delete_outline,
              label: 'Clear',
              isActive: false,
              onTap: onClearAll,
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: isActive ? Colors.blue.shade100 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 18,
              color: isActive ? Colors.blue.shade700 : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
