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
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// ML imports commented out until packages fetched.
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class DetectionEvent {
  DetectionEvent({
    required this.emotion,
    required this.bounds,
    required this.imageSize,
    this.ageGender,
    // Raw metrics (optional diagnostics)
    this.mouthOpenMetric,
    this.browCompression,
    this.energyMetric,
    this.smileProbability,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.trackingId,
    this.isPrimary = false,
  });
  final EmotionResult emotion;
  final FaceBounds? bounds;
  final Size imageSize; // camera image size in analysis orientation
  final AgeGenderData? ageGender;
  // Exposed diagnostics
  final double? mouthOpenMetric;
  final double? browCompression;
  final double? energyMetric;
  final double? smileProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final int? trackingId;
  final bool isPrimary;
}

/// FaceAnalysisService: on-device face detection + (optional) age/gender inference.
class FaceAnalysisService {
  FaceAnalysisService(this._camera);

  final CameraService _camera;
  final _controller = StreamController<DetectionEvent>.broadcast();
  Stream<DetectionEvent> get stream => _controller.stream;

  FaceDetector? _detector;
  // tfl.Interpreter? _ageGenderInterpreter;
  bool _running = false;
  bool _processing = false; // guard against async overlap
  int _skipCounter = 0;
  int targetFps = 15; // configurable
  // Thresholds (externally tunable)
  double mouthOpenThreshold = 0.18;
  double browCompressionThreshold = 0.10;
  double energyThreshold = 0.25;
  // ML probabilities thresholds
  double smileThreshold = 0.50;
  double eyeOpenThreshold = 0.45;

  // FaceIDS controller / instance (placeholder; package docs sparse)
  // dynamic _faceIds; // using dynamic due to limited API reference

