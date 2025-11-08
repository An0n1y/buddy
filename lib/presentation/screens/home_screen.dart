import 'package:camera/camera.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/presentation/providers/camera_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:emotion_sense/presentation/providers/emotion_provider.dart';
import 'package:emotion_sense/presentation/providers/history_provider.dart';
import 'package:emotion_sense/data/models/age_gender_data.dart';
import 'package:emotion_sense/presentation/widgets/camera_preview_widget.dart';
import 'package:emotion_sense/presentation/widgets/emotion_display_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final emotion = context.watch<EmotionProvider>();
    final camera = context.watch<CameraProvider>();

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
                    Align(
                      alignment: Alignment.topCenter,
                      child: EmotionDisplayCard(
                        emotion: emotion.current,
                        confidence: emotion.confidence,
                      ),
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
            final file = await camera.controller?.takePicture();
            if (!context.mounted) return;
            if (file != null) {
              // Add to history with current emotion info and stub age/gender.
              final emotionProvider = context.read<EmotionProvider>();
              final history = context.read<HistoryProvider>();
              // Placeholder age/gender data (future: real estimation)
              final stubAgeGender = AgeGenderData(
                  ageRange: '25-30', gender: 'Unknown', confidence: 0.0);
              await history.addCapture(
                imagePath: file.path,
                emotion: emotionProvider.current,
                confidence: emotionProvider.confidence,
                ageGender: stubAgeGender,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Saved: ${file.path}')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Capture failed')),
              );
            }
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
