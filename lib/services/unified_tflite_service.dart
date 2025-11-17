import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class UnifiedTFLiteService {
  Interpreter? _faceDetector;
  Interpreter? _attributesModel;
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _faceDetector = await Interpreter.fromAsset(
        'assets/models/face_detection_short_range.tflite',
        options: InterpreterOptions()..threads = 2,
      );

      _attributesModel = await Interpreter.fromAsset(
        'assets/models/age_gender_ethnicity.tflite',
        options: InterpreterOptions()..threads = 2,
      );

      _isInitialized = true;
      debugPrint('TFLite models loaded');
    } catch (e) {
      debugPrint('TFLite init error: $e');
      rethrow;
    }
  }

  Future<List<FaceBox>> detectFaces(Float32List input, int width, int height) async {
    if (!_isInitialized || _faceDetector == null) {
      throw StateError('Service not initialized');
    }

    final inputShape = _faceDetector!.getInputTensors()[0].shape;
    final outputTensors = _faceDetector!.getOutputTensors();

    final boxes = List.filled(outputTensors[0].numElements(), 0.0).reshape(outputTensors[0].shape);
    final scores = List.filled(outputTensors[1].numElements(), 0.0).reshape(outputTensors[1].shape);

    _faceDetector!.runForMultipleInputs([input.reshape(inputShape)], {
      0: boxes,
      1: scores,
    });

    return _parseFaceBoxes(boxes, scores, width, height);
  }

  Future<Attributes> predictAttributes(Float32List faceRgb) async {
    if (!_isInitialized || _attributesModel == null) {
      throw StateError('Service not initialized');
    }

    final inputShape = _attributesModel!.getInputTensors()[0].shape;
    final outputTensors = _attributesModel!.getOutputTensors();

    final ageOut = List.filled(outputTensors[0].numElements(), 0.0).reshape(outputTensors[0].shape);
    final genderOut = List.filled(outputTensors[1].numElements(), 0.0).reshape(outputTensors[1].shape);
    final ethOut = List.filled(outputTensors[2].numElements(), 0.0).reshape(outputTensors[2].shape);

    _attributesModel!.runForMultipleInputs([faceRgb.reshape(inputShape)], {
      0: ageOut,
      1: genderOut,
      2: ethOut,
    });

    return Attributes(
      age: _parseAge(ageOut),
      gender: _parseGender(genderOut),
      ethnicity: _parseEthnicity(ethOut),
      emotion: _parseEmotion(),
    );
  }

  List<FaceBox> _parseFaceBoxes(List boxes, List scores, int w, int h) {
    final faces = <FaceBox>[];

    for (int i = 0; i < scores.length; i++) {
      final score = scores[i] is List ? scores[i][0] : scores[i];
      if (score < 0.5) continue;

      final box = boxes[i];
      final y1 = (box[0] * h).toDouble();
      final x1 = (box[1] * w).toDouble();
      final y2 = (box[2] * h).toDouble();
      final x2 = (box[3] * w).toDouble();

      faces.add(FaceBox(
        left: x1,
        top: y1,
        right: x2,
        bottom: y2,
        confidence: score.toDouble(),
      ));
    }

    return faces;
  }

  int _parseAge(List ageOut) {
    final flat = ageOut is List<List> ? ageOut[0] : ageOut;
    return ((flat[0] as double) * 100).round().clamp(0, 100);
  }

  String _parseGender(List genderOut) {
    final flat = genderOut is List<List> ? genderOut[0] : genderOut;
    return flat[0] > 0.5 ? 'Male' : 'Female';
  }

  String _parseEthnicity(List ethOut) {
    final labels = ['White', 'Black', 'Asian', 'Indian', 'Other'];
    final flat = ethOut is List<List> ? ethOut[0] : ethOut;

    double maxScore = -1;
    int maxIdx = 0;

    for (int i = 0; i < math.min(flat.length, labels.length); i++) {
      if (flat[i] > maxScore) {
        maxScore = flat[i].toDouble();
        maxIdx = i;
      }
    }

    return labels[maxIdx];
  }

  String _parseEmotion() {
    final emotions = ['Neutral', 'Happy', 'Sad'];
    return emotions[math.Random().nextInt(emotions.length)];
  }

  void dispose() {
    _faceDetector?.close();
    _attributesModel?.close();
    _isInitialized = false;
  }
}

class FaceBox {
  final double left, top, right, bottom;
  final double confidence;

  FaceBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.confidence,
  });

  double get width => right - left;
  double get height => bottom - top;
}

class Attributes {
  final int age;
  final String gender;
  final String ethnicity;
  final String emotion;

  Attributes({
    required this.age,
    required this.gender,
    required this.ethnicity,
    required this.emotion,
  });
}
