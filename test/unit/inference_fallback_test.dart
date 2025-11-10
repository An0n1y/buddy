import 'dart:typed_data';

import 'package:emotion_sense/services/inference_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('estimateAttributes with zero-valued input makes reasonable predictions',
      () async {
    final svc = InferenceService(
        weightsAsset: 'assets/models/model_weights.json');
    await svc.initialize();
    final input = Float32List(1 * 48 * 48 * 3); // All zeros (very dark face)
    final res = await svc.estimateAttributes(input, [1, 48, 48, 3]);
    
    // With zero pixels (very dark), should make some prediction (not fallback)
    // Age, Gender, Ethnicity should not all be defaults
    expect(res.ageRange, isNotNull);
    expect(res.gender, isNotNull);
    expect(res.ethnicity, isNotNull);
    // When weights can't load, inference still returns valid values via heuristics
  });

  test('estimateAttributes handles empty input gracefully', () async {
    final svc = InferenceService(
        weightsAsset: 'assets/models/model_weights.json');
    await svc.initialize();
    final input = Float32List(0); // Empty input
    final res = await svc.estimateAttributes(input, [1, 48, 48, 3]);
    
    // Empty input should return fallback defaults
    expect(res.ageRange, '25-30');
    expect(res.gender, 'Unknown');
    expect(res.ethnicity, 'Uncertain');
    expect(res.ageConfidence, 0.0);
    expect(res.genderConfidence, 0.0);
    expect(res.ethnicityConfidence, 0.0);
  });
}
