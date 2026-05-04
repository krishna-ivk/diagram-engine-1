import 'dart:math' as math;

import '../models/diagram_data.dart';
import '../models/diagram_element.dart';
import '../models/question_data.dart';

final List<QuestionData> mockQuestions = [
  // Q1: Regular octagon geometry
  QuestionData(
    id: 'geo_001',
    text:
        'ABCDEFGH is a regular octagon with center O. If the side length is 4 cm, find the area of triangle AOB.',
    diagram: DiagramData(
      id: 'diag_octagon',
      type: DiagramType.geometry,
      width: 300,
      height: 300,
      title: 'Regular Octagon ABCDEFGH',
      elements: [
        // Center point
        const DiagramElement(
          id: 'O',
          type: ElementType.point,
          properties: {'x': 150.0, 'y': 150.0, 'text': 'O'},
          insight: 'Center of the regular octagon. All radii OA, OB, ... OH are equal.',
        ),
        // Octagon vertices (regular octagon centered at 150,150, radius ~100)
        ..._octagonVertices(),
        // Octagon edges
        ..._octagonEdges(),
        // Triangle AOB highlight region
        const DiagramElement(
          id: 'triangle_AOB',
          type: ElementType.region,
          properties: {
            'vertices': [
              {'x': 193.0, 'y': 58.0},
              {'x': 107.0, 'y': 58.0},
              {'x': 150.0, 'y': 150.0},
            ],
            'isHint': true,
          },
          group: 'hint',
          insight: 'Triangle AOB is one of 8 congruent triangles formed by connecting center to vertices.',
        ),
        // Angle at O
        const DiagramElement(
          id: 'angle_AOB',
          type: ElementType.angle,
          properties: {
            'x': 150.0,
            'y': 150.0,
            'text': '45°',
            'isValue': true,
          },
          group: 'values',
          insight: 'Central angle = 360°/8 = 45°. This is key for computing the triangle area.',
        ),
        // Side length label
        const DiagramElement(
          id: 'side_AB',
          type: ElementType.label,
          properties: {
            'x': 150.0,
            'y': 45.0,
            'text': '4 cm',
            'isValue': true,
          },
          group: 'values',
        ),
      ],
    ),
    options: [
      '4√2 cm²',
      '8√2 cm²',
      '8(1 + √2) cm²',
      '4(1 + √2) cm²',
    ],
    correctIndex: 0,
    explanation:
        'In a regular octagon, the central angle for each triangle is 360°/8 = 45°. '
        'Area of triangle AOB = ½ × OA × OB × sin(45°). '
        'With side = 4, OA = OB = 4/(2sin(π/8)) ≈ 5.226. Area = ½ × 5.226² × sin(45°) ≈ 4√2 cm².',
    subject: 'Mathematics',
    topic: 'Geometry',
    revealSteps: [
      RevealStep(
        text: 'A regular octagon has 8 equal sides and 8 equal angles. The center O divides it into 8 congruent triangles.',
        highlightIds: ['O'],
      ),
      RevealStep(
        text: 'Central angle at O for each triangle = 360°/8 = 45°.',
        highlightIds: ['angle_AOB'],
      ),
      RevealStep(
        text: 'Use the formula: Area = ½ × OA × OB × sin(∠AOB). Find OA using the side length.',
        highlightIds: ['triangle_AOB'],
        showHints: true,
      ),
    ],
  ),

  // Q2: Triangle with angle bisector
  QuestionData(
    id: 'geo_002',
    text:
        'In triangle PQR, PS is the angle bisector of ∠P. If PQ = 8 cm, PR = 6 cm, and QR = 10 cm, find QS.',
    diagram: DiagramData(
      id: 'diag_triangle',
      type: DiagramType.geometry,
      width: 300,
      height: 280,
      title: 'Triangle PQR with Angle Bisector',
      elements: [
        const DiagramElement(
          id: 'P',
          type: ElementType.point,
          properties: {'x': 150.0, 'y': 30.0, 'text': 'P'},
          insight: 'Vertex P where the angle bisector originates. ∠QPR is bisected by PS.',
        ),
        const DiagramElement(
          id: 'Q',
          type: ElementType.point,
          properties: {'x': 40.0, 'y': 250.0, 'text': 'Q'},
          insight: 'QS is the unknown segment we need to find.',
        ),
        const DiagramElement(
          id: 'R',
          type: ElementType.point,
          properties: {'x': 270.0, 'y': 250.0, 'text': 'R'},
          insight: 'SR = QR - QS. Use the angle bisector theorem to find the ratio.',
        ),
        const DiagramElement(
          id: 'S',
          type: ElementType.point,
          properties: {'x': 152.0, 'y': 250.0, 'text': 'S'},
          insight: 'S divides QR in the ratio PQ:PR = 8:6 = 4:3 (Angle Bisector Theorem).',
        ),
        // Sides
        const DiagramElement(
          id: 'PQ',
          type: ElementType.line,
          properties: {
            'fromX': 150.0, 'fromY': 30.0,
            'toX': 40.0, 'toY': 250.0,
          },
        ),
        const DiagramElement(
          id: 'QR',
          type: ElementType.line,
          properties: {
            'fromX': 40.0, 'fromY': 250.0,
            'toX': 270.0, 'toY': 250.0,
          },
        ),
        const DiagramElement(
          id: 'PR',
          type: ElementType.line,
          properties: {
            'fromX': 150.0, 'fromY': 30.0,
            'toX': 270.0, 'toY': 250.0,
          },
        ),
        // Angle bisector
        const DiagramElement(
          id: 'PS',
          type: ElementType.line,
          properties: {
            'fromX': 150.0, 'fromY': 30.0,
            'toX': 152.0, 'toY': 250.0,
            'dashed': true,
          },
          insight: 'Angle bisector of ∠P. By the Angle Bisector Theorem: QS/SR = PQ/PR.',
        ),
        // Labels
        const DiagramElement(
          id: 'label_PQ',
          type: ElementType.label,
          properties: {'x': 80.0, 'y': 130.0, 'text': '8 cm', 'isValue': true},
          group: 'values',
        ),
        const DiagramElement(
          id: 'label_PR',
          type: ElementType.label,
          properties: {'x': 225.0, 'y': 130.0, 'text': '6 cm', 'isValue': true},
          group: 'values',
        ),
        const DiagramElement(
          id: 'label_QR',
          type: ElementType.label,
          properties: {'x': 155.0, 'y': 268.0, 'text': '10 cm', 'isValue': true},
          group: 'values',
        ),
        // Angle bisector hint
        const DiagramElement(
          id: 'hint_bisector',
          type: ElementType.label,
          properties: {
            'x': 165.0,
            'y': 150.0,
            'text': 'Angle\nBisector',
            'isHint': true,
          },
          group: 'hint',
        ),
      ],
    ),
    options: ['40/7 cm', '50/7 cm', '4 cm', '5 cm'],
    correctIndex: 0,
    explanation:
        'By the angle bisector theorem, QS/SR = PQ/PR = 8/6 = 4/3. '
        'Since QS + SR = 10, we get QS = 40/7 cm.',
    subject: 'Mathematics',
    topic: 'Geometry',
    revealSteps: [
      RevealStep(
        text: 'PS is the angle bisector of ∠P. Recall the Angle Bisector Theorem.',
        highlightIds: ['PS', 'P'],
      ),
      RevealStep(
        text: 'By the theorem: QS/SR = PQ/PR = 8/6 = 4/3.',
        highlightIds: ['Q', 'S', 'R'],
      ),
      RevealStep(
        text: 'Since QS + SR = QR = 10, solve: QS = 10 × 4/7 = 40/7 cm.',
        highlightIds: ['label_QR'],
        showHints: true,
      ),
    ],
  ),

  // Q3: Circle with chord
  QuestionData(
    id: 'geo_003',
    text:
        'A circle has center A and passes through points P, Q, B. If AB is a diameter, PQ is a chord, and ∠PAQ = 90°, find the ratio of arc PQ to circumference.',
    diagram: DiagramData(
      id: 'diag_circle',
      type: DiagramType.geometry,
      width: 300,
      height: 300,
      title: 'Circle with Chord PQ',
      elements: [
        // Axes
        const DiagramElement(
          id: 'x_axis',
          type: ElementType.line,
          properties: {
            'fromX': 10.0, 'fromY': 150.0,
            'toX': 290.0, 'toY': 150.0,
          },
          interactive: false,
        ),
        const DiagramElement(
          id: 'y_axis',
          type: ElementType.line,
          properties: {
            'fromX': 80.0, 'fromY': 10.0,
            'toX': 80.0, 'toY': 290.0,
          },
          interactive: false,
        ),
        // Circle
        const DiagramElement(
          id: 'main_circle',
          type: ElementType.circle,
          properties: {'x': 180.0, 'y': 150.0, 'radius': 100.0},
          insight: 'The full circle. Arc PQ corresponds to the central angle ∠PAQ.',
        ),
        // Points
        const DiagramElement(
          id: 'O_origin',
          type: ElementType.point,
          properties: {'x': 80.0, 'y': 150.0, 'text': 'O'},
        ),
        const DiagramElement(
          id: 'A',
          type: ElementType.point,
          properties: {'x': 180.0, 'y': 150.0, 'text': 'A'},
          insight: 'Center of the circle. AP = AQ = AB = radius.',
        ),
        const DiagramElement(
          id: 'B',
          type: ElementType.point,
          properties: {'x': 280.0, 'y': 150.0, 'text': 'B'},
        ),
        const DiagramElement(
          id: 'P',
          type: ElementType.point,
          properties: {'x': 180.0, 'y': 50.0, 'text': 'P'},
          insight: 'Point on the circle. AP is a radius.',
        ),
        const DiagramElement(
          id: 'Q_point',
          type: ElementType.point,
          properties: {'x': 180.0, 'y': 250.0, 'text': 'Q'},
          insight: 'Point on the circle. AQ is a radius.',
        ),
        // Lines from A to P and A to Q
        const DiagramElement(
          id: 'AP',
          type: ElementType.line,
          properties: {
            'fromX': 180.0, 'fromY': 150.0,
            'toX': 180.0, 'toY': 50.0,
          },
        ),
        const DiagramElement(
          id: 'AQ',
          type: ElementType.line,
          properties: {
            'fromX': 180.0, 'fromY': 150.0,
            'toX': 180.0, 'toY': 250.0,
          },
        ),
        // Chord PQ through B
        const DiagramElement(
          id: 'PB',
          type: ElementType.line,
          properties: {
            'fromX': 180.0, 'fromY': 50.0,
            'toX': 280.0, 'toY': 150.0,
            'dashed': true,
          },
        ),
        const DiagramElement(
          id: 'QB',
          type: ElementType.line,
          properties: {
            'fromX': 180.0, 'fromY': 250.0,
            'toX': 280.0, 'toY': 150.0,
            'dashed': true,
          },
        ),
        // Angle marker
        const DiagramElement(
          id: 'angle_PAQ',
          type: ElementType.angle,
          properties: {
            'x': 180.0,
            'y': 150.0,
            'text': '90°',
            'isValue': true,
          },
          group: 'values',
          insight: '∠PAQ = 90° is the central angle. The arc it subtends equals this angle.',
        ),
      ],
    ),
    options: ['1/4', '1/3', '1/2', '2/3'],
    correctIndex: 0,
    explanation:
        'Since ∠PAQ = 90° is the central angle, arc PQ = 90°. '
        'Ratio = 90/360 = 1/4.',
    subject: 'Mathematics',
    topic: 'Geometry',
    revealSteps: [
      RevealStep(
        text: 'Identify the central angle. ∠PAQ is the angle at the center A subtended by arc PQ.',
        highlightIds: ['A', 'angle_PAQ'],
      ),
      RevealStep(
        text: 'Central angle = 90°. The arc equals the central angle in a circle.',
        highlightIds: ['main_circle'],
      ),
      RevealStep(
        text: 'Ratio = arc/circumference = 90°/360° = 1/4.',
        highlightIds: ['P', 'Q_point'],
      ),
    ],
  ),

  // Q4: Wheatstone bridge (physics)
  QuestionData(
    id: 'phy_001',
    text:
        'In the circuit shown, a current of 6A enters at point P. '
        'All resistors are 2Ω. Find the current i₁ through the PQ branch.',
    diagram: DiagramData(
      id: 'diag_circuit',
      type: DiagramType.physics,
      width: 280,
      height: 280,
      title: 'Wheatstone Bridge Circuit',
      elements: [
        // Nodes
        const DiagramElement(
          id: 'node_P',
          type: ElementType.point,
          properties: {'x': 140.0, 'y': 60.0, 'text': 'P'},
          insight: 'Junction P: Apply Kirchhoff\'s junction rule. Total current 6A splits here.',
        ),
        const DiagramElement(
          id: 'node_Q',
          type: ElementType.point,
          properties: {'x': 40.0, 'y': 240.0, 'text': 'Q'},
          insight: 'Node Q: Current i₁ flows through PQ branch. Check symmetry with node R.',
        ),
        const DiagramElement(
          id: 'node_R',
          type: ElementType.point,
          properties: {'x': 240.0, 'y': 240.0, 'text': 'R'},
          insight: 'Node R: Current i₂ flows through PR branch. By symmetry, i₁ = i₂.',
        ),
        // Resistor lines (simplified as lines with labels)
        const DiagramElement(
          id: 'R_top',
          type: ElementType.line,
          properties: {
            'fromX': 140.0, 'fromY': 20.0,
            'toX': 140.0, 'toY': 60.0,
          },
        ),
        const DiagramElement(
          id: 'R_PQ',
          type: ElementType.line,
          properties: {
            'fromX': 140.0, 'fromY': 60.0,
            'toX': 40.0, 'toY': 240.0,
          },
          insight: 'Branch PQ: carries current i₁. Resistance = 2Ω.',
        ),
        const DiagramElement(
          id: 'R_PR',
          type: ElementType.line,
          properties: {
            'fromX': 140.0, 'fromY': 60.0,
            'toX': 240.0, 'toY': 240.0,
          },
          insight: 'Branch PR: carries current i₂. Resistance = 2Ω.',
        ),
        const DiagramElement(
          id: 'R_QR',
          type: ElementType.line,
          properties: {
            'fromX': 40.0, 'fromY': 240.0,
            'toX': 240.0, 'toY': 240.0,
          },
        ),
        // Current label
        const DiagramElement(
          id: 'label_current',
          type: ElementType.label,
          properties: {'x': 155.0, 'y': 12.0, 'text': '6 A', 'isValue': true},
          group: 'values',
        ),
        // Resistor labels
        const DiagramElement(
          id: 'label_R_top',
          type: ElementType.label,
          properties: {'x': 155.0, 'y': 35.0, 'text': '2Ω', 'isValue': true},
          group: 'values',
        ),
        const DiagramElement(
          id: 'label_R_PQ',
          type: ElementType.label,
          properties: {'x': 72.0, 'y': 140.0, 'text': '2Ω', 'isValue': true},
          group: 'values',
        ),
        const DiagramElement(
          id: 'label_R_PR',
          type: ElementType.label,
          properties: {'x': 205.0, 'y': 140.0, 'text': '2Ω', 'isValue': true},
          group: 'values',
        ),
        const DiagramElement(
          id: 'label_R_QR',
          type: ElementType.label,
          properties: {'x': 140.0, 'y': 258.0, 'text': '2Ω', 'isValue': true},
          group: 'values',
        ),
        // Current direction arrows
        const DiagramElement(
          id: 'i1_label',
          type: ElementType.label,
          properties: {'x': 75.0, 'y': 165.0, 'text': 'i₁', 'isHint': true},
          group: 'hint',
        ),
        const DiagramElement(
          id: 'i2_label',
          type: ElementType.label,
          properties: {'x': 210.0, 'y': 165.0, 'text': 'i₂', 'isHint': true},
          group: 'hint',
        ),
      ],
    ),
    options: ['2 A', '3 A', '4 A', '1 A'],
    correctIndex: 1,
    explanation:
        'By symmetry, i₁ = i₂ = 6/2 = 3A each through the two branches PQ and PR.',
    subject: 'Physics',
    topic: 'Current Electricity',
    revealSteps: [
      RevealStep(
        text: 'Look at junction P. Total incoming current is 6A. It splits into branches PQ and PR.',
        highlightIds: ['node_P'],
      ),
      RevealStep(
        text: 'All resistors are equal (2Ω). Check: is the circuit symmetric about P?',
        highlightIds: ['R_PQ', 'R_PR'],
        showHints: true,
      ),
      RevealStep(
        text: 'By symmetry, i₁ = i₂ = 6/2 = 3A through each branch.',
        highlightIds: ['node_Q', 'node_R'],
      ),
    ],
  ),

  // Q5: Star resistor network
  QuestionData(
    id: 'phy_002',
    text:
        'In the star-delta network shown, each resistor has resistance R. Find the equivalent resistance between nodes D and E.',
    diagram: DiagramData(
      id: 'diag_star',
      type: DiagramType.physics,
      width: 300,
      height: 280,
      title: 'Star-Delta Resistor Network',
      elements: [
        // Triangle vertices
        const DiagramElement(
          id: 'D',
          type: ElementType.point,
          properties: {'x': 150.0, 'y': 20.0, 'text': 'D'},
          insight: 'Terminal D: one end of the equivalent resistance we need to find.',
        ),
        const DiagramElement(
          id: 'C',
          type: ElementType.point,
          properties: {'x': 270.0, 'y': 250.0, 'text': 'C'},
          insight: 'Node C: connects delta and star networks. Analyze paths through C.',
        ),
        const DiagramElement(
          id: 'E',
          type: ElementType.point,
          properties: {'x': 30.0, 'y': 250.0, 'text': 'E'},
          insight: 'Terminal E: other end of the equivalent resistance.',
        ),
        // Center node
        const DiagramElement(
          id: 'A_center',
          type: ElementType.point,
          properties: {'x': 165.0, 'y': 180.0, 'text': 'A'},
          insight: 'Star center node A: connected to D, E, and B. Apply star-delta transformation.',
        ),
        const DiagramElement(
          id: 'B_center',
          type: ElementType.point,
          properties: {'x': 210.0, 'y': 210.0, 'text': 'B'},
          insight: 'Node B: intermediate node in the star network.',
        ),
        // Star connections
        const DiagramElement(
          id: 'DA',
          type: ElementType.line,
          properties: {
            'fromX': 150.0, 'fromY': 20.0,
            'toX': 165.0, 'toY': 180.0,
          },
        ),
        const DiagramElement(
          id: 'EA',
          type: ElementType.line,
          properties: {
            'fromX': 30.0, 'fromY': 250.0,
            'toX': 165.0, 'toY': 180.0,
          },
        ),
        const DiagramElement(
          id: 'AB',
          type: ElementType.line,
          properties: {
            'fromX': 165.0, 'fromY': 180.0,
            'toX': 210.0, 'toY': 210.0,
          },
        ),
        const DiagramElement(
          id: 'BC',
          type: ElementType.line,
          properties: {
            'fromX': 210.0, 'fromY': 210.0,
            'toX': 270.0, 'toY': 250.0,
          },
        ),
        // Delta connections
        const DiagramElement(
          id: 'DC',
          type: ElementType.line,
          properties: {
            'fromX': 150.0, 'fromY': 20.0,
            'toX': 270.0, 'toY': 250.0,
          },
        ),
        const DiagramElement(
          id: 'CE',
          type: ElementType.line,
          properties: {
            'fromX': 270.0, 'fromY': 250.0,
            'toX': 30.0, 'toY': 250.0,
          },
        ),
        // R labels
        ..._starResistorLabels(),
      ],
    ),
    options: ['R', '2R/3', '3R/2', 'R/2'],
    correctIndex: 0,
    explanation:
        'Using star-delta transformation and symmetry, the equivalent resistance between D and E is R.',
    subject: 'Physics',
    topic: 'Current Electricity',
    revealSteps: [
      RevealStep(
        text: 'Identify the star (A connected to D, E, B) and delta (D-C-E triangle) sub-networks.',
        highlightIds: ['A_center', 'D', 'E'],
      ),
      RevealStep(
        text: 'Apply star-delta transformation: convert the star at A into an equivalent delta.',
        highlightIds: ['DA', 'EA', 'AB'],
        showHints: true,
      ),
      RevealStep(
        text: 'After transformation, use series-parallel simplification. R_eq between D and E = R.',
        highlightIds: ['DC', 'CE'],
      ),
    ],
  ),
];

