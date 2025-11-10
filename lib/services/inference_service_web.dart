import 'dart:typed_data';

import 'package:emotion_sense/data/models/multitask_result.dart';

/// Web stub: tflite_flutter (dart:ffi) is not supported on web targets. All calls
/// return conservative defaults so the rest of the UI can function without errors.
class InferenceService {
  InferenceService(
      {this.multiModelAsset = 'assets/models/age_gender_ethnicity.tflite'});

  final String multiModelAsset;

  bool get isInitialized => false;
  List<int>? get multiInputShape => null;

  Future<void> initialize() async {}
  Future<void> dispose() async {}

  Future<AgeGenderEthnicityData> estimateAttributes(
          Float32List input, List<int> shape) async =>
      AgeGenderEthnicityData(
        ageRange: '25-30',
        gender: 'Unknown',
        ethnicity: 'Uncertain',
        ageConfidence: 0.0,
        genderConfidence: 0.0,
        ethnicityConfidence: 0.0,
      );
}
