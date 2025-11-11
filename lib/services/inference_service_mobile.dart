import 'package:flutter/foundation.dart';
import 'package:emotion_sense/data/models/multitask_result.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Mobile/desktop implementation using TensorFlow Lite models for age, gender, and ethnicity detection.
/// Loads separate models: age_gender_ethnicity.tflite (age) and gender_googlenet.tflite (gender)
class InferenceService {
  InferenceService({
    this.ageModelAsset = 'assets/models/age_gender_ethnicity.tflite',
    this.genderModelAsset = 'assets/models/gender_googlenet.tflite',
  });

  final String ageModelAsset;
  final String genderModelAsset;

  bool _initialized = false;
  Interpreter? _ageInterpreter;
  Interpreter? _genderInterpreter;

  // Gender labels
  static const _genderLabels = ['Male', 'Female'];

  bool get isInitialized => _initialized;

  List<int>? get ageInputShape => _ageInterpreter?.getInputTensor(0).shape;
  List<int>? get genderInputShape => _genderInterpreter?.getInputTensor(0).shape;

  Future<void> initialize() async {
    try {
      // Load age detection model
      _ageInterpreter = await Interpreter.fromAsset(ageModelAsset);
      debugPrint('✅ Age model loaded successfully');
      debugPrint('Age input shape: ${_ageInterpreter?.getInputTensor(0).shape}');
      
      // Load gender detection model
      _genderInterpreter = await Interpreter.fromAsset(genderModelAsset);
      debugPrint('✅ Gender model loaded successfully');
      debugPrint('Gender input shape: ${_genderInterpreter?.getInputTensor(0).shape}');
      
      _initialized = true;
    } catch (e) {
      debugPrint('❌ Failed to load TFLite models: $e');
      _initialized = false;
    }
  }

  Future<void> dispose() async {
    _ageInterpreter?.close();
    _ageInterpreter = null;
    _genderInterpreter?.close();
    _genderInterpreter = null;
    _initialized = false;
  }

  /// Run inference on preprocessed face image to estimate age, gender, and ethnicity.
  /// Input should be normalized RGB values [0.0-1.0] in shape [1, H, W, 3]
  Future<AgeGenderEthnicityData> estimateAttributes(
      Float32List input, List<int> shape) async {
    if (!_initialized || _ageInterpreter == null || _genderInterpreter == null || input.isEmpty) {
      return _fallback();
    }

    try {
      // Prepare input tensor for both models
      final inputData = input.buffer.asFloat32List();

      // === AGE DETECTION ===
      final ageOutputTensors = _ageInterpreter!.getOutputTensors();
      final ageOutputSize = ageOutputTensors[0].shape.reduce((a, b) => a * b);
      final ageOutput = Float32List(ageOutputSize);
      
      _ageInterpreter!.run(inputData, ageOutput);
      
      // Parse age predictions (8 classes in this model)
      final ageLogits = ageOutput.toList();
      final ageIdx = _argmax(ageLogits);
      
      // Map model output (0-7) to our age ranges
      String ageRange;
      if (ageIdx == 0) {
        ageRange = '0-12';
      } else if (ageIdx == 1) {
        ageRange = '13-18';
      } else if (ageIdx <= 3) {
        ageRange = '19-29';
      } else if (ageIdx == 4) {
        ageRange = '30-39';
      } else if (ageIdx == 5) {
        ageRange = '40-49';
      } else if (ageIdx == 6) {
        ageRange = '50-59';
      } else {
        ageRange = '60+';
      }
      
      final ageConf = _softmax(ageLogits)[ageIdx];

      // === GENDER DETECTION ===
      final genderOutputTensors = _genderInterpreter!.getOutputTensors();
      final genderOutputSize = genderOutputTensors[0].shape.reduce((a, b) => a * b);
      final genderOutput = Float32List(genderOutputSize);
      
      _genderInterpreter!.run(inputData, genderOutput);
      
      // Parse gender predictions (2 classes: Male, Female)
      final genderLogits = genderOutput.toList();
      final genderIdx = _argmax(genderLogits);
      final gender = _genderLabels[genderIdx.clamp(0, _genderLabels.length - 1)];
      final genderConf = _softmax(genderLogits)[genderIdx];

      // Ethnicity is not available yet (would need a third model)
      const ethnicity = 'Unknown';
      const ethnicityConf = 0.0;

      // Debug output
      debugPrint(
          '🎯 TFLite Results: Age=$ageRange($ageConf), Gender=$gender($genderConf), Ethnicity=$ethnicity');

      // Only return predictions with reasonable confidence
      return AgeGenderEthnicityData(
        ageRange: ageConf > 0.3 ? ageRange : 'Unknown',
        gender: genderConf > 0.5 ? gender : 'Unknown',
        ethnicity: ethnicity,
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
