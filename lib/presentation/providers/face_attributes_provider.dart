import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/data/services/camera_service.dart';
import 'package:emotion_sense/services/tflite_face_detection_service.dart';
import 'package:emotion_sense/services/tflite_emotion_service.dart';
import 'package:emotion_sense/services/inference_service.dart';
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

/// Provider that connects Camera -> TFLite face detection -> TFLite emotion/age/gender inference.
/// 100% TFLite, no Google ML Kit dependency.
class FaceAttributesProvider extends ChangeNotifier {
  FaceAttributesProvider(
    this._camera, {
    TFLiteFaceDetectionService? faceDetector,
    TFLiteEmotionService? emotionService,
    InferenceService? attributeService,
  })  : _faceDetector = faceDetector ?? TFLiteFaceDetectionService(),
        _emotionService = emotionService ?? TFLiteEmotionService(),
        _attributeService = attributeService ?? InferenceService();

  final CameraService _camera;
  final TFLiteFaceDetectionService _faceDetector;
  final TFLiteEmotionService _emotionService;
  final InferenceService _attributeService;

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
    // Initialize all TFLite services once (avoid reloading models repeatedly)
    if (!kIsWeb) {
      if (!_faceDetector.isInitialized) {
        // Determine if we're using front or back camera
        final isFrontCamera = _camera.controller?.description.lensDirection ==
            CameraLensDirection.front;
        await _faceDetector.initialize(isFrontCamera: isFrontCamera);
      }
      if (!_emotionService.isInitialized) {
        await _emotionService.initialize();
      }
      if (!_attributeService.isInitialized) {
        await _attributeService.initialize();
      }
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
    _faceDetector.close();
    _emotionService.dispose();
    _attributeService.dispose();
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
      // Step 1: Detect faces using TFLite face detection
      final faces = await _faceDetector.process(image);
      _faces.clear();

      // Process only the largest face to keep latency predictable
      final iterable = faces.isEmpty
          ? const <DetectedFace>[]
          : <DetectedFace>[
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

        // Step 2: Extract face region and detect emotion using TFLite
        Emotion inferredEmotion = Emotion.neutral;
        double inferredConfidence = 0.5;

        try {
          // Prepare face image for emotion detection (224x224 required by model.tflite)
          if (_rgbBuffer == null || _rgbBuffer!.length != (224 * 224 * 3)) {
            _rgbBuffer = Float32List(224 * 224 * 3);
          }

          final faceInput = yuvToRgbInput(
            image.planes[0].bytes,
            image.planes.length > 1 ? image.planes[1].bytes : null,
            image.planes.length > 2 ? image.planes[2].bytes : null,
            image.width,
            image.height,
            image.planes.length > 1 ? image.planes[1].bytesPerRow : 0,
            image.planes.length > 1 ? image.planes[1].bytesPerPixel ?? 1 : 1,
            bb,
            224,
            224,
            _rgbBuffer,
          );

          final emotionResult =
              await _emotionService.detectEmotion(faceInput, [1, 224, 224, 3]);
          inferredEmotion = emotionResult.emotion;
          inferredConfidence = emotionResult.confidence;
        } catch (e) {
          debugPrint('⚠️ Emotion detection error: $e');
        }

        // Step 3: Detect age/gender/ethnicity using TFLite
        String gender = 'Unknown';
        var ageRange = 'Unknown';
        String? ethnicity = 'Unknown';

        try {
          if (_attributeService.inputShape != null) {
            final shape = _attributeService.inputShape!; // [1,H,W,C]
            final w = shape[2];
            final h = shape[1];

            // Prepare buffer for attribute model input
            final attrBuffer = Float32List(w * h * 3);

            final attrInput = yuvToRgbInput(
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
              attrBuffer,
            );

            final res =
                await _attributeService.estimateAttributes(attrInput, shape);
            ageRange = res.ageRange;
            gender = res.gender;
            ethnicity = res.ethnicity;
          }
        } catch (e) {
          debugPrint('⚠️ Attribute detection error: $e');
        }

        // Compute a simple stable key from quantized rect to smooth confidence
        final key = _rectKey(rect);
        final prev = _emaConfidence[key];
        final smoothed = prev == null
            ? inferredConfidence
            : (prev * (1 - _emaAlpha) + inferredConfidence * _emaAlpha);
        _emaConfidence[key] = smoothed;

        _faces.add(FaceAttributes(
          rect: rect,
          emotion: inferredEmotion,
          confidence: smoothed,
          ageRange: ageRange,
          gender: gender,
          ethnicity: ethnicity,
          rawSmileProb: null, // Not available from TFLite face detection
          leftEyeOpenProb: null,
          rightEyeOpenProb: null,
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
