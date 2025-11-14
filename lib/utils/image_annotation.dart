import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/presentation/providers/face_attributes_provider.dart';

/// Utility to draw face detection data (bounding box, emotion, age, gender, ethnicity)
/// on captured images before saving to gallery
class ImageAnnotation {
  /// Annotates an image with face detection data
  /// Returns the annotated image as bytes ready to save
  static Future<Uint8List> annotateImage({
    required String imagePath,
    required FaceAttributes faceData,
    required Size imageSize,
  }) async {
    try {
      // Load the original image
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Create a canvas to draw on
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();

      // Draw the original image
      canvas.drawImage(image, Offset.zero, paint);

      // Get actual image dimensions
      final imgWidth = image.width.toDouble();
      final imgHeight = image.height.toDouble();

      // Convert normalized rect [0-1] to pixel coordinates
      final rect = Rect.fromLTWH(
        faceData.rect.left * imgWidth,
        faceData.rect.top * imgHeight,
        faceData.rect.width * imgWidth,
        faceData.rect.height * imgHeight,
      );

      // Draw bounding box around face
      final boxPaint = Paint()
        ..color = _getEmotionColor(faceData.emotion).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawRect(rect, boxPaint);

      // Draw semi-transparent background for text
      final textBgPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;

      // Prepare text content
      final emotion = faceData.emotion.toString().split('.').last.toUpperCase();
      final confidence = '${(faceData.confidence * 100).toStringAsFixed(0)}%';
      final age = faceData.ageRange;
      final gender = faceData.gender;
      final ethnicity = faceData.ethnicity ?? 'Unknown';

      // Build text lines
      final lines = [
        '$emotion ($confidence)',
        'Age: $age',
        'Gender: $gender',
        'Ethnicity: $ethnicity',
      ];

      // Text styling
      const textStyle = TextStyle(
        color: Colors.white,
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            blurRadius: 4.0,
            color: Colors.black,
            offset: Offset(2, 2),
          ),
        ],
      );

      // Calculate text background size
      const padding = 16.0;
      const lineHeight = 36.0;
      double maxWidth = 0;

      // Find max width for background
      for (final line in lines) {
        final textPainter = TextPainter(
          text: TextSpan(text: line, style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        if (textPainter.width > maxWidth) {
          maxWidth = textPainter.width;
        }
      }

      // Position text above the face box (or below if too high)
      final textTop = rect.top > lineHeight * lines.length + padding * 2
          ? rect.top - lineHeight * lines.length - padding * 2
          : rect.bottom + padding;

      // Draw text background
      final textBgRect = Rect.fromLTWH(
        rect.left - padding,
        textTop,
        maxWidth + padding * 2,
        lineHeight * lines.length + padding,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(textBgRect, const Radius.circular(8)),
        textBgPaint,
      );

      // Draw each line of text
      double yOffset = textTop + padding / 2;
      for (final line in lines) {
        final textPainter = TextPainter(
          text: TextSpan(text: line, style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(canvas, Offset(rect.left, yOffset));
        yOffset += lineHeight;
      }

      // Convert canvas to image
      final picture = recorder.endRecording();
      final annotatedImage = await picture.toImage(
        image.width,
        image.height,
      );

      // Convert to bytes
      final byteData = await annotatedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      image.dispose();
      annotatedImage.dispose();

      return byteData!.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ Error annotating image: $e');
      // Return original image bytes on error
      final file = File(imagePath);
      return await file.readAsBytes();
    }
  }

  /// Get color for each emotion
  static Color _getEmotionColor(Emotion emotion) {
    switch (emotion) {
      case Emotion.happy:
        return Colors.green;
      case Emotion.sad:
        return Colors.blue;
      case Emotion.angry:
        return Colors.red;
      case Emotion.surprised:
        return Colors.orange;
      case Emotion.funny:
        return Colors.purple;
      case Emotion.neutral:
        return Colors.grey;
    }
  }
}
