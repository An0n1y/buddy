import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// TFLite-based face detection service
/// Uses face_detection_back.tflite and face_detection_short_range.tflite
class TFLiteFaceDetectionService {
  TFLiteFaceDetectionService();

  Interpreter? _detector;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initialize the face detection model
  Future<void> initialize({bool isFrontCamera = true}) async {
    try {
      // Use short_range model for front camera, back model for back camera
      final modelPath = isFrontCamera
          ? 'assets/models/face_detection_short_range.tflite'
          : 'assets/models/face_detection_back.tflite';

      _detector = await Interpreter.fromAsset(modelPath);
      _initialized = true;
      debugPrint('✅ TFLite Face Detection model loaded: $modelPath');
      debugPrint('Input shape: ${_detector?.getInputTensor(0).shape}');
      debugPrint('Output tensors: ${_detector?.getOutputTensors().length}');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to load face detection model: $e');
      debugPrint('Stack trace: $stackTrace');
      _initialized = false;
    }
  }

  /// Process camera image and return detected faces
  Future<List<DetectedFace>> process(CameraImage image) async {
    if (!_initialized || _detector == null) {
      return [];
    }

    try {
      // Get model input requirements
      final inputShape = _detector!.getInputTensor(0).shape;
      final inputHeight = inputShape[1];
      final inputWidth = inputShape[2];

      // Preprocess image to model input format
      final inputData = _preprocessImage(image, inputWidth, inputHeight);

      // Run inference
      final outputTensors = _detector!.getOutputTensors();
      final outputs = <int, Object>{};

      for (int i = 0; i < outputTensors.length; i++) {
        final shape = outputTensors[i].shape;
        final size = shape.reduce((a, b) => a * b);
        outputs[i] = Float32List(size);
      }

      _detector!.runForMultipleInputs([inputData], outputs);

      // Parse outputs to face detections
      return _parseDetections(outputs, image.width, image.height);
    } catch (e, stackTrace) {
      debugPrint('❌ Face detection error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Preprocess camera image to model input format
  Float32List _preprocessImage(
      CameraImage image, int targetWidth, int targetHeight) {
    // Convert YUV to RGB and resize
    final pixels = Float32List(targetWidth * targetHeight * 3);

    // Simple YUV to RGB conversion
    for (int h = 0; h < targetHeight; h++) {
      for (int w = 0; w < targetWidth; w++) {
        final srcX = (w * image.width / targetWidth).floor();
        final srcY = (h * image.height / targetHeight).floor();
        final srcIndex = srcY * image.width + srcX;

        if (srcIndex < image.planes[0].bytes.length) {
          final y = image.planes[0].bytes[srcIndex];
          final pixelIndex = (h * targetWidth + w) * 3;

          // Normalize to [0, 1] or [-1, 1] depending on model
          pixels[pixelIndex] = y / 255.0; // R
          pixels[pixelIndex + 1] = y / 255.0; // G
          pixels[pixelIndex + 2] = y / 255.0; // B
        }
      }
    }

    return pixels;
  }

  /// Parse model outputs to face detections
  List<DetectedFace> _parseDetections(
      Map<int, Object> outputs, int imageWidth, int imageHeight) {
    final faces = <DetectedFace>[];

    try {
      // Face detection models typically output:
      // [0] = bounding boxes [n, 4] (x, y, width, height)
      // [1] = scores [n]
      // [2] = num detections

      final boxes = outputs[0] as Float32List;
      final scores = outputs[1] as Float32List?;

      // Parse each detection
      for (int i = 0; i < boxes.length ~/ 4; i++) {
        final score = scores != null && i < scores.length ? scores[i] : 1.0;

        // Filter low confidence detections
        if (score < 0.5) continue;

        final boxIndex = i * 4;
        final y1 = boxes[boxIndex];
        final x1 = boxes[boxIndex + 1];
        final y2 = boxes[boxIndex + 2];
        final x2 = boxes[boxIndex + 3];

        // Convert to absolute coordinates
        final rect = Rect.fromLTRB(
          (x1 * imageWidth).clamp(0.0, imageWidth.toDouble()),
          (y1 * imageHeight).clamp(0.0, imageHeight.toDouble()),
          (x2 * imageWidth).clamp(0.0, imageWidth.toDouble()),
          (y2 * imageHeight).clamp(0.0, imageHeight.toDouble()),
        );

        faces.add(DetectedFace(
          boundingBox: rect,
          confidence: score,
        ));
      }
    } catch (e) {
      debugPrint('❌ Error parsing detections: $e');
    }

    return faces;
  }

  Future<void> close() async {
    _detector?.close();
    _detector = null;
    _initialized = false;
  }
}

/// Simple face detection result
class DetectedFace {
  final Rect boundingBox;
  final double confidence;

  DetectedFace({
    required this.boundingBox,
    required this.confidence,
  });
}
