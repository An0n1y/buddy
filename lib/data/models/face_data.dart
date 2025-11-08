import 'package:flutter/material.dart';

/// Placeholder for face metadata (bounding box). No ML integration.
class FaceData {
  FaceData({required this.boundingBox});
  final Rect boundingBox;
}
