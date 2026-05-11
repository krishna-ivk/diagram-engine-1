# Diagram Engine

Diagram Engine is a visual STEM learning system that helps school students build the reasoning skills needed for future competitive exams.

Instead of showing hard JEE questions directly, the app guides students from familiar classroom concepts to advanced problem-solving through interactive diagrams, micro-lessons, prerequisite ladders, smart rescue questions, and revision loops.

The first target user is a Class 7 student aspiring toward JEE-level thinking.

> From Class 7 basics to JEE-level thinking, one visual step at a time.

## Mission

Help school students build visual STEM reasoning from familiar classroom concepts to competitive-exam-level problem solving, without losing confidence.

The mission is not to make Class 7 students solve JEE papers immediately. It is to build the mental bridge that makes JEE-level thinking feel reachable.

## Vision

Become a visual STEM bridge system where every advanced exam question is broken into prerequisite concepts, interactive diagrams, micro-lessons, rescue paths, repair sessions, and revision loops.

The app is not trying to be another question bank. It is a learning engine that converts school-level understanding into future JEE thinking.

## Current Focus

The current product focus is the **Class 7 JEE Foundation Geometry MVP**.

The first complete proof is:

```text
Square
-> central angle
-> regular polygon
-> hexagon
-> octagon
-> simplified JEE-style question
-> original JEE-level question
```

This validates the core promise: a Class 7 student can reach a hard JEE-style idea step by step without dropping off.

## Product Pillars

| Pillar | Meaning |
| --- | --- |
| Visual reasoning | Diagrams are thinking tools, not decorations |
| Foundation journey | Start from Class 7 concepts before JEE-level questions |
| Smart rescue | If the student fails, move backward to a familiar concept |
| Diagnosis and repair | Mock exams expose gaps; repair sessions close them |
| Revision and mastery | Concepts are repeated until confidence and accuracy improve |

## What Exists Now

- Foundation Journey mode for the geometry bridge path.
- Interactive diagram runtime with zoom, pan, tap highlighting, layers, fullscreen, and drawing tools.
- Learner, mock exam, revision, and Foundation Journey practice modes.
- Smart rescue primitives for prerequisite-based fallback questions.
- Per-option why-wrong explanations, reveal steps, concept feedback, and weak-area nudges.
- Content validation for app sample questions, rescue ladders, and journey assets.
- Flutter CI workflow for analyze, tests, and build validation.

## Learning Flow

```text
Foundation Journey
-> Learner Mode
-> Mock Exam
-> Diagnosis
-> Repair Session
-> Revision Loop
-> Mastery
```

The immediate MVP concentrates on the first step: one polished Geometry Foundation Journey from school geometry to a JEE-level regular polygon idea.

## Content Model

Diagrams and learning content are structured data, not static screenshots.

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

- Element-level interactivity, hit testing, and highlighting.
- Layer-based visibility for values, hints, and labels.
- Step-by-step reveal panels tied to diagram elements.
- Future content generation and diagram explanation workflows.

## Architecture

```text
lib/
+-- main.dart
+-- data/                         # In-app question sets
+-- models/                       # Question, diagram, journey, rescue, mastery models
+-- screens/                      # Home, question, foundation journey, revision screens
+-- services/                     # Content loading
+-- widgets/                      # Diagram canvas, painter, question panel, controls

content/
+-- journeys/                     # Content-driven foundation journeys
+-- sample_questions/             # App-ready sample questions and rescue ladders
+-- math/                         # Concept maps
+-- ncert/                        # School concept alignment
+-- rescue_ladders/               # Prerequisite rescue paths

test/
+-- content_validation_test.dart
+-- foundation_journey_test.dart
+-- rescue_flow_test.dart
+-- widget_test.dart
```

## Getting Started

```bash
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
flutter build web
```

In this WSL workspace, Flutter is available at:

```bash
/home/vashista/flutter/bin/flutter
```

## Execution Priorities

1. Stabilize content pipeline and CI.
2. Keep Foundation Journey asset and dependency loading green.
3. Merge and polish post-exam diagnosis after selected-answer tracking is solid.
4. Build one polished Geometry Foundation Journey end-to-end.

Do not expand to algebra, physics, chemistry, or dynamic generation until the first geometry journey works beautifully.
