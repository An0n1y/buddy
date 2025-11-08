import 'package:flutter/material.dart';
import 'package:emotion_sense/data/repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final _repo = SettingsRepository();

  bool _showAgeGender = true;
  bool _useLottie = false;
  bool _soundOn = true;
  bool _hapticOn = true;
  ThemeMode _themeMode = ThemeMode.system;
  double _sensitivity = 0.6; // 0..1
  int _frameRate = 15; // fps
  bool _autoCapture = true;
  double _smoothingAlpha = 0.4;
  int _confidenceWindow = 12;
  int _missingFramesNeutral = 45;
  double _autoCaptureConfidence = 0.75;
  int _autoCaptureCooldownSec = 8;

  bool get showAgeGender => _showAgeGender;
  bool get useLottie => _useLottie;
  bool get soundOn => _soundOn;
  bool get hapticOn => _hapticOn;
  ThemeMode get themeMode => _themeMode;
  double get sensitivity => _sensitivity;
  int get frameRate => _frameRate;
  bool get autoCapture => _autoCapture;
  double get smoothingAlpha => _smoothingAlpha;
  int get confidenceWindow => _confidenceWindow;
  int get missingFramesNeutral => _missingFramesNeutral;
  double get autoCaptureConfidence => _autoCaptureConfidence;
  int get autoCaptureCooldownSec => _autoCaptureCooldownSec;

  SettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    _showAgeGender = await _repo.getShowAgeGender();
    _useLottie = await _repo.getUseLottie();
    _soundOn = await _repo.getSoundOn();
    _hapticOn = await _repo.getHapticOn();
    _themeMode = await _repo.getThemeMode();
    _sensitivity = await _repo.getSensitivity();
    _frameRate = await _repo.getFrameRate();
    _autoCapture = await _repo.getAutoCapture();
    _smoothingAlpha = await _repo.getSmoothingAlpha();
    _confidenceWindow = await _repo.getConfidenceWindow();
    _missingFramesNeutral = await _repo.getMissingFramesNeutral();
    _autoCaptureConfidence = await _repo.getAutoCaptureConfidence();
    _autoCaptureCooldownSec = await _repo.getAutoCaptureCooldownSec();
    notifyListeners();
  }

  Future<void> setShowAgeGender(bool v) async {
    _showAgeGender = v;
    await _repo.setShowAgeGender(v);
    notifyListeners();
  }

  Future<void> setUseLottie(bool v) async {
    _useLottie = v;
    await _repo.setUseLottie(v);
    notifyListeners();
  }

  Future<void> setSoundOn(bool v) async {
    _soundOn = v;
    await _repo.setSoundOn(v);
    notifyListeners();
  }

  Future<void> setHapticOn(bool v) async {
    _hapticOn = v;
    await _repo.setHapticOn(v);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _repo.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setSensitivity(double v) async {
    _sensitivity = v;
    await _repo.setSensitivity(v);
    notifyListeners();
  }

  Future<void> setFrameRate(int v) async {
    _frameRate = v;
    await _repo.setFrameRate(v);
    notifyListeners();
  }

  Future<void> setAutoCapture(bool v) async {
    _autoCapture = v;
    await _repo.setAutoCapture(v);
    notifyListeners();
  }

  Future<void> setSmoothingAlpha(double v) async {
    _smoothingAlpha = v;
    await _repo.setSmoothingAlpha(v);
    notifyListeners();
  }

  Future<void> setConfidenceWindow(int v) async {
    _confidenceWindow = v;
    await _repo.setConfidenceWindow(v);
    notifyListeners();
  }

  Future<void> setMissingFramesNeutral(int v) async {
    _missingFramesNeutral = v;
    await _repo.setMissingFramesNeutral(v);
    notifyListeners();
  }

  Future<void> setAutoCaptureConfidence(double v) async {
    _autoCaptureConfidence = v;
    await _repo.setAutoCaptureConfidence(v);
    notifyListeners();
  }

  Future<void> setAutoCaptureCooldownSec(int v) async {
    _autoCaptureCooldownSec = v;
    await _repo.setAutoCaptureCooldownSec(v);
    notifyListeners();
  }
}
