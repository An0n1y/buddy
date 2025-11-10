import 'package:camera/camera.dart';
import 'package:emotion_sense/presentation/providers/camera_provider.dart';
import 'package:emotion_sense/presentation/providers/face_attributes_provider.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'dart:math' as math;
import 'package:emotion_sense/presentation/widgets/camera_preview_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emotion_sense/presentation/providers/settings_provider.dart';

/// New entry view: shows camera preview with space reserved at bottom for controls/labels.
class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraProvider>().initialize();
      // Start attributes provider when camera ready
      final cam = context.read<CameraProvider>();
      final settings = context.read<SettingsProvider>();
      final attrs = FaceAttributesProvider(cam.service, settings: settings);
      // Attach to tree
      Provider.of<FaceAttributesProvider?>(context, listen: false);
      // Manually keep it alive in state for now
      _attrs = attrs;
      _attrs!.start();
    });
  }

  FaceAttributesProvider? _attrs;

  @override
  void dispose() {
    _attrs?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('EmotionSense'),
        actions: [
          IconButton(
            onPressed: () => camera.toggleCamera(),
            icon: const Icon(Icons.cameraswitch),
          ),
          IconButton(
            onPressed: () {
              final next = switch (camera.flash) {
                FlashMode.off => FlashMode.torch,
                FlashMode.torch => FlashMode.off,
                _ => FlashMode.off,
              };
              camera.setFlash(next);
            },
            icon: Icon(camera.flash == FlashMode.torch
                ? Icons.flash_on
                : Icons.flash_off),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Camera preview area reduced in height by reserving ~96 dp for bottom rows
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreviewWidget(controller: camera.controller),
                    // Temporary simple overlay: draw face rects if provider available
                    if (_attrs != null) _FaceBoxesOverlay(provider: _attrs!),
                  ],
                ),
              ),
            ),
            // Reserve two rows (~96 dp) at the bottom for controls/labels
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }
}

class _FaceBoxesOverlay extends StatelessWidget {
  const _FaceBoxesOverlay({required this.provider});
  final FaceAttributesProvider provider;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        return CustomPaint(
          painter: _BoxesPainter(provider.faces,
              context.read<SettingsProvider>().ethnicityEnabled),
        );
      },
    );
  }
}

class _BoxesPainter extends CustomPainter {
  _BoxesPainter(this.faces, this.ethnicityEnabled);
  final List<FaceAttributes> faces;
  final bool ethnicityEnabled;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.amber;
    for (final f in faces) {
      final rect = Rect.fromLTWH(
        f.rect.left * size.width,
        f.rect.top * size.height,
        f.rect.width * size.width,
        f.rect.height * size.height,
      );
      canvas.drawRect(rect, paint);

      // Morphing emoji: crossfade between neutral and happy based on smile probability (0..1)
      final smile = (f.rawSmileProb ?? (f.emotion == Emotion.happy ? 1.0 : 0.0))
          .clamp(0.0, 1.0);
      final neutralOpacity = (1.0 - smile);
      final happyOpacity = smile;
      final emojiFontSize = 16.0 + 10.0 * smile; // grow size with smile

      void paintEmoji(String emoji, double opacity) {
        final tp = TextPainter(
          text: TextSpan(
            text: emoji,
            style: TextStyle(
              color: Color.fromARGB((255 * opacity).round(), 255, 255, 255),
              fontSize: emojiFontSize,
              shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        final offset = Offset(rect.left, math.max(0, rect.top - tp.height - 4));
        tp.paint(canvas, offset);
      }

      paintEmoji('😐', neutralOpacity);
      paintEmoji('😄', happyOpacity);

      // Optional info: age • gender [• ethnicity if enabled]
      final info = ethnicityEnabled && (f.ethnicity != null)
          ? "${f.ageRange} • ${f.gender} • ${f.ethnicity}"
          : "${f.ageRange} • ${f.gender}";
      final infoPainter = TextPainter(
        text: TextSpan(
          text: info,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            shadows: [Shadow(color: Colors.black, blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: size.width);
      final infoOffset = Offset(rect.left, rect.bottom + 4);
      infoPainter.paint(canvas, infoOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _BoxesPainter oldDelegate) =>
      _didFacesChange(oldDelegate.faces, faces);
}

// Old discrete emoji helper removed; replaced by morphing crossfade rendering above.

bool _didFacesChange(List<FaceAttributes> a, List<FaceAttributes> b) {
  if (identical(a, b)) return false;
  if (a.length != b.length) return true;
  for (var i = 0; i < a.length; i++) {
    final fa = a[i];
    final fb = b[i];
    if (fa.rect != fb.rect ||
        fa.emotion != fb.emotion ||
        fa.confidence != fb.confidence) {
      return true;
    }
  }
  return false;
}
