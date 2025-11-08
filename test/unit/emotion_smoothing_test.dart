import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/data/models/emotion_result.dart';
import 'package:emotion_sense/data/models/face_bounds.dart';
import 'package:emotion_sense/data/services/face_analysis_service.dart';
import 'package:emotion_sense/presentation/providers/emotion_provider.dart';
import 'package:emotion_sense/data/services/audio_service.dart';
import 'package:emotion_sense/core/utils/debouncer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// No-op audio for tests to avoid platform channel calls
class _NoopAudio implements IAudioService {
  @override
  Future<void> dispose() async {}

  @override
  Future<void> playForEmotion(Emotion e) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('EMA smoothing reduces jump in face bounds', () {
    final provider = EmotionProvider(
      debouncer: Debouncer(duration: Duration.zero),
      audioService: _NoopAudio(),
    );
    provider.updateSettings(smoothing: 0.5, windowSize: 5);
    const r1 = Rect.fromLTWH(0.1, 0.1, 0.4, 0.4);
    const r2 = Rect.fromLTWH(0.5, 0.5, 0.4, 0.4);
    provider.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.neutral, confidence: 0.9),
      bounds: FaceBounds(rect: r1, timestamp: DateTime.now()),
      imageSize: const Size(0, 0),
      ageGender: null,
    ));
    final afterFirst = provider.smoothedFaceBounds!.rect;
    provider.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.neutral, confidence: 0.9),
      bounds: FaceBounds(rect: r2, timestamp: DateTime.now()),
      imageSize: const Size(0, 0),
      ageGender: null,
    ));
    final afterSecond = provider.smoothedFaceBounds!.rect;
    // The smoothed rect should not jump fully to r2's left/top (EMA applies)
    expect(afterSecond.left, greaterThan(afterFirst.left));
    expect(afterSecond.left, lessThan(r2.left));
  });

  test('Confidence window averages results', () {
    final provider = EmotionProvider(
      debouncer: Debouncer(duration: Duration.zero),
      audioService: _NoopAudio(),
    );
    provider.updateSettings(
        windowSize: 3, threshold: 0.5, sound: false, haptic: false);
    provider.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.happy, confidence: 0.6),
      bounds: null,
      imageSize: const Size(0, 0),
      ageGender: null,
    ));
    provider.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.happy, confidence: 0.9),
      bounds: null,
      imageSize: const Size(0, 0),
      ageGender: null,
    ));
    provider.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.happy, confidence: 0.3),
      bounds: null,
      imageSize: const Size(0, 0),
      ageGender: null,
    ));
    // Average of [0.6,0.9,0.3]=0.6 triggers update
    expect(provider.current, Emotion.happy);
    expect(provider.confidence, closeTo(0.6, 0.0001));
  });
}
