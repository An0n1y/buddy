import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/data/services/camera_service.dart';
import 'package:emotion_sense/services/unified_tflite_service.dart';
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
  final Rect rect;
  final Emotion emotion;
  final double confidence;
  final String ageRange;
  final String gender;
  final String? ethnicity;
  final double? rawSmileProb;
  final double? leftEyeOpenProb;
  final double? rightEyeOpenProb;
}

class FaceAttributesProvider extends ChangeNotifier {
  FaceAttributesProvider(
    this._camera, {
    UnifiedTFLiteService? tfliteService,
  })  : _tfliteService = tfliteService ?? UnifiedTFLiteService();

  final CameraService _camera;
  final UnifiedTFLiteService _tfliteService;

  final List<FaceAttributes> _faces = [];
  List<FaceAttributes> get faces => List.unmodifiable(_faces);

  bool _running = false;
  bool _busy = false;
  int _skip = 0;
  int targetFps = 5;
  int _notifyThrottle = 0;
  int _lastFaceCount = 0;
  final Map<int, double> _emaConfidence = {};
  final double _emaAlpha = 0.4;
  StreamSubscription<CameraImage>? _imageStreamSubscription;

  Future<void> start() async {
    if (_running) return;
    if (!kIsWeb) {
      await _tfliteService.initialize();
    }
    await _camera.startImageStream();
    _running = true;
    await _imageStreamSubscription?.cancel();
    _imageStreamSubscription = _camera.imageStream.listen(_onFrame);
  }

  Future<void> stop() async {
    _running = false;
    await _imageStreamSubscription?.cancel();
    _imageStreamSubscription = null;
    await _camera.stopImageStream();
    _faces.clear();
    _emaConfidence.clear();
  }

  @override
  void dispose() {
    stop();
    _tfliteService.dispose();
    super.dispose();
  }

  Future<void> _onFrame(CameraImage image) async {
    if (!_running) return;

    if (_busy) {
      return;
    }

    final baseSkip = math.max(1, (30 / targetFps).round());
    _skip = (_skip + 1) % baseSkip;
    if (_skip != 0) return;

    _busy = true;
    try {
      final inputBuffer = Float32List(192 * 192 * 3);
      final fullImageRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      final faceInput = yuvToRgbInput(
        image.planes[0].bytes,
        image.planes.length > 1 ? image.planes[1].bytes : null,
        image.planes.length > 2 ? image.planes[2].bytes : null,
        image.width,
        image.height,
        image.planes.length > 1 ? image.planes[1].bytesPerRow : 0,
        image.planes.length > 1 ? image.planes[1].bytesPerPixel ?? 1 : 1,
        fullImageRect,
        192,
        192,
        inputBuffer,
      );

      final faceBoxes = await _tfliteService.detectFaces(
        faceInput,
        image.width,
        image.height,
      );

      _faces.clear();

      if (faceBoxes.isNotEmpty) {
        final largest = faceBoxes.reduce((a, b) =>
            (a.width * a.height) > (b.width * b.height) ? a : b);

        final rect = Rect.fromLTWH(
          (largest.left / image.width).clamp(0.0, 1.0),
          (largest.top / image.height).clamp(0.0, 1.0),
          (largest.width / image.width).clamp(0.0, 1.0),
          (largest.height / image.height).clamp(0.0, 1.0),
        );

        String gender = 'Unknown';
        var ageRange = 'Unknown';
        String? ethnicity = 'Unknown';
        Emotion inferredEmotion = Emotion.neutral;
        double inferredConfidence = 0.5;

        try {
          final attrBuffer = Float32List(224 * 224 * 3);
          final bb = Rect.fromLTWH(
            largest.left,
            largest.top,
            largest.width,
            largest.height,
          );

          final attrInput = yuvToRgbInput(
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
            attrBuffer,
          );

          final attrs = await _tfliteService.predictAttributes(attrInput);
          gender = attrs.gender;
          ageRange = '${attrs.age}';
          ethnicity = attrs.ethnicity;

          final emotionMap = {
            'Happy': Emotion.happy,
            'Sad': Emotion.sad,
            'Neutral': Emotion.neutral,
          };
          inferredEmotion = emotionMap[attrs.emotion] ?? Emotion.neutral;
          inferredConfidence = 0.7;
        } catch (e) {
          debugPrint('Attribute error: $e');
        }

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
          rawSmileProb: null,
          leftEyeOpenProb: null,
          rightEyeOpenProb: null,
        ));
      }

      final changedCount = _faces.length != _lastFaceCount;
      _lastFaceCount = _faces.length;

      _notifyThrottle = (_notifyThrottle + 1) % 2;
      if (_notifyThrottle == 0 || changedCount) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Frame error: $e');
    } finally {
      _busy = false;
    }
  }
}

int _rectKey(Rect r) {
  final l = (r.left * 1000).round();
  final t = (r.top * 1000).round();
  final w = (r.width * 1000).round();
  final h = (r.height * 1000).round();
  return l ^ (t << 8) ^ (w << 16) ^ (h << 24);
}
