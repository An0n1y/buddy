import 'dart:ui';

/// Normalized face bounds (0..1 relative to preview dimensions).
class FaceBounds {
  FaceBounds({required this.rect, required this.timestamp});
  final Rect rect; // left/top/width/height normalized
  final DateTime timestamp;
}
