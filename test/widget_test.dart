import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diagram_engine/main.dart';
import 'package:diagram_engine/data/mock_questions.dart';

void main() {
  testWidgets('App launches and shows home screen', (tester) async {
    await tester.pumpWidget(const DiagramEngineApp());
    expect(find.text('Diagram Engine'), findsOneWidget);
    expect(find.text('Solve with Interactive Diagrams (${mockQuestions.length})'), findsOneWidget);
  });

  testWidgets('Navigate to question screen', (tester) async {
    await tester.pumpWidget(const DiagramEngineApp());
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Q1 of 5'), findsOneWidget);
  });
}
