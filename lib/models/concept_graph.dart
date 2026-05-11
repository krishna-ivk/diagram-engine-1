class ConceptNode {
  final String id;
  final String name;
  final String subject;
  final String chapter;
  final List<String> prerequisites;
  final List<String> relatedConcepts;
  final int questionCount;
  final double averageDifficulty;
  final List<String> commonMistakes;

  const ConceptNode({
    required this.id,
    required this.name,
    required this.subject,
    required this.chapter,
    this.prerequisites = const [],
    this.relatedConcepts = const [],
    this.questionCount = 0,
    this.averageDifficulty = 0.5,
    this.commonMistakes = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subject': subject,
        'chapter': chapter,
        'prerequisites': prerequisites,
        'relatedConcepts': relatedConcepts,
        'questionCount': questionCount,
        'averageDifficulty': averageDifficulty,
        'commonMistakes': commonMistakes,
      };

  factory ConceptNode.fromJson(Map<String, dynamic> json) => ConceptNode(
        id: json['id'] as String,
        name: json['name'] as String,
        subject: json['subject'] as String,
        chapter: json['chapter'] as String,
        prerequisites: List<String>.from(json['prerequisites'] ?? []),
        relatedConcepts: List<String>.from(json['relatedConcepts'] ?? []),
        questionCount: json['questionCount'] as int? ?? 0,
        averageDifficulty: (json['averageDifficulty'] as num?)?.toDouble() ?? 0.5,
        commonMistakes: List<String>.from(json['commonMistakes'] ?? []),
      );
}

class ConceptGraph {
  final Map<String, ConceptNode> nodes;

  const ConceptGraph({this.nodes = const {}});

  ConceptNode? getConcept(String id) => nodes[id];

  List<ConceptNode> getPrerequisites(String conceptId) {
    final concept = nodes[conceptId];
    if (concept == null) return [];
    return concept.prerequisites
        .map((id) => nodes[id])
        .whereType<ConceptNode>()
        .toList();
  }

  List<ConceptNode> getRelatedConcepts(String conceptId) {
    final concept = nodes[conceptId];
    if (concept == null) return [];
    return concept.relatedConcepts
        .map((id) => nodes[id])
        .whereType<ConceptNode>()
        .toList();
  }

  List<ConceptNode> getConceptsForTopic(String topic) {
    return nodes.values.where((c) => c.name == topic).toList();
  }

  List<ConceptNode> getConceptsForChapter(String chapter) {
    return nodes.values.where((c) => c.chapter == chapter).toList();
  }

  List<ConceptNode> getConceptsForSubject(String subject) {
    return nodes.values.where((c) => c.subject == subject).toList();
  }

  List<String> getLearningPath(String targetConcept) {
    final visited = <String>{};
    final path = <String>[];

    void dfs(String conceptId) {
      if (visited.contains(conceptId)) return;
      visited.add(conceptId);

      final concept = nodes[conceptId];
      if (concept == null) return;

      for (final prereq in concept.prerequisites) {
        dfs(prereq);
      }

      path.add(conceptId);
    }

    dfs(targetConcept);
    return path;
  }

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory ConceptGraph.fromJson(Map<String, dynamic> json) {
    final nodesMap = <String, ConceptNode>{};
    final nodes = json['nodes'] as Map<String, dynamic>? ?? {};
    for (final entry in nodes.entries) {
      nodesMap[entry.key] = ConceptNode.fromJson(entry.value as Map<String, dynamic>);
    }
    return ConceptGraph(nodes: nodesMap);
  }
}

final defaultConceptGraph = ConceptGraph(
  nodes: {
    'circle_basic': const ConceptNode(
      id: 'circle_basic',
      name: 'Circle - Basics',
      subject: 'Mathematics',
      chapter: 'Coordinate Geometry',
      prerequisites: [],
      relatedConcepts: ['circle_equation', 'tangent_line'],
      commonMistakes: ['Confuses radius with diameter', 'Forgets pi'],
    ),
    'circle_equation': const ConceptNode(
      id: 'circle_equation',
      name: 'Circle Equation',
      subject: 'Mathematics',
      chapter: 'Coordinate Geometry',
      prerequisites: ['circle_basic', 'distance_formula'],
      relatedConcepts: ['circle_basic', 'tangent_line', 'circle_center'],
      commonMistakes: ['Incorrect center form', 'Wrong sign in equation'],
    ),
    'tangent_line': const ConceptNode(
      id: 'tangent_line',
      name: 'Tangent to Circle',
      subject: 'Mathematics',
      chapter: 'Coordinate Geometry',
      prerequisites: ['circle_equation', 'slope_line'],
      relatedConcepts: ['circle_equation', 'normal_line'],
      commonMistakes: ['Wrong tangent condition', 'Calculation errors'],
    ),
    'parabola': const ConceptNode(
      id: 'parabola',
      name: 'Parabola',
      subject: 'Mathematics',
      chapter: 'Conic Sections',
      prerequisites: ['quadratic_equation'],
      relatedConcepts: ['ellipse', 'hyperbola'],
      commonMistakes: ['Confuses vertex with focus', 'Wrong parameter'],
    ),
    'quadratic_equation': const ConceptNode(
      id: 'quadratic_equation',
      name: 'Quadratic Equations',
      subject: 'Mathematics',
      chapter: 'Algebra',
      prerequisites: ['polynomial_basics'],
      relatedConcepts: ['parabola', 'quadratic_formula'],
      commonMistakes: ['Sign errors in formula', 'Discriminant mistakes'],
    ),
    'derivative': const ConceptNode(
      id: 'derivative',
      name: 'Derivatives',
      subject: 'Mathematics',
      chapter: 'Calculus',
      prerequisites: ['limit_concept', 'function_basics'],
      relatedConcepts: ['differentiation_rules', 'tangent_slope'],
      commonMistakes: ['Chain rule errors', 'Power rule mistakes'],
    ),
    'integral': const ConceptNode(
      id: 'integral',
      name: 'Integrals',
      subject: 'Mathematics',
      chapter: 'Calculus',
      prerequisites: ['derivative', 'antiderivative'],
      relatedConcepts: ['integration_methods', 'area_under_curve'],
      commonMistakes: ['Forgets +C', 'Integration by parts errors'],
    ),
    'limit_concept': const ConceptNode(
      id: 'limit_concept',
      name: 'Limits',
      subject: 'Mathematics',
      chapter: 'Calculus',
      prerequisites: ['function_basics'],
      relatedConcepts: ['derivative', 'continuity'],
      commonMistakes: ['Direct substitution without checking', 'Infinity confusion'],
    ),
    'trig_identities': const ConceptNode(
      id: 'trig_identities',
      name: 'Trigonometric Identities',
      subject: 'Mathematics',
      chapter: 'Trigonometry',
      prerequisites: ['trig_basics'],
      relatedConcepts: ['trig_equations', 'inverse_trig'],
      commonMistakes: ['Sign errors', 'Wrong identity application'],
    ),
    'vector': const ConceptNode(
      id: 'vector',
      name: 'Vectors',
      subject: 'Mathematics',
      chapter: 'Algebra',
      prerequisites: ['coordinate_geometry'],
      relatedConcepts: ['vector_product', 'vector_addition'],
      commonMistakes: ['Direction confusion', 'Magnitude calculation'],
    ),
    'matrices': const ConceptNode(
      id: 'matrices',
      name: 'Matrices',
      subject: 'Mathematics',
      chapter: 'Algebra',
      prerequisites: ['determinants'],
      relatedConcepts: ['matrix_operations', 'eigenvalues'],
      commonMistakes: ['Order confusion', 'Multiplication errors'],
    ),
    'complex_numbers': const ConceptNode(
      id: 'complex_numbers',
      name: 'Complex Numbers',
      subject: 'Mathematics',
      chapter: 'Algebra',
      prerequisites: ['quadratic_equation'],
      relatedConcepts: ['complex_operations', 'argand_diagram'],
      commonMistakes: ['i² = -1 confusion', 'Modulus calculation'],
    ),
    // Physics concepts
    'newton_laws': const ConceptNode(
      id: 'newton_laws',
      name: "Newton's Laws",
      subject: 'Physics',
      chapter: 'Mechanics',
      prerequisites: ['force_concept'],
      relatedConcepts: ['friction', 'circular_motion'],
      commonMistakes: ['Free body diagram errors', 'Direction mistakes'],
    ),
    'electric_circuit': const ConceptNode(
      id: 'electric_circuit',
      name: 'Electric Circuits',
      subject: 'Physics',
      chapter: 'Current Electricity',
      prerequisites: ['ohms_law'],
      relatedConcepts: ['kirchhoff_laws', 'circuit_analysis'],
      commonMistakes: ['Series/parallel confusion', 'Sign errors in emf'],
    ),
    'wave_optics': const ConceptNode(
      id: 'wave_optics',
      name: 'Wave Optics',
      subject: 'Physics',
      chapter: 'Optics',
      prerequisites: ['wave_basics', 'reflection_refraction'],
      relatedConcepts: ['interference', 'diffraction'],
      commonMistakes: ['Path difference confusion', 'Phase errors'],
    ),
  },
);