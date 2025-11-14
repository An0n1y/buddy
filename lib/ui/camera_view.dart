import 'package:camera/camera.dart';
import 'package:emotion_sense/presentation/providers/camera_provider.dart';
import 'package:emotion_sense/presentation/providers/face_attributes_provider.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/presentation/widgets/camera_preview_widget.dart';
import 'package:emotion_sense/presentation/screens/history_screen.dart';
import 'package:emotion_sense/presentation/screens/settings_screen.dart';
import 'package:emotion_sense/data/models/age_gender_data.dart';
// Photos saving intentionally removed to avoid extra permissions
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emotion_sense/presentation/providers/history_provider.dart';
import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:emotion_sense/presentation/widgets/morphing_emoji.dart';

/// New entry view: shows camera preview with space reserved at bottom for controls/labels.
class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cam = context.read<CameraProvider>();

      // Initialize camera first
      await cam.initialize();

      // Now create and start face detection
      final attrs = FaceAttributesProvider(cam.service);
      _attrs = attrs;
      _attrs!.addListener(() {
        if (mounted) setState(() {});
      });

      // Start face detection (this starts the image stream)
      await _attrs!.start();

      if (mounted) setState(() {});
    });
  }

  FaceAttributesProvider? _attrs;

  Future<void> _saveToPhotos(String path) async {
    try {
      // Request permission first
      final perm = await PhotoManager.requestPermissionExtend();
      if (!perm.isAuth) {
        debugPrint('⚠️ Photo library permission denied');
        return; // user denied
      }

      final file = File(path);
      if (!await file.exists()) {
        debugPrint('⚠️ Image file not found: $path');
        return;
      }

      // Add a small delay on iOS to prevent conflicts with camera operations
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final bytes = await file.readAsBytes();
      final title = path.split(Platform.pathSeparator).last;

      // Save image with proper error handling
      await PhotoManager.editor.saveImage(bytes, title: title, filename: title);
      debugPrint('✅ Image saved to Photos: $title');
    } catch (e, stackTrace) {
      // Log the error but don't crash the app
      debugPrint('⚠️ Failed to save to Photos: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _attrs?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Pause/resume face detection based on app state to prevent iOS crashes
    if (_attrs == null) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // Stop processing when app goes to background
        _attrs?.stop();
        break;
      case AppLifecycleState.resumed:
        // Resume processing when app comes to foreground
        _attrs?.start();
        break;
      case AppLifecycleState.hidden:
        // On newer Flutter versions
        _attrs?.stop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraProvider>();
    // Settings no longer gate age/gender/ethnicity display here
    final history = context.watch<HistoryProvider>();
    // Use internal _attrs instance for overlays instead of watching provider (which we never added to tree)
    final faces = _attrs?.faces ?? const <FaceAttributes>[];

    // Debug: print face count
    if (faces.isNotEmpty) {
      debugPrint(
          '✅ Detected ${faces.length} face(s) - Emotion: ${faces.first.emotion}');
    }

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

                    // TOP-CENTER: Real-time morphing emoji avatar (always visible, default neutral)
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: MorphingEmoji(
                          emotion: faces.isNotEmpty
                              ? faces.first.emotion
                              : Emotion
                                  .neutral, // Default to neutral when no face
                          size: 120,
                          showFaceCircle: true,
                        ),
                      ),
                    ),

                    // BOTTOM-RIGHT: Age/Gender/Ethnicity capsule (always visible)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: _AgeGenderEthnicityCard(
                        face: faces.isNotEmpty ? faces.first : null,
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
                children: [
                  // Left: switch camera
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton.filled(
                        onPressed: () async {
                          await camera.toggleCamera();
                        },
                        icon: Icon(
                          camera.isFront
                              ? Icons.cameraswitch
                              : Icons.cameraswitch_outlined,
                        ),
                        tooltip: 'Switch camera',
                      ),
                    ),
                  ),
                  // Center: capture button
                  Expanded(
                    child: Center(
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (camera.controller == null) return;
                          try {
                            // Temporarily stop streaming/processing to avoid camera crashes on capture
                            try {
                              await _attrs?.stop();
                            } catch (e) {
                              debugPrint('⚠️ Error stopping attributes: $e');
                            }
                            // Allow the camera to settle after stopping the stream (iOS race-condition fix)
                            await Future.delayed(
                                const Duration(milliseconds: 80));
                            final img = await camera.controller!.takePicture();

                            if (faces.isNotEmpty) {
                              final face = faces.first;
                              final ageGenderData = AgeGenderData(
                                ageRange: face.ageRange,
                                gender: face.gender,
                                confidence: face.confidence,
                              );
                              final savedPath = await history.addCapture(
                                imagePath: img.path,
                                emotion: face.emotion,
                                confidence: face.confidence,
                                ageGender: ageGenderData,
                              );
                              // Save to Photos/Gallery using photo_manager (defer to microtask)
                              // Don't await to prevent blocking the UI
                              Future.microtask(() => _saveToPhotos(savedPath));
                            } else {
                              // Save neutral placeholder entry even if no face
                              final savedPath = await history.addCapture(
                                imagePath: img.path,
                                emotion: Emotion.neutral,
                                confidence: 0.0,
                                ageGender: null,
                              );
                              Future.microtask(() => _saveToPhotos(savedPath));
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Captured!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                            // Resume detection stream after capture
                            // Add a longer delay on iOS to avoid race conditions with photo save
                            await Future.delayed(Duration(
                                milliseconds: Platform.isIOS ? 500 : 350));
                            if (!mounted) return;
                            try {
                              await _attrs?.start();
                            } catch (e) {
                              debugPrint('⚠️ Error restarting attributes: $e');
                            }
                          } catch (e, stackTrace) {
                            debugPrint('❌ Capture error: $e');
                            debugPrint('Stack trace: $stackTrace');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                            // Attempt to resume stream on error as well
                            try {
                              await _attrs?.start();
                            } catch (e) {
                              debugPrint(
                                  '⚠️ Error restarting attributes after error: $e');
                            }
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Capture'),
                        style: ButtonStyle(
                          textStyle: WidgetStatePropertyAll(
                            TextStyle(
                              fontSize: Theme.of(context).platform ==
                                      TargetPlatform.iOS
                                  ? 13.0
                                  : 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          minimumSize: WidgetStatePropertyAll(
                            Size(
                              Theme.of(context).platform == TargetPlatform.iOS
                                  ? 140
                                  : 120,
                              44,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Right: flash toggle
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Builder(builder: (context) {
                        // CameraValue does not expose flashAvailable directly; assume flash unsupported on front camera
                        final hasFlash = !(camera.isFront);
                        return IconButton.filled(
                          onPressed: (!camera.isInitialized || !hasFlash)
                              ? null
                              : () async {
                                  final next = switch (camera.flash) {
                                    FlashMode.off => FlashMode.torch,
                                    FlashMode.torch => FlashMode.off,
                                    _ => FlashMode.off,
                                  };
                                  await camera.setFlash(next);
                                  if (mounted) setState(() {});
                                },
                          icon: Icon(
                            (camera.flash == FlashMode.torch && hasFlash)
                                ? Icons.flash_on
                                : Icons.flash_off,
                          ),
                          tooltip:
                              hasFlash ? 'Toggle flash' : 'Flash not available',
                        );
                      }),
                    ),
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

/// Professional single-row capsule with blackish transparent background
class _AgeGenderEthnicityCard extends StatelessWidget {
  const _AgeGenderEthnicityCard({
    required this.face,
  });
  final FaceAttributes? face; // Now nullable

  @override
  Widget build(BuildContext context) {
    final ethnicity = face?.ethnicity ?? '---';
    final ageRange = face?.ageRange ?? '---';
    final gender = face?.gender ?? '---';

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7), // Blackish transparent
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Age
          _InfoItem(
            icon: Icons.calendar_today_rounded,
            text: ageRange,
            iconColor: Colors.amber.shade400,
          ),
          const SizedBox(width: 16),
          // Gender
          _InfoItem(
            icon: gender.toLowerCase() == 'male'
                ? Icons.male_rounded
                : gender.toLowerCase() == 'female'
                    ? Icons.female_rounded
                    : Icons.person_outline_rounded,
            text: gender,
            iconColor: Colors.blue.shade300,
          ),
          const SizedBox(width: 16),
          // Ethnicity
          _InfoItem(
            icon: Icons.public_rounded,
            text: ethnicity,
            iconColor: Colors.green.shade300,
          ),
        ],
      ),
    );
  }
}

/// Individual info item with icon and text
class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.text,
    required this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
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
          painter: _BoxesPainter(provider.faces),
        );
      },
    );
  }
}

class _BoxesPainter extends CustomPainter {
  _BoxesPainter(this.faces);
  final List<FaceAttributes> faces;

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

      // Emoji rendering handled by top-center card; avoid drawing emoji here to prevent duplication.

      // Info: age • gender • ethnicity (or Unknown)
      final info = "${f.ageRange} • ${f.gender} • ${f.ethnicity ?? 'Unknown'}";
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
