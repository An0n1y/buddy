import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/data/services/camera_service.dart';
import 'package:emotion_sense/services/face_detection_service.dart';
import 'package:emotion_sense/services/inference_service.dart';
import 'package:emotion_sense/data/models/emotion_result.dart';
import 'package:emotion_sense/utils/image_preprocess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FaceAttributes {
  FaceAttributes({
    required this.rect,
    required this.emotion,
    required this.confidence,
    required this.ageRange,
    required this.gender,
    this.ethnicity,
    this.rawSmileProb,
    this.leftEyeOpenProb,
    this.rightEyeOpenProb,
  });
  final Rect rect; // normalized [0,1] in image space
  final Emotion emotion;
  final double confidence;
  final String ageRange;
  final String gender;
  final String? ethnicity;
  final double? rawSmileProb;
  final double? leftEyeOpenProb;
  final double? rightEyeOpenProb;
}

/// Provider that connects Camera -> ML Kit detection -> TFLite inference.
class FaceAttributesProvider extends ChangeNotifier {
  FaceAttributesProvider(this._camera,
      {FaceDetectionService? detector, InferenceService? inference})
      : _detector = detector ?? FaceDetectionService(),
        _inference = inference ?? InferenceService();

  final CameraService _camera;
  final FaceDetectionService _detector;
  final InferenceService _inference;

  final List<FaceAttributes> _faces = [];
  List<FaceAttributes> get faces => List.unmodifiable(_faces);

  bool _running = false;
  bool _busy = false;
  int _skip = 0;
  int targetFps = 5; // throttle (reduced to 5 to minimize buffer warnings)
  int _notifyThrottle = 0; // debounce UI updates
  int _lastFaceCount = 0;
  final Map<int, double> _emaConfidence =
      {}; // track smoothed confidence by hash rect
  final double _emaAlpha = 0.4; // smoothing factor (can expose later)
  Float32List? _rgbBuffer; // reusable buffer for RGB preprocessing
  StreamSubscription<CameraImage>? _imageStreamSubscription;

  Future<void> start() async {
    if (_running) return;
    // Always initialize inference for age/gender (ethnicity is optional)
    if (!kIsWeb) {
      await _inference.initialize();
    }
    await _camera.startImageStream();
    _running = true;
    // Cancel existing subscription if any
    await _imageStreamSubscription?.cancel();
    _imageStreamSubscription = _camera.imageStream.listen(_onFrame);
  }

  Future<void> stop() async {
    _running = false;
    await _imageStreamSubscription?.cancel();
    _imageStreamSubscription = null;
    await _camera.stopImageStream();
    // Clear buffers to free memory
    _rgbBuffer = null;
    _faces.clear();
    _emaConfidence.clear();
  }

  @override
  void dispose() {
    stop();
    _detector.close();
    _inference.dispose();
    super.dispose();
  }

