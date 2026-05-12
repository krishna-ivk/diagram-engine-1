import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diagram_engine/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('App launches and shows home screen', (tester) async {
    await tester.pumpWidget(const DiagramEngineApp());
    expect(find.text('Diagram Engine'), findsOneWidget);
    expect(find.text('Start Foundation Journey'), findsWidgets);
    expect(find.text('Visual Reasoning'), findsOneWidget);
    expect(find.text('Smart Rescue'), findsOneWidget);
  });

  testWidgets('Navigate to question screen', (tester) async {
    await tester.pumpWidget(const DiagramEngineApp());
    final learnerMode = find.text('Learner');
    await tester.scrollUntilVisible(learnerMode, 400);
    await tester.tap(learnerMode);
    await tester.pumpAndSettle();
    final learnerCta =
        find.textContaining('Practice with Interactive Diagrams');
    await tester.scrollUntilVisible(learnerCta, 400);
    await tester.tap(learnerCta);
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
