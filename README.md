# Diagram Engine

Interactive diagram runtime for JEE exam preparation — built with Flutter.

Diagrams are **interactive thinking tools**, not static images. Students can zoom, tap, highlight, toggle layers, and expand to fullscreen — all while keeping the question context visible.

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
│   └── question_data.dart       # Question with diagram + options
├── data/
│   └── mock_questions.dart      # 5 JEE mock questions
├── widgets/
│   ├── diagram_painter.dart     # CustomPainter for all element types
│   ├── diagram_canvas.dart      # InteractiveViewer + hit testing
│   ├── question_panel.dart      # Question text + option tiles
│   ├── fullscreen_diagram.dart  # Fullscreen mode with overlay
│   └── layer_toggle.dart        # Values/Hints/Labels toggle bar
└── screens/
    ├── home_screen.dart         # Landing page with feature cards
    └── question_screen.dart     # Split Focus layout + navigation
```

## Roadmap

- [ ] Phase 1: SVG rendering + zoom/pan + tap highlight (done)
- [ ] Phase 2: Layer toggles + fullscreen expand (done)
- [ ] Phase 3: Drawing layer (vectors, angles, point marking)
- [ ] Phase 4: AI-enhanced diagram parsing
- [ ] Phase 5: Real JEE content integration

## Tech Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Rendering | `CustomPainter` | Full control over interactivity, no SVG parsing overhead |
| Data format | Structured JSON | Enables AI parsing, element-level interaction |
| Hit testing | Geometric (distance/polygon) | Works for all element types without DOM |
| State | `setState` | Simple enough for MVP, upgrade to Riverpod later |
| Platform | Web first | Easy to demo, mobile follows same code |
