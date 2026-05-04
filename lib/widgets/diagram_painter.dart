import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/diagram_element.dart';

class DiagramPainter extends CustomPainter {
  final List<DiagramElement> elements;
  final Set<String> highlightedIds;
  final bool showValues;
  final bool showHints;
  final bool showLabels;
  final Color backgroundColor;

  DiagramPainter({
    required this.elements,
    this.highlightedIds = const {},
    this.showValues = true,
    this.showHints = false,
    this.showLabels = true,
    this.backgroundColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final element in elements) {
      if (!_shouldShow(element)) continue;

      final isHighlighted = highlightedIds.contains(element.id);
      switch (element.type) {
        case ElementType.point:
          _drawPoint(canvas, element, isHighlighted);
        case ElementType.line:
          _drawLine(canvas, element, isHighlighted);
        case ElementType.circle:
          _drawCircle(canvas, element, isHighlighted);
        case ElementType.arc:
          _drawArc(canvas, element, isHighlighted);
        case ElementType.polygon:
          _drawPolygon(canvas, element, isHighlighted);
        case ElementType.angle:
          _drawAngle(canvas, element, isHighlighted);
        case ElementType.label:
          _drawLabel(canvas, element, isHighlighted);
        case ElementType.vector:
          _drawVector(canvas, element, isHighlighted);
        case ElementType.region:
          _drawRegion(canvas, element, isHighlighted);
      }
    }
  }

  bool _shouldShow(DiagramElement element) {
    if (element.isValue && !showValues) return false;
    if (element.isHint && !showHints) return false;
    if (element.group == 'values' && !showValues) return false;
    if (element.group == 'hint' && !showHints) return false;
    return true;
  }

  void _drawPoint(Canvas canvas, DiagramElement el, bool highlighted) {
    final pos = el.position;
    if (pos == null) return;

    final paint = Paint()
      ..color = highlighted ? Colors.orange : Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pos, highlighted ? 6 : 4, paint);

    final text = el.text;
    if (text != null && showLabels) {
      _drawText(
        canvas,
        text,
        Offset(pos.dx + 8, pos.dy - 16),
        highlighted ? Colors.orange.shade800 : Colors.black87,
        fontSize: 14,
        fontWeight: highlighted ? FontWeight.bold : FontWeight.w600,
      );
    }
  }

  void _drawLine(Canvas canvas, DiagramElement el, bool highlighted) {
    final from = el.from;
    final to = el.to;
    if (from == null || to == null) return;

    final isDashed = el.properties['dashed'] == true;
    final paint = Paint()
      ..color = highlighted ? Colors.blue.shade600 : Colors.black87
      ..strokeWidth = highlighted ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;

    if (isDashed) {
      _drawDashedLine(canvas, from, to, paint);
    } else {
      canvas.drawLine(from, to, paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final length = math.sqrt(dx * dx + dy * dy);
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

  void _drawCircle(Canvas canvas, DiagramElement el, bool highlighted) {
    final pos = el.position;
    final radius = el.radius;
    if (pos == null || radius == null) return;

    final paint = Paint()
      ..color = highlighted ? Colors.blue.shade400 : Colors.black87
      ..strokeWidth = highlighted ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(pos, radius, paint);
  }

  void _drawArc(Canvas canvas, DiagramElement el, bool highlighted) {
    final pos = el.position;
    final radius = el.radius ?? 20;
    if (pos == null) return;

    final startAngle = ((el.properties['startAngle'] as num?)?.toDouble() ?? 0) *
        math.pi /
        180;
    final sweepAngle = ((el.properties['sweepAngle'] as num?)?.toDouble() ?? 90) *
        math.pi /
        180;

    final paint = Paint()
      ..color = highlighted ? Colors.orange : Colors.black54
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  void _drawPolygon(Canvas canvas, DiagramElement el, bool highlighted) {
    final verts = el.vertices;
    if (verts.length < 3) return;

    final path = Path()..moveTo(verts[0].dx, verts[0].dy);
    for (var i = 1; i < verts.length; i++) {
      path.lineTo(verts[i].dx, verts[i].dy);
    }
    path.close();

    final paint = Paint()
      ..color = highlighted
          ? Colors.blue.shade100.withValues(alpha: 0.5)
          : Colors.grey.shade200.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    final strokePaint = Paint()
      ..color = highlighted ? Colors.blue.shade600 : Colors.black87
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);
  }

  void _drawAngle(Canvas canvas, DiagramElement el, bool highlighted) {
    final pos = el.position;
    if (pos == null) return;

    final paint = Paint()
      ..color = highlighted ? Colors.orange : Colors.blue.shade300
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: 15),
      -math.pi / 4,
      math.pi / 4,
      false,
      paint,
    );

    final text = el.text;
    if (text != null) {
      _drawText(
        canvas,
        text,
        Offset(pos.dx + 18, pos.dy - 25),
        highlighted ? Colors.orange.shade800 : Colors.blue.shade700,
        fontSize: 11,
      );
    }
  }

  void _drawLabel(Canvas canvas, DiagramElement el, bool highlighted) {
    final pos = el.position;
    final text = el.text;
    if (pos == null || text == null) return;

    Color color;
    if (highlighted) {
      color = Colors.orange.shade800;
    } else if (el.isHint) {
      color = Colors.green.shade700;
    } else if (el.isValue) {
      color = Colors.indigo.shade700;
    } else {
      color = Colors.black87;
    }

    _drawText(
      canvas,
      text,
      pos,
      color,
      fontSize: el.isValue ? 12 : 11,
      fontWeight: highlighted ? FontWeight.bold : FontWeight.w500,
    );
  }

  void _drawVector(Canvas canvas, DiagramElement el, bool highlighted) {
    final from = el.from;
    final to = el.to;
    if (from == null || to == null) return;

    final paint = Paint()
      ..color = highlighted ? Colors.red.shade600 : Colors.red.shade400
      ..strokeWidth = highlighted ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(from, to, paint);

    // Arrowhead
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final ux = dx / len;
    final uy = dy / len;
    const arrowSize = 10.0;

    final arrowPath = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - arrowSize * ux + arrowSize * 0.4 * uy,
        to.dy - arrowSize * uy - arrowSize * 0.4 * ux,
      )
      ..lineTo(
        to.dx - arrowSize * ux - arrowSize * 0.4 * uy,
        to.dy - arrowSize * uy + arrowSize * 0.4 * ux,
      )
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill,
    );
  }

  void _drawRegion(Canvas canvas, DiagramElement el, bool highlighted) {
    final verts = el.vertices;
    if (verts.length < 3) return;

    final path = Path()..moveTo(verts[0].dx, verts[0].dy);
    for (var i = 1; i < verts.length; i++) {
      path.lineTo(verts[i].dx, verts[i].dy);
    }
    path.close();

    final paint = Paint()
      ..color = highlighted
          ? Colors.amber.shade200.withValues(alpha: 0.5)
          : Colors.blue.shade50.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    Color color, {
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    )
      ..pushStyle(ui.TextStyle(color: color))
      ..addText(text);

    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 100));

    canvas.drawParagraph(paragraph, position);
  }

  @override
  bool shouldRepaint(covariant DiagramPainter oldDelegate) {
    return oldDelegate.highlightedIds != highlightedIds ||
        oldDelegate.showValues != showValues ||
        oldDelegate.showHints != showHints ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.elements != elements;
  }
}
