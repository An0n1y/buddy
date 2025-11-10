import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Simple ML Kit face detector wrapper that outputs face bounding boxes
/// in the camera image coordinate space.
class FaceDetectionService {
  FaceDetectionService({FaceDetector? detector})
      : _detector = detector ??
            FaceDetector(
              options: FaceDetectorOptions(
                enableContours: false,
                enableClassification:
                    true, // needed for smiling/eye probabilities
                enableLandmarks: true,
                performanceMode: FaceDetectorMode.accurate,
                minFaceSize: 0.08,
              ),
            );

  final FaceDetector _detector;

  Future<List<Face>> process(CameraImage image, {int rotation = 0}) async {
    // Build an InputImage from CameraImage (YUV420). For plugin ^0.10.0 we use metadata API.
    final bytes = image.planes.first
        .bytes; // NV21 layout (first plane sufficient for luminance)
    final input = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
    return _detector.processImage(input);
  }

  Future<void> close() => _detector.close();
}
