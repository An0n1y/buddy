import 'package:camera/camera.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/presentation/providers/camera_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:emotion_sense/presentation/providers/emotion_provider.dart';
import 'package:emotion_sense/presentation/providers/history_provider.dart';
import 'package:emotion_sense/data/models/age_gender_data.dart';
import 'package:emotion_sense/presentation/widgets/camera_preview_widget.dart';
import 'package:emotion_sense/presentation/widgets/morphing_emoji.dart';
import 'package:emotion_sense/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Emotion? _lastCapturedEmotion;
  DateTime _lastAutoCapture = DateTime.fromMillisecondsSinceEpoch(0);
  Duration _autoCaptureCooldown = const Duration(seconds: 8);
  double autoCaptureMinConfidence = 0.75;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraProvider>().initialize();
      // Listen for emotion changes to trigger auto-capture.
      final emotionProvider = context.read<EmotionProvider>();
      emotionProvider.addListener(_maybeAutoCapture);
    });
  }

  @override
  void dispose() {
    context.read<EmotionProvider>().removeListener(_maybeAutoCapture);
    super.dispose();
  }

  void _maybeAutoCapture() async {
    if (!mounted) return;
    final emotionProvider = context.read<EmotionProvider>();
    final camera = context.read<CameraProvider>();
    final history = context.read<HistoryProvider>();
    final settings = context.read<SettingsProvider>();
    if (!settings.autoCapture) return;
    // Refresh thresholds from settings
    autoCaptureMinConfidence = settings.autoCaptureConfidence;
    _autoCaptureCooldown = Duration(seconds: settings.autoCaptureCooldownSec);
    final now = DateTime.now();
    final changed = emotionProvider.current != _lastCapturedEmotion;
    final highConfidence =
        emotionProvider.confidence >= autoCaptureMinConfidence;
    final cooldownPassed =
        now.difference(_lastAutoCapture) >= _autoCaptureCooldown;
    if (changed && highConfidence && cooldownPassed) {
      final file = await camera.controller?.takePicture();
      if (file != null) {
        await history.addCapture(
          imagePath: file.path,
          emotion: emotionProvider.current,
          confidence: emotionProvider.confidence,
          ageGender: emotionProvider.ageGender,
        );
        _lastCapturedEmotion = emotionProvider.current;
        _lastAutoCapture = now;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Auto-captured ${emotionProvider.current.emoji}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emotion = context.watch<EmotionProvider>();
    final camera = context.watch<CameraProvider>();
    final settings = context.watch<SettingsProvider>();
    // Keep provider thresholds in sync with settings
    emotion.updateSettings(
      threshold: settings.sensitivity,
      sound: settings.soundOn,
      haptic: settings.hapticOn,
      smoothing: settings.smoothingAlpha,
      windowSize: settings.confidenceWindow,
      missingFramesToNeutral: settings.missingFramesNeutral,
      frameRate: settings.frameRate,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('EmotionSense'),
        actions: [
          FutureBuilder<PermissionStatus>(
            future: Permission.camera.status,
            builder: (context, snapshot) {
              final status = snapshot.data;
              Color color;
              IconData icon;
              String tooltip;
              switch (status) {
                case PermissionStatus.granted:
                  color = Colors.green;
                  icon = Icons.videocam;
                  tooltip = 'Camera granted';
                  break;
                case PermissionStatus.denied:
                  color = Colors.orange;
                  icon = Icons.videocam_off;
                  tooltip = 'Camera denied';
                  break;
                case PermissionStatus.permanentlyDenied:
                case PermissionStatus.restricted:
                  color = Colors.red;
                  icon = Icons.lock;
                  tooltip = 'Enable in Settings';
                  break;
                default:
                  color = Colors.grey;
                  icon = Icons.help_outline;
                  tooltip = 'Unknown';
              }
              return IconButton(
                tooltip: tooltip,
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (status == PermissionStatus.denied ||
                      status == PermissionStatus.restricted ||
                      status == PermissionStatus.permanentlyDenied) {
                    await openAppSettings();
                    if (!mounted) return;
                    setState(() {}); // refresh
                  } else if (status == PermissionStatus.granted) {
                    messenger.showSnackBar(const SnackBar(
                        content: Text('Camera already granted')));
                  } else {
                    final result = await Permission.camera.request();
                    if (!mounted) return;
                    messenger.showSnackBar(
                        SnackBar(content: Text('Camera status: $result')));
                    setState(() {});
                  }
                },
                icon: Icon(icon, color: color),
              );
            },
          ),
          IconButton(
              onPressed: () => Navigator.pushNamed(context, '/history'),
              icon: const Icon(Icons.history)),
          IconButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              icon: const Icon(Icons.settings)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CameraPreviewWidget(controller: camera.controller),
                    ),
                    // Centered emoji overlay without background
                    // Face-tracked emoji (fallback to center if no bounds)
                    _FaceTrackedEmoji(emotion: emotion),
                    // Bottom-right age/gender overlay chip (if enabled)
                    if (settings.showAgeGender)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: _AgeGenderChip(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Controls(camera: camera),
              const SizedBox(height: 8),
              _ManualOverride(emotion: emotion),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeGenderChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ageGender =
        context.select<EmotionProvider, AgeGenderData?>((p) => p.ageGender);
    final text =
        ageGender == null ? '—' : '${ageGender.ageRange} • ${ageGender.gender}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.camera});
  final CameraProvider camera;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
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
        IconButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final file = await camera.controller?.takePicture();
            if (!context.mounted) return;
            if (file == null) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Capture failed')),
              );
              return;
            }
            // Access providers after ensuring mounted (context safe).
            final emotionProvider = context.read<EmotionProvider>();
            final history = context.read<HistoryProvider>();
            final stubAgeGender = AgeGenderData(
              ageRange: '25-30',
              gender: 'Unknown',
              confidence: 0.0,
            );
            await history.addCapture(
              imagePath: file.path,
              emotion: emotionProvider.current,
              confidence: emotionProvider.confidence,
              ageGender: stubAgeGender,
            );
            if (!context.mounted) return;
            messenger.showSnackBar(
              SnackBar(content: Text('Saved: ${file.path}')),
            );
          },
          icon: const Icon(Icons.camera),
        ),
      ],
    );
  }
}

