import 'package:flutter/material.dart';
import '../models/question_data.dart';

class DiagramManipulatives extends StatefulWidget {
  final QuestionData question;
  final List<String> availableManipulatives;
  final Function(String, dynamic) onManipulationChange;

  const DiagramManipulatives({
    super.key,
    required this.question,
    required this.availableManipulatives,
    required this.onManipulationChange,
  });

  @override
  State<DiagramManipulatives> createState() => _DiagramManipulativesState();
}

class _DiagramManipulativesState extends State<DiagramManipulatives> {
  final Map<String, dynamic> _manipulationValues = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interactive Tools',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildManipulatives(),
        ],
      ),
    );
  }

  Widget _buildManipulatives() {
    return Column(
      children: widget.availableManipulatives.map((manipulative) {
        switch (manipulative) {
          case 'sides_slider':
            return _SidesSlider(
              value: _manipulationValues['sides'] ?? 4,
              onChanged: (value) {
                _manipulationValues['sides'] = value;
                widget.onManipulationChange('sides', value);
              },
            );
          case 'polygon_sides_slider':
            return _PolygonSidesSlider(
              value: _manipulationValues['polygon_sides'] ?? 4,
              onChanged: (value) {
                _manipulationValues['polygon_sides'] = value;
                widget.onManipulationChange('polygon_sides', value);
              },
            );
          case 'angle_calculator':
            return _AngleCalculator(
              sides: _manipulationValues['polygon_sides'] ?? 4,
            );
          case 'hexagon_slider':
            return _HexagonSlider(
              value: _manipulationValues['hexagon_side'] ?? 6.0,
              onChanged: (value) {
                _manipulationValues['hexagon_side'] = value;
                widget.onManipulationChange('hexagon_side', value);
              },
            );
          case 'triangle_area_calculator':
            return _TriangleAreaCalculator(
              side: _manipulationValues['hexagon_side'] ?? 6.0,
            );
          case 'octagon_slider':
            return _OctagonSlider(
              value: _manipulationValues['octagon_radius'] ?? 5.0,
              onChanged: (value) {
                _manipulationValues['octagon_radius'] = value;
                widget.onManipulationChange('octagon_radius', value);
              },
            );
          case 'cosine_calculator':
            return _CosineCalculator(
              radius: _manipulationValues['octagon_radius'] ?? 5.0,
              sides: _manipulationValues['octagon_sides'] ?? 8,
            );
          case 'area_calculator':
            return _AreaCalculator(
              values: _manipulationValues,
            );
          case 'shape_subtraction':
            return _ShapeSubtraction();
          default:
            return const SizedBox.shrink();
        }
      }).toList(),
    );
  }
}

class _SidesSlider extends StatelessWidget {
  final int value;
  final Function(int) onChanged;

  const _SidesSlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shape Sides: $value',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: ['3', '4', '5', '6', '8'].asMap().entries.map((entry) {
            final sides = int.parse(entry.value);
            final isSelected = value == sides;
            
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(sides),
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected 
                          ? theme.colorScheme.onPrimary 
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _getShapeName(value),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _getShapeName(int sides) {
    switch (sides) {
      case 3: return 'Triangle';
      case 4: return 'Square/Rectangle';
      case 5: return 'Pentagon';
      case 6: return 'Hexagon';
      case 8: return 'Octagon';
      default: return 'Polygon';
    }
  }
}

class _PolygonSidesSlider extends StatelessWidget {
  final int value;
  final Function(int) onChanged;

