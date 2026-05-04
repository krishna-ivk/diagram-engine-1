import 'dart:ui';

enum ElementType { point, line, arc, circle, polygon, angle, label, vector, region }

class DiagramElement {
  final String id;
  final ElementType type;
  final Map<String, dynamic> properties;
  final bool interactive;
  final String? group;

  const DiagramElement({
    required this.id,
    required this.type,
    required this.properties,
    this.interactive = true,
    this.group,
  });

  Offset? get position {
    final x = properties['x'];
    final y = properties['y'];
    if (x != null && y != null) {
      return Offset((x as num).toDouble(), (y as num).toDouble());
    }
    return null;
  }

  Offset? get from {
    final fx = properties['fromX'];
    final fy = properties['fromY'];
    if (fx != null && fy != null) {
      return Offset((fx as num).toDouble(), (fy as num).toDouble());
    }
    return null;
  }

  Offset? get to {
    final tx = properties['toX'];
    final ty = properties['toY'];
    if (tx != null && ty != null) {
      return Offset((tx as num).toDouble(), (ty as num).toDouble());
    }
    return null;
  }

  String? get text => properties['text'] as String?;

  double? get radius {
    final r = properties['radius'];
    return r != null ? (r as num).toDouble() : null;
  }

  List<Offset> get vertices {
    final verts = properties['vertices'] as List<dynamic>?;
    if (verts == null) return [];
    return verts
        .cast<Map<String, dynamic>>()
        .map((v) => Offset(
              (v['x'] as num).toDouble(),
              (v['y'] as num).toDouble(),
            ))
        .toList();
  }

  bool get isValue => properties['isValue'] == true;
  bool get isHint => properties['isHint'] == true;

  factory DiagramElement.fromJson(Map<String, dynamic> json) {
    return DiagramElement(
      id: json['id'] as String,
      type: ElementType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      properties: Map<String, dynamic>.from(json['properties'] as Map),
      interactive: json['interactive'] as bool? ?? true,
      group: json['group'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'properties': properties,
        'interactive': interactive,
        if (group != null) 'group': group,
      };
}