class _ManualOverride extends StatelessWidget {
  const _ManualOverride({required this.emotion});
  final EmotionProvider emotion;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Emotion.values.map((e) {
        return ElevatedButton(
          onPressed: () => emotion.manualOverride(e),
          child: Text(e.emoji),
        );
      }).toList(),
    );
  }
}

class _FaceTrackedEmoji extends StatelessWidget {
  const _FaceTrackedEmoji({required this.emotion});
  final EmotionProvider emotion;

  @override
  Widget build(BuildContext context) {
    final bounds = emotion.smoothedFaceBounds?.rect ?? emotion.faceBounds?.rect;
    final size = MediaQuery.of(context).size;
    const baseSize = 120.0;
    if (bounds == null) {
      return Align(
        alignment: Alignment.center,
        child: MorphingEmoji(
          emotion: emotion.current,
          size: baseSize,
          showFaceCircle: false,
        ),
      );
    }
    // Scale emoji relative to face width (normalized) with clamp.
    final scaled = (bounds.width * size.width * 0.9).clamp(80.0, 180.0);
    final left =
        bounds.left * size.width + (bounds.width * size.width - scaled) / 2;
    final top =
        bounds.top * size.height + (bounds.height * size.height - scaled) / 2;
    return Positioned(
      left: left,
      top: top,
      width: scaled,
      height: scaled,
      child: MorphingEmoji(
        emotion: emotion.current,
        size: scaled,
        showFaceCircle: false,
      ),
    );
  }
}