List<DiagramElement> _octagonVertices() {
  const labels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
  const cx = 150.0;
  const cy = 150.0;
  const r = 100.0;
  final elements = <DiagramElement>[];

  for (var i = 0; i < 8; i++) {
    final angle = -90.0 + i * 45.0;
    final rad = angle * 3.14159265 / 180.0;
    final x = cx + r * _cos(rad);
    final y = cy + r * _sin(rad);
    elements.add(DiagramElement(
      id: labels[i],
      type: ElementType.point,
      properties: {'x': x, 'y': y, 'text': labels[i]},
      insight: 'Vertex ${labels[i]} of the regular octagon. All vertices are equidistant from center O.',
    ));
  }
  return elements;
}

List<DiagramElement> _octagonEdges() {
  const labels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
  const cx = 150.0;
  const cy = 150.0;
  const r = 100.0;
  final elements = <DiagramElement>[];

  for (var i = 0; i < 8; i++) {
    final j = (i + 1) % 8;
    final a1 = (-90.0 + i * 45.0) * 3.14159265 / 180.0;
    final a2 = (-90.0 + j * 45.0) * 3.14159265 / 180.0;
    elements.add(DiagramElement(
      id: '${labels[i]}${labels[j]}',
      type: ElementType.line,
      properties: {
        'fromX': cx + r * _cos(a1),
        'fromY': cy + r * _sin(a1),
        'toX': cx + r * _cos(a2),
        'toY': cy + r * _sin(a2),
      },
    ));
  }
  return elements;
}

