import 'package:camera/camera.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/presentation/providers/camera_provider.dart';
import 'package:emotion_sense/presentation/providers/emotion_provider.dart';
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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    file != null ? 'Saved: ${file.path}' : 'Capture failed')));
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