  Future<void> _onFrame(CameraImage image) async {
    if (!_running) return;

    // Drop frame immediately if still processing previous frame
    if (_busy) {
      return;
    }

    // Simple decimation from ~30fps -> targetFps
    final baseSkip = math.max(1, (30 / targetFps).round());
    _skip = (_skip + 1) % baseSkip;
    if (_skip != 0) return;

    _busy = true;
    try {
      final faces = await _detector.process(image);
      _faces.clear();
      // Process only the largest face to keep latency predictable
      final iterable = faces.isEmpty
          ? const <dynamic>[]
          : <dynamic>[
              faces.reduce((a, b) =>
                  (a.boundingBox.width * a.boundingBox.height) >=
                          (b.boundingBox.width * b.boundingBox.height)
                      ? a
                      : b)
            ];
      for (final f in iterable) {
        final bb = f.boundingBox;
        final rect = Rect.fromLTWH(
          (bb.left / image.width).clamp(0.0, 1.0),
          (bb.top / image.height).clamp(0.0, 1.0),
          (bb.width / image.width).clamp(0.0, 1.0),
          (bb.height / image.height).clamp(0.0, 1.0),
        );

        // Google ML Kit-based emotion inference (default, no fallbacks to TFLite emotion):
        final s = ((f.smilingProbability ?? 0.0).clamp(0.0, 1.0)).toDouble();
        final le =
            ((f.leftEyeOpenProbability ?? 1.0).clamp(0.0, 1.0)).toDouble();
        final re =
            ((f.rightEyeOpenProbability ?? 1.0).clamp(0.0, 1.0)).toDouble();
        final eyesOpenAvg = (le + re) / 2.0;
        final bothClosed = le < 0.25 && re < 0.25;
        final tilt = (f.headEulerAngleZ ?? 0.0).abs(); // degrees

        // Tunable thresholds
        const happySmile = 0.70;
        const surprisedSmile = 0.20;
        const eyesVeryOpen = 0.85;
        const eyesClosed = 0.25;
        const angrySmile = 0.25;
        const angryTilt = 15.0; // degrees

        Emotion inferredEmotion;
        double inferredConfidence;

        if (s >= happySmile) {
          // Happy
          inferredEmotion = Emotion.happy;
          inferredConfidence = s;
        } else if (s < surprisedSmile &&
            (le > eyesVeryOpen && re > eyesVeryOpen)) {
          // Surprised: not smiling, eyes very open
          inferredEmotion = Emotion.surprised;
          final eyeMin = le < re ? le : re; // avoid generic inference issues
          double eyeBoostRaw = eyeMin - eyesVeryOpen; // can be negative
          if (eyeBoostRaw < 0) eyeBoostRaw = 0;
          if (eyeBoostRaw > 1) eyeBoostRaw = 1;
          double surprisedScore = (1 - s) * 0.6 + eyeBoostRaw * 0.4;
          if (surprisedScore < 0) surprisedScore = 0;
          if (surprisedScore > 1) surprisedScore = 1;
          inferredConfidence = surprisedScore;
        } else if (s <= 0.40 && (le < eyesClosed && re < eyesClosed)) {
          // Sad: low smile, both eyes nearly closed
          inferredEmotion = Emotion.sad;
          inferredConfidence =
              (((1 - s) * 0.5) + ((1 - eyesOpenAvg) * 0.5)).clamp(0.0, 1.0);
        } else if (s <= angrySmile &&
            !bothClosed &&
            (tilt > angryTilt ||
                (eyesOpenAvg >= 0.25 && eyesOpenAvg <= 0.65))) {
          // Angry: low smile, not both closed; either head tilt or eyes in mid-open range (narrowed)
          inferredEmotion = Emotion.angry;
          final eyesMidness =
              (0.5 - (eyesOpenAvg - 0.5).abs()) * 2; // 0..1 peaking at 0.5
          double tiltScore = (tilt / 30.0);
          if (tiltScore < 0) tiltScore = 0;
          if (tiltScore > 1) tiltScore = 1;
          final maxComponent = math.max(eyesMidness, tiltScore);
          double angryRaw = (1 - s) * 0.5 + maxComponent * 0.5;
          if (angryRaw < 0) angryRaw = 0;
          if (angryRaw > 1) angryRaw = 1;
          inferredConfidence = angryRaw;
        } else {
          inferredEmotion = Emotion.neutral;
          double neutralSmile = 1.0 - (s - 0.5).abs() * 2;
          if (neutralSmile < 0) neutralSmile = 0;
          if (neutralSmile > 1) neutralSmile = 1;
          double neutralEyes = (1 - (eyesOpenAvg - 0.5).abs() * 2).toDouble();
          if (neutralEyes < 0) neutralEyes = 0;
          if (neutralEyes > 1) neutralEyes = 1;
          inferredConfidence = neutralSmile * 0.6 + neutralEyes * 0.4;
        }
        final emotion = EmotionResult(
            emotion: inferredEmotion, confidence: inferredConfidence);

        // Multitask (Age/Gender/Ethnicity) preprocessing
        String gender = 'Unknown';
        var ageRange = '25-30';
        String? ethnicity;
        if (_inference.multiInputShape != null) {
          final shape = _inference.multiInputShape!; // [1,H,W,C]
          final w = shape[2];
          final h = shape[1];
          // Prepare or reuse buffer for model input
          if (_rgbBuffer == null || _rgbBuffer!.length != (w * h * 3)) {
            _rgbBuffer = Float32List(w * h * 3);
          }
          final input = yuvToRgbInput(
            image.planes[0].bytes,
            image.planes.length > 1 ? image.planes[1].bytes : null,
            image.planes.length > 2 ? image.planes[2].bytes : null,
            image.width,
            image.height,
            image.planes.length > 1 ? image.planes[1].bytesPerRow : 0,
            image.planes.length > 1 ? image.planes[1].bytesPerPixel ?? 1 : 1,
            bb,
            w,
            h,
            _rgbBuffer,
          );
          final res = await _inference.estimateAttributes(input, shape);
          ageRange = res.ageRange;
          gender = res.gender;
          // Always include ethnicity when estimated
          ethnicity = res.ethnicity;
        }

        // Compute a simple stable key from quantized rect to smooth confidence
        final key = _rectKey(rect);
        final prev = _emaConfidence[key];
        final smoothed = prev == null
            ? emotion.confidence
            : (prev * (1 - _emaAlpha) + emotion.confidence * _emaAlpha);
        _emaConfidence[key] = smoothed;

        _faces.add(FaceAttributes(
          rect: rect,
          emotion: emotion.emotion,
          confidence: smoothed,
          ageRange: ageRange,
          gender: gender,
          ethnicity: ethnicity,
          rawSmileProb: s,
          leftEyeOpenProb: le,
          rightEyeOpenProb: re,
        ));
      }
      final changedCount = _faces.length != _lastFaceCount;
      _lastFaceCount = _faces.length;
      // Debounce: notify every 2 processed frames or when face count changes
      _notifyThrottle = (_notifyThrottle + 1) % 2;
      if (_notifyThrottle == 0 || changedCount) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('FaceAttributes frame error: $e');
    } finally {
      _busy = false;
    }
  }
}

// (Removed inline preprocessing extension in favor of shared utils functions.)
int _rectKey(Rect r) {
  // Quantize to reduce churn: scale to 1000 and pack
  final l = (r.left * 1000).round();
  final t = (r.top * 1000).round();
  final w = (r.width * 1000).round();
  final h = (r.height * 1000).round();
  return l ^ (t << 8) ^ (w << 16) ^ (h << 24);
}
