import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
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
    // Convert YUV420 to NV21 format that ML Kit expects
    final WriteBuffer allBytes = WriteBuffer();

    // Add Y plane
    allBytes.putUint8List(image.planes[0].bytes);

    // Add UV planes in NV21 format (VU interleaved)
    if (image.planes.length > 1) {
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

      final int width = image.width;
      final int height = image.height;

      // For NV21, we need VU interleaved
      for (int row = 0; row < height ~/ 2; row++) {
        for (int col = 0; col < width ~/ 2; col++) {
          final int uvIndex = row * uvRowStride + col * uvPixelStride;

          // Write V then U (NV21 format)
          if (image.planes.length > 2) {
            allBytes.putUint8(image.planes[2].bytes[uvIndex]); // V
            allBytes.putUint8(image.planes[1].bytes[uvIndex]); // U
          }
        }
      }
    }

    final bytes = allBytes.done().buffer.asUint8List();

    final input = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      ),
    );

    return _detector.processImage(input);
  }

  Future<void> close() => _detector.close();
}
