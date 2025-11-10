import 'package:emotion_sense/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App initializes with providers',
      (tester) async {
    await tester.pumpWidget(const EmotionApp());
    await tester.pump(); // Single pump, don't settle (camera init ongoing)

    // App should build without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