List<DiagramElement> _starResistorLabels() {
  return const [
    DiagramElement(
      id: 'r_DA',
      type: ElementType.label,
      properties: {'x': 140.0, 'y': 95.0, 'text': 'R', 'isValue': true},
      group: 'values',
    ),
    DiagramElement(
      id: 'r_EA',
      type: ElementType.label,
      properties: {'x': 80.0, 'y': 220.0, 'text': 'R', 'isValue': true},
      group: 'values',
    ),
    DiagramElement(
      id: 'r_AB',
      type: ElementType.label,
      properties: {'x': 195.0, 'y': 185.0, 'text': 'R', 'isValue': true},
      group: 'values',
    ),
    DiagramElement(
      id: 'r_BC',
      type: ElementType.label,
      properties: {'x': 248.0, 'y': 222.0, 'text': 'R', 'isValue': true},
      group: 'values',
    ),
    DiagramElement(
      id: 'r_DC',
      type: ElementType.label,
      properties: {'x': 225.0, 'y': 130.0, 'text': 'R', 'isValue': true},
      group: 'values',
    ),
    DiagramElement(
      id: 'r_CE',
      type: ElementType.label,
      properties: {'x': 150.0, 'y': 262.0, 'text': 'R', 'isValue': true},
      group: 'values',
    ),
  ];
}

double _cos(double radians) => math.cos(radians);
double _sin(double radians) => math.sin(radians);
