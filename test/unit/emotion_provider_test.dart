import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/presentation/providers/emotion_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// The provider updates asynchronously after listening to the stream and
/// passing through a debouncer. Rely on expectLater with matcher + timeout
/// instead of a fixed delay to reduce flakiness.

void main() {
  test('manualOverride sets emotion & confidence above threshold', () async {
    final provider = EmotionProvider();
    addTearDown(provider.dispose);

    expect(provider.current, Emotion.neutral);
    // Disable side effects that rely on platform channels in tests
    provider.updateSettings(sound: false, haptic: false);

    provider.manualOverride(Emotion.happy, confidence: 0.95);

    // Poll until the provider reflects the change or timeout.
    await _waitFor(() => provider.current == Emotion.happy);
    expect(provider.confidence, greaterThanOrEqualTo(0.9));
  });

  test('ignored low confidence result does not change current', () async {
    final provider = EmotionProvider();
    addTearDown(provider.dispose);
    expect(provider.current, Emotion.neutral);

    // Lower than default threshold 0.6
    provider.updateSettings(sound: false, haptic: false);
    provider.manualOverride(Emotion.angry, confidence: 0.4);
    // Give a short moment; should remain neutral.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(provider.current, Emotion.neutral);
  });

  test('changing threshold allows lower confidence updates', () async {
    final provider = EmotionProvider();
    addTearDown(provider.dispose);
    provider.updateSettings(threshold: 0.3, sound: false, haptic: false);
    provider.manualOverride(Emotion.sad, confidence: 0.35);
    await _waitFor(() => provider.current == Emotion.sad);
    expect(provider.confidence, closeTo(0.35, 0.001));
  });
}

Future<void> _waitFor(bool Function() condition,
    {Duration timeout = const Duration(seconds: 2),
    Duration pollInterval = const Duration(milliseconds: 25)}) async {
  final start = DateTime.now();
  while (!condition()) {
    if (DateTime.now().difference(start) > timeout) {
      fail('Condition not met within timeout');
    }
    await Future<void>.delayed(pollInterval);
  }
}
