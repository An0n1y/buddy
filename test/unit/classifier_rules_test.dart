import 'package:flutter_test/flutter_test.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/data/models/emotion_result.dart';
import 'package:emotion_sense/data/models/face_bounds.dart';
import 'package:emotion_sense/data/services/face_analysis_service.dart';
import 'package:emotion_sense/presentation/providers/emotion_provider.dart';
import 'package:emotion_sense/data/services/audio_service.dart';
import 'package:emotion_sense/core/utils/debouncer.dart';
import 'package:flutter/material.dart';

// Synthetic metric tests: we simulate DetectionEvent inputs directly.
// We approximate metrics by crafting events with confidence values reflective of rule thresholds.

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

  test('Surprised classification high mouth open low brow compression proxy',
      () {
    final p = makeProvider();
    // Simulate a high confidence surprised event
    p.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.surprised, confidence: 0.85),
      bounds: FaceBounds(
          rect: const Rect.fromLTWH(0.3, 0.25, 0.4, 0.5),
          timestamp: DateTime.now()),
      imageSize: const Size(10, 10),
      ageGender: null,
    ));
    expect(p.current, Emotion.surprised);
  });

  test('Angry classification high brow compression proxy', () {
    final p = makeProvider();
    p.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.angry, confidence: 0.8),
      bounds: FaceBounds(
          rect: const Rect.fromLTWH(0.3, 0.25, 0.4, 0.5),
          timestamp: DateTime.now()),
      imageSize: const Size(10, 10),
      ageGender: null,
    ));
    expect(p.current, Emotion.angry);
  });

  test('Funny classification motion + mouth open proxy', () {
    final p = makeProvider();
    p.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.funny, confidence: 0.75),
      bounds: FaceBounds(
          rect: const Rect.fromLTWH(0.3, 0.25, 0.4, 0.5),
          timestamp: DateTime.now()),
      imageSize: const Size(10, 10),
      ageGender: null,
    ));
    expect(p.current, Emotion.funny);
  });

  test('Happy classification brightness proxy', () {
    final p = makeProvider();
    p.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.happy, confidence: 0.7),
      bounds: FaceBounds(
          rect: const Rect.fromLTWH(0.3, 0.25, 0.4, 0.5),
          timestamp: DateTime.now()),
      imageSize: const Size(10, 10),
      ageGender: null,
    ));
    expect(p.current, Emotion.happy);
  });

  test('Sad classification mid vs bottom diff proxy', () {
    final p = makeProvider();
    p.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.sad, confidence: 0.65),
      bounds: FaceBounds(
          rect: const Rect.fromLTWH(0.3, 0.25, 0.4, 0.5),
          timestamp: DateTime.now()),
      imageSize: const Size(10, 10),
      ageGender: null,
    ));
    expect(p.current, Emotion.sad);
  });

  test('Neutral classification jitter penalty proxy', () {
    final p = makeProvider();
    p.debugInjectEvent(DetectionEvent(
      emotion: EmotionResult(emotion: Emotion.neutral, confidence: 0.55),
      bounds: FaceBounds(
          rect: const Rect.fromLTWH(0.3, 0.25, 0.4, 0.5),
          timestamp: DateTime.now()),
      imageSize: const Size(10, 10),
      ageGender: null,
    ));
    expect(p.current, Emotion.neutral);
  });
}
