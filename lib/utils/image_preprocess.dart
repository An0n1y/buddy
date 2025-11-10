import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Convert Y plane to grayscale Float32 input [1, H, W, 1] flattened
/// normalized by /255 for model input. Returns a flat Float32List size H*W.
Float32List yuvToGrayscaleInput(
  Uint8List yBytes,
  int width,
  int height,
  Rect bb,
  int outW,
  int outH,
) {
  final left = bb.left.clamp(0.0, width.toDouble()).toInt();
  final top = bb.top.clamp(0.0, height.toDouble()).toInt();
  final right = (bb.right.clamp(0.0, width.toDouble())).toInt();
  final bottom = (bb.bottom.clamp(0.0, height.toDouble())).toInt();
  final cropW = math.max(1, right - left);
  final cropH = math.max(1, bottom - top);
  final out = Float32List(outH * outW);
  for (int oy = 0; oy < outH; oy++) {
    final sy = top + (oy * cropH / outH).floor();
    for (int ox = 0; ox < outW; ox++) {
      final sx = left + (ox * cropW / outW).floor();
      final yIndex = sy * width + sx;
      final yVal = yBytes[yIndex];
      out[oy * outW + ox] = yVal / 255.0;
    }
  }
  return out;
}

/// Convert YUV420 to RGB Float32 input [1, H, W, 3] flattened and normalized
/// with (x-127.5)/128 per channel. Returns a flat Float32List size H*W*3.
Float32List yuvToRgbInput(
    Uint8List yBytes,
    Uint8List? uBytes,
    Uint8List? vBytes,
    int width,
    int height,
    int uvRowStride,
    int uvPixelStride,
    Rect bb,
    int outW,
    int outH,
    [Float32List? outBuffer]) {
  final left = bb.left.clamp(0.0, width.toDouble()).toInt();
  final top = bb.top.clamp(0.0, height.toDouble()).toInt();
  final right = (bb.right.clamp(0.0, width.toDouble())).toInt();
  final bottom = (bb.bottom.clamp(0.0, height.toDouble())).toInt();
  final cropW = math.max(1, right - left);
  final cropH = math.max(1, bottom - top);

  final needed = outH * outW * 3;
  final out = (outBuffer != null && outBuffer.length == needed)
      ? outBuffer
      : Float32List(needed);
  int outIdx = 0;
  for (int oy = 0; oy < outH; oy++) {
    final sy = top + (oy * cropH / outH).floor();
    for (int ox = 0; ox < outW; ox++) {
      final sx = left + (ox * cropW / outW).floor();
      final yIndex = sy * width + sx;
      final y = yBytes[yIndex].toDouble();
      double r, g, b;
      if (uBytes != null && vBytes != null) {
        final uvX = (sx / 2).floor();
        final uvY = (sy / 2).floor();
        final uvIndex = uvY * uvRowStride + uvX * uvPixelStride;
        final u = uBytes[uvIndex].toDouble() - 128.0;
        final v = vBytes[uvIndex].toDouble() - 128.0;
        r = y + 1.402 * v;
        g = y - 0.344136 * u - 0.714136 * v;
        b = y + 1.772 * u;
      } else {
        r = g = b = y;
      }
      r = r.clamp(0.0, 255.0);
      g = g.clamp(0.0, 255.0);
      b = b.clamp(0.0, 255.0);
      out[outIdx++] = (r - 127.5) / 128.0;
      out[outIdx++] = (g - 127.5) / 128.0;
      out[outIdx++] = (b - 127.5) / 128.0;
    }
  }
  return out;
}