  const _PolygonSidesSlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Regular Polygon: $value sides',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Slider(
          value: value.toDouble(),
          min: 3,
          max: 12,
          divisions: 9,
          label: '$value sides',
          onChanged: (newValue) => onChanged(newValue.round()),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Central Angle: ${(360 / value).toStringAsFixed(1)}°',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Interior Angle: ${((value - 2) * 180 / value).toStringAsFixed(1)}°',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _AngleCalculator extends StatelessWidget {
  final int sides;

  const _AngleCalculator({
    required this.sides,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final centralAngle = 360 / sides;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Angle Calculator',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '360° ÷ $sides = ${centralAngle.toStringAsFixed(1)}°',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Each central angle = ${centralAngle.toStringAsFixed(1)}°',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _HexagonSlider extends StatelessWidget {
  final double value;
  final Function(double) onChanged;

  const _HexagonSlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final centralAngle = 60.0; // Hexagon central angle
    final area = 0.5 * value * value * (3 * 0.866); // Using √3/2 ≈ 0.866
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hexagon Side Length: ${value.toStringAsFixed(1)} cm',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: 1,
          max: 10,
          divisions: 18,
          label: '${value.toStringAsFixed(1)} cm',
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Central Angle: $centralAngle°',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Central Triangle Area: ${area.toStringAsFixed(2)} cm²',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TriangleAreaCalculator extends StatelessWidget {
  final double side;

  const _TriangleAreaCalculator({
    required this.side,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final angle = 60.0; // Hexagon central triangle
    final radians = angle * 3.14159 / 180;
    final area = 0.5 * side * side * (radians == 0 ? 1 : radians.sin()); // sin(60°)
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Triangle Area Calculator',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Formula: (1/2) × r² × sin(θ)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          Text(
            '(1/2) × ${side.toStringAsFixed(1)}² × sin(60°)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          Text(
            '= ${area.toStringAsFixed(2)} cm²',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _OctagonSlider extends StatelessWidget {
  final double value;
  final Function(double) onChanged;

  const _OctagonSlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final centralAngle = 45.0; // Octagon central angle
    final radians = centralAngle * 3.14159 / 180;
    final sideLength = 2 * value * (radians == 0 ? 0.5 : radians.sin()); // 2r sin(θ/2)
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Octagon Radius: ${value.toStringAsFixed(1)} cm',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: 1,
          max: 10,
          divisions: 18,
          label: '${value.toStringAsFixed(1)} cm',
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Central Angle: $centralAngle°',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Side Length: ${sideLength.toStringAsFixed(2)} cm',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CosineCalculator extends StatelessWidget {
  final double radius;
  final int sides;

  const _CosineCalculator({
    required this.radius,
    required this.sides,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final centralAngle = 360.0 / sides;
    final radians = centralAngle * 3.14159 / 180;
    final sideSquared = 2 * radius * radius * (1 - (radians == 0 ? 1 : radians.cos()));
    final sideLength = sideSquared.sqrt();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cosine Law Calculator',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Formula: side² = r² + r² - 2r²cos(θ)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          Text(
            'side² = ${radius.toStringAsFixed(1)}² + ${radius.toStringAsFixed(1)}² - 2 × ${radius.toStringAsFixed(1)}² × cos($centralAngle°)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          Text(
            'side = ${sideLength.toStringAsFixed(2)} cm',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaCalculator extends StatelessWidget {
  final Map<String, dynamic> values;

  const _AreaCalculator({
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Area Calculator',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          if (values.containsKey('square_side')) ...[
            Text(
              'Square Area: ${(values['square_side'] * values['square_side']).toStringAsFixed(1)} cm²',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
          if (values.containsKey('hexagon_side')) ...[
            Text(
              'Hexagon Area: ${(2.598 * values['hexagon_side'] * values['hexagon_side']).toStringAsFixed(1)} cm²',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
          if (values.containsKey('octagon_radius')) ...[
            Text(
              'Octagon Area: ${(2.828 * values['octagon_radius'] * values['octagon_radius']).toStringAsFixed(1)} cm²',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShapeSubtraction extends StatelessWidget {
  const _ShapeSubtraction();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shape Subtraction Method',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Octagon Area = Square Area - 4 × Corner Triangle Area',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      'Square\n64 cm²',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.remove, color: theme.colorScheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '4 × Triangles\n32 cm²',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.add, color: theme.colorScheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      'Octagon\n32 cm²',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on double {
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double sqrt() => math.sqrt(this);
}

import 'dart:math' as math;