import 'package:flutter/foundation.dart';
import 'package:emotion_sense/data/models/multitask_result.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Mobile/desktop implementation using TensorFlow Lite model for age, gender, and ethnicity detection.
/// Loads and runs the age_gender_ethnicity.tflite model for accurate predictions.
class InferenceService {
  InferenceService({
    this.multiModelAsset = 'assets/models/age_gender_ethnicity.tflite',
  });

  final String multiModelAsset;

  bool _initialized = false;
  Interpreter? _interpreter;

  // Age ranges based on typical model output
  static const _ageRanges = [
    '0-12',
    '13-18',
    '19-29',
    '30-39',
    '40-49',
    '50-59',
    '60+'
  ];

  // Gender labels
  static const _genderLabels = ['Male', 'Female'];

  // Ethnicity labels (common categories)
  static const _ethnicityLabels = [
    'White',
    'Black',
    'Asian',
    'Indian',
    'Hispanic'
  ];

  bool get isInitialized => _initialized;

  List<int>? get multiInputShape => _interpreter?.getInputTensor(0).shape;

  Future<void> initialize() async {
    try {
      // Load TFLite model
      _interpreter = await Interpreter.fromAsset(multiModelAsset);
      _initialized = true;

      // Print model info for debugging
      debugPrint('✅ TFLite model loaded successfully');
      debugPrint('Input shape: ${_interpreter?.getInputTensor(0).shape}');
      debugPrint('Input type: ${_interpreter?.getInputTensor(0).type}');
      debugPrint('Output tensors: ${_interpreter?.getOutputTensors().length}');
    } catch (e) {
      debugPrint('❌ Failed to load TFLite model: $e');
      _initialized = false;
    }
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
  }

  /// Run inference on preprocessed face image to estimate age, gender, and ethnicity.
  /// Input should be normalized RGB values [0.0-1.0] in shape [1, H, W, 3]
  Future<AgeGenderEthnicityData> estimateAttributes(
      Float32List input, List<int> shape) async {
    if (!_initialized || _interpreter == null || input.isEmpty) {
      return _fallback();
    }

    try {
      // Reshape input to proper tensor format
      final inputData = [input.buffer.asFloat32List()];

      // Prepare output tensors
      final outputTensors = _interpreter!.getOutputTensors();
      final numOutputs = outputTensors.length;

      // Create output buffers based on model architecture
      Map<int, Object> outputs = {};
      for (int i = 0; i < numOutputs; i++) {
        final outputShape = outputTensors[i].shape;
        final outputSize = outputShape.reduce((a, b) => a * b);
        outputs[i] = Float32List(outputSize);
      }

      // Run inference
      _interpreter!.runForMultipleInputs([inputData], outputs);

      // Parse age (first output)
      final ageOutput = outputs[0] as Float32List;
      final ageLogits = ageOutput.toList();
      final ageIdx = _argmax(ageLogits);
      final ageRange = _ageRanges[ageIdx.clamp(0, _ageRanges.length - 1)];
      final ageConf = _softmax(ageLogits)[ageIdx];

      // Parse gender (second output)
      final genderOutput =
          numOutputs >= 2 ? outputs[1] as Float32List : Float32List(2);
      final genderLogits = genderOutput.toList();
      final genderIdx = _argmax(genderLogits);
      final gender =
          _genderLabels[genderIdx.clamp(0, _genderLabels.length - 1)];
      final genderConf = _softmax(genderLogits)[genderIdx];

      // Parse ethnicity (third output)
      final ethnicityOutput =
          numOutputs >= 3 ? outputs[2] as Float32List : Float32List(5);
      final ethnicityLogits = ethnicityOutput.toList();
      final ethnicityIdx = _argmax(ethnicityLogits);
      final ethnicity =
          _ethnicityLabels[ethnicityIdx.clamp(0, _ethnicityLabels.length - 1)];
      final ethnicityConf = _softmax(ethnicityLogits)[ethnicityIdx];

      // Debug output
      debugPrint(
          '🎯 TFLite Results: Age=$ageRange($ageConf), Gender=$gender($genderConf), Ethnicity=$ethnicity($ethnicityConf)');

      // Only return predictions with reasonable confidence
      return AgeGenderEthnicityData(
        ageRange: ageConf > 0.3 ? ageRange : 'Unknown',
        gender: genderConf > 0.5 ? gender : 'Unknown',
        ethnicity: ethnicityConf > 0.3 ? ethnicity : 'Unknown',
        ageConfidence: ageConf,
        genderConfidence: genderConf,
        ethnicityConfidence: ethnicityConf,
      );
    } catch (e) {
      debugPrint('❌ TFLite inference error: $e');
      return _fallback();
    }
  }

  AgeGenderEthnicityData _fallback() {
    return AgeGenderEthnicityData(
      ageRange: 'Unknown',
      gender: 'Unknown',
      ethnicity: 'Unknown',
      ageConfidence: 0.0,
      genderConfidence: 0.0,
      ethnicityConfidence: 0.0,
    );
  }

  // Helper function to find index of maximum value
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

  // Apply softmax to convert logits to probabilities
  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return [];

    // Find max for numerical stability
    double maxLogit = logits.reduce((a, b) => a > b ? a : b);

    // Compute exp(x - max) for each element
    final expValues = logits.map((x) => exp(x - maxLogit)).toList();
    final sumExp = expValues.reduce((a, b) => a + b);

    // Normalize
    return expValues.map((x) => x / sumExp).toList();
  }

  // Simple exp approximation
  double exp(double x) {
    // Use built-in if available, otherwise approximate
    return _fastExp(x);
  }

  double _fastExp(double x) {
    // Taylor series approximation for exp(x)
    if (x < -10) return 0.0;
    if (x > 10) return 22026.0; // e^10

    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 10; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }
}
