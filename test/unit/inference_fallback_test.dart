import 'dart:typed_data';

import 'package:emotion_sense/services/inference_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'estimateAttributes returns conservative defaults when interpreter missing',
      () async {
    final svc = InferenceService(
        weightsAsset: 'assets/models/missing_weights.json');
    await svc.initialize();
    final input = Float32List(1 * 48 * 48 * 3);
    final res = await svc.estimateAttributes(input, [1, 48, 48, 3]);
    expect(res.ageRange, '25-30');
    expect(res.gender, 'Unknown');
    expect(res.ethnicity, 'Uncertain');
    expect(res.ageConfidence, 0.0);
    expect(res.genderConfidence, 0.0);
    expect(res.ethnicityConfidence, 0.0);
  });

  test('estimateAttributes shape mismatch returns defaults', () async {
    final svc = InferenceService(
        weightsAsset: 'assets/models/missing_weights.json');
    await svc.initialize();
    final input = Float32List(10); // wrong size
    final res = await svc.estimateAttributes(input, [1, 99, 99, 3]);
    expect(res.gender, 'Unknown');
    expect(res.ethnicity, 'Uncertain');
  });
}
