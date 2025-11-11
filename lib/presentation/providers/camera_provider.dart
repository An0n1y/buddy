import 'package:camera/camera.dart';
import 'package:emotion_sense/data/services/camera_service.dart';
import 'package:flutter/material.dart';

class CameraProvider extends ChangeNotifier {
  final CameraService _service = CameraService();
  CameraService get service => _service;

  CameraController? get controller => _service.controller;
  bool get isInitialized => _service.isInitialized.value;
  bool get isFront => _service.isFrontCamera.value;
  FlashMode get flash => _service.flashMode.value;

  Future<void> initialize() async {
    await _service.initialize();
    notifyListeners();
    _service.isInitialized.addListener(notifyListeners);
    _service.isFrontCamera.addListener(notifyListeners);
    _service.flashMode.addListener(notifyListeners);
  }

  Future<void> toggleCamera() async {
    await _service.toggleCamera();
    notifyListeners();
  }

  Future<void> setFlash(FlashMode mode) async {
    try {
      await _service.setFlash(mode);
    } catch (_) {
      // ignore failures (e.g., torch unsupported on front camera)
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
