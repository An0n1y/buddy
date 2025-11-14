import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:emotion_sense/core/constants/emotions.dart';

/// TFLite-based emotion detection service using model.tflite
class TFLiteEmotionService {
  TFLiteEmotionService({
    this.modelAsset = 'assets/models/model.tflite',
  });

  final String modelAsset;
  Interpreter? _interpreter;
  bool _initialized = false;

  // Common emotion labels (adjust based on your model.tflite)
  static const _emotionLabels = [
    'Angry',
    'Disgust',
    'Fear',
    'Happy',
    'Sad',
    'Surprise',
    'Neutral',
  ];

  bool get isInitialized => _initialized;
  List<int>? get inputShape => _interpreter?.getInputTensor(0).shape;

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(modelAsset);
      debugPrint('✅ Emotion model loaded successfully');
      debugPrint('Input shape: ${_interpreter?.getInputTensor(0).shape}');
      debugPrint('Output shape: ${_interpreter?.getOutputTensor(0).shape}');
      _initialized = true;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to load emotion model: $e');
      debugPrint('Stack trace: $stackTrace');
      _initialized = false;
    }
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
  }

  /// Run emotion detection on preprocessed face image
  /// Input should be normalized RGB values [0.0-1.0] in shape [1, H, W, 3]
  Future<EmotionResult> detectEmotion(
      Float32List input, List<int> shape) async {
    if (!_initialized || _interpreter == null || input.isEmpty) {
      debugPrint('⚠️ Emotion model not initialized or input empty');
      return EmotionResult(emotion: Emotion.neutral, confidence: 0.0);
    }

    try {
      final inputData = input.buffer.asFloat32List();

      // Get output size
      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputSize = outputTensor.shape.reduce((a, b) => a * b);
      final output = Float32List(outputSize);

      // Run inference
      _interpreter!.run(inputData, output);

      // Parse emotion predictions
      final emotions = output.toList();
      final emotionIdx = _argmax(emotions);
      final confidence = _softmax(emotions)[emotionIdx];

      // Map to our Emotion enum
      final emotion = _mapToEmotion(emotionIdx);

      debugPrint(
          '🎭 Emotion Results: ${_emotionLabels[emotionIdx]} ($confidence)');

      return EmotionResult(
        emotion: emotion,
        confidence: confidence,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Emotion detection error: $e');
      debugPrint('Stack trace: $stackTrace');
      return EmotionResult(emotion: Emotion.neutral, confidence: 0.0);
    }
  }

  /// Map model output index to our Emotion enum
  Emotion _mapToEmotion(int index) {
    if (index >= _emotionLabels.length) return Emotion.neutral;

    switch (_emotionLabels[index].toLowerCase()) {
      case 'happy':
        return Emotion.happy;
      case 'sad':
        return Emotion.sad;
      case 'angry':
        return Emotion.angry;
      case 'surprise':
        return Emotion.surprised;
      case 'fear':
        return Emotion.sad; // Map fear to sad
      case 'disgust':
        return Emotion.angry; // Map disgust to angry
      case 'neutral':
      default:
        return Emotion.neutral;
    }
  }

  int _argmax(List<double> values) {
    if (values.isEmpty) return 0;
    double maxVal = values[0];
    int maxIdx = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > maxVal) {
        maxVal = values[i];
        maxIdx = i;
      }
    }
    return maxIdx;
  }

  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return [];
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    final expValues = logits.map((x) => _exp(x - maxLogit)).toList();
    final sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((x) => x / sumExp).toList();
  }

  double _exp(double x) {
    if (x < -10) return 0.0;
    if (x > 10) return 22026.0;
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 10; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }
}

/// Emotion detection result
class EmotionResult {
  final Emotion emotion;
  final double confidence;

  EmotionResult({required this.emotion, required this.confidence});
}
