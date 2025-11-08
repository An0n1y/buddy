import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/presentation/providers/emotion_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'EmotionProvider manual override updates current emotion with confidence',
      () async {
    final provider = EmotionProvider();
    addTearDown(provider.dispose);

    // Start neutral
    expect(provider.current, Emotion.neutral);

    // Manual override to happy
    provider.manualOverride(Emotion.happy, confidence: 0.95);

    // Give the stream/debouncer a moment
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(provider.current, Emotion.happy);
    expect(provider.confidence >= 0.9, true);
  });
}
