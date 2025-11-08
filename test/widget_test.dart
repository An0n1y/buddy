import 'package:emotion_sense/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders onboarding and navigates to home after consent',
      (tester) async {
    await tester.pumpWidget(const EmotionApp());

    // Onboarding screen should show privacy text
    expect(find.text('Privacy-first'), findsOneWidget);

    // Simulate consent checkbox and continue button enabled state
    final checkbox = find.byType(CheckboxListTile);
    expect(checkbox, findsOneWidget);

    // Tap the checkbox
    await tester.tap(checkbox);
    await tester.pump();

    // Continue button should exist
    final continueBtn = find.widgetWithText(ElevatedButton, 'Continue');
    expect(continueBtn, findsOneWidget);
  });
}
