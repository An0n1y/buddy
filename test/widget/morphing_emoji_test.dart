import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/presentation/widgets/morphing_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MorphingEmoji builds and transitions between emotions',
      (tester) async {
    const widget = MaterialApp(
      home: Scaffold(
        body: MorphingEmoji(
            emotion: Emotion.neutral, size: 100, showFaceCircle: false),
      ),
    );
    await tester.pumpWidget(widget);
    expect(find.byType(MorphingEmoji), findsOneWidget);

    // Update with different emotion and animate
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MorphingEmoji(
            emotion: Emotion.happy, size: 100, showFaceCircle: false),
      ),
    ));
    // let animation run
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.byType(MorphingEmoji), findsOneWidget);
  });
}
