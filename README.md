# Diagram Engine

**Interactive diagram-first STEM mastery platform** — built with Flutter.

## Vision

Every STEM question should be an **interactive learning object**, not a static image. The goal is to build a platform where:

1. **Diagrams teach** — animated, progressive reveals show *how* to solve, not just the answer
2. **Mistakes become learning opportunities** — explain *why* an answer is wrong, not just that it's incorrect
3. **Two distinct modes** serve different purposes:
   - **Learner Mode**: Teaches, forgives, adapts. Shows hints, reveals steps, explains concepts, offers rescue questions on wrong answers.
   - **Mock Exam Mode**: Measures, times, exposes gaps. No hints, shows timer, produces diagnostic report with learning prescription.

### Core Principle
> *Mock Exam exposes gaps; Learner Mode closes them.*

This creates a virtuous cycle: exam reveals what you don't know → learner mode teaches it → spaced revision keeps it → next exam confirms mastery.

## Key Features

### Adaptive Learning Intelligence
- **Concept Graph**: Maps 15+ math/physics concepts with prerequisites and relationships
- **Mastery Tracker**: Weighted scoring by difficulty, recency, and mistake patterns
- **Recommendation Engine**: Suggests what to practice based on weak areas
- **Rescue System**: On wrong answer, offers easier questions to rebuild confidence

### Schema-First Design
Every question includes:
- `whyWrongExplanations`: Per-option explanations for why each wrong answer is incorrect
- `solutionSteps`: Visual step-by-step breakdown with numbered progression
- `mistakePatterns`: Common errors students make (e.g., "Forgot to apply chain rule")
- `prerequisites`: Concepts needed before attempting this question

### Practice Modes
| Feature | Learner | Mock Exam | Revision |
|---------|---------|------------|----------|
| Hints | ✅ | ❌ | ❌ |
| Reveal Steps | ✅ | ❌ | ❌ |
| Concept Explanation | ✅ | ❌ | ✅ |
| Timer | ❌ | ✅ | ❌ |
| Spaced Repetition | ❌ | ❌ | ✅ |
| Adaptive Difficulty | ✅ | ❌ | ✅ |

## Why This Matters

Traditional exam prep apps show a question → expect an answer → show correct/incorrect. That's passive.

This platform makes every question **active learning**:
- Animated diagrams draw themselves, showing the logic visually
- Wrong answers teach *why* — "You chose B because you forgot the derivative of e^x is e^x"
- Rescue questions rebuild understanding before moving on
- Post-exam diagnosis tells you exactly which concepts to focus on

---

## Feature Overview

### Split Focus UI
- **Mobile**: Top 45% diagram, bottom 55% question + options
- **Desktop/Wide**: Side-by-side layout
- Student never "leaves" the question context

## Features

### Split Focus UI
- **Mobile**: Top 45% diagram, bottom 55% question + options
- **Desktop/Wide**: Side-by-side layout
- Student never "leaves" the question context

### Interactive Diagrams
- **Zoom & Pan** — smooth `InteractiveViewer` with pinch/scroll support
- **Tap to Highlight** — tap any element (point, line, circle, region) to highlight it
- **Layer Toggles** — show/hide values, hints, and labels independently
- **Fullscreen Expand** — diagram goes fullscreen with floating question overlay

### Structured Data Model
Diagrams are stored as **structured JSON**, not images:

```json
{
  "type": "geometry",
  "elements": [
    {"id": "A", "type": "point", "properties": {"x": 50, "y": 100, "text": "A"}},
    {"id": "AB", "type": "line", "properties": {"fromX": 50, "fromY": 100, "toX": 200, "toY": 100}}
  ]
}
```

This enables:
- Element-level interactivity (tap detection, highlighting)
- Layer-based visibility (values, hints, labels)
- Future AI parsing ("Explain this diagram", "Generate similar question")

