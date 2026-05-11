import '../models/diagram_data.dart';
import '../models/diagram_element.dart';
import '../models/question_data.dart';

final List<QuestionData> algebricaQuestions = [
  // Area under curve - from algebrica.org/definite-integrals
  QuestionData(
    id: 'alg_int_001',
    text: 'Calculate the area bounded by the curve y = x², the x-axis, and the lines x = 0 and x = 3.',
    diagram: DiagramData(
      id: 'diag_definite_integral_1',
      type: DiagramType.geometry,
      width: 300,
      height: 300,
      title: 'Area under y = x² from x=0 to x=3',
      elements: [
        const DiagramElement(
          id: 'origin',
          type: ElementType.point,
          properties: {'x': 30.0, 'y': 270.0, 'text': 'O'},
        ),
        const DiagramElement(
          id: 'x_axis',
          type: ElementType.line,
          properties: {'fromX': 30.0, 'fromY': 270.0, 'toX': 290.0, 'toY': 270.0},
          interactive: false,
        ),
        const DiagramElement(
          id: 'y_axis',
          type: ElementType.line,
          properties: {'fromX': 30.0, 'fromY': 270.0, 'toX': 30.0, 'toY': 20.0},
          interactive: false,
        ),
        // Parabola curve
        const DiagramElement(
          id: 'curve_1',
          type: ElementType.line,
          properties: {'fromX': 30.0, 'fromY': 270.0, 'toX': 80.0, 'toY': 240.0},
        ),
        const DiagramElement(
          id: 'curve_2',
          type: ElementType.line,
          properties: {'fromX': 80.0, 'fromY': 240.0, 'toX': 130.0, 'toY': 180.0},
        ),
        const DiagramElement(
          id: 'curve_3',
          type: ElementType.line,
          properties: {'fromX': 130.0, 'fromY': 180.0, 'toX': 180.0, 'toY': 90.0},
        ),
        const DiagramElement(
          id: 'curve_4',
          type: ElementType.line,
          properties: {'fromX': 180.0, 'fromY': 90.0, 'toX': 230.0, 'toY': -30.0},
        ),
        // Filled region
        const DiagramElement(
          id: 'region',
          type: ElementType.polygon,
          properties: {
            'vertices': [
              {'x': 30.0, 'y': 270.0},
              {'x': 80.0, 'y': 240.0},
              {'x': 130.0, 'y': 180.0},
              {'x': 180.0, 'y': 90.0},
              {'x': 230.0, 'y': -30.0},
              {'x': 280.0, 'toY': -210.0},
              {'x': 280.0, 'y': 270.0},
            ],
          },
          group: 'hint',
        ),
        const DiagramElement(
          id: 'label_x',
          type: ElementType.label,
          properties: {'x': 280.0, 'y': 290.0, 'text': '3', 'isValue': true},
          group: 'values',
        ),
      ],
    ),
    options: ['9 sq units', '27 sq units', '18 sq units', '13.5 sq units'],
    correctIndex: 0,
    explanation: '∫₀³ x² dx = [x³/3]₀³ = 27/3 = 9 sq units',
    correctReason: 'The antiderivative of x² is x³/3. Evaluating at 3 gives 27/3 = 9, and at 0 gives 0. Subtract to get 9.',
    whyWrongExplanations: {
      1: 'You calculated ∫₀³ x² dx = [x³/3]₀³ = 27 but forgot to divide by the power (3). The correct antiderivative is x³/3, not x³.',
      2: 'You may have confused the integral with just the antiderivative at x=3. Remember: ∫₀³ x² dx = F(3) - F(0), not just F(3).',
      3: 'This is the result of using the trapezoidal rule incorrectly. The exact integral gives 9, not 13.5.',
    },
    commonMistakeTypes: [MistakeType.formulaRecall, MistakeType.substitution],
    subject: 'Mathematics',
    topic: 'Integrals',
    coreConcept: 'Definite integral as area under curve',
    primaryConcept: 'definite_integral',
    difficulty: Difficulty.easy,
    estimatedSeconds: 60,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake: 'Students forget to evaluate at both bounds.',
    similarQuestionIds: [],
    revealSteps: [
      const RevealStep(
        text: 'Set up the definite integral: ∫₀³ x² dx',
        highlightIds: ['curve_1', 'curve_2'],
      ),
      const RevealStep(
        text: 'Find antiderivative: x³/3. Evaluate from 0 to 3',
        highlightIds: ['label_x'],
        showHints: true,
      ),
      const RevealStep(
        text: 'Calculate: (3³/3) - (0³/3) = 27/3 - 0 = 9 sq units',
        highlightIds: ['region'],
      ),
    ],
    solutionSteps: [
      'Step 1: Identify the region bounded by y=x², x-axis, x=0, x=3',
      'Step 2: Set up the definite integral ∫₀³ x² dx',
      'Step 3: Find the antiderivative: x³/3',
      'Step 4: Evaluate at upper bound: 3³/3 = 27/3 = 9',
      'Step 5: Evaluate at lower bound: 0³/3 = 0',
      'Step 6: Subtract: 9 - 0 = 9 sq units',
    ],
  ),

  // Parabola vertex - from algebrica.org
  QuestionData(
    id: 'alg_eq_001',
    text: 'Find the coordinates of the vertex of the parabola y = x² - 4x + 3.',
    diagram: DiagramData(
      id: 'diag_parabola_vertex',
      type: DiagramType.geometry,
      width: 300,
      height: 300,
      title: 'Parabola y = x² - 4x + 3',
      elements: [
        const DiagramElement(
          id: 'origin',
          type: ElementType.point,
          properties: {'x': 30.0, 'y': 270.0, 'text': 'O'},
        ),
        const DiagramElement(
          id: 'x_axis',
          type: ElementType.line,
          properties: {'fromX': 20.0, 'fromY': 150.0, 'toX': 280.0, 'toY': 150.0},
          interactive: false,
        ),
        const DiagramElement(
          id: 'y_axis',
          type: ElementType.line,
          properties: {'fromX': 150.0, 'fromY': 280.0, 'toX': 150.0, 'toY': 20.0},
          interactive: false,
        ),
        // Parabola - vertex at (2, -1)
        const DiagramElement(
          id: 'p1',
          type: ElementType.point,
          properties: {'x': 50.0, 'y': 90.0, 'text': '(0,3)'},
        ),
        const DiagramElement(
          id: 'p2',
          type: ElementType.point,
          properties: {'x': 100.0, 'y': 150.0, 'text': '(1,0)'},
        ),
        const DiagramElement(
          id: 'vertex',
          type: ElementType.point,
          properties: {'x': 150.0, 'y': 165.0, 'text': '(2,-1)'},
          insight: 'Vertex of parabola. Complete the square: x²-4x+3 = (x-2)² - 1',
        ),
        const DiagramElement(
          id: 'p3',
          type: ElementType.point,
          properties: {'x': 200.0, 'y': 150.0, 'text': '(3,0)'},
        ),
        const DiagramElement(
          id: 'p4',
          type: ElementType.point,
          properties: {'x': 250.0, 'y': 90.0, 'text': '(4,3)'},
        ),
        // Parabola curve
        const DiagramElement(
          id: 'curve_left',
          type: ElementType.line,
          properties: {'fromX': 50.0, 'fromY': 90.0, 'toX': 100.0, 'toY': 150.0},
        ),
        const DiagramElement(
          id: 'curve_mid1',
          type: ElementType.line,
          properties: {'fromX': 100.0, 'fromY': 150.0, 'toX': 150.0, 'toY': 165.0},
        ),
        const DiagramElement(
          id: 'curve_mid2',
          type: ElementType.line,
          properties: {'fromX': 150.0, 'fromY': 165.0, 'toX': 200.0, 'toY': 150.0},
        ),
        const DiagramElement(
          id: 'curve_right',
          type: ElementType.line,
          properties: {'fromX': 200.0, 'fromY': 150.0, 'toX': 250.0, 'toY': 90.0},
        ),
        // Axis of symmetry
        const DiagramElement(
          id: 'axis',
          type: ElementType.line,
          properties: {'fromX': 150.0, 'fromY': 20.0, 'toX': 150.0, 'toY': 280.0},
        ),
        const DiagramElement(
          id: 'axis_label',
          type: ElementType.label,
          properties: {'x': 155.0, 'y': 30.0, 'text': 'x = 2'},
          group: 'hint',
        ),
      ],
    ),
    options: ['(2, -1)', '(2, 1)', '(4, -1)', '(0, 3)'],
    correctIndex: 0,
    explanation: 'Using completing the square: x² - 4x + 3 = (x-2)² - 1. Vertex is at (2, -1)',
    subject: 'Mathematics',
    topic: 'Quadratic Equations',
    coreConcept: 'Vertex of parabola',
    difficulty: Difficulty.medium,
    estimatedSeconds: 90,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake: 'Students confuse vertex formula with the constant term.',
    similarQuestionIds: [],
    revealSteps: [
      const RevealStep(
        text: 'Complete the square: x² - 4x + 3 = (x² - 4x + 4) - 4 + 3 = (x-2)² - 1',
        highlightIds: ['vertex'],
      ),
      const RevealStep(
        text: 'Vertex form is (x-h)² + k, where (h,k) is vertex. Here h=2, k=-1',
        highlightIds: ['axis', 'axis_label'],
      ),
      const RevealStep(
        text: 'So the vertex is at (2, -1)',
        highlightIds: ['vertex'],
      ),
    ],
  ),

  // Unit Circle - from algebrica.org
  QuestionData(
    id: 'alg_trig_001',
    text: 'In the unit circle, if cos(θ) = 0.6 and θ is in the first quadrant, find sin(θ).',
    diagram: DiagramData(
      id: 'diag_unit_circle',
      type: DiagramType.geometry,
      width: 300,
      height: 300,
      title: 'Unit Circle - Trigonometric Values',
      elements: [
        const DiagramElement(
          id: 'unit_circle',
          type: ElementType.circle,
          properties: {'x': 150.0, 'y': 150.0, 'radius': 80.0},
        ),
        const DiagramElement(
          id: 'center',
          type: ElementType.point,
          properties: {'x': 150.0, 'y': 150.0, 'text': 'O'},
        ),
        // Point P at (0.6, 0.8)
        const DiagramElement(
          id: 'P',
          type: ElementType.point,
          properties: {'x': 198.0, 'y': 86.0, 'text': 'P'},
          insight: 'Point P(cosθ, sinθ) on the unit circle. Coordinates are (0.6, 0.8)',
        ),
        const DiagramElement(
          id: 'OP',
          type: ElementType.line,
          properties: {'fromX': 150.0, 'fromY': 150.0, 'toX': 198.0, 'toY': 86.0},
        ),
        const DiagramElement(
          id: 'PX',
          type: ElementType.line,
          properties: {'fromX': 198.0, 'fromY': 86.0, 'toX': 198.0, 'toY': 150.0},
        ),
        const DiagramElement(
          id: 'cos_label',
          type: ElementType.label,
          properties: {'x': 175.0, 'y': 130.0, 'text': '0.6', 'isValue': true},
          group: 'values',
        ),
        const DiagramElement(
          id: 'sin_label',
          type: ElementType.label,
          properties: {'x': 210.0, 'y': 100.0, 'text': '0.8', 'isValue': true},
          group: 'values',
        ),
        const DiagramElement(
          id: 'theta',
          type: ElementType.angle,
          properties: {'x': 150.0, 'y': 150.0, 'text': 'θ'},
          group: 'values',
        ),
        const DiagramElement(
          id: 'x_axis',
          type: ElementType.line,
          properties: {'fromX': 50.0, 'fromY': 150.0, 'toX': 250.0, 'toY': 150.0},
          interactive: false,
        ),
        const DiagramElement(
          id: 'y_axis',
          type: ElementType.line,
          properties: {'fromX': 150.0, 'fromY': 50.0, 'toX': 150.0, 'toY': 250.0},
          interactive: false,
        ),
      ],
    ),
    options: ['0.8', '0.6', '0.4', '1.0'],
    correctIndex: 0,
    explanation: 'sin²θ + cos²θ = 1 → sin²θ = 1 - 0.36 = 0.64 → sinθ = 0.8 (positive in Q1)',
    subject: 'Mathematics',
    topic: 'Trigonometry',
    coreConcept: 'Pythagorean identity',
    difficulty: Difficulty.easy,
    estimatedSeconds: 45,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake: 'Forgetting to take the positive root in first quadrant.',
    similarQuestionIds: [],
    revealSteps: [
      const RevealStep(
        text: 'Use the Pythagorean identity: sin²θ + cos²θ = 1',
        highlightIds: ['unit_circle'],
      ),
      const RevealStep(
        text: 'Substitute cosθ = 0.6: sin²θ = 1 - (0.6)² = 1 - 0.36 = 0.64',
        highlightIds: ['cos_label'],
      ),
      const RevealStep(
        text: 'sinθ = √0.64 = 0.8 (positive since θ is in first quadrant)',
        highlightIds: ['sin_label', 'P'],
      ),
    ],
  ),

  // Vector Addition - from algebrica.org
  QuestionData(
    id: 'alg_vec_001',
    text: 'Given vectors a = (3, 4) and b = (1, 2), find the magnitude of a + b.',
    diagram: DiagramData(
      id: 'diag_vector_addition',
      type: DiagramType.geometry,
      width: 300,
      height: 300,
      title: 'Vector Addition',
      elements: [
        const DiagramElement(
          id: 'origin',
          type: ElementType.point,
          properties: {'x': 50.0, 'y': 250.0, 'text': 'O'},
        ),
        // Vector a = (3, 4)
        const DiagramElement(
          id: 'vec_a',
          type: ElementType.vector,
          properties: {'fromX': 50.0, 'fromY': 250.0, 'toX': 140.0, 'toY': 130.0},
          insight: 'Vector a = (3, 4). Magnitude = 5',
        ),
        const DiagramElement(
          id: 'label_a',
          type: ElementType.label,
          properties: {'x': 100.0, 'y': 180.0, 'text': 'a', 'isValue': true},
          group: 'values',
        ),
        // Vector b from tip of a
        const DiagramElement(
          id: 'vec_b',
          type: ElementType.vector,
          properties: {'fromX': 140.0, 'fromY': 130.0, 'toX': 170.0, 'toY': 70.0},
          insight: 'Vector b = (1, 2)',
        ),
        const DiagramElement(
          id: 'label_b',
          type: ElementType.label,
          properties: {'x': 160.0, 'y': 95.0, 'text': 'b', 'isValue': true},
          group: 'values',
        ),
        // Resultant vector
        const DiagramElement(
          id: 'vec_result',
          type: ElementType.vector,
          properties: {'fromX': 50.0, 'fromY': 250.0, 'toX': 170.0, 'toY': 70.0},
          group: 'hint',
          insight: 'a + b = (4, 6), magnitude = √(16+36) = √52',
        ),
        const DiagramElement(
          id: 'label_result',
          type: ElementType.label,
          properties: {'x': 120.0, 'y': 150.0, 'text': 'a + b', 'isHint': true},
          group: 'hint',
        ),
      ],
    ),
    options: ['√52', '5', '7', '√13'],
    correctIndex: 0,
    explanation: 'a + b = (3+1, 4+2) = (4, 6). |a + b| = √(4² + 6²) = √(16+36) = √52',
    subject: 'Mathematics',
    topic: 'Vectors',
    coreConcept: 'Vector addition and magnitude',
    difficulty: Difficulty.medium,
    estimatedSeconds: 60,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake: 'Adding magnitudes instead of component magnitudes.',
    similarQuestionIds: [],
    revealSteps: [
      const RevealStep(
        text: 'Add the vectors component-wise: a + b = (3+1, 4+2) = (4, 6)',
        highlightIds: ['vec_a', 'vec_b'],
      ),
      const RevealStep(
        text: 'Calculate magnitude: |a + b| = √(4² + 6²) = √(16 + 36) = √52',
        highlightIds: ['vec_result'],
      ),
      const RevealStep(
        text: 'The magnitude is √52 ≈ 7.21',
        highlightIds: ['label_result'],
      ),
    ],
  ),

  // Derivative - Slope of Tangent
  QuestionData(
    id: 'alg_deriv_001',
    text: 'Find the slope of the tangent to the curve y = x³ at x = 2.',
    diagram: DiagramData(
      id: 'diag_derivative_tangent',
      type: DiagramType.function,
      width: 320,
      height: 300,
      title: 'Tangent to y = x³ at x = 2',
      elements: [
        const DiagramElement(
          id: 'origin',
          type: ElementType.point,
          properties: {'x': 30.0, 'y': 270.0, 'text': 'O'},
        ),
        const DiagramElement(
          id: 'x_axis',
          type: ElementType.line,
          properties: {'fromX': 30.0, 'fromY': 270.0, 'toX': 300.0, 'toY': 270.0},
          interactive: false,
        ),
        const DiagramElement(
          id: 'y_axis',
          type: ElementType.line,
          properties: {'fromX': 30.0, 'fromY': 270.0, 'toX': 30.0, 'toY': 20.0},
          interactive: false,
        ),
        // Cubic curve points
        const DiagramElement(
          id: 'p1',
          type: ElementType.point,
          properties: {'x': 50.0, 'y': 270.0, 'text': ''},
        ),
        const DiagramElement(
          id: 'p2',
          type: ElementType.point,
          properties: {'x': 80.0, 'y': 260.0, 'text': ''},
        ),
        const DiagramElement(
          id: 'p3',
          type: ElementType.point,
          properties: {'x': 110.0, 'y': 240.0, 'text': ''},
        ),
        const DiagramElement(
          id: 'point_at_2',
          type: ElementType.point,
          properties: {'x': 170.0, 'y': 170.0, 'text': '(2,8)'},
          insight: 'At x=2, y=2³=8. This is the point of tangency.',
        ),
        const DiagramElement(
          id: 'curve_line_1',
          type: ElementType.line,
          properties: {'fromX': 50.0, 'fromY': 270.0, 'toX': 80.0, 'toY': 260.0},
        ),
        const DiagramElement(
          id: 'curve_line_2',
          type: ElementType.line,
          properties: {'fromX': 80.0, 'fromY': 260.0, 'toX': 110.0, 'toY': 240.0},
        ),
        const DiagramElement(
          id: 'curve_line_3',
          type: ElementType.line,
          properties: {'fromX': 110.0, 'fromY': 240.0, 'toX': 140.0, 'toY': 210.0},
        ),
        const DiagramElement(
          id: 'curve_line_4',
          type: ElementType.line,
          properties: {'fromX': 140.0, 'fromY': 210.0, 'toX': 170.0, 'toY': 170.0},
        ),
        // Tangent line with slope 12
        const DiagramElement(
          id: 'tangent',
          type: ElementType.line,
          properties: {'fromX': 70.0, 'fromY': 246.0, 'toX': 220.0, 'toY': 54.0},
          group: 'hint',
          insight: 'Tangent slope = dy/dx = 3x² = 3(2)² = 12',
        ),
        const DiagramElement(
          id: 'slope_label',
          type: ElementType.label,
          properties: {'x': 230.0, 'y': 50.0, 'text': 'm = 12', 'isHint': true},
          group: 'hint',
        ),
      ],
    ),
    options: ['12', '6', '8', '4'],
    correctIndex: 0,
    explanation: 'dy/dx = 3x². At x=2: 3(2)² = 3(4) = 12',
    subject: 'Mathematics',
    topic: 'Derivatives',
    coreConcept: 'Slope of tangent as derivative',
    difficulty: Difficulty.medium,
    estimatedSeconds: 90,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake: 'Forgetting to square the x value.',
    similarQuestionIds: [],
    revealSteps: [
      const RevealStep(
        text: 'Differentiate: dy/dx = 3x²',
        highlightIds: ['curve_line_4'],
      ),
      const RevealStep(
        text: 'Substitute x = 2: dy/dx = 3(2)² = 3 × 4 = 12',
        highlightIds: ['point_at_2'],
      ),
      const RevealStep(
        text: 'The slope of the tangent is 12',
        highlightIds: ['tangent', 'slope_label'],
      ),
    ],
  ),

  // Limit - End Behavior
  QuestionData(
    id: 'alg_limit_001',
    text: 'Find lim(x→∞) (3x² + 2x + 1) / (x² - 4x + 3)',
    diagram: DiagramData(
      id: 'diag_limit_infinity',
      type: DiagramType.function,
      width: 320,
      height: 300,
      title: 'Limit as x → ∞',
      elements: [
        const DiagramElement(
          id: 'origin',
          type: ElementType.point,
          properties: {'x': 30.0, 'y': 270.0, 'text': 'O'},
        ),
        const DiagramElement(
          id: 'x_axis',
          type: ElementType.line,
          properties: {'fromX': 30.0, 'fromY': 270.0, 'toX': 300.0, 'toY': 270.0},
          interactive: false,
        ),
        const DiagramElement(
          id: 'y_axis',
          type: ElementType.line,
          properties: {'fromX': 30.0, 'fromY': 270.0, 'toX': 30.0, 'toY': 20.0},
          interactive: false,
        ),
        // Both curves approaching y=3
        const DiagramElement(
          id: 'numerator_curve',
          type: ElementType.line,
          properties: {'fromX': 50.0, 'fromY': 220.0, 'toX': 150.0, 'toY': 100.0},
          insight: 'Numerator grows as 3x²',
        ),
        const DiagramElement(
          id: 'denominator_curve',
          type: ElementType.line,
          properties: {'fromX': 50.0, 'fromY': 250.0, 'toX': 150.0, 'toY': 150.0},
          insight: 'Denominator grows as x²',
        ),
        const DiagramElement(
          id: 'asymptote',
          type: ElementType.line,
          properties: {'fromX': 40.0, 'fromY': 170.0, 'toX': 290.0, 'toY': 170.0, 'dashed': true},
          group: 'hint',
        ),
        const DiagramElement(
          id: 'limit_label',
          type: ElementType.label,
          properties: {'x': 250.0, 'y': 160.0, 'text': 'y = 3', 'isHint': true},
          group: 'hint',
        ),
        const DiagramElement(
          id: 'arrow_top',
          type: ElementType.label,
          properties: {'x': 280.0, 'y': 50.0, 'text': '∞', 'isValue': true},
        ),
      ],
    ),
    options: ['3', '∞', '0', '1'],
    correctIndex: 0,
    explanation: 'Divide by x²: (3 + 2/x + 1/x²) / (1 - 4/x + 3/x²) → 3/1 = 3 as x→∞',
    subject: 'Mathematics',
    topic: 'Limits',
    coreConcept: 'Limits at infinity',
    difficulty: Difficulty.medium,
    estimatedSeconds: 90,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake: 'Forgetting to divide numerator and denominator by highest power.',
    similarQuestionIds: [],
    revealSteps: [
      const RevealStep(
        text: 'Divide numerator and denominator by x² (highest power)',
        highlightIds: ['numerator_curve', 'denominator_curve'],
      ),
      const RevealStep(
        text: 'lim(x→∞) (3 + 2/x + 1/x²) / (1 - 4/x + 3/x²)',
        highlightIds: [],
      ),
      const RevealStep(
        text: 'As x→∞, terms with x in denominator → 0. Result = 3/1 = 3',
        highlightIds: ['asymptote', 'limit_label'],
      ),
    ],
  ),

  // Sequences - Arithmetic Progression
  QuestionData(
    id: 'alg_seq_001',
    text: 'Find the 10th term of the arithmetic sequence: 5, 9, 13, 17, ...',
    diagram: DiagramData(
      id: 'diag_arithmetic_sequence',
      type: DiagramType.numberLine,
      width: 320,
      height: 200,
      title: 'Arithmetic Sequence',
      elements: [
        const DiagramElement(
          id: 'axis',
          type: ElementType.line,
          properties: {'fromX': 20.0, 'fromY': 100.0, 'toX': 300.0, 'toY': 100.0},
          interactive: false,
        ),
        const DiagramElement(
          id: 't1',
          type: ElementType.point,
          properties: {'x': 40.0, 'y': 100.0, 'text': '5'},
        ),
        const DiagramElement(
          id: 't2',
          type: ElementType.point,
          properties: {'x': 70.0, 'y': 100.0, 'text': '9'},
        ),
        const DiagramElement(
          id: 't3',
          type: ElementType.point,
          properties: {'x': 100.0, 'y': 100.0, 'text': '13'},
        ),
        const DiagramElement(
          id: 't4',
          type: ElementType.point,
          properties: {'x': 130.0, 'y': 100.0, 'text': '17'},
        ),
        const DiagramElement(
          id: 'ellipsis',
          type: ElementType.label,
          properties: {'x': 155.0, 'y': 100.0, 'text': '...'},
        ),
        const DiagramElement(
          id: 't10_marker',
          type: ElementType.point,
          properties: {'x': 280.0, 'y': 100.0, 'text': '?'},
          insight: '10th term = a + (n-1)d = 5 + 9(4) = 5 + 36 = 41',
        ),
        const DiagramElement(
          id: 'common_diff',
          type: ElementType.label,
          properties: {'x': 55.0, 'y': 120.0, 'text': 'd=4', 'isValue': true},
        ),
        const DiagramElement(
          id: 'formula',
          type: ElementType.label,
          properties: {'x': 160.0, 'y': 40.0, 'text': 'a₁₀ = 5 + 9×4 = 41', 'isHint': true},
          group: 'hint',
        ),
      ],
    ),
    options: ['41', '38', '45', '36'],
    correctIndex: 0,
    explanation: 'a₁₀ = a + (n-1)d = 5 + 9×4 = 5 + 36 = 41',
    subject: 'Mathematics',
    topic: 'Sequences',
    coreConcept: 'Arithmetic progression',
    difficulty: Difficulty.easy,
    estimatedSeconds: 60,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake: 'Using n instead of (n-1) in the formula.',
    similarQuestionIds: [],
    revealSteps: [
      const RevealStep(
        text: 'Identify first term a = 5 and common difference d = 9 - 5 = 4',
        highlightIds: ['t1', 't2', 'common_diff'],
      ),
      const RevealStep(
        text: 'Use formula: aₙ = a + (n-1)d = 5 + (10-1)×4',
        highlightIds: ['formula'],
      ),
      const RevealStep(
        text: 'a₁₀ = 5 + 9×4 = 5 + 36 = 41',
        highlightIds: ['t10_marker'],
      ),
    ],
  ),

  // Matrices - Determinant
  QuestionData(
    id: 'alg_matrix_001',
    text: 'Find the determinant of the matrix: [3, 2], [1, 4]',
    diagram: DiagramData(
      id: 'diag_matrix_det',
      type: DiagramType.matrix,
      width: 200,
      height: 180,
      title: '2×2 Matrix Determinant',
      elements: [
        const DiagramElement(
          id: 'bracket_left',
          type: ElementType.line,
          properties: {'fromX': 40.0, 'fromY': 30.0, 'toX': 40.0, 'toY': 130.0},
        ),
        const DiagramElement(
          id: 'bracket_right',
          type: ElementType.line,
          properties: {'fromX': 160.0, 'fromY': 30.0, 'toX': 160.0, 'toY': 130.0},
        ),
        const DiagramElement(
          id: 'a11',
          type: ElementType.label,
          properties: {'x': 70.0, 'y': 50.0, 'text': '3'},
        ),
        const DiagramElement(
          id: 'a12',
          type: ElementType.label,
          properties: {'x': 110.0, 'y': 50.0, 'text': '2'},
        ),
        const DiagramElement(
          id: 'a21',
          type: ElementType.label,
          properties: {'x': 70.0, 'y': 90.0, 'text': '1'},
        ),
        const DiagramElement(
          id: 'a22',
          type: ElementType.label,
          properties: {'x': 110.0, 'y': 90.0, 'text': '4'},
        ),
        const DiagramElement(
          id: 'det_formula',
          type: ElementType.label,
          properties: {'x': 70.0, 'y': 140.0, 'text': 'det = 3×4 - 2×1 = 12 - 2 = 10', 'isHint': true},
          group: 'hint',
        ),
        const DiagramElement(
          id: 'diagonal1',
          type: ElementType.line,
          properties: {'fromX': 70.0, 'fromY': 50.0, 'toX': 110.0, 'toY': 90.0},
          group: 'hint',
        ),
        const DiagramElement(
          id: 'diagonal2',
          type: ElementType.line,
          properties: {'fromX': 110.0, 'fromY': 50.0, 'toX': 70.0, 'toY': 90.0},
          group: 'hint',
        ),
      ],
    ),
    options: ['10', '14', '8', '12'],
    correctIndex: 0,
    explanation: 'det = ad - bc = 3×4 - 2×1 = 12 - 2 = 10',
    subject: 'Mathematics',
    topic: 'Matrices',
    coreConcept: 'Determinant of 2×2 matrix',
    difficulty: Difficulty.easy,
    estimatedSeconds: 45,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake: 'Adding instead of subtracting the products.',
    similarQuestionIds: [],
    revealSteps: [
      const RevealStep(
        text: 'For 2×2 matrix [a,b;c,d], det = ad - bc',
        highlightIds: ['bracket_left', 'bracket_right'],
      ),
      const RevealStep(
        text: 'Substitute: 3×4 - 2×1 = 12 - 2',
        highlightIds: ['diagonal1', 'diagonal2'],
      ),
      const RevealStep(
        text: 'det = 10',
        highlightIds: ['det_formula'],
      ),
    ],
  ),

  // Complex Numbers - Argand Diagram
  QuestionData(
    id: 'alg_complex_001',
    text: 'Find the modulus of the complex number z = 3 + 4i.',
    diagram: DiagramData(
      id: 'diag_complex_modulus',
      type: DiagramType.geometry,
      width: 300,
      height: 300,
      title: 'Argand Diagram - |z|',
      elements: [
        const DiagramElement(
          id: 'origin',
          type: ElementType.point,
          properties: {'x': 30.0, 'y': 270.0, 'text': 'O'},
        ),
        const DiagramElement(
          id: 'real_axis',
          type: ElementType.line,
          properties: {'fromX': 30.0, 'fromY': 270.0, 'toX': 280.0, 'toY': 270.0},
          interactive: false,
        ),
        const DiagramElement(
          id: 'imag_axis',
          type: ElementType.line,
          properties: {'fromX': 30.0, 'fromY': 270.0, 'toX': 30.0, 'toY': 20.0},
          interactive: false,
        ),
        const DiagramElement(
          id: 'real_label',
          type: ElementType.label,
          properties: {'x': 270.0, 'y': 285.0, 'text': 'Re'},
        ),
        const DiagramElement(
          id: 'imag_label',
          type: ElementType.label,
          properties: {'x': 15.0, 'y': 25.0, 'text': 'Im'},
        ),
        const DiagramElement(
          id: 'z_point',
          type: ElementType.point,
          properties: {'x': 170.0, 'y': 150.0, 'text': 'z'},
          insight: 'Point (3, 4) in the complex plane',
        ),
        const DiagramElement(
          id: 'real_proj',
          type: ElementType.line,
          properties: {'fromX': 170.0, 'fromY': 270.0, 'toX': 170.0, 'toY': 150.0},
        ),
        const DiagramElement(
          id: 'imag_proj',
          type: ElementType.line,
          properties: {'fromX': 30.0, 'fromY': 150.0, 'toX': 170.0, 'toY': 150.0},
        ),
        const DiagramElement(
          id: 'real_component',
          type: ElementType.label,
          properties: {'x': 170.0, 'y': 285.0, 'text': '3', 'isValue': true},
        ),
        const DiagramElement(
          id: 'imag_component',
          type: ElementType.label,
          properties: {'x': 10.0, 'y': 150.0, 'text': '4i', 'isValue': true},
        ),
        const DiagramElement(
          id: 'modulus_line',
          type: ElementType.vector,
          properties: {'fromX': 30.0, 'fromY': 270.0, 'toX': 170.0, 'toY': 150.0},
          group: 'hint',
          insight: '|z| = √(3² + 4²) = √(9 + 16) = √25 = 5',
        ),
        const DiagramElement(
          id: 'modulus_label',
          type: ElementType.label,
          properties: {'x': 100.0, 'y': 200.0, 'text': '|z| = 5', 'isHint': true},
          group: 'hint',
        ),
      ],
    ),
    options: ['5', '7', '25', '4'],
    correctIndex: 0,
    explanation: '|z| = √(3² + 4²) = √(9 + 16) = √25 = 5',
    subject: 'Mathematics',
    topic: 'Complex Numbers',
    coreConcept: 'Modulus of complex number',
    difficulty: Difficulty.easy,
    estimatedSeconds: 45,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake: 'Forgetting to square and add both components.',
    similarQuestionIds: [],
    revealSteps: [
      const RevealStep(
        text: 'z = 3 + 4i has real part 3 and imaginary part 4',
        highlightIds: ['real_component', 'imag_component'],
      ),
      const RevealStep(
        text: '|z| = √(Re² + Im²) = √(3² + 4²) = √(9 + 16)',
        highlightIds: ['modulus_line'],
      ),
      const RevealStep(
        text: '|z| = √25 = 5',
        highlightIds: ['modulus_label', 'z_point'],
      ),
    ],
  ),

  // Logarithms - Properties
  QuestionData(
    id: 'alg_log_001',
    text: 'Simplify: log₂(8) + log₂(4)',
    diagram: DiagramData(
      id: 'diag_logarithm',
      type: DiagramType.numberLine,
      width: 300,
      height: 180,
      title: 'Logarithm Addition',
      elements: [
        const DiagramElement(
          id: 'term1',
          type: ElementType.label,
          properties: {'x': 50.0, 'y': 60.0, 'text': 'log₂(8)'},
        ),
        const DiagramElement(
          id: 'plus',
          type: ElementType.label,
          properties: {'x': 120.0, 'y': 60.0, 'text': '+'},
        ),
        const DiagramElement(
          id: 'term2',
          type: ElementType.label,
          properties: {'x': 140.0, 'y': 60.0, 'text': 'log₂(4)'},
        ),
        const DiagramElement(
          id: 'equals',
          type: ElementType.label,
          properties: {'x': 190.0, 'y': 60.0, 'text': '='},
        ),
        const DiagramElement(
          id: 'result',
          type: ElementType.label,
          properties: {'x': 220.0, 'y': 60.0, 'text': '?', 'isValue': true},
        ),
        const DiagramElement(
          id: 'tree_diagram',
          type: ElementType.point,
          properties: {'x': 80.0, 'y': 120.0, 'text': '8 = 2³'},
        ),
        const DiagramElement(
          id: 'tree_diagram2',
          type: ElementType.point,
          properties: {'x': 150.0, 'y': 120.0, 'text': '4 = 2²'},
        ),
        const DiagramElement(
          id: 'arrow1',
          type: ElementType.line,
          properties: {'fromX': 80.0, 'fromY': 110.0, 'toX': 80.0, 'toY': 80.0},
        ),
        const DiagramElement(
          id: 'arrow2',
          type: ElementType.line,
          properties: {'fromX': 150.0, 'fromY': 110.0, 'toX': 150.0, 'toY': 80.0},
        ),
        const DiagramElement(
          id: 'explanation',
          type: ElementType.label,
          properties: {'x': 80.0, 'y': 150.0, 'text': '= 3 + 2 = 5', 'isHint': true},
          group: 'hint',
        ),
      ],
    ),
    options: ['5', '32', '4', '12'],
    correctIndex: 0,
    explanation: 'log₂(8) + log₂(4) = log₂(8×4) = log₂(32) = 5',
    subject: 'Mathematics',
    topic: 'Logarithms',
    coreConcept: 'Logarithm product rule',
    difficulty: Difficulty.easy,
    estimatedSeconds: 45,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake: 'Adding the arguments instead of using the product rule.',
    similarQuestionIds: [],
    revealSteps: [
      const RevealStep(
        text: 'Use log(a) + log(b) = log(a×b)',
        highlightIds: ['term1', 'term2', 'plus'],
      ),
      const RevealStep(
        text: 'log₂(8×4) = log₂(32)',
        highlightIds: ['tree_diagram', 'tree_diagram2'],
      ),
      const RevealStep(
        text: 'Since 2⁵ = 32, log₂(32) = 5',
        highlightIds: ['result', 'explanation'],
      ),
    ],
  ),

  // Permutations
  QuestionData(
    id: 'alg_perm_001',
    text: 'How many ways can 3 students be arranged in a row from 5 students?',
    diagram: DiagramData(
      id: 'diag_permutations',
      type: DiagramType.combinatorial,
      width: 300,
      height: 200,
      title: 'Permutations P(5,3)',
      elements: [
        const DiagramElement(
          id: 'students',
          type: ElementType.label,
          properties: {'x': 50.0, 'y': 50.0, 'text': '5 students: A, B, C, D, E'},
        ),
        const DiagramElement(
          id: 'choose',
          type: ElementType.label,
          properties: {'x': 50.0, 'y': 80.0, 'text': 'Choose 3 positions'},
        ),
        const DiagramElement(
          id: 'slot1',
          type: ElementType.label,
          properties: {'x': 60.0, 'y': 120.0, 'text': '_'},
        ),
        const DiagramElement(
          id: 'slot2',
          type: ElementType.label,
          properties: {'x': 110.0, 'y': 120.0, 'text': '_'},
        ),
        const DiagramElement(
          id: 'slot3',
          type: ElementType.label,
          properties: {'x': 160.0, 'y': 120.0, 'text': '_'},
        ),
        const DiagramElement(
          id: 'calc1',
          type: ElementType.label,
          properties: {'x': 50.0, 'y': 160.0, 'text': '5 × 4 × 3 = 60', 'isHint': true},
          group: 'hint',
        ),
        const DiagramElement(
          id: 'formula',
          type: ElementType.label,
          properties: {'x': 180.0, 'y': 50.0, 'text': 'P(5,3) = 5!/(5-3)!', 'isValue': true},
        ),
      ],
    ),
    options: ['60', '10', '125', '6'],
    correctIndex: 0,
    explanation: 'P(n,r) = n!/(n-r)! = 5!/(5-3)! = 120/2 = 60',
    subject: 'Mathematics',
    topic: 'Permutations',
    coreConcept: 'Arrangement counting',
    difficulty: Difficulty.medium,
    estimatedSeconds: 60,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake: 'Confusing with combinations (order doesn\'t matter).',
    similarQuestionIds: [],
    revealSteps: [
      const RevealStep(
        text: 'First position: 5 choices, second: 4, third: 3',
        highlightIds: ['slot1', 'slot2', 'slot3'],
      ),
      const RevealStep(
        text: 'Multiply: 5 × 4 × 3 = 60',
        highlightIds: ['calc1'],
      ),
      const RevealStep(
        text: 'Or use formula: P(5,3) = 5!/(5-3)! = 60',
        highlightIds: ['formula'],
      ),
    ],
  ),

  // Trigonometric Identity
  QuestionData(
    id: 'alg_trig_id_001',
    text: 'Simplify: sin(2θ)',
    diagram: DiagramData(
      id: 'diag_trig_identity',
      type: DiagramType.geometry,
      width: 300,
      height: 250,
      title: 'Double Angle Formula',
      elements: [
        const DiagramElement(
          id: 'triangle',
          type: ElementType.polygon,
          properties: {
            'vertices': [
              {'x': 50.0, 'y': 200.0},
              {'x': 200.0, 'y': 200.0},
              {'x': 200.0, 'y': 80.0},
            ],
          },
        ),
        const DiagramElement(
          id: 'angle_theta',
          type: ElementType.angle,
          properties: {'x': 50.0, 'y': 200.0, 'text': 'θ'},
        ),
        const DiagramElement(
          id: 'angle_2theta',
          type: ElementType.angle,
          properties: {'x': 200.0, 'y': 80.0, 'text': 'θ'},
        ),
        const DiagramElement(
          id: 'hypotenuse',
          type: ElementType.line,
          properties: {'fromX': 50.0, 'fromY': 200.0, 'toX': 200.0, 'toY': 80.0},
        ),
        const DiagramElement(
          id: 'base_label',
          type: ElementType.label,
          properties: {'x': 120.0, 'y': 215.0, 'text': 'adjacent'},
        ),
        const DiagramElement(
          id: 'height_label',
          type: ElementType.label,
          properties: {'x': 210.0, 'y': 140.0, 'text': 'opp'},
        ),
        const DiagramElement(
          id: 'hyp_label',
          type: ElementType.label,
          properties: {'x': 120.0, 'y': 130.0, 'text': 'hyp'},
        ),
        const DiagramElement(
          id: 'formula',
          type: ElementType.label,
          properties: {'x': 80.0, 'y': 40.0, 'text': 'sin(2θ) = 2 sinθ cosθ', 'isHint': true},
          group: 'hint',
        ),
      ],
    ),
    options: ['2 sin θ cos θ', 'sin²θ - cos²θ', '2 sin²θ', 'cos²θ - sin²θ'],
    correctIndex: 0,
    explanation: 'sin(2θ) = 2 sinθ cosθ (double angle formula)',
    subject: 'Mathematics',
    topic: 'Trigonometry',
    coreConcept: 'Double angle identities',
    difficulty: Difficulty.medium,
    estimatedSeconds: 60,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake: 'Confusing with cos(2θ) formula.',
    similarQuestionIds: [],
    revealSteps: [
      const RevealStep(
        text: 'Use the identity: sin(2θ) = sin(θ + θ)',
        highlightIds: ['angle_theta', 'angle_2theta'],
      ),
      const RevealStep(
        text: 'sin(A+B) = sinA cosB + cosA sinB',
        highlightIds: ['formula'],
      ),
      const RevealStep(
        text: 'sin(θ+θ) = sinθ cosθ + cosθ sinθ = 2 sinθ cosθ',
        highlightIds: ['formula'],
      ),
    ],
  ),

  // Probability - Basic
  QuestionData(
    id: 'alg_prob_001',
    text: 'A bag contains 3 red and 2 blue marbles. What is the probability of drawing a red marble?',
    diagram: DiagramData(
      id: 'diag_probability',
      type: DiagramType.combinatorial,
      width: 300,
      height: 200,
      title: 'Basic Probability',
      elements: [
        const DiagramElement(
          id: 'bag',
          type: ElementType.polygon,
          properties: {
            'vertices': [
              {'x': 80.0, 'y': 50.0},
              {'x': 220.0, 'y': 50.0},
              {'x': 240.0, 'y': 150.0},
              {'x': 60.0, 'y': 150.0},
            ],
          },
        ),
        const DiagramElement(
          id: 'red1',
          type: ElementType.circle,
          properties: {'x': 120.0, 'y': 100.0, 'radius': 15.0},
          insight: 'Red marble - 1 of 3 red',
        ),
        const DiagramElement(
          id: 'red2',
          type: ElementType.circle,
          properties: {'x': 150.0, 'y': 110.0, 'radius': 15.0},
          insight: 'Red marble - 1 of 3 red',
        ),
        const DiagramElement(
          id: 'red3',
          type: ElementType.circle,
          properties: {'x': 180.0, 'y': 100.0, 'radius': 15.0},
          insight: 'Red marble - 1 of 3 red',
        ),
        const DiagramElement(
          id: 'blue1',
          type: ElementType.circle,
          properties: {'x': 135.0, 'y': 130.0, 'radius': 15.0},
          insight: 'Blue marble - 1 of 2 blue',
        ),
        const DiagramElement(
          id: 'blue2',
          type: ElementType.circle,
          properties: {'x': 165.0, 'y': 130.0, 'radius': 15.0},
          insight: 'Blue marble - 1 of 2 blue',
        ),
        const DiagramElement(
          id: 'calc',
          type: ElementType.label,
          properties: {'x': 80.0, 'y': 170.0, 'text': 'P(red) = 3/5 = 0.6', 'isHint': true},
          group: 'hint',
        ),
      ],
    ),
    options: ['3/5', '2/5', '1/2', '3/2'],
    correctIndex: 0,
    explanation: 'P(red) = favorable/total = 3/(3+2) = 3/5 = 0.6',
    subject: 'Mathematics',
    topic: 'Probability',
    coreConcept: 'Basic probability calculation',
    difficulty: Difficulty.easy,
    estimatedSeconds: 45,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake: 'Forgetting to add total marbles.',
    similarQuestionIds: [],
    revealSteps: [
      const RevealStep(
        text: 'Total marbles = 3 red + 2 blue = 5',
        highlightIds: ['red1', 'red2', 'red3', 'blue1', 'blue2'],
      ),
      const RevealStep(
        text: 'Favorable outcomes (red) = 3',
        highlightIds: ['red1', 'red2', 'red3'],
      ),
      const RevealStep(
        text: 'P(red) = 3/5 = 0.6',
        highlightIds: ['calc'],
      ),
    ],
  ),

  // Integration by Parts
  QuestionData(
    id: 'alg_int_parts_001',
    text: '∫ x·eˣ dx = ?',
    diagram: DiagramData(
      id: 'diag_integration_by_parts',
      type: DiagramType.function,
      width: 300,
      height: 220,
      title: 'Integration by Parts',
      elements: [
        const DiagramElement(
          id: 'formula1',
          type: ElementType.label,
          properties: {'x': 50.0, 'y': 40.0, 'text': '∫ u dv = uv - ∫ v du'},
        ),
        const DiagramElement(
          id: 'u',
          type: ElementType.label,
          properties: {'x': 50.0, 'y': 80.0, 'text': 'u = x', 'isValue': true},
        ),
        const DiagramElement(
          id: 'dv',
          type: ElementType.label,
          properties: {'x': 150.0, 'y': 80.0, 'text': 'dv = eˣ dx', 'isValue': true},
        ),
        const DiagramElement(
          id: 'du',
          type: ElementType.label,
          properties: {'x': 50.0, 'y': 120.0, 'text': 'du = dx', 'isHint': true},
          group: 'hint',
        ),
        const DiagramElement(
          id: 'v',
          type: ElementType.label,
          properties: {'x': 150.0, 'y': 120.0, 'text': 'v = eˣ', 'isHint': true},
          group: 'hint',
        ),
        const DiagramElement(
          id: 'result',
          type: ElementType.label,
          properties: {'x': 50.0, 'y': 160.0, 'text': '= x·eˣ - eˣ + C', 'isHint': true},
          group: 'hint',
        ),
        const DiagramElement(
          id: 'arrow1',
          type: ElementType.line,
          properties: {'fromX': 90.0, 'fromY': 80.0, 'toX': 90.0, 'toY': 120.0},
        ),
        const DiagramElement(
          id: 'arrow2',
          type: ElementType.line,
          properties: {'fromX': 200.0, 'fromY': 80.0, 'toX': 200.0, 'toY': 120.0},
        ),
      ],
    ),
    options: ['x·eˣ - eˣ + C', 'x·eˣ + eˣ + C', 'eˣ(x-1) + C', 'eˣ(x+1) + C'],
    correctIndex: 0,
    explanation: '∫ x·eˣ dx = x·eˣ - ∫ eˣ dx = x·eˣ - eˣ + C = eˣ(x-1) + C',
    subject: 'Mathematics',
    topic: 'Integrals',
    coreConcept: 'Integration by parts',
    difficulty: Difficulty.hard,
    estimatedSeconds: 120,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake: 'Forgetting to subtract the integral term.',
    similarQuestionIds: [],
    revealSteps: [
      const RevealStep(
        text: 'Choose u = x, dv = eˣ dx (LIATE rule)',
        highlightIds: ['u', 'dv'],
      ),
      const RevealStep(
        text: 'Then du = dx, v = eˣ',
        highlightIds: ['du', 'v'],
      ),
      const RevealStep(
        text: '∫ x·eˣ dx = x·eˣ - ∫ eˣ dx = x·eˣ - eˣ + C',
        highlightIds: ['result'],
      ),
    ],
  ),

  // Quadratic Formula
  QuestionData(
    id: 'alg_quad_001',
    text: 'Solve: x² - 5x + 6 = 0',
    diagram: DiagramData(
      id: 'diag_quadratic',
      type: DiagramType.geometry,
      width: 300,
      height: 250,
      title: 'Quadratic Formula',
      elements: [
        const DiagramElement(
          id: 'parabola',
          type: ElementType.polygon,
          properties: {
            'vertices': [
              {'x': 50.0, 'y': 200.0},
              {'x': 100.0, 'y': 150.0},
              {'x': 150.0, 'y': 50.0},
              {'x': 200.0, 'y': 150.0},
              {'x': 250.0, 'y': 200.0},
            ],
          },
        ),
        const DiagramElement(
          id: 'root1',
          type: ElementType.point,
          properties: {'x': 100.0, 'y': 200.0, 'text': 'x=2'},
        ),
        const DiagramElement(
          id: 'root2',
          type: ElementType.point,
          properties: {'x': 200.0, 'y': 200.0, 'text': 'x=3'},
        ),
        const DiagramElement(
          id: 'axis',
          type: ElementType.line,
          properties: {'fromX': 150.0, 'fromY': 30.0, 'toX': 150.0, 'toY': 220.0, 'dashed': true},
        ),
        const DiagramElement(
          id: 'formula',
          type: ElementType.label,
          properties: {'x': 80.0, 'y': 230.0, 'text': 'x = (5 ± √1)/2 = 2, 3', 'isHint': true},
          group: 'hint',
        ),
      ],
    ),
    options: ['x = 2 or 3', 'x = 1 or 6', 'x = -2 or -3', 'x = 1 or 5'],
    correctIndex: 0,
    explanation: 'x = [5 ± √(25-24)]/2 = (5 ± 1)/2 = 2 or 3',
    subject: 'Mathematics',
    topic: 'Quadratic Equations',
    coreConcept: 'Quadratic formula',
    difficulty: Difficulty.easy,
    estimatedSeconds: 60,
    frequentlyAsked: true,
    highWeightTopic: true,
    commonMistake: 'Sign errors in the formula.',
    similarQuestionIds: [],
    revealSteps: [
      const RevealStep(
        text: 'Use quadratic formula: x = [-b ± √(b²-4ac)]/2a',
        highlightIds: ['parabola'],
      ),
      const RevealStep(
        text: 'a=1, b=-5, c=6. Discriminant = 25 - 24 = 1',
        highlightIds: ['formula'],
      ),
      const RevealStep(
        text: 'x = (5 ± 1)/2 = 2 or 3',
        highlightIds: ['root1', 'root2'],
      ),
    ],
  ),
];