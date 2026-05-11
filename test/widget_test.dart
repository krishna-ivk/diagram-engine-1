import 'package:flutter_test/flutter_test.dart';

import 'package:diagram_engine/main.dart';
import 'package:diagram_engine/data/algebrica_questions.dart';
import 'package:diagram_engine/data/mock_questions.dart';

void main() {
  testWidgets('App launches and shows home screen', (tester) async {
    await tester.pumpWidget(const DiagramEngineApp());
    expect(find.text('Diagram Engine'), findsOneWidget);
    expect(
      find.text(
        'Solve with Interactive Diagrams (${mockQuestions.length + algebricaQuestions.length})',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Navigate to question screen', (tester) async {
    await tester.pumpWidget(const DiagramEngineApp());
    final practiceCta = find.textContaining('Solve with Interactive Diagrams');
    await tester.scrollUntilVisible(practiceCta, 400);
    await tester.tap(practiceCta);
    await tester.pumpAndSettle();
    expect(find.textContaining('Q1 of'), findsOneWidget);
  });

  testWidgets('Navigate to Foundation Journey and load content',
      (tester) async {
    await tester.pumpWidget(const DiagramEngineApp());
    final journeyCta = find.text('Start Journey');
    await tester.ensureVisible(journeyCta);
    await tester.tap(journeyCta);
    await tester.pumpAndSettle();

    expect(find.text('Foundation Journey'), findsWidgets);
    expect(find.text('From Square to JEE Octagon'), findsOneWidget);
    expect(find.text('Familiar: Square Parts'), findsWidgets);
  });
}
