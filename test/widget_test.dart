import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diagram_engine/main.dart';

void main() {
  testWidgets('App launches and shows home screen', (tester) async {
    await tester.pumpWidget(const DiagramEngineApp());
    expect(find.text('Diagram Engine'), findsOneWidget);
    expect(find.text('Start Practice (5 Questions)'), findsOneWidget);
  });

  testWidgets('Navigate to question screen', (tester) async {
    await tester.pumpWidget(const DiagramEngineApp());
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Q1 of 5'), findsOneWidget);
  });
}
