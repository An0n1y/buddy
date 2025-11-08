import 'package:flutter_test/flutter_test.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/data/models/emotion_result.dart';
import 'package:emotion_sense/data/models/face_bounds.dart';
import 'package:emotion_sense/presentation/providers/emotion_provider.dart';
import 'package:emotion_sense/data/services/face_analysis_service.dart';
import 'package:emotion_sense/core/utils/debouncer.dart';
import 'package:emotion_sense/data/services/audio_service.dart';
import 'package:flutter/material.dart';

class _NoAudio implements IAudioService {
  @override
  Future<void> dispose() async {}
  @override
  Future<void> playForEmotion(Emotion e) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  EmotionProvider makeProvider() => EmotionProvider(
        debouncer: Debouncer(duration: Duration.zero),
        audioService: _NoAudio(),
      );

  test('Mouth open just below threshold should not trigger surprised', () {
    final p = makeProvider();
    // Simulate a near-threshold event: confidence low
    p.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.neutral, confidence: 0.4),
      bounds: FaceBounds(
          rect: const Rect.fromLTWH(0.3, 0.25, 0.4, 0.5),
          timestamp: DateTime.now()),
      imageSize: const Size(10, 10),
      ageGender: null,
      mouthOpenMetric: 0.21, // slightly below default 0.22
      browCompression: 0.05,
      energyMetric: 0.2,
    ));
    expect(p.current, isNot(Emotion.surprised));
  });

  test(
      'Mouth open just above threshold can trigger surprised/funny with enough confidence',
      () {
    final p = makeProvider();
    p.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.surprised, confidence: 0.7),
      bounds: FaceBounds(
          rect: const Rect.fromLTWH(0.3, 0.25, 0.4, 0.5),
          timestamp: DateTime.now()),
      imageSize: const Size(10, 10),
      ageGender: null,
      mouthOpenMetric: 0.23, // slightly above default 0.22
      browCompression: 0.05,
      energyMetric: 0.25,
    ));
    expect(p.current, anyOf(Emotion.surprised, Emotion.funny));
  });

  test('Brow compression just below threshold should not trigger angry', () {
    final p = makeProvider();
    p.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.neutral, confidence: 0.45),
      bounds: FaceBounds(
          rect: const Rect.fromLTWH(0.3, 0.25, 0.4, 0.5),
          timestamp: DateTime.now()),
      imageSize: const Size(10, 10),
      ageGender: null,
      browCompression: 0.11, // slightly below default 0.12
      mouthOpenMetric: 0.05,
      energyMetric: 0.1,
    ));
    expect(p.current, isNot(Emotion.angry));
  });

  test('Brow compression just above threshold can trigger angry', () {
    final p = makeProvider();
    p.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.angry, confidence: 0.6),
      bounds: FaceBounds(
          rect: const Rect.fromLTWH(0.3, 0.25, 0.4, 0.5),
          timestamp: DateTime.now()),
      imageSize: const Size(10, 10),
      ageGender: null,
      browCompression: 0.14, // above default 0.12
      mouthOpenMetric: 0.03,
      energyMetric: 0.2,
    ));
    expect(p.current, Emotion.angry);
  });

  test('Energy just below threshold should not trigger funny', () {
    final p = makeProvider();
    p.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.neutral, confidence: 0.45),
      bounds: FaceBounds(
          rect: const Rect.fromLTWH(0.3, 0.25, 0.4, 0.5),
          timestamp: DateTime.now()),
      imageSize: const Size(10, 10),
      ageGender: null,
      energyMetric: 1.19, // slightly below default 1.2
      mouthOpenMetric: 0.22,
      browCompression: 0.05,
    ));
    expect(p.current, isNot(Emotion.funny));
  });

  test('Energy just above threshold can trigger funny with mouth open', () {
    final p = makeProvider();
    p.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.funny, confidence: 0.65),
      bounds: FaceBounds(
          rect: const Rect.fromLTWH(0.3, 0.25, 0.4, 0.5),
          timestamp: DateTime.now()),
      imageSize: const Size(10, 10),
      ageGender: null,
      energyMetric: 1.25,
      mouthOpenMetric: 0.24,
      browCompression: 0.04,
    ));
    expect(p.current, Emotion.funny);
  });
}
