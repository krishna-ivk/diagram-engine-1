import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hero manipulative for Foundation Journey: interactive polygon
/// with side count selector and live central angle display.
class PolygonManipulative extends StatefulWidget {
  final int initialSides;
  final ValueChanged<int>? onSidesChanged;

  const PolygonManipulative({
    super.key,
    this.initialSides = 4,
    this.onSidesChanged,
  });

  @override
  State<PolygonManipulative> createState() => _PolygonManipulativeState();
}

class _PolygonManipulativeState extends State<PolygonManipulative>
    with SingleTickerProviderStateMixin {
  late int _sides;
  late AnimationController _animController;
  late Animation<double> _morphAnimation;
  int _previousSides = 4;

  static const _allowedSides = [3, 4, 5, 6, 8];

  @override
  void initState() {
    super.initState();
    _sides = widget.initialSides;
    _previousSides = _sides;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _morphAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );
    _animController.value = 1.0;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _setSides(int sides) {
    if (sides == _sides) return;
    setState(() {
      _previousSides = _sides;
      _sides = sides;
    });
    _animController.forward(from: 0);
    widget.onSidesChanged?.call(sides);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final centralAngle = 360.0 / _sides;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade50,
            Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Polygon Explorer',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a number to change the shape',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.indigo.shade400,
            ),
          ),
          const SizedBox(height: 16),

          // Polygon canvas
          AspectRatio(
            aspectRatio: 1,
            child: AnimatedBuilder(
              animation: _morphAnimation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _PolygonPainter(
                    sides: _sides,
                    previousSides: _previousSides,
                    morphProgress: _morphAnimation.value,
                    accentColor: _colorForSides(_sides),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Side selector buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _allowedSides.map((s) {
              final isSelected = s == _sides;
              final color = _colorForSides(s);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => _setSides(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$s',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoChip(
                      label: 'Shape',
                      value: _shapeName(_sides),
                      color: _colorForSides(_sides),
                    ),
                    _InfoChip(
                      label: 'Central Angle',
                      value: '${centralAngle.toStringAsFixed(centralAngle == centralAngle.roundToDouble() ? 0 : 1)}°',
                      color: Colors.orange.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '360° ÷ $_sides = ${centralAngle.toStringAsFixed(centralAngle == centralAngle.roundToDouble() ? 0 : 1)}°',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForSides(int sides) {
    switch (sides) {
      case 3:
        return Colors.red.shade400;
      case 4:
        return Colors.blue.shade500;
      case 5:
        return Colors.purple.shade400;
      case 6:
        return Colors.green.shade500;
      case 8:
        return Colors.orange.shade600;
      default:
        return Colors.indigo;
    }
  }

  String _shapeName(int sides) {
    switch (sides) {
      case 3:
        return 'Triangle';
      case 4:
        return 'Square';
      case 5:
        return 'Pentagon';
      case 6:
        return 'Hexagon';
      case 8:
        return 'Octagon';
      default:
        return '$sides-gon';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Custom painter that renders a regular polygon with center point,
/// radial lines forming central triangles, and an arc showing the
/// central angle.
class _PolygonPainter extends CustomPainter {
  final int sides;
  final int previousSides;
  final double morphProgress;
  final Color accentColor;

  _PolygonPainter({
    required this.sides,
    required this.previousSides,
    required this.morphProgress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    final effectiveSides = morphProgress >= 1.0 ? sides : _maxSides;

    // Interpolate vertex count for smooth morphing
    final targetVertices = _computeVertices(center, radius, sides);
    final fromVertices = _computeVertices(center, radius, previousSides);
    final vertices = _interpolateVertices(
      fromVertices,
      targetVertices,
      morphProgress,
    );

    // Draw filled polygon
    final fillPaint = Paint()
      ..color = accentColor.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    final path = Path()..addPolygon(vertices, true);
    canvas.drawPath(path, fillPaint);

    // Highlight one central triangle
    if (vertices.length >= 2) {
      final trianglePaint = Paint()
        ..color = accentColor.withOpacity(0.18)
        ..style = PaintingStyle.fill;
      final trianglePath = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(vertices[0].dx, vertices[0].dy)
        ..lineTo(vertices[1].dx, vertices[1].dy)
        ..close();
      canvas.drawPath(trianglePath, trianglePaint);
    }

    // Draw radial lines from center to each vertex
    final radialPaint = Paint()
      ..color = accentColor.withOpacity(0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final vertex in vertices) {
      canvas.drawLine(center, vertex, radialPaint);
    }

    // Draw polygon outline
    final outlinePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, outlinePaint);

    // Draw highlighted triangle outline
    if (vertices.length >= 2) {
      final triOutline = Paint()
        ..color = accentColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      final triPath = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(vertices[0].dx, vertices[0].dy)
        ..lineTo(vertices[1].dx, vertices[1].dy)
        ..close();
      canvas.drawPath(triPath, triOutline);
    }

    // Draw central angle arc
    if (morphProgress >= 0.5) {
      final centralAngle = 2 * math.pi / sides;
      // Start angle: from first vertex direction
      final startAngle = -math.pi / 2;
      final arcRadius = radius * 0.2;
      final arcPaint = Paint()
        ..color = Colors.orange.shade600
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      final arcRect = Rect.fromCircle(center: center, radius: arcRadius);
      canvas.drawArc(arcRect, startAngle, centralAngle, false, arcPaint);

      // Draw angle label
      final labelAngle = startAngle + centralAngle / 2;
      final labelOffset = Offset(
        center.dx + (arcRadius + 16) * math.cos(labelAngle),
        center.dy + (arcRadius + 16) * math.sin(labelAngle),
      );
      final degrees = 360.0 / sides;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${degrees.toStringAsFixed(degrees == degrees.roundToDouble() ? 0 : 1)}°',
          style: TextStyle(
            color: Colors.orange.shade800,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        labelOffset - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Draw center point
    final centerDot = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerDot);

    // Draw vertex dots
    final vertexDot = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    for (final vertex in vertices) {
      canvas.drawCircle(vertex, 3.5, vertexDot);
    }
  }

  int get _maxSides => math.max(sides, previousSides);

  List<Offset> _computeVertices(Offset center, double radius, int n) {
    final vertices = <Offset>[];
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / n);
      vertices.add(Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      ));
    }
    return vertices;
  }

  /// Interpolate between two polygon vertex sets by normalizing to the
  /// same count and lerping positions.
  List<Offset> _interpolateVertices(
    List<Offset> from,
    List<Offset> to,
    double t,
  ) {
    if (t >= 1.0) return to;
    if (t <= 0.0) return from;

    // Normalize both to same count by distributing extra points
    final maxCount = math.max(from.length, to.length);
    final normalizedFrom = _normalizeVertices(from, maxCount);
    final normalizedTo = _normalizeVertices(to, maxCount);

    return List.generate(maxCount, (i) {
      return Offset.lerp(normalizedFrom[i], normalizedTo[i], t)!;
    });
  }

  /// Distribute vertices evenly to reach targetCount by inserting
  /// midpoints along the polygon edges.
  List<Offset> _normalizeVertices(List<Offset> vertices, int targetCount) {
    if (vertices.length == targetCount) return vertices;
    if (vertices.isEmpty) return List.filled(targetCount, Offset.zero);

    final result = <Offset>[];
    final n = vertices.length;

    for (int i = 0; i < targetCount; i++) {
      final pos = i * n / targetCount;
      final idx = pos.floor() % n;
      final frac = pos - pos.floor();
      final next = (idx + 1) % n;
      result.add(Offset.lerp(vertices[idx], vertices[next], frac)!);
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _PolygonPainter oldDelegate) {
    return oldDelegate.sides != sides ||
        oldDelegate.previousSides != previousSides ||
        oldDelegate.morphProgress != morphProgress ||
        oldDelegate.accentColor != accentColor;
  }
}
