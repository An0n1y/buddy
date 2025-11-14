import 'package:flutter/foundation.dart';
import 'package:emotion_sense/data/models/multitask_result.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Mobile/desktop implementation using TensorFlow Lite model for age, gender, and ethnicity detection.
/// Uses single unified model: age_gender_ethnicity.tflite
class InferenceService {
  InferenceService({
    this.modelAsset = 'assets/models/age_gender_ethnicity.tflite',
  });

  final String modelAsset;

  bool _initialized = false;
  Interpreter? _interpreter;

  // Gender labels - INVERTED because model outputs are reversed
  static const _genderLabels = ['Female', 'Male'];

  bool get isInitialized => _initialized;
  List<int>? get inputShape => _interpreter?.getInputTensor(0).shape;

  Future<void> initialize() async {
    try {
      // Load unified age/gender/ethnicity model
      _interpreter = await Interpreter.fromAsset(modelAsset);
      debugPrint('✅ Age/Gender/Ethnicity model loaded successfully');
      debugPrint('Input shape: ${_interpreter?.getInputTensor(0).shape}');

      // This model has multiple outputs (age, gender, ethnicity)
      final numOutputs = _interpreter!.getOutputTensors().length;
      debugPrint('Number of outputs: $numOutputs');
      for (int i = 0; i < numOutputs; i++) {
        debugPrint(
            'Output $i shape: ${_interpreter?.getOutputTensor(i).shape}');
      }

      _initialized = true;
      debugPrint('✅ TFLite model initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to load TFLite model: $e');
      debugPrint('Stack trace: $stackTrace');
      _initialized = false;
      // Don't rethrow - allow app to continue with fallback values
    }
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
  }

  /// Run inference on preprocessed face image to estimate age, gender, and ethnicity.
  /// Input should be normalized RGB values [0.0-1.0] in shape [1, H, W, 3]
  /// The unified model outputs: [age_logits, gender_logits, ethnicity_logits]
  Future<AgeGenderEthnicityData> estimateAttributes(
      Float32List input, List<int> shape) async {
    if (!_initialized || _interpreter == null || input.isEmpty) {
      debugPrint('⚠️ Model not initialized or input empty, using fallback');
      return _fallback();
    }

    try {
      // Prepare input tensor
      final inputData = input.buffer.asFloat32List();

      // Get all output tensors from the unified model
      final outputTensors = _interpreter!.getOutputTensors();

      // This model has 3 outputs: age, gender, ethnicity
      if (outputTensors.length < 2) {
        debugPrint('⚠️ Unexpected number of outputs: ${outputTensors.length}');
        return _fallback();
      }

      // Prepare output buffers
      final ageOutputSize = outputTensors[0].shape.reduce((a, b) => a * b);
      final ageOutput = Float32List(ageOutputSize);

      final genderOutputSize = outputTensors[1].shape.reduce((a, b) => a * b);
      final genderOutput = Float32List(genderOutputSize);

      // Ethnicity output if available
      Float32List? ethnicityOutput;
      if (outputTensors.length >= 3) {
        final ethnicityOutputSize =
            outputTensors[2].shape.reduce((a, b) => a * b);
        ethnicityOutput = Float32List(ethnicityOutputSize);
      }

      // Run inference with multiple outputs
      final outputs = {
        0: ageOutput,
        1: genderOutput,
        if (ethnicityOutput != null) 2: ethnicityOutput,
      };

      _interpreter!.runForMultipleInputs([inputData], outputs);

      // === AGE DETECTION ===
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
      final genderLogits = genderOutput.toList();
      final genderIdx = _argmax(genderLogits);
      final gender =
          _genderLabels[genderIdx.clamp(0, _genderLabels.length - 1)];
      final genderConf = _softmax(genderLogits)[genderIdx];

      // === ETHNICITY DETECTION ===
      String ethnicity = 'Unknown';
      double ethnicityConf = 0.0;

      if (ethnicityOutput != null && ethnicityOutput.isNotEmpty) {
        final ethnicityLogits = ethnicityOutput.toList();
        final ethnicityIdx = _argmax(ethnicityLogits);
        ethnicityConf = _softmax(ethnicityLogits)[ethnicityIdx];

        // Map ethnicity index to labels (adjust based on your model)
        const ethnicityLabels = [
          'Asian',
          'Black',
          'Caucasian',
          'Hispanic',
          'Other'
        ];
        ethnicity =
            ethnicityLabels[ethnicityIdx.clamp(0, ethnicityLabels.length - 1)];
      }

      // Debug output
      debugPrint(
          '🎯 TFLite Results: Age=$ageRange($ageConf), Gender=$gender($genderConf), Ethnicity=$ethnicity($ethnicityConf)');

      // Return predictions with reasonable confidence thresholds
      // Show age if confidence > 0.25, gender if confidence > 0.4, ethnicity if confidence > 0.35
      return AgeGenderEthnicityData(
        ageRange: ageConf > 0.25 ? ageRange : 'Unknown',
        gender: genderConf > 0.4 ? gender : 'Unknown',
        ethnicity: ethnicityConf > 0.35 ? ethnicity : 'Unknown',
        ageConfidence: ageConf,
        genderConfidence: genderConf,
        ethnicityConfidence: ethnicityConf,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ TFLite inference error: $e');
      debugPrint('Stack trace: $stackTrace');
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
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);

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
