import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/data/models/age_gender_data.dart';
import 'package:emotion_sense/data/models/emotion_result.dart';
import 'package:emotion_sense/data/models/face_bounds.dart';
import 'package:emotion_sense/data/services/camera_service.dart';
import 'package:flutter/foundation.dart';
// ML imports commented out until packages fetched.
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class DetectionEvent {
  DetectionEvent({
    required this.emotion,
    required this.bounds,
    required this.imageSize,
    this.ageGender,
  });
  final EmotionResult emotion;
  final FaceBounds? bounds;
  final Size imageSize; // camera image size in analysis orientation
  final AgeGenderData? ageGender;
}

/// FaceAnalysisService: on-device face detection + (optional) age/gender inference.
class FaceAnalysisService {
  FaceAnalysisService(this._camera);

  final CameraService _camera;
  final _controller = StreamController<DetectionEvent>.broadcast();
  Stream<DetectionEvent> get stream => _controller.stream;

  // FaceDetector? _detector;
  // tfl.Interpreter? _ageGenderInterpreter;
  bool _running = false;
  int _skipCounter = 0;
  int targetFps = 15; // configurable

  Future<void> initialize() async {
    // _detector = FaceDetector(
    // TODO: Initialize MLKit FaceDetector & TFLite models once dependencies resolved.
    // _detector = FaceDetector(
    //   options: FaceDetectorOptions(
    //     enableClassification: true,
    //     enableLandmarks: false,
    //     enableContours: false,
    //     performanceMode: FaceDetectorMode.fast,
    //   ),
    // );
    // // Try load TFLite model if present (optional)
    // try {
    //   _ageGenderInterpreter = await tfl.Interpreter.fromAsset('models/age_gender.tflite');
    // } catch (_) {
    //   _ageGenderInterpreter = null; // optional
    // }
  }

  Future<void> start() async {
    if (_running) return;
    // if (_detector == null) await initialize();
    _running = true;
    await _camera.startImageStream();
    _camera.imageStream.listen(_onFrame, onError: (e, st) {
      debugPrint('FaceAnalysis frame error: $e');
    });
  }

  Future<void> stop() async {
    _running = false;
    await _camera.stopImageStream();
  }

  Future<void> dispose() async {
    await stop();
    // await _detector?.close();
    _controller.close();
    // _ageGenderInterpreter?.close();
  }

  void _onFrame(CameraImage image) async {
    if (!_running) return;
    // Throttle to target FPS
    _skipCounter = (_skipCounter + 1) % math.max(1, (30 / targetFps).round());
    if (_skipCounter != 0) return;

    // final bytes = _concatenatePlanes(image.planes); // unused until ML integrated
    // final inputImage = InputImage.fromBytes(
    //   bytes: bytes,
    //   inputImageData: InputImageData(
    //     size: Size(image.width.toDouble(), image.height.toDouble()),
    //     imageRotation: _rotation0(),
    //     inputImageFormat: _convertFormat(image.format.raw),
    //     planeData: image.planes
    //         .map((p) => InputImagePlaneMetadata(bytesPerRow: p.bytesPerRow, height: p.height, width: p.width))
    //         .toList(),
    //   ),
    // );

    // TODO: Replace mock with real detector output.
    // MOCK: generate pseudo face + occasional emotion changes
    final rnd = math.Random();
    final emotionSeed = rnd.nextDouble();
    final emotion = emotionSeed > 0.98
        ? Emotion.surprised
        : emotionSeed > 0.95
            ? Emotion.happy
            : Emotion.neutral;
    final rect = Rect.fromLTWH(0.3 + rnd.nextDouble() * 0.02, 0.3, 0.4, 0.42);
    _controller.add(DetectionEvent(
      emotion: EmotionResult(emotion: emotion, confidence: 0.65),
      bounds: FaceBounds(rect: rect, timestamp: DateTime.now()),
      imageSize: Size(image.width.toDouble(), image.height.toDouble()),
      ageGender: null,
    ));
  }

  // Future: mapping functions & model preprocessing will be added here.

  // Placeholder stubs until MLKit integrated
  // InputImageRotation _rotation0() => InputImageRotation.rotation0deg;
  // InputImageFormat _convertFormat(int raw) => InputImageFormat.nv21;
}
