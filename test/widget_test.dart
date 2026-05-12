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
    expect(find.text('Start Topic Capsule'), findsWidgets);
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

  testWidgets('Navigate to Topic Capsule and load content', (tester) async {
    await tester.pumpWidget(const DiagramEngineApp());
    final topicCapsuleCta = find.text('Start Topic Capsule');
    await tester.ensureVisible(topicCapsuleCta);
    await tester.tap(topicCapsuleCta);
    await tester.pumpAndSettle();

    expect(find.text('Central Angle of a Regular Polygon'), findsOneWidget);
    expect(find.text('Class 7-8'), findsOneWidget);
    expect(find.text('Synopsis'), findsOneWidget);
  });

  testWidgets('Navigate to Foundation Journey and load content',
      (tester) async {
    await tester.pumpWidget(const DiagramEngineApp());
    // Navigate to Foundation Journey through the old flow
    final foundationJourneyMode = find.text('Foundation Journey');
    await tester.scrollUntilVisible(foundationJourneyMode, 400);
    await tester.tap(foundationJourneyMode);
    await tester.pumpAndSettle();
    
    final journeyCta = find.text('Start Journey');
    await tester.ensureVisible(journeyCta);
    await tester.tap(journeyCta);
    await tester.pumpAndSettle();

    expect(find.text('Foundation Journey'), findsWidgets);
    expect(find.text('From Square to JEE Octagon'), findsOneWidget);
    expect(find.text('Familiar: Square Parts'), findsWidgets);
  });
}
