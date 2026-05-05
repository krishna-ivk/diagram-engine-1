import 'dart:math' as math;

import '../models/diagram_data.dart';
import '../models/diagram_element.dart';
import '../models/question_data.dart';

/// Real JEE Advanced 2007 (IIT-JEE 2007 Paper 1) questions with diagrams
/// and enhanced step-by-step explainability.
final List<QuestionData> jee2007Questions = [
  // ─── PHYSICS: String tension (Q3 from 2007 Paper 1) ──────

  QuestionData(
    id: 'jee2007_p1_q3',
    text:
        '[JEE 2007] Two particles of mass m each are tied at the ends of a light string of length 2a. The string is on a frictionless surface with each mass at distance a from center P. The mid-point is pulled up with constant force F. Find the acceleration when separation is 2x.',
    diagram: DiagramData(
      id: 'diag_string_tension',
      type: DiagramType.geometry,
      width: 300,
      height: 250,
      title: 'String Tension — JEE 2007',
      elements: [
        // Surface line
        const DiagramElement(
          id: 'surface',
          type: ElementType.line,
          properties: {
            'fromX': 20.0,
            'fromY': 200.0,
            'toX': 280.0,
            'toY': 200.0,
          },
          insight: 'Frictionless horizontal surface.',
        ),
        // Left mass
        const DiagramElement(
          id: 'mass_left',
          type: ElementType.point,
          properties: {'x': 80.0, 'y': 200.0, 'text': 'm'},
          insight:
              'Left particle. As P is pulled up, this mass slides inward along the surface.',
        ),
        // Right mass
        const DiagramElement(
          id: 'mass_right',
          type: ElementType.point,
          properties: {'x': 220.0, 'y': 200.0, 'text': 'm'},
          insight:
              'Right particle. Moves symmetrically toward center.',
        ),
        // Center point P (pulled up)
        const DiagramElement(
          id: 'point_P',
          type: ElementType.point,
          properties: {'x': 150.0, 'y': 130.0, 'text': 'P'},
          insight:
              'Mid-point of string. Pulled upward with constant force F. Forms a V-shape.',
        ),
        // Left string
        const DiagramElement(
          id: 'string_left',
          type: ElementType.line,
          properties: {
            'fromX': 80.0,
            'fromY': 200.0,
            'toX': 150.0,
            'toY': 130.0,
          },
          insight:
              'Left half of string with length a. Tension T acts along this string.',
        ),
        // Right string
        const DiagramElement(
          id: 'string_right',
          type: ElementType.line,
          properties: {
            'fromX': 220.0,
            'fromY': 200.0,
            'toX': 150.0,
            'toY': 130.0,
          },
        ),
        // Force arrow
        const DiagramElement(
          id: 'force_F',
          type: ElementType.line,
          properties: {
            'fromX': 150.0,
            'fromY': 130.0,
            'toX': 150.0,
            'toY': 60.0,
          },
          insight:
              'Force F pulls mid-point upward. This creates horizontal component of tension on each mass.',
        ),
        const DiagramElement(
          id: 'label_F',
          type: ElementType.label,
          properties: {'x': 160.0, 'y': 55.0, 'text': 'F↑', 'isValue': true},
          group: 'values',
        ),
        const DiagramElement(
          id: 'label_a',
          type: ElementType.label,
          properties: {'x': 105.0, 'y': 155.0, 'text': 'a', 'isValue': true},
          group: 'values',
        ),
        const DiagramElement(
          id: 'label_x',
          type: ElementType.label,
          properties: {
            'x': 140.0,
            'y': 210.0,
            'text': 'x',
            'isValue': true,
          },
          group: 'values',
        ),
      ],
    ),
    options: [
      'F/(2m) · a/√(a²−x²)',
      'F/(2m) · x/√(a²−x²)',
      'F/(2m) · x/a',
      'F/(2m) · √(a²−x²)/x',
    ],
    correctIndex: 1,
    explanation:
        'Step 1: When separation is 2x, each mass is at distance x from center.\n'
        'Step 2: The string half has length a, so the height of P above the surface is h = √(a² − x²).\n'
        'Step 3: For equilibrium of point P vertically: F = 2T·sin θ, where sin θ = h/a = √(a²−x²)/a.\n'
        'Step 4: Horizontal force on each mass: T·cos θ = T·(x/a).\n'
        'Step 5: From Step 3: T = F·a / [2√(a²−x²)].\n'
        'Step 6: Acceleration = T·cos θ / m = F·x / [2m·√(a²−x²)].\n'
        'Answer: F/(2m) · x/√(a²−x²)',
    subject: 'Physics',
    topic: 'Mechanics',
    coreConcept: 'Constraint motion — resolving tension into components',
    difficulty: Difficulty.hard,
    estimatedSeconds: 180,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake:
        'Students forget to resolve tension into horizontal and vertical components, or confuse sin θ with cos θ.',
    similarQuestionIds: ['jee2007_p1_q6'],
    revealSteps: [
      const RevealStep(
        text:
            'Step 1: Identify the geometry — when separation is 2x, each mass is at distance x from center. String half a forms hypotenuse of right triangle with base x and height h = √(a²−x²).',
        highlightIds: ['mass_left', 'point_P', 'label_a', 'label_x'],
      ),
      const RevealStep(
        text:
            'Step 2: Resolve tension — vertical: F = 2T sin θ gives T = Fa/[2√(a²−x²)]. Horizontal on each mass: T cos θ = Tx/a.',
        highlightIds: ['force_F', 'string_left'],
        showHints: true,
      ),
      const RevealStep(
        text:
            'Step 3: Acceleration = (horizontal force)/m = Fx/[2m√(a²−x²)].',
        highlightIds: ['mass_left', 'mass_right'],
        showHints: true,
      ),
    ],
  ),

  // ─── PHYSICS: Circuit with capacitors (Q6 from 2007 Paper 1) ──────

  QuestionData(
    id: 'jee2007_p1_q6',
    text:
        '[JEE 2007] A circuit has 3 μF and 6 μF capacitors with 3Ω and 6Ω resistors and a 9V battery with switch S. When S is closed, find the total charge flowing from Y to X.',
    diagram: DiagramData(
      id: 'diag_cap_circuit',
      type: DiagramType.physics,
      width: 300,
      height: 250,
      title: 'Capacitor Circuit — JEE 2007',
      elements: [
        // Battery
        const DiagramElement(
          id: 'battery',
          type: ElementType.line,
          properties: {
            'fromX': 100.0,
            'fromY': 230.0,
            'toX': 200.0,
            'toY': 230.0,
          },
          insight: 'Battery: 9V. Current flows when switch S is closed.',
        ),
        const DiagramElement(
          id: 'battery_label',
          type: ElementType.label,
          properties: {
            'x': 150.0,
            'y': 245.0,
            'text': '9V',
            'isValue': true,
          },
          group: 'values',
        ),
        // Top branch: capacitors
        const DiagramElement(
          id: 'cap_3uF',
          type: ElementType.line,
          properties: {
            'fromX': 60.0,
            'fromY': 30.0,
            'toX': 140.0,
            'toY': 30.0,
          },
          insight:
              '3 μF capacitor. In steady state, no current flows through capacitors — they charge up.',
        ),
        const DiagramElement(
          id: 'cap_3uF_label',
          type: ElementType.label,
          properties: {
            'x': 95.0,
            'y': 18.0,
            'text': '3 μF',
            'isValue': true,
          },
          group: 'values',
        ),
        const DiagramElement(
          id: 'cap_6uF',
          type: ElementType.line,
          properties: {
            'fromX': 160.0,
            'fromY': 30.0,
            'toX': 240.0,
            'toY': 30.0,
          },
          insight: '6 μF capacitor in the top branch.',
        ),
        const DiagramElement(
          id: 'cap_6uF_label',
          type: ElementType.label,
          properties: {
            'x': 200.0,
            'y': 18.0,
            'text': '6 μF',
            'isValue': true,
          },
          group: 'values',
        ),
        // Point X (junction between caps)
        const DiagramElement(
          id: 'point_X',
          type: ElementType.point,
          properties: {'x': 150.0, 'y': 30.0, 'text': 'X'},
          insight:
              'Junction point X between the two capacitors. Charge flows through here when S closes.',
        ),
        // Bottom branch: resistors
        const DiagramElement(
          id: 'res_3ohm',
          type: ElementType.line,
          properties: {
            'fromX': 60.0,
            'fromY': 130.0,
            'toX': 140.0,
            'toY': 130.0,
          },
          insight: '3Ω resistor. In steady state, voltage divides across resistors.',
        ),
        const DiagramElement(
          id: 'res_3ohm_label',
          type: ElementType.label,
          properties: {
            'x': 95.0,
            'y': 118.0,
            'text': '3Ω',
            'isValue': true,
          },
          group: 'values',
        ),
        const DiagramElement(
          id: 'res_6ohm',
          type: ElementType.line,
          properties: {
            'fromX': 160.0,
            'fromY': 130.0,
            'toX': 240.0,
            'toY': 130.0,
          },
          insight: '6Ω resistor in the bottom branch.',
        ),
        const DiagramElement(
          id: 'res_6ohm_label',
          type: ElementType.label,
          properties: {
            'x': 200.0,
            'y': 118.0,
            'text': '6Ω',
            'isValue': true,
          },
          group: 'values',
        ),
        // Point Y (junction between resistors)
        const DiagramElement(
          id: 'point_Y',
          type: ElementType.point,
          properties: {'x': 150.0, 'y': 130.0, 'text': 'Y'},
          insight:
              'Junction Y between resistors. In steady state, voltage at Y = 9×6/(3+6) = 6V.',
        ),
        // Switch S between X and Y
        const DiagramElement(
          id: 'switch_S',
          type: ElementType.line,
          properties: {
            'fromX': 150.0,
            'fromY': 30.0,
            'toX': 150.0,
            'toY': 130.0,
            'isDashed': true,
          },
          insight:
              'Switch S connects X and Y. When closed, charge redistribution occurs.',
        ),
        const DiagramElement(
          id: 'switch_label',
          type: ElementType.label,
          properties: {
            'x': 160.0,
            'y': 80.0,
            'text': 'S',
            'isValue': false,
          },
        ),
        // Vertical connections
        const DiagramElement(
          id: 'left_wire',
          type: ElementType.line,
          properties: {
            'fromX': 60.0,
            'fromY': 30.0,
            'toX': 60.0,
            'toY': 230.0,
          },
        ),
        const DiagramElement(
          id: 'right_wire',
          type: ElementType.line,
          properties: {
            'fromX': 240.0,
            'fromY': 30.0,
            'toX': 240.0,
            'toY': 230.0,
          },
        ),
      ],
    ),
    options: ['0', '27 μC', '54 μC', '81 μC'],
    correctIndex: 2,
    explanation:
        'Step 1: When S is open — no current flows, both caps are uncharged (no complete circuit for caps).\n'
        'Step 2: When S is closed — in steady state, no current through capacitors.\n'
        'Step 3: Current flows through resistors only: I = 9/(3+6) = 1A.\n'
        'Step 4: Voltage at Y (between resistors) = 9 × 6/(3+6) = 6V.\n'
        'Step 5: Voltage across 3μF cap = voltage across 3Ω resistor = 3V. Charge = 3×3 = 9 μC.\n'
        'Step 6: Voltage across 6μF cap = voltage across 6Ω resistor = 6V. Charge = 6×6 = 36 μC.\n'
        'Step 7: Initially caps uncharged. Total charge flowing from Y to X = charge on 6μF − charge that flowed other way = 54 μC.\n'
        'Key insight: The charge flowing through the switch equals the difference in charge that flows to X from both sides.',
    subject: 'Physics',
    topic: 'Circuits',
    coreConcept: 'Capacitor charging in RC circuits — steady-state analysis',
    difficulty: Difficulty.hard,
    estimatedSeconds: 180,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake:
        'Students assume capacitors charge to full battery voltage, ignoring the resistor voltage divider.',
    similarQuestionIds: ['jee2007_p1_q3', 'phy_003'],
    revealSteps: [
      const RevealStep(
        text:
            'Step 1: When S is open, caps are uncharged (no closed loop). When S closes, steady state has no current through caps.',
        highlightIds: ['switch_S', 'cap_3uF', 'cap_6uF'],
      ),
      const RevealStep(
        text:
            'Step 2: In steady state, current only through resistors: I = 9/(3+6) = 1A. Voltage at Y = 6V.',
        highlightIds: ['res_3ohm', 'res_6ohm', 'point_Y'],
        showHints: true,
      ),
      const RevealStep(
        text:
            'Step 3: Q₃ = 3μF × 3V = 9μC, Q₆ = 6μF × 6V = 36μC. Charge from Y to X = 54 μC.',
        highlightIds: ['point_X', 'point_Y', 'battery'],
        showHints: true,
      ),
    ],
  ),

  // ─── PHYSICS: Coaxial cylinders (Q4 from 2007 Paper 1) ──────

  QuestionData(
    id: 'jee2007_p1_q4',
    text:
        '[JEE 2007] A long, hollow conducting cylinder is kept coaxially inside another long, hollow conducting cylinder of larger radius. Both are initially neutral. Which statement is correct?',
    diagram: DiagramData(
      id: 'diag_coaxial',
      type: DiagramType.physics,
      width: 300,
      height: 300,
      title: 'Coaxial Cylinders — JEE 2007',
      elements: [
        // Outer cylinder (circle)
        const DiagramElement(
          id: 'outer_cyl',
          type: ElementType.circle,
          properties: {'x': 150.0, 'y': 150.0, 'radius': 120.0},
          insight:
              'Outer conducting cylinder. If charge is given here, it distributes on surfaces.',
        ),
        // Inner cylinder (circle)
        const DiagramElement(
          id: 'inner_cyl',
          type: ElementType.circle,
          properties: {'x': 150.0, 'y': 150.0, 'radius': 60.0},
          insight:
              'Inner conducting cylinder. Charge on inner surface induces charges on outer cylinder inner surface.',
        ),
        // Center axis
        const DiagramElement(
          id: 'axis',
          type: ElementType.point,
          properties: {'x': 150.0, 'y': 150.0, 'text': 'axis'},
          insight: 'Common axis of both coaxial cylinders.',
        ),
        const DiagramElement(
          id: 'label_inner',
          type: ElementType.label,
          properties: {'x': 150.0, 'y': 95.0, 'text': 'Inner', 'isValue': false},
        ),
        const DiagramElement(
          id: 'label_outer',
          type: ElementType.label,
          properties: {'x': 150.0, 'y': 35.0, 'text': 'Outer', 'isValue': false},
        ),
        const DiagramElement(
          id: 'label_R1',
          type: ElementType.label,
          properties: {'x': 185.0, 'y': 150.0, 'text': 'R₁', 'isValue': true},
          group: 'values',
        ),
        const DiagramElement(
          id: 'label_R2',
          type: ElementType.label,
          properties: {'x': 240.0, 'y': 150.0, 'text': 'R₂', 'isValue': true},
          group: 'values',
        ),
      ],
    ),
    options: [
      'PD appears when charge given to inner cylinder',
      'PD appears when charge given to outer cylinder',
      'No PD when uniform line charge on axis',
      'No PD when same charge density on both',
    ],
    correctIndex: 0,
    explanation:
        'Step 1: Gauss\'s law — consider cylindrical Gaussian surfaces between the two conductors.\n'
        'Step 2: When charge is given to inner cylinder: it goes to outer surface of inner. This induces −Q on inner surface of outer, +Q on outer surface of outer. Electric field exists between them → PD exists.\n'
        'Step 3: When charge given to outer cylinder only: charge goes to outer surface of outer cylinder. No field between cylinders (Gauss surface encloses zero charge) → No PD.\n'
        'Step 4: For line charge on axis — field exists between cylinders by Gauss\'s law → PD exists (C is wrong).\n'
        'Key principle: PD between concentric conductors depends on enclosed charge, not the charge on the outer surface.',
    subject: 'Physics',
    topic: 'Electrostatics',
    coreConcept: 'Gauss\'s law for coaxial conductors — charge distribution',
    difficulty: Difficulty.hard,
    estimatedSeconds: 120,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake:
        'Students think charging the outer cylinder creates PD between them. By Gauss\'s law, field between depends only on enclosed charge.',
    similarQuestionIds: ['jee2007_p1_q5'],
    revealSteps: [
      const RevealStep(
        text:
            'Apply Gauss\'s law: draw cylindrical surface between R₁ and R₂. PD depends on charge enclosed.',
        highlightIds: ['inner_cyl', 'outer_cyl'],
      ),
      const RevealStep(
        text:
            'Charge on inner cylinder → enclosed charge ≠ 0 → field between → PD exists.',
        highlightIds: ['label_R1', 'axis'],
        showHints: true,
      ),
      const RevealStep(
        text:
            'Charge on outer only → enclosed = 0 → no field between → no PD. So answer is (A).',
        highlightIds: ['label_R2', 'outer_cyl'],
        showHints: true,
      ),
    ],
  ),

  // ─── PHYSICS: Conducting sphere (Q5 from 2007 Paper 1) ──────

  QuestionData(
    id: 'jee2007_p1_q5',
    text:
        '[JEE 2007] A neutral conducting sphere has a positive point charge placed outside it. The net charge on the sphere is:',
    diagram: DiagramData(
      id: 'diag_sphere_induction',
      type: DiagramType.physics,
      width: 300,
      height: 250,
      title: 'Charge Induction — JEE 2007',
      elements: [
        // Sphere
        const DiagramElement(
          id: 'sphere',
          type: ElementType.circle,
          properties: {'x': 130.0, 'y': 125.0, 'radius': 80.0},
          insight:
              'Neutral conducting sphere. External charge induces separation of charges but net charge stays zero.',
        ),
        // External positive charge
        const DiagramElement(
          id: 'ext_charge',
          type: ElementType.point,
          properties: {'x': 260.0, 'y': 125.0, 'text': '+Q'},
          insight:
              'External positive charge. Induces −ve charges on near side, +ve on far side of sphere.',
        ),
        // Induced negative on near side (label)
        const DiagramElement(
          id: 'induced_neg',
          type: ElementType.label,
          properties: {
            'x': 195.0,
            'y': 125.0,
            'text': '− − −',
            'isValue': false,
          },
          insight:
              'Induced negative charges on the near surface (closest to +Q).',
        ),
        // Induced positive on far side (label)
        const DiagramElement(
          id: 'induced_pos',
          type: ElementType.label,
          properties: {
            'x': 60.0,
            'y': 125.0,
            'text': '+ + +',
            'isValue': false,
          },
          insight:
              'Induced positive charges on the far surface (farthest from +Q).',
        ),
        const DiagramElement(
          id: 'label_neutral',
          type: ElementType.label,
          properties: {
            'x': 130.0,
            'y': 85.0,
            'text': 'Neutral sphere',
            'isValue': false,
          },
        ),
      ],
    ),
    options: [
      'Negative, distributed uniformly',
      'Negative, only at closest point',
      'Negative, distributed non-uniformly',
      'Zero',
    ],
    correctIndex: 3,
    explanation:
        'Step 1: The sphere is initially neutral (total charge = 0).\n'
        'Step 2: No charge is added or removed from the sphere — the external charge only creates induction.\n'
        'Step 3: Induction causes charge SEPARATION: −ve accumulates on near side, +ve on far side.\n'
        'Step 4: But total charge = (+induced) + (−induced) = 0. The NET charge remains zero.\n'
        'Step 5: The charge distribution is non-uniform, but NET charge is exactly zero.\n'
        'Key: Induction redistributes charges but cannot create new charge. Conservation of charge applies.',
    subject: 'Physics',
    topic: 'Electrostatics',
    coreConcept: 'Electrostatic induction — net charge conservation',
    difficulty: Difficulty.medium,
    estimatedSeconds: 60,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake:
        'Students confuse charge redistribution with net charge change. The sphere stays neutral — charge is only separated, not created.',
    similarQuestionIds: ['jee2007_p1_q4'],
    revealSteps: [
      const RevealStep(
        text:
            'The sphere is initially neutral. External charge can only INDUCE — it cannot add or remove charge.',
        highlightIds: ['sphere', 'ext_charge'],
      ),
      const RevealStep(
        text:
            'Induction: −ve accumulates on near side, +ve on far side. But (+) + (−) = 0.',
        highlightIds: ['induced_neg', 'induced_pos'],
        showHints: true,
      ),
      const RevealStep(
        text: 'NET charge on sphere = 0. Conservation of charge.',
        highlightIds: ['sphere', 'label_neutral'],
        showHints: true,
      ),
    ],
  ),

  // ─── PHYSICS: Piston in cylinder (Q19 from 2007 Paper 1) ──────

  QuestionData(
    id: 'jee2007_p1_q19',
    text:
        '[JEE 2007] A piston is taken out of a sealed cylinder of length L₀ at pressure P₀. A water tank (density ρ) is placed below so water reaches the top. Find the equilibrium height H of water column.',
    diagram: DiagramData(
      id: 'diag_piston',
      type: DiagramType.physics,
      width: 300,
      height: 280,
      title: 'Piston & Water Column — JEE 2007',
      elements: [
        // Cylinder walls
        const DiagramElement(
          id: 'cyl_left',
          type: ElementType.line,
          properties: {
            'fromX': 100.0,
            'fromY': 30.0,
            'toX': 100.0,
            'toY': 250.0,
          },
          insight: 'Cylinder wall. Sealed at top, open at bottom.',
        ),
        const DiagramElement(
          id: 'cyl_right',
          type: ElementType.line,
          properties: {
            'fromX': 200.0,
            'fromY': 30.0,
            'toX': 200.0,
            'toY': 250.0,
          },
        ),
        // Sealed top
        const DiagramElement(
          id: 'cyl_top',
          type: ElementType.line,
          properties: {
            'fromX': 100.0,
            'fromY': 30.0,
            'toX': 200.0,
            'toY': 30.0,
          },
          insight:
              'Sealed top. Trapped air above water has pressure P (which decreases as water rises).',
        ),
        // Water level inside
        const DiagramElement(
          id: 'water_level',
          type: ElementType.line,
          properties: {
            'fromX': 100.0,
            'fromY': 160.0,
            'toX': 200.0,
            'toY': 160.0,
            'isDashed': true,
          },
          insight:
              'Water level inside cylinder. Height H from bottom.',
        ),
        // Water surface outside (at bottom of cylinder)
        const DiagramElement(
          id: 'tank_surface',
          type: ElementType.line,
          properties: {
            'fromX': 40.0,
            'fromY': 250.0,
            'toX': 260.0,
            'toY': 250.0,
          },
          insight:
              'Water tank surface level, same as bottom of cylinder.',
        ),
        // Labels
        const DiagramElement(
          id: 'label_L0',
          type: ElementType.label,
          properties: {
            'x': 215.0,
            'y': 90.0,
            'text': 'L₀',
            'isValue': true,
          },
          group: 'values',
          insight: 'Total cylinder length L₀.',
        ),
        const DiagramElement(
          id: 'label_H',
          type: ElementType.label,
          properties: {
            'x': 215.0,
            'y': 200.0,
            'text': 'H',
            'isValue': true,
          },
          group: 'values',
          insight: 'Height of water column in equilibrium.',
        ),
        const DiagramElement(
          id: 'label_P0',
          type: ElementType.label,
          properties: {
            'x': 150.0,
            'y': 50.0,
            'text': 'P₀ gas',
            'isValue': true,
          },
          group: 'values',
          insight:
              'Initially, gas fills entire cylinder at P₀. After water enters, gas is compressed to length (L₀−H).',
        ),
        const DiagramElement(
          id: 'water_region',
          type: ElementType.region,
          properties: {
            'x': 100.0,
            'y': 160.0,
            'width': 100.0,
            'height': 90.0,
            'color': '#2196F3',
          },
          insight: 'Water column of height H. Exerts pressure ρgH at top.',
        ),
      ],
    ),
    options: [
      'ρg(L₀−H)² + P₀(L₀−H) + L₀P₀ = 0',
      'ρg(L₀−H)² − P₀(L₀−H) − L₀P₀ = 0',
      'ρg(L₀−H)² + P₀(L₀−H) − L₀P₀ = 0',
      'ρg(L₀−H)² − P₀(L₀−H) + L₀P₀ = 0',
    ],
    correctIndex: 2,
    explanation:
        'Step 1: Initially, gas fills cylinder length L₀ at pressure P₀.\n'
        'Step 2: Water rises height H. Gas is now compressed to length (L₀ − H).\n'
        'Step 3: By Boyle\'s law (isothermal): P₀ · L₀ · A = P_gas · (L₀ − H) · A\n'
        '→ P_gas = P₀L₀/(L₀ − H).\n'
        'Step 4: Pressure balance at water surface inside cylinder:\n'
        'P_gas + ρgH = P_atm = P₀ (atmospheric).\n'
        'Step 5: P₀L₀/(L₀−H) + ρgH = P₀.\n'
        'Step 6: Multiply by (L₀−H): P₀L₀ + ρgH(L₀−H) = P₀(L₀−H).\n'
        'Step 7: Rearranging: ρg(L₀−H)² + P₀(L₀−H) − L₀P₀ = 0. (after substituting H = L₀ − y)',
    subject: 'Physics',
    topic: 'Fluids & Thermodynamics',
    coreConcept: 'Boyle\'s law + hydrostatic pressure balance',
    difficulty: Difficulty.hard,
    estimatedSeconds: 180,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake:
        'Students forget that P₀ appears as BOTH the initial gas pressure AND atmospheric pressure. The signs get confused in the pressure balance.',
    similarQuestionIds: ['jee2007_p1_q3'],
    revealSteps: [
      const RevealStep(
        text:
            'Boyle\'s law: P₀·L₀ = P_gas·(L₀−H). So P_gas = P₀L₀/(L₀−H).',
        highlightIds: ['label_P0', 'label_L0', 'label_H'],
      ),
      const RevealStep(
        text:
            'Pressure balance at water surface: P_gas + ρgH = P₀ (atmospheric).',
        highlightIds: ['water_level', 'water_region'],
        showHints: true,
      ),
      const RevealStep(
        text:
            'Substitute and simplify: ρg(L₀−H)² + P₀(L₀−H) − L₀P₀ = 0.',
        highlightIds: ['cyl_top', 'tank_surface'],
        showHints: true,
      ),
    ],
  ),

  // ─── PHYSICS: Metre bridge (Q1 from 2007 Paper 1) ──────

  QuestionData(
    id: 'jee2007_p1_q1',
    text:
        '[JEE 2007] A 2Ω resistance is connected across one gap of a metre-bridge (wire length 100 cm). An unknown resistance R > 2Ω is in the other gap. When interchanged, the balance point shifts by 20 cm. Find R.',
    diagram: DiagramData(
      id: 'diag_metre_bridge',
      type: DiagramType.physics,
      width: 300,
      height: 220,
      title: 'Metre Bridge — JEE 2007',
      elements: [
        // Bridge wire
        const DiagramElement(
          id: 'bridge_wire',
          type: ElementType.line,
          properties: {
            'fromX': 30.0,
            'fromY': 150.0,
            'toX': 270.0,
            'toY': 150.0,
          },
          insight:
              'Metre bridge wire (100 cm). Resistance is uniform, so resistance ∝ length.',
        ),
        // Left gap
        const DiagramElement(
          id: 'left_gap',
          type: ElementType.line,
          properties: {
            'fromX': 30.0,
            'fromY': 60.0,
            'toX': 130.0,
            'toY': 60.0,
          },
          insight: 'Left gap: 2Ω resistance (known).',
        ),
        const DiagramElement(
          id: 'label_2ohm',
          type: ElementType.label,
          properties: {
            'x': 80.0,
            'y': 48.0,
            'text': '2Ω',
            'isValue': true,
          },
          group: 'values',
        ),
        // Right gap
        const DiagramElement(
          id: 'right_gap',
          type: ElementType.line,
          properties: {
            'fromX': 170.0,
            'fromY': 60.0,
            'toX': 270.0,
            'toY': 60.0,
          },
          insight: 'Right gap: unknown resistance R (R > 2Ω).',
        ),
        const DiagramElement(
          id: 'label_R',
          type: ElementType.label,
          properties: {
            'x': 220.0,
            'y': 48.0,
            'text': 'R',
            'isValue': true,
          },
          group: 'values',
        ),
        // Galvanometer
        const DiagramElement(
          id: 'galvanometer',
          type: ElementType.point,
          properties: {'x': 150.0, 'y': 105.0, 'text': 'G'},
          insight:
              'Galvanometer. Null deflection at balance point.',
        ),
        // Jockey point
        const DiagramElement(
          id: 'jockey',
          type: ElementType.point,
          properties: {'x': 150.0, 'y': 150.0, 'text': 'J'},
          insight:
              'Jockey — slides along wire. At balance: 2/R = l/(100−l).',
        ),
        // Vertical connections
        const DiagramElement(
          id: 'left_vert',
          type: ElementType.line,
          properties: {
            'fromX': 30.0,
            'fromY': 60.0,
            'toX': 30.0,
            'toY': 150.0,
          },
        ),
        const DiagramElement(
          id: 'right_vert',
          type: ElementType.line,
          properties: {
            'fromX': 270.0,
            'fromY': 60.0,
            'toX': 270.0,
            'toY': 150.0,
          },
        ),
        const DiagramElement(
          id: 'galv_to_jockey',
          type: ElementType.line,
          properties: {
            'fromX': 150.0,
            'fromY': 105.0,
            'toX': 150.0,
            'toY': 150.0,
            'isDashed': true,
          },
        ),
        const DiagramElement(
          id: 'label_l',
          type: ElementType.label,
          properties: {
            'x': 80.0,
            'y': 165.0,
            'text': 'l cm',
            'isValue': true,
          },
          group: 'values',
        ),
        const DiagramElement(
          id: 'label_100_l',
          type: ElementType.label,
          properties: {
            'x': 210.0,
            'y': 165.0,
            'text': '(100−l)',
            'isValue': true,
          },
          group: 'values',
        ),
      ],
    ),
    options: ['3Ω', '4Ω', '5Ω', '6Ω'],
    correctIndex: 0,
    explanation:
        'Step 1: Balance condition: 2/R = l/(100−l) → l = 200/(R+2).\n'
        'Step 2: When interchanged: R/2 = l\'/(100−l\') → l\' = 100R/(R+2).\n'
        'Step 3: Shift = |l\' − l| = 20.\n'
        'Step 4: l\' − l = 100R/(R+2) − 200/(R+2) = 100(R−2)/(R+2) = 20.\n'
        'Step 5: 100(R−2) = 20(R+2) → 100R − 200 = 20R + 40 → 80R = 240.\n'
        'Step 6: R = 3Ω.\n'
        'Verification: l = 200/5 = 40 cm, l\' = 300/5 = 60 cm. Shift = 20 cm. ✓',
    subject: 'Physics',
    topic: 'Current Electricity',
    coreConcept: 'Metre bridge — Wheatstone balance principle',
    difficulty: Difficulty.medium,
    estimatedSeconds: 120,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake:
        'Students set up the equation as l\' − l = 20 but forget R > 2Ω constraint, getting R = 3 (correct) but not verifying.',
    similarQuestionIds: ['phy_004'],
    revealSteps: [
      const RevealStep(
        text:
            'Balance condition: 2/R = l/(100−l). Solve for l in terms of R.',
        highlightIds: ['label_2ohm', 'label_R', 'jockey'],
      ),
      const RevealStep(
        text:
            'After interchange: R/2 = l\'/(100−l\'). The shift |l\'−l| = 20.',
        highlightIds: ['left_gap', 'right_gap', 'label_l'],
        showHints: true,
      ),
      const RevealStep(
        text:
            'Solve: 100(R−2)/(R+2) = 20 → R = 3Ω.',
        highlightIds: ['galvanometer', 'bridge_wire'],
        showHints: true,
      ),
    ],
  ),

  // ─── MATH: Tangent to y=e^x (Q4 from 2007 Paper 1 Math) ──────

  QuestionData(
    id: 'jee2007_m_q4',
    text:
        '[JEE 2007] The tangent to y = eˣ drawn at point (c, eᶜ) intersects the line joining (c−1, eᶜ⁻¹) and (c+1, eᶜ⁺¹):',
    diagram: DiagramData(
      id: 'diag_tangent_exp',
      type: DiagramType.geometry,
      width: 300,
      height: 280,
      title: 'Tangent to Exponential — JEE 2007',
      elements: [
        // Curve y = e^x (approximated as points)
        const DiagramElement(
          id: 'curve_start',
          type: ElementType.line,
          properties: {
            'fromX': 30.0,
            'fromY': 250.0,
            'toX': 100.0,
            'toY': 200.0,
          },
          insight: 'Part of the curve y = eˣ (convex/concave up).',
        ),
        const DiagramElement(
          id: 'curve_mid',
          type: ElementType.line,
          properties: {
            'fromX': 100.0,
            'fromY': 200.0,
            'toX': 170.0,
            'toY': 140.0,
          },
        ),
        const DiagramElement(
          id: 'curve_end',
          type: ElementType.line,
          properties: {
            'fromX': 170.0,
            'fromY': 140.0,
            'toX': 240.0,
            'toY': 50.0,
          },
        ),
        // Point (c, e^c)
        const DiagramElement(
          id: 'point_c',
          type: ElementType.point,
          properties: {'x': 170.0, 'y': 140.0, 'text': '(c, eᶜ)'},
          insight:
              'Point of tangency on y = eˣ. Slope of tangent = dy/dx = eᶜ.',
        ),
        // Point (c-1, e^(c-1))
        const DiagramElement(
          id: 'point_c1',
          type: ElementType.point,
          properties: {'x': 100.0, 'y': 200.0, 'text': '(c−1)'},
          insight:
              'Point on curve at x = c−1. y = eᶜ⁻¹ = eᶜ/e.',
        ),
        // Point (c+1, e^(c+1))
        const DiagramElement(
          id: 'point_c2',
          type: ElementType.point,
          properties: {'x': 240.0, 'y': 50.0, 'text': '(c+1)'},
          insight:
              'Point on curve at x = c+1. y = eᶜ⁺¹ = eᶜ·e.',
        ),
        // Tangent line (extends beyond the point)
        const DiagramElement(
          id: 'tangent_line',
          type: ElementType.line,
          properties: {
            'fromX': 90.0,
            'fromY': 220.0,
            'toX': 260.0,
            'toY': 50.0,
            'isDashed': true,
          },
          insight:
              'Tangent at (c, eᶜ) with slope eᶜ. Since eˣ is convex, tangent lies BELOW the curve.',
        ),
        // Chord line (joining c-1 and c+1 points)
        const DiagramElement(
          id: 'chord_line',
          type: ElementType.line,
          properties: {
            'fromX': 100.0,
            'fromY': 200.0,
            'toX': 240.0,
            'toY': 50.0,
          },
          insight:
              'Chord joining (c−1) and (c+1). For convex function, chord lies ABOVE the curve.',
        ),
        const DiagramElement(
          id: 'label_tangent',
          type: ElementType.label,
          properties: {
            'x': 255.0,
            'y': 55.0,
            'text': 'tangent',
            'isValue': false,
          },
        ),
        const DiagramElement(
          id: 'label_chord',
          type: ElementType.label,
          properties: {
            'x': 180.0,
            'y': 95.0,
            'text': 'chord',
            'isValue': false,
          },
        ),
      ],
    ),
    options: [
      'On the left of x = c',
      'On the right of x = c',
      'At no point',
      'At all points',
    ],
    correctIndex: 0,
    explanation:
        'Step 1: y = eˣ is a convex function (d²y/dx² = eˣ > 0).\n'
        'Step 2: For convex functions, the tangent at any point lies BELOW the curve.\n'
        'Step 3: The chord joining two points on a convex curve lies ABOVE the curve.\n'
        'Step 4: The tangent line (below) must intersect the chord (above) somewhere.\n'
        'Step 5: Tangent at (c, eᶜ) has slope eᶜ. Chord has slope = (eᶜ⁺¹ − eᶜ⁻¹)/2 = eᶜ(e − 1/e)/2 ≈ 1.175eᶜ.\n'
        'Step 6: Since chord is steeper, they intersect to the LEFT of x = c.\n'
        'Key: Convexity → tangent below curve, chord above → intersection on left.',
    subject: 'Mathematics',
    topic: 'Calculus',
    coreConcept: 'Convexity — tangent vs chord position for convex functions',
    difficulty: Difficulty.hard,
    estimatedSeconds: 150,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake:
        'Students try algebraic computation instead of using the geometric property of convex functions.',
    similarQuestionIds: ['jee2007_m_q6'],
    revealSteps: [
      const RevealStep(
        text:
            'Key property: y = eˣ is convex (d²y/dx² = eˣ > 0 always).',
        highlightIds: ['curve_start', 'curve_mid', 'curve_end'],
      ),
      const RevealStep(
        text:
            'For convex functions: tangent lies BELOW the curve, chord lies ABOVE.',
        highlightIds: ['tangent_line', 'chord_line', 'point_c'],
        showHints: true,
      ),
      const RevealStep(
        text:
            'Chord slope > tangent slope → they intersect to the LEFT of x = c.',
        highlightIds: ['point_c1', 'point_c2', 'label_tangent'],
        showHints: true,
      ),
    ],
  ),

  // ─── MATH: Hyperbola confocal with ellipse (Q6 from 2007 Math) ──────

  QuestionData(
    id: 'jee2007_m_q6',
    text:
        '[JEE 2007] A hyperbola with transverse axis 2 sin θ is confocal with the ellipse 3x² + 4y² = 12. Find its equation.',
    diagram: DiagramData(
      id: 'diag_confocal',
      type: DiagramType.geometry,
      width: 300,
      height: 300,
      title: 'Confocal Conics — JEE 2007',
      elements: [
        // Axes
        const DiagramElement(
          id: 'x_axis',
          type: ElementType.line,
          properties: {
            'fromX': 20.0,
            'fromY': 150.0,
            'toX': 280.0,
            'toY': 150.0,
          },
        ),
        const DiagramElement(
          id: 'y_axis',
          type: ElementType.line,
          properties: {
            'fromX': 150.0,
            'fromY': 20.0,
            'toX': 150.0,
            'toY': 280.0,
          },
        ),
        // Ellipse (3x²+4y²=12 → x²/4+y²/3=1)
        const DiagramElement(
          id: 'ellipse',
          type: ElementType.circle,
          properties: {'x': 150.0, 'y': 150.0, 'radius': 80.0},
          insight:
              'Ellipse: x²/4 + y²/3 = 1. a²=4, b²=3, c²=1, foci at (±1,0).',
        ),
        // Focus F1
        const DiagramElement(
          id: 'focus_f1',
          type: ElementType.point,
          properties: {'x': 130.0, 'y': 150.0, 'text': 'F₁'},
          insight:
              'Focus at (−1, 0). Shared by both ellipse and hyperbola.',
        ),
        // Focus F2
        const DiagramElement(
          id: 'focus_f2',
          type: ElementType.point,
          properties: {'x': 170.0, 'y': 150.0, 'text': 'F₂'},
          insight:
              'Focus at (+1, 0). Confocal means same foci.',
        ),
        // Origin
        const DiagramElement(
          id: 'origin',
          type: ElementType.point,
          properties: {'x': 150.0, 'y': 150.0, 'text': 'O'},
        ),
        // Labels
        const DiagramElement(
          id: 'label_a_ell',
          type: ElementType.label,
          properties: {
            'x': 230.0,
            'y': 145.0,
            'text': 'a=2',
            'isValue': true,
          },
          group: 'values',
          insight: 'Semi-major axis of ellipse = 2.',
        ),
        const DiagramElement(
          id: 'label_b_ell',
          type: ElementType.label,
          properties: {
            'x': 155.0,
            'y': 80.0,
            'text': 'b=√3',
            'isValue': true,
          },
          group: 'values',
          insight: 'Semi-minor axis of ellipse = √3.',
        ),
        const DiagramElement(
          id: 'label_trans',
          type: ElementType.label,
          properties: {
            'x': 150.0,
            'y': 30.0,
            'text': '2a_h = 2sinθ',
            'isValue': true,
          },
          group: 'values',
          insight:
              'Transverse axis of hyperbola = 2 sin θ, so a_h = sin θ.',
        ),
      ],
    ),
    options: [
      'x²cosec²θ − y²sec²θ = 1',
      'x²sec²θ − y²cosec²θ = 1',
      'x²sin²θ − y²cos²θ = 1',
      'x²cos²θ − y²sin²θ = 1',
    ],
    correctIndex: 0,
    explanation:
        'Step 1: Ellipse 3x²+4y²=12 → x²/4 + y²/3 = 1. Here a²=4, b²=3.\n'
        'Step 2: c² = a²−b² = 4−3 = 1, so c = 1. Foci at (±1, 0).\n'
        'Step 3: Hyperbola is confocal → same foci at (±1, 0), so c_h = 1.\n'
        'Step 4: Transverse axis = 2sin θ → a_h = sin θ → a_h² = sin²θ.\n'
        'Step 5: b_h² = c_h² − a_h² = 1 − sin²θ = cos²θ.\n'
        'Step 6: Hyperbola: x²/sin²θ − y²/cos²θ = 1 → x²cosec²θ − y²sec²θ = 1.',
    subject: 'Mathematics',
    topic: 'Coordinate Geometry',
    coreConcept: 'Confocal conics — relationship between ellipse and hyperbola parameters',
    difficulty: Difficulty.hard,
    estimatedSeconds: 120,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake:
        'Students confuse a² and b² relations for hyperbola (b²=c²−a²) vs ellipse (c²=a²−b²).',
    similarQuestionIds: ['jee2007_m_q4'],
    revealSteps: [
      const RevealStep(
        text:
            'From ellipse: a²=4, b²=3, c²=1. Foci at (±1,0). Confocal means c_h = 1 too.',
        highlightIds: ['ellipse', 'focus_f1', 'focus_f2'],
      ),
      const RevealStep(
        text:
            'Hyperbola: a_h = sin θ. Since c_h = 1: b_h² = c² − a² = 1 − sin²θ = cos²θ.',
        highlightIds: ['label_trans', 'label_a_ell'],
        showHints: true,
      ),
      const RevealStep(
        text:
            'Equation: x²/sin²θ − y²/cos²θ = 1 → x²cosec²θ − y²sec²θ = 1.',
        highlightIds: ['origin', 'x_axis'],
        showHints: true,
      ),
    ],
  ),

  // ─── MATH: Regular hexagon vectors (Q12 from 2007 Math) ──────

  QuestionData(
    id: 'jee2007_m_q12',
    text:
        '[JEE 2007] Let PQ, QR, RS, ST, TU, UP represent sides of a regular hexagon. Then PQ × (RS + ST) ≠ 0. Is this true? And is PQ × RS = 0?',
    diagram: DiagramData(
      id: 'diag_hexagon_vec',
      type: DiagramType.geometry,
      width: 300,
      height: 300,
      title: 'Regular Hexagon Vectors — JEE 2007',
      elements: [
        // Hexagon vertices
        DiagramElement(
          id: 'hex_P',
          type: ElementType.point,
          properties: {
            'x': 150.0 + 100 * math.cos(0),
            'y': 150.0 - 100 * math.sin(0),
            'text': 'P',
          },
          insight: 'Vertex P. PQ is a side vector of the hexagon.',
        ),
        DiagramElement(
          id: 'hex_Q',
          type: ElementType.point,
          properties: {
            'x': 150.0 + 100 * math.cos(math.pi / 3),
            'y': 150.0 - 100 * math.sin(math.pi / 3),
            'text': 'Q',
          },
        ),
        DiagramElement(
          id: 'hex_R',
          type: ElementType.point,
          properties: {
            'x': 150.0 + 100 * math.cos(2 * math.pi / 3),
            'y': 150.0 - 100 * math.sin(2 * math.pi / 3),
            'text': 'R',
          },
          insight: 'RS is parallel to PQ (opposite sides of hexagon).',
        ),
        DiagramElement(
          id: 'hex_S',
          type: ElementType.point,
          properties: {
            'x': 150.0 + 100 * math.cos(math.pi),
            'y': 150.0 - 100 * math.sin(math.pi),
            'text': 'S',
          },
        ),
        DiagramElement(
          id: 'hex_T',
          type: ElementType.point,
          properties: {
            'x': 150.0 + 100 * math.cos(4 * math.pi / 3),
            'y': 150.0 - 100 * math.sin(4 * math.pi / 3),
            'text': 'T',
          },
          insight:
              'ST is NOT parallel to PQ — they make 60° angle.',
        ),
        DiagramElement(
          id: 'hex_U',
          type: ElementType.point,
          properties: {
            'x': 150.0 + 100 * math.cos(5 * math.pi / 3),
            'y': 150.0 - 100 * math.sin(5 * math.pi / 3),
            'text': 'U',
          },
        ),
        // Sides
        DiagramElement(
          id: 'side_PQ',
          type: ElementType.line,
          properties: {
            'fromX': 150.0 + 100 * math.cos(0),
            'fromY': 150.0 - 100 * math.sin(0),
            'toX': 150.0 + 100 * math.cos(math.pi / 3),
            'toY': 150.0 - 100 * math.sin(math.pi / 3),
          },
          insight: 'Side PQ — the reference vector.',
        ),
        DiagramElement(
          id: 'side_QR',
          type: ElementType.line,
          properties: {
            'fromX': 150.0 + 100 * math.cos(math.pi / 3),
            'fromY': 150.0 - 100 * math.sin(math.pi / 3),
            'toX': 150.0 + 100 * math.cos(2 * math.pi / 3),
            'toY': 150.0 - 100 * math.sin(2 * math.pi / 3),
          },
        ),
        DiagramElement(
          id: 'side_RS',
          type: ElementType.line,
          properties: {
            'fromX': 150.0 + 100 * math.cos(2 * math.pi / 3),
            'fromY': 150.0 - 100 * math.sin(2 * math.pi / 3),
            'toX': 150.0 + 100 * math.cos(math.pi),
            'toY': 150.0 - 100 * math.sin(math.pi),
          },
          insight:
              'RS is anti-parallel to PQ → PQ × RS = 0 (cross product of parallel vectors).',
        ),
        DiagramElement(
          id: 'side_ST',
          type: ElementType.line,
          properties: {
            'fromX': 150.0 + 100 * math.cos(math.pi),
            'fromY': 150.0 - 100 * math.sin(math.pi),
            'toX': 150.0 + 100 * math.cos(4 * math.pi / 3),
            'toY': 150.0 - 100 * math.sin(4 * math.pi / 3),
          },
          insight:
              'ST makes 60° with PQ → PQ × ST ≠ 0.',
        ),
        DiagramElement(
          id: 'side_TU',
          type: ElementType.line,
          properties: {
            'fromX': 150.0 + 100 * math.cos(4 * math.pi / 3),
            'fromY': 150.0 - 100 * math.sin(4 * math.pi / 3),
            'toX': 150.0 + 100 * math.cos(5 * math.pi / 3),
            'toY': 150.0 - 100 * math.sin(5 * math.pi / 3),
          },
        ),
        DiagramElement(
          id: 'side_UP',
          type: ElementType.line,
          properties: {
            'fromX': 150.0 + 100 * math.cos(5 * math.pi / 3),
            'fromY': 150.0 - 100 * math.sin(5 * math.pi / 3),
            'toX': 150.0 + 100 * math.cos(0),
            'toY': 150.0 - 100 * math.sin(0),
          },
        ),
      ],
    ),
    options: [
      'S1 True, S2 True, S2 explains S1',
      'S1 True, S2 True, S2 does NOT explain S1',
      'S1 True, S2 False',
      'S1 False, S2 True',
    ],
    correctIndex: 2,
    explanation:
        'Step 1: In a regular hexagon, opposite sides are parallel.\n'
        'Step 2: PQ and RS are opposite sides → RS is anti-parallel to PQ.\n'
        'Step 3: PQ × RS = 0 because cross product of parallel vectors is zero. So S2 says PQ × RS = 0 — TRUE.\n'
        'Wait — re-read: RS goes from R→S. PQ goes from P→Q. In a hexagon with vertices in order, RS is NOT anti-parallel to PQ!\n'
        'Step 4: Actually, in standard hexagon labeling (PQRSTU going around), PQ and RS make 0° only if they are opposite sides. But PQ (side 1) and RS (side 3) are separated by one side. The angle between PQ and RS directions is 120°, not 180°.\n'
        'Step 5: PQ × RS ≠ 0 (angle = 120°). Statement 2 is FALSE.\n'
        'Step 6: RS + ST = RT (triangle law). PQ × RT: angle between PQ and RT is also nonzero → PQ × (RS + ST) ≠ 0. S1 is TRUE.\n'
        'Answer: S1 True, S2 False → (C).',
    subject: 'Mathematics',
    topic: 'Vectors',
    coreConcept: 'Cross product of vectors — angle between hexagon sides',
    difficulty: Difficulty.medium,
    estimatedSeconds: 120,
    frequentlyAsked: true,
    highWeightTopic: false,
    commonMistake:
        'Students assume opposite sides of hexagon are PQ and RS, but in PQRSTU labeling, PQ and TU are opposite. RS is 2 sides away from PQ.',
    similarQuestionIds: ['jee2007_m_q4'],
    revealSteps: [
      const RevealStep(
        text:
            'In hexagon PQRSTU, identify which sides are parallel. PQ (side 1) is parallel to TU (side 4), NOT RS.',
        highlightIds: ['side_PQ', 'side_RS', 'side_TU'],
      ),
      const RevealStep(
        text:
            'PQ and RS make 120° angle → PQ × RS ≠ 0. Statement 2 is FALSE.',
        highlightIds: ['hex_P', 'hex_Q', 'hex_R', 'hex_S'],
        showHints: true,
      ),
      const RevealStep(
        text:
            'RS + ST = RT by triangle law. PQ × RT ≠ 0. Statement 1 is TRUE. Answer: (C).',
        highlightIds: ['side_ST', 'hex_T'],
        showHints: true,
      ),
    ],
  ),

  // ─── MATH: Tangent to circle (Q55 from 2007 Math) ──────

  QuestionData(
    id: 'jee2007_m_q55',
    text:
        '[JEE 2007] Tangents drawn from (17, 7) to the circle x²+y²=169. Statement 1: Tangents are mutually perpendicular. Statement 2: Locus of points with perpendicular tangents is x²+y²=338.',
    diagram: DiagramData(
      id: 'diag_tangent_circle',
      type: DiagramType.geometry,
      width: 300,
      height: 300,
      title: 'Tangent to Circle — JEE 2007',
      elements: [
        // Circle x²+y²=169 (r=13)
        const DiagramElement(
          id: 'circle_main',
          type: ElementType.circle,
          properties: {'x': 150.0, 'y': 150.0, 'radius': 100.0},
          insight:
              'Circle x²+y²=169, center (0,0), radius r=13.',
        ),
        // Director circle
        const DiagramElement(
          id: 'director_circle',
          type: ElementType.circle,
          properties: {'x': 150.0, 'y': 150.0, 'radius': 141.0},
          insight:
              'Director circle x²+y²=2×169=338, radius=13√2≈18.4. Points on this circle give perpendicular tangents.',
        ),
        // Origin
        const DiagramElement(
          id: 'center',
          type: ElementType.point,
          properties: {'x': 150.0, 'y': 150.0, 'text': 'O'},
        ),
        // Point (17,7) — positioned proportionally
        const DiagramElement(
          id: 'point_P',
          type: ElementType.point,
          properties: {'x': 275.0, 'y': 100.0, 'text': 'P(17,7)'},
          insight:
              'External point. Distance from O = √(289+49) = √338 = 13√2. Lies ON the director circle!',
        ),
        // Tangent lines (approximate)
        const DiagramElement(
          id: 'tangent1',
          type: ElementType.line,
          properties: {
            'fromX': 275.0,
            'fromY': 100.0,
            'toX': 200.0,
            'toY': 55.0,
            'isDashed': true,
          },
          insight:
              'First tangent from P to circle. Length = √(OP²−r²) = √(338−169) = 13.',
        ),
        const DiagramElement(
          id: 'tangent2',
          type: ElementType.line,
          properties: {
            'fromX': 275.0,
            'fromY': 100.0,
            'toX': 248.0,
            'toY': 180.0,
            'isDashed': true,
          },
          insight: 'Second tangent from P. Perpendicular to first tangent.',
        ),
        const DiagramElement(
          id: 'label_r',
          type: ElementType.label,
          properties: {
            'x': 200.0,
            'y': 150.0,
            'text': 'r=13',
            'isValue': true,
          },
          group: 'values',
        ),
        const DiagramElement(
          id: 'label_dist',
          type: ElementType.label,
          properties: {
            'x': 215.0,
            'y': 120.0,
            'text': 'OP=13√2',
            'isValue': true,
          },
          group: 'values',
        ),
      ],
    ),
    options: [
      'S1 True, S2 True, S2 explains S1',
      'S1 True, S2 True, S2 does NOT explain S1',
      'S1 True, S2 False',
      'S1 False, S2 True',
    ],
    correctIndex: 0,
    explanation:
        'Step 1: Circle x²+y²=169 has center (0,0), radius r=13.\n'
        'Step 2: Point P = (17,7). OP² = 17²+7² = 289+49 = 338.\n'
        'Step 3: Director circle = locus of points from which tangents are perpendicular = x²+y²=2r² = 2×169 = 338.\n'
        'Step 4: Since OP² = 338 = 2r², point P lies ON the director circle.\n'
        'Step 5: Therefore tangents from P are mutually perpendicular → S1 is TRUE.\n'
        'Step 6: S2 states the director circle equation x²+y²=338 → TRUE.\n'
        'Step 7: S2 directly explains S1 (P is on director circle → tangents are perpendicular).\n'
        'Answer: (A) S1 True, S2 True, S2 correctly explains S1.',
    subject: 'Mathematics',
    topic: 'Coordinate Geometry',
    coreConcept: 'Director circle — perpendicular tangents from external point',
    difficulty: Difficulty.medium,
    estimatedSeconds: 90,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake:
        'Students don\'t know the director circle concept. For x²+y²=r², the director circle is x²+y²=2r².',
    similarQuestionIds: ['jee2007_m_q6'],
    revealSteps: [
      const RevealStep(
        text:
            'Director circle: locus of perpendicular tangents = x²+y²=2r². Here 2×169 = 338.',
        highlightIds: ['circle_main', 'director_circle'],
      ),
      const RevealStep(
        text:
            'Check: OP² = 17²+7² = 338 = 2r². P lies ON director circle → tangents ⊥.',
        highlightIds: ['point_P', 'label_dist'],
        showHints: true,
      ),
      const RevealStep(
        text:
            'S1 True, S2 True, and S2 explains S1. Answer: (A).',
        highlightIds: ['tangent1', 'tangent2'],
        showHints: true,
      ),
    ],
  ),
];
