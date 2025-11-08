import 'package:flutter/material.dart';
import 'package:emotion_sense/data/models/face_data.dart';

class FaceOverlayPainter extends CustomPainter {
  FaceOverlayPainter({required this.face});
  final FaceData? face;

  @override
  void paint(Canvas canvas, Size size) {
    if (face == null) return;
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(face!.boundingBox, paint);
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) =>
      oldDelegate.face != face;
}
