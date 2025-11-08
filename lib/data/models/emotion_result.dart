import 'package:emotion_sense/core/constants/emotions.dart';

class EmotionResult {
  EmotionResult(
      {required this.emotion, required this.confidence, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  final Emotion emotion;
  final double confidence; // 0..1
  final DateTime timestamp;
}