  Future<void> initialize() async {
    _detector ??= FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableClassification: true,
        enableLandmarks: false,
        enableContours: false,
        enableTracking: true,
      ),
    );
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
    await _detector?.close();
    _controller.close();
  }

  // State for motion clustering / ROI tracking
  // Previous rect retained only if needed for future smoothing; currently unused with MLKit ROI
  List<int>? _lastDownscaled;
  static const int _dsW = 64;
  static const int _dsH = 64;
  // Per face smoothing using trackingId
  final Map<int, Rect> _lastRectByTrack = {};
  double _lastEnergy = 0.0; // for adaptive decimation

  void _onFrame(CameraImage image) async {
    if (!_running) return;
    if (_processing) return; // avoid overlap
    // Throttle to target FPS with adaptive decimation based on last energy
    final baseSkip = math.max(1, (30 / targetFps).round());
    // If very low motion, skip more frames; if high motion, skip fewer.
    final adapt = _lastEnergy < 0.02
        ? 2
        : (_lastEnergy < 0.05 ? 1 : 0); // 0 = no extra skip, 1 = mild, 2 = more
    final effectiveSkip = math.max(1, baseSkip + adapt);
    _skipCounter = (_skipCounter + 1) % effectiveSkip;
    if (_skipCounter != 0) return;
    _processing = true;

    // Build ML Kit InputImage from CameraImage
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg, // best effort
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
    try {
      await initialize();
      final faces = await _detector!.processImage(inputImage);
      if (faces.isEmpty) {
        // keep previous rect but increase missing handled in provider
        _lastDownscaled = _lastDownscaled; // no-op
        return;
      }

      final frameW = image.width;
      final frameH = image.height;
      final yPlane = image.planes.first; // Y plane
      final yBytes = yPlane.bytes;

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
          downscaled[outRow + x] = yBytes[rowOffset + srcX];
        }
      }

      // Motion map (if previous exists) and overall brightness stats
      double motionSum = 0;
      if (_lastDownscaled != null &&
          _lastDownscaled!.length == downscaled.length) {
        for (var i = 0; i < downscaled.length; i++) {
          final v = downscaled[i];
          motionSum += (v - _lastDownscaled![i]).abs();
        }
      } else {
        // no previous frame, skip motion accumulation
      }
      final avgMotion =
          _lastDownscaled == null ? 0.0 : motionSum / downscaled.length;
      _lastEnergy = (avgMotion / 255.0).clamp(0.0, 1.0);

      // Feature region sampling inside rect
      // Prepare multi-face processing
      // Compute per-face metrics and emit one event per face. Mark the primary as closest to center.
      final faceData = <({Face face, Rect rectNorm, double centerDist})>[];
      for (final face in faces) {
        final bb = face.boundingBox;
        var rect = Rect.fromLTWH(
          (bb.left / frameW).clamp(0.0, 1.0),
          (bb.top / frameH).clamp(0.0, 1.0),
          (bb.width / frameW).clamp(0.0, 1.0),
          (bb.height / frameH).clamp(0.0, 1.0),
        );
        // Smooth with trackingId if available
        final tid = face.trackingId;
        if (tid != null && _lastRectByTrack.containsKey(tid)) {
          final prev = _lastRectByTrack[tid]!;
          // heavier smoothing when low motion
          final a =
              _lastEnergy < 0.03 ? 0.75 : (_lastEnergy < 0.07 ? 0.6 : 0.45);
          rect = Rect.fromLTWH(
            prev.left + (rect.left - prev.left) * a,
            prev.top + (rect.top - prev.top) * a,
            prev.width + (rect.width - prev.width) * a,
            prev.height + (rect.height - prev.height) * a,
          );
        }
        if (tid != null) _lastRectByTrack[tid] = rect;

        final cx = rect.left + rect.width / 2;
        final cy = rect.top + rect.height / 2;
        final dist = math.sqrt(math.pow(cx - 0.5, 2) + math.pow(cy - 0.5, 2));
        faceData.add((face: face, rectNorm: rect, centerDist: dist));
      }
      faceData.sort((a, b) => a.centerDist.compareTo(b.centerDist));

      // Helper: compute band metrics for a rect
      Map<String, double> bandMetrics(Rect rect) {
        int topCount = 0, midCount = 0, botCount = 0;
        double topSum = 0, midSum = 0, botSum = 0;
        final leftPx = (rect.left * _dsW).clamp(0, _dsW - 1).toInt();
        final rightPx =
            ((rect.left + rect.width) * _dsW).clamp(1, _dsW).toInt();
        final topPx = (rect.top * _dsH).clamp(0, _dsH - 1).toInt();
        final bottomPx =
            ((rect.top + rect.height) * _dsH).clamp(1, _dsH).toInt();
        final hSpan = (bottomPx - topPx).clamp(1, _dsH);
        final topBandEnd = topPx + (hSpan * 0.33).floor();
        final midBandEnd = topPx + (hSpan * 0.66).floor();
        for (var y = topPx; y < bottomPx; y++) {
          for (var x = leftPx; x < rightPx; x++) {
            final v = downscaled[y * _dsW + x];
            if (y < topBandEnd) {
              topSum += v;
              topCount++;
            } else if (y < midBandEnd) {
              midSum += v;
              midCount++;
            } else {
              botSum += v;
              botCount++;
            }
          }
        }
        // Avoid div0
        topCount = topCount == 0 ? 1 : topCount;
        midCount = midCount == 0 ? 1 : midCount;
        botCount = botCount == 0 ? 1 : botCount;
        final topAvg = topSum / topCount;
        final midAvg = midSum / midCount;
        final botAvg = botSum / botCount;
        final brow = (topAvg - midAvg).abs() / 255.0;
        final mouth = (midAvg - botAvg).abs() / 255.0;
        return {
          'top': topAvg,
          'mid': midAvg,
          'bot': botAvg,
          'brow': brow,
          'mouth': mouth,
        };
      }

      for (var i = 0; i < faceData.length; i++) {
        final data = faceData[i];
        final face = data.face;
        final rect = data.rectNorm;
        final isPrimary = i == 0;
        final bands = bandMetrics(rect);
        final browCompression = bands['brow']!;
        final mouthOpenMetric = bands['mouth']!;
        final energyMetric = _lastEnergy; // normalized 0..1
        final sp = (face.smilingProbability ?? 0.0).clamp(0.0, 1.0);
        final le = (face.leftEyeOpenProbability ?? 0.0).clamp(0.0, 1.0);
        final re = (face.rightEyeOpenProbability ?? 0.0).clamp(0.0, 1.0);

        // Emotion mapping blending ML probabilities with heuristics
        Emotion emotion = Emotion.neutral;
        double conf = 0.25; // lower base to avoid overconfident neutral

        final eyesOpen = (le + re) / 2;
        if (sp >= smileThreshold &&
            mouthOpenMetric < mouthOpenThreshold * 0.7) {
          // Clear smile with relatively closed mouth -> happy
          emotion = Emotion.happy;
          conf = 0.5 + 0.5 * sp;
        } else if (mouthOpenMetric > mouthOpenThreshold &&
            eyesOpen > eyeOpenThreshold) {
          // Wide mouth and eyes open -> surprised
          emotion = Emotion.surprised;
          conf = 0.45 +
              0.4 *
                  ((mouthOpenMetric - mouthOpenThreshold) /
                          (1 - mouthOpenThreshold))
                      .clamp(0, 1);
        } else if (mouthOpenMetric > mouthOpenThreshold * 0.8 &&
            energyMetric > energyThreshold) {
          // Motion + mouth open -> funny (exaggerated motion)
          emotion = Emotion.funny;
          conf = 0.4 +
              0.4 *
                  ((energyMetric - energyThreshold) / (1 - energyThreshold))
                      .clamp(0, 1);
        } else if (browCompression > browCompressionThreshold &&
            mouthOpenMetric < mouthOpenThreshold * 0.55) {
          // Brow tense and mouth closed -> angry
          emotion = Emotion.angry;
          conf = 0.45 +
              0.3 *
                  ((browCompression - browCompressionThreshold) /
                          (1 - browCompressionThreshold))
                      .clamp(0, 1);
        } else {
          // fallback neutral with slight penalization for jitter
          emotion = Emotion.neutral;
          conf = (0.35 - energyMetric * 0.2).clamp(0.05, 0.5);
        }
        conf = conf.clamp(0.0, 0.98);

        _controller.add(DetectionEvent(
          emotion: EmotionResult(emotion: emotion, confidence: conf),
          bounds: FaceBounds(rect: rect, timestamp: DateTime.now()),
          imageSize: Size(frameW.toDouble(), frameH.toDouble()),
          ageGender: null,
          mouthOpenMetric: mouthOpenMetric,
          browCompression: browCompression,
          energyMetric: energyMetric,
          smileProbability: sp,
          leftEyeOpenProbability: le,
          rightEyeOpenProbability: re,
          trackingId: face.trackingId,
          isPrimary: isPrimary,
        ));
      }

      // Update temporal state
      _lastDownscaled = downscaled;
    } finally {
      _processing = false;
    }
  }

  // Future: mapping functions & model preprocessing will be added here.

  // Placeholder stubs until MLKit integrated
  // InputImageRotation _rotation0() => InputImageRotation.rotation0deg;
  // InputImageFormat _convertFormat(int raw) => InputImageFormat.nv21;
}
