import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Manages camera lifecycle and exposes a controller for preview and capture.
class CameraService {
  CameraController? _controller;
  final ValueNotifier<bool> isInitialized = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isFrontCamera = ValueNotifier<bool>(true);
  final ValueNotifier<FlashMode> flashMode =
      ValueNotifier<FlashMode>(FlashMode.off);

  CameraController? get controller => _controller;

  Future<void> initialize() async {
    final cameras = await availableCameras();
    // Prefer front camera
    CameraDescription? front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.isNotEmpty
          ? cameras.first
          : throw StateError('No camera found'),
    );
    _controller =
        CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    isInitialized.value = true;
    isFrontCamera.value =
        _controller!.description.lensDirection == CameraLensDirection.front;
    // initial flash mode from controller value
    flashMode.value = _controller!.value.flashMode;
  }

  Future<void> toggleCamera() async {
    if (!isInitialized.value) return;
    final cameras = await availableCameras();
    final targetDirection = isFrontCamera.value
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final target = cameras.firstWhere(
      (c) => c.lensDirection == targetDirection,
      orElse: () => _controller!.description,
    );
    await _controller?.dispose();
    _controller =
        CameraController(target, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    isFrontCamera.value = targetDirection == CameraLensDirection.front;
  }

  Future<void> setFlash(FlashMode mode) async {
    if (_controller == null) return;
    await _controller!.setFlashMode(mode);
    flashMode.value = mode;
  }

  Future<XFile?> capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    return _controller!.takePicture();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    isInitialized.dispose();
    isFrontCamera.dispose();
    flashMode.dispose();
  }
}