### Supported Element Types
- `point` — labeled vertices
- `line` — solid and dashed lines
- `circle` — circles with center + radius
- `arc` — partial arcs with angle control
- `polygon` — filled polygons
- `region` — highlighted areas (e.g., triangle in octagon)
- `angle` — angle markers with labels
- `label` — text annotations (values, hints)
- `vector` — arrows with direction

### Context-Aware Rendering
- **Geometry**: Points, lines, polygons, angles, regions
- **Physics**: Circuit nodes, resistor connections, current labels
- **Chemistry**: Molecular structures (future)
- **Graphs**: Coordinate geometry with axes (future)

## Mock Content
Includes 5 JEE-style questions:
1. Regular octagon area calculation
2. Triangle angle bisector theorem
3. Circle chord and arc ratio
4. Wheatstone bridge circuit
5. Star-delta resistor network

## Getting Started

```bash
# Install Flutter (3.41+)
flutter --version

# Get dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run analyzer
flutter analyze

# Run tests
flutter test
```

## Architecture

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── diagram_element.dart     # Element types + properties
│   ├── diagram_data.dart        # Diagram container model
│   ├── question_data.dart       # Question with whyWrong, solutionSteps, prerequisites
│   ├── practice_mode.dart       # Enum: learner/mockExam/revision + ExamResult
│   ├── rescue_system.dart       # Adaptive difficulty + rescue question paths
│   ├── concept_graph.dart       # 15+ concepts with prerequisites
│   ├── mastery_tracker.dart     # Weighted scoring by difficulty/recency
│   ├── recommendation_engine.dart # Suggests practice based on weak areas
│   └── revision_manager.dart    # Spaced repetition tracking
├── data/
│   ├── mock_questions.dart      # 5 JEE geometry/physics questions
│   └── algebrica_questions.dart # 11 Algebra/Calculus questions with diagrams
├── widgets/
│   ├── diagram_painter.dart     # CustomPainter for all element types
│   ├── diagram_canvas.dart      # InteractiveViewer + hit testing
│   ├── question_panel.dart      # Question text + option tiles
│   ├── fullscreen_diagram.dart  # Fullscreen mode with overlay
│   ├── layer_toggle.dart        # Values/Hints/Labels toggle bar
│   └── reveal_panel.dart        # Shows solution steps + concept explanation
└── screens/
    ├── home_screen.dart         # Landing page with mode selector
    ├── question_screen.dart    # Split Focus layout + mode-based features
    └── topic_revision_screen.dart # Topic-based visual review with animations
```

## Roadmap

### Completed
- ✅ Phase 1: CustomPainter rendering + zoom/pan + tap highlight
- ✅ Phase 2: Layer toggles + fullscreen expand
- ✅ Phase 3: Progressive diagram animations + bounce on answer selection
- ✅ Phase 4: Concept Graph (15+ concepts) + Mastery Tracker + Recommendation Engine
- ✅ Phase 5: Per-option "Why Wrong" explanations + solution steps
- ✅ Phase 6: Practice Mode selector (Learner/MockExam/Revision) with behavior gating

### In Progress
- ⏳ Post-exam diagnosis screen with learning prescription
- ⏳ Rescue question flow on wrong answer (adaptive difficulty)
- ⏳ Exam timer display in Mock Exam mode
- ⏳ Topic revision screen with animated diagrams

### Future
- [ ] AI-enhanced diagram parsing ("Explain this diagram")
- [ ] Question difficulty auto-calibration based on user performance
- [ ] Spaced repetition algorithm (SM-2 variant)
- [ ] Real JEE question integration (100+ questions across topics)

## Tech Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Rendering | `CustomPainter` | Full control over interactivity, no SVG parsing overhead |
| Data format | Structured JSON | Enables AI parsing, element-level interaction |
| Hit testing | Geometric (distance/polygon) | Works for all element types without DOM |
| State | `setState` | Simple enough for MVP, upgrade to Riverpod later |
| Platform | Web first | Easy to demo, mobile follows same code |
