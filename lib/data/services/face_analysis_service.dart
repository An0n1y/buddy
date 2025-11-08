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

  // Simple state for heuristic temporal tracking
  Rect? _lastRect; // last normalized face box
  List<int>? _lastDownscaled; // previous downscaled luminance for motion diff
  // cached dimensions not used currently, kept for future coordinate transforms

  // Downscale target (kept modest for speed)
  static const int _dsW = 64;
  static const int _dsH = 64;

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

    // Heuristic pipeline (no ML): operate on luminance plane
    final yPlane = image.planes.first; // assume plane[0] = Y
    final bytes = yPlane.bytes;
    final frameW = image.width;
    final frameH = image.height;

    // Downscale nearest-neighbor to fixed grid
    final downscaled = List<int>.filled(_dsW * _dsH, 0, growable: false);
    final xRatio = frameW / _dsW;
    final yRatio = frameH / _dsH;
    for (var y = 0; y < _dsH; y++) {
      final srcY = (y * yRatio).floor();
      final rowOffset = srcY * frameW;
      final outRow = y * _dsW;
      for (var x = 0; x < _dsW; x++) {
        final srcX = (x * xRatio).floor();
        downscaled[outRow + x] = bytes[rowOffset + srcX];
      }
    }

    // Motion map (if previous exists) and overall brightness stats
    double motionSum = 0;
    double brightnessSum = 0;
    if (_lastDownscaled != null &&
        _lastDownscaled!.length == downscaled.length) {
      for (var i = 0; i < downscaled.length; i++) {
        final v = downscaled[i];
        brightnessSum += v;
        motionSum += (v - _lastDownscaled![i]).abs();
      }
    } else {
      for (final v in downscaled) {
        brightnessSum += v;
      }
    }
    final avgBrightness = brightnessSum / downscaled.length;
    final avgMotion =
        _lastDownscaled == null ? 0.0 : motionSum / downscaled.length;

    // Approximate face box: keep previous, else initialize center box.
    Rect rect = _lastRect ?? const Rect.fromLTWH(0.3, 0.25, 0.4, 0.5);

    // Adjust box size slightly based on global brightness (simulate distance)
    final brightnessNorm = (avgBrightness / 255.0).clamp(0.0, 1.0);
    final scaleAdjust =
        (0.5 - (brightnessNorm - 0.5).abs()) * 0.04; // narrower in extremes
    rect = Rect.fromLTWH(
        rect.left,
        rect.top,
        (rect.width + scaleAdjust).clamp(0.32, 0.55),
        (rect.height + scaleAdjust).clamp(0.42, 0.65));

    // Feature region sampling inside rect
    int sampleCount = 0;
    double topSum = 0, midSum = 0, bottomSum = 0;
    // Convert rect to pixel region indices in downscaled grid
    final leftPx = (rect.left * _dsW).clamp(0, _dsW - 1).toInt();
    final rightPx = ((rect.left + rect.width) * _dsW).clamp(1, _dsW).toInt();
    final topPx = (rect.top * _dsH).clamp(0, _dsH - 1).toInt();
    final bottomPx = ((rect.top + rect.height) * _dsH).clamp(1, _dsH).toInt();
    final hSpan = bottomPx - topPx;
    final topBandEnd = topPx + (hSpan * 0.33).floor();
    final midBandEnd = topPx + (hSpan * 0.66).floor();

    for (var y = topPx; y < bottomPx; y++) {
      for (var x = leftPx; x < rightPx; x++) {
        final v = downscaled[y * _dsW + x];
        sampleCount++;
        if (y < topBandEnd) {
          topSum += v;
        } else if (y < midBandEnd) {
          midSum += v;
        } else {
          bottomSum += v;
        }
      }
    }
    if (sampleCount == 0) sampleCount = 1; // avoid div0
    final topAvg = topSum / sampleCount;
    final midAvg = midSum / sampleCount;
    final bottomAvg = bottomSum / sampleCount;

    // Simple derived metrics
    final browCompression = (topAvg - midAvg).abs() / 255.0; // intensity diff
    final mouthOpenMetric =
        (midAvg - bottomAvg).abs() / 255.0; // vertical gradient proxy
    final energyMetric = avgMotion / 64.0; // scaled

    // Emotion decision rules (heuristic)
    Emotion emotion;
    double confidence = 0.55; // base confidence
    if (mouthOpenMetric > 0.22 && browCompression < 0.05) {
      emotion = Emotion.surprised;
      confidence += (mouthOpenMetric - 0.22) * 0.8;
    } else if (mouthOpenMetric > 0.18 && energyMetric > 1.2) {
      emotion = Emotion.funny;
      confidence += (mouthOpenMetric - 0.18) * 0.6;
    } else if (browCompression > 0.12 && mouthOpenMetric < 0.12) {
      emotion = Emotion.angry;
      confidence += (browCompression - 0.12) * 0.7;
    } else if (mouthOpenMetric < 0.10 &&
        browCompression < 0.06 &&
        avgBrightness > 110) {
      emotion = Emotion.happy;
      confidence += (avgBrightness - 110) / 255.0;
    } else if (midAvg < bottomAvg - 6) {
      emotion = Emotion.sad;
      confidence += ((bottomAvg - midAvg) / 255.0) * 0.5;
    } else {
      emotion = Emotion.neutral;
      confidence -= (avgMotion / 255.0) * 0.2; // penalize jitter for neutral
    }
    confidence = confidence.clamp(0.0, 0.95);

    // Update temporal state
    _lastRect = rect;
    _lastDownscaled = downscaled;
    // (dimensions cached previously; removed unused vars)

    _controller.add(DetectionEvent(
      emotion: EmotionResult(emotion: emotion, confidence: confidence),
      bounds: FaceBounds(rect: rect, timestamp: DateTime.now()),
      imageSize: Size(frameW.toDouble(), frameH.toDouble()),
      ageGender: null,
    ));
  }

  // Future: mapping functions & model preprocessing will be added here.

  // Placeholder stubs until MLKit integrated
  // InputImageRotation _rotation0() => InputImageRotation.rotation0deg;
  // InputImageFormat _convertFormat(int raw) => InputImageFormat.nv21;
}
