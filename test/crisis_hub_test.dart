import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindmap_youth/features/crisis_hub/crisis_hub_screen.dart';
import 'package:mindmap_youth/features/exit/calculator_screen.dart';

void main() {
  testWidgets('Crisis Hub shows 988 call and text first', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CrisisHubScreen()));
    expect(find.text('Call 988'), findsOneWidget);
    expect(find.text('Text 988'), findsOneWidget);
    expect(find.text('Text HOME to 741741'), findsOneWidget);
  });

  testWidgets('exit calculator works and long-press returns', (tester) async {
    var returned = false;
    await tester.pumpWidget(MaterialApp(
        home: CalculatorScreen(onReturn: () => returned = true)));
    for (final k in ['1', '2', '+', '3', '=']) {
      await tester.tap(find.widgetWithText(FilledButton, k));
    }
    await tester.pump();
    expect(find.text('15'), findsOneWidget);
    await tester.longPress(find.text('15'));
    expect(returned, isTrue);
  });
}
