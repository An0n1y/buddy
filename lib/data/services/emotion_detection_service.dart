import 'dart:async';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/data/models/emotion_result.dart';

/// Mock/manual detection service: emits results based on manual overrides.
class EmotionDetectionService {
  final _controller = StreamController<EmotionResult>.broadcast();
  Stream<EmotionResult> get stream => _controller.stream;

  void setManual(Emotion emotion, {double confidence = 0.9}) {
    _controller.add(EmotionResult(emotion: emotion, confidence: confidence));
  }

  Future<void> start() async {}
  Future<void> stop() async {}
  Future<void> dispose() async {
    await _controller.close();
  }
}
