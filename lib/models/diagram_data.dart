import 'diagram_element.dart';

enum DiagramType { geometry, physics, chemistry, graph, function, numberLine, matrix, combinatorial }

class DiagramData {
  final String id;
  final DiagramType type;
  final List<DiagramElement> elements;
  final double width;
  final double height;
  final String? title;

  const DiagramData({
    required this.id,
    required this.type,
    required this.elements,
    this.width = 300,
    this.height = 300,
    this.title,
  });

  factory DiagramData.fromJson(Map<String, dynamic> json) {
    return DiagramData(
      id: json['id'] as String,
      type: DiagramType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      elements: (json['elements'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(DiagramElement.fromJson)
          .toList(),
      width: (json['width'] as num?)?.toDouble() ?? 300,
      height: (json['height'] as num?)?.toDouble() ?? 300,
      title: json['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'elements': elements.map((e) => e.toJson()).toList(),
        'width': width,
        'height': height,
        if (title != null) 'title': title,
      };
}
