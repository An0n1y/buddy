import 'package:camera/camera.dart';
import 'package:emotion_sense/presentation/providers/camera_provider.dart';
import 'package:emotion_sense/presentation/providers/face_attributes_provider.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'dart:math' as math;
import 'package:emotion_sense/presentation/widgets/camera_preview_widget.dart';
import 'package:emotion_sense/presentation/widgets/morphing_emoji.dart';
import 'package:emotion_sense/presentation/screens/history_screen.dart';
import 'package:emotion_sense/presentation/screens/settings_screen.dart';
import 'package:emotion_sense/data/models/age_gender_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emotion_sense/presentation/providers/settings_provider.dart';
import 'package:emotion_sense/presentation/providers/history_provider.dart';

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
    final settings = context.watch<SettingsProvider>();
    final history = context.watch<HistoryProvider>();
    final attrs = context.watch<FaceAttributesProvider?>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('EmotionSense'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Camera preview with overlay (larger height - 65%)
            Expanded(
              flex: 65,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreviewWidget(controller: camera.controller),
                    // Face detection overlay with bounding boxes
                    if (_attrs != null) _FaceBoxesOverlay(provider: _attrs!),
                    // Top-center: Primary emotion with morphing emoji
                    if (attrs != null && attrs.faces.isNotEmpty)
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _PrimaryEmotionCard(face: attrs.faces.first),
                        ),
                      ),
                    // Top-right: Age/Gender/Ethnicity card (capsule)
                    if (settings.showAgeGender && attrs != null && attrs.faces.isNotEmpty)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _AgeGenderEthnicityCard(
                          face: attrs.faces.first,
                          ethnicityEnabled: settings.ethnicityEnabled,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Control buttons row (fixed height)
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Camera switch button
                  IconButton.filled(
                    onPressed: () => camera.toggleCamera(),
                    icon: const Icon(Icons.cameraswitch),
                    tooltip: 'Switch camera',
                  ),
                  const SizedBox(width: 16),
                  // Flash button
                  IconButton.filled(
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
                    tooltip: 'Toggle flash',
                  ),
                  const SizedBox(width: 24),
                  // Capture button (center, prominent)
                  FilledButton.icon(
                    onPressed: () async {
                      if (camera.controller == null) return;
                      try {
                        final img = await camera.controller!.takePicture();
                        if (context.mounted) {
                          final attrs = context.read<FaceAttributesProvider?>();
                          if (attrs != null && attrs.faces.isNotEmpty) {
                            final face = attrs.faces.first;
                            // Create AgeGenderData from FaceAttributes
                            final ageGenderData = AgeGenderData(
                              ageRange: face.ageRange,
                              gender: face.gender,
                              confidence: face.confidence,
                            );
                            await history.addCapture(
                              imagePath: img.path,
                              emotion: face.emotion,
                              confidence: face.confidence,
                              ageGender: ageGenderData,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Captured!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capture'),
                  ),
                  const SizedBox(width: 24),
                  // Placeholder for balance
                  SizedBox(
                    width: 40,
                    child: Container(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary emotion display card
class _PrimaryEmotionCard extends StatelessWidget {
  const _PrimaryEmotionCard({required this.face});
  final FaceAttributes face;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Morphing emoji
            Expanded(
              flex: 1,
              child: MorphingEmoji(
                emotion: face.emotion,
                size: 60,
                showFaceCircle: true,
              ),
            ),
            const SizedBox(width: 16),
            // Emotion text and confidence
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    face.emotion.name.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: face.confidence.clamp(0.0, 1.0),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(face.confidence * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Age/Gender/Ethnicity card displayed as a capsule in top-right
class _AgeGenderEthnicityCard extends StatelessWidget {
  const _AgeGenderEthnicityCard({
    required this.face,
    required this.ethnicityEnabled,
  });
  final FaceAttributes face;
  final bool ethnicityEnabled;

  @override
  Widget build(BuildContext context) {
    final ethnicity = ethnicityEnabled && face.ethnicity != null
        ? ' • ${face.ethnicity}'
        : '';
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              face.ageRange,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              '${face.gender}$ethnicity',
              style: Theme.of(context).textTheme.labelSmall,
            ),
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
