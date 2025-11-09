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
  int _targetFps = 15; // analysis target FPS
  bool _autoCapture = true;
  double _smoothingAlpha = 0.4;
  int _confidenceWindow = 12;
  int _missingFramesNeutral = 45;
  double _autoCaptureConfidence = 0.75;
  int _autoCaptureCooldownSec = 8;
  // New thresholds for heuristic / model tuning
  double _mouthOpenThreshold = 0.18;
  double _browCompressionThreshold = 0.10;
  double _energyThreshold = 0.25;
  double _smileThreshold = 0.50;
  double _eyeOpenThreshold = 0.45;

  bool get showAgeGender => _showAgeGender;
  bool get useLottie => _useLottie;
  bool get soundOn => _soundOn;
  bool get hapticOn => _hapticOn;
  ThemeMode get themeMode => _themeMode;
  double get sensitivity => _sensitivity;
  int get frameRate => _frameRate;
  int get targetFps => _targetFps;
  bool get autoCapture => _autoCapture;
  double get smoothingAlpha => _smoothingAlpha;
  int get confidenceWindow => _confidenceWindow;
  int get missingFramesNeutral => _missingFramesNeutral;
  double get autoCaptureConfidence => _autoCaptureConfidence;
  int get autoCaptureCooldownSec => _autoCaptureCooldownSec;
  double get mouthOpenThreshold => _mouthOpenThreshold;
  double get browCompressionThreshold => _browCompressionThreshold;
  double get energyThreshold => _energyThreshold;
  double get smileThreshold => _smileThreshold;
  double get eyeOpenThreshold => _eyeOpenThreshold;

  SettingsProvider() {
    _init();
  }

  // Test-only constructor: initializes synchronously with provided values, skipping async SharedPreferences.
  SettingsProvider.test({
    bool showAgeGender = true,
    bool useLottie = false,
    bool soundOn = true,
    bool hapticOn = true,
    ThemeMode themeMode = ThemeMode.system,
    double sensitivity = 0.6,
    int frameRate = 15,
    int targetFps = 15,
    bool autoCapture = true,
    double smoothingAlpha = 0.4,
    int confidenceWindow = 12,
    int missingFramesNeutral = 45,
    double autoCaptureConfidence = 0.75,
    int autoCaptureCooldownSec = 8,
    double mouthOpenThreshold = 0.18,
    double browCompressionThreshold = 0.10,
    double energyThreshold = 0.25,
    double smileThreshold = 0.50,
    double eyeOpenThreshold = 0.45,
  }) {
    _showAgeGender = showAgeGender;
    _useLottie = useLottie;
    _soundOn = soundOn;
    _hapticOn = hapticOn;
    _themeMode = themeMode;
    _sensitivity = sensitivity;
    _frameRate = frameRate;
    _targetFps = targetFps;
    _autoCapture = autoCapture;
    _smoothingAlpha = smoothingAlpha;
    _confidenceWindow = confidenceWindow;
    _missingFramesNeutral = missingFramesNeutral;
    _autoCaptureConfidence = autoCaptureConfidence;
    _autoCaptureCooldownSec = autoCaptureCooldownSec;
    _mouthOpenThreshold = mouthOpenThreshold;
    _browCompressionThreshold = browCompressionThreshold;
    _energyThreshold = energyThreshold;
    _smileThreshold = smileThreshold;
    _eyeOpenThreshold = eyeOpenThreshold;
  }

  Future<void> _init() async {
    _showAgeGender = await _repo.getShowAgeGender();
    _useLottie = await _repo.getUseLottie();
    _soundOn = await _repo.getSoundOn();
    _hapticOn = await _repo.getHapticOn();
    _themeMode = await _repo.getThemeMode();
    _sensitivity = await _repo.getSensitivity();
    _frameRate = await _repo.getFrameRate();
    _targetFps = await _repo.getTargetFps();
    _autoCapture = await _repo.getAutoCapture();
    _smoothingAlpha = await _repo.getSmoothingAlpha();
    _confidenceWindow = await _repo.getConfidenceWindow();
    _missingFramesNeutral = await _repo.getMissingFramesNeutral();
    _autoCaptureConfidence = await _repo.getAutoCaptureConfidence();
    _autoCaptureCooldownSec = await _repo.getAutoCaptureCooldownSec();
    _mouthOpenThreshold = await _repo.getMouthOpenThreshold();
    _browCompressionThreshold = await _repo.getBrowCompressionThreshold();
    _energyThreshold = await _repo.getEnergyThreshold();
    _smileThreshold = await _repo.getSmileThreshold();
    _eyeOpenThreshold = await _repo.getEyeOpenThreshold();
    // One-time normalization: fix out-of-range energy thresholds from older defaults.
    if (_energyThreshold > 1.0) {
      _energyThreshold = 0.25;
      await _repo.setEnergyThreshold(_energyThreshold);
    }
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

  Future<void> setTargetFps(int v) async {
    _targetFps = v;
    await _repo.setTargetFps(v);
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

  Future<void> setMouthOpenThreshold(double v) async {
    _mouthOpenThreshold = v;
    await _repo.setMouthOpenThreshold(v);
    notifyListeners();
  }

  Future<void> setBrowCompressionThreshold(double v) async {
    _browCompressionThreshold = v;
    await _repo.setBrowCompressionThreshold(v);
    notifyListeners();
  }

  Future<void> setEnergyThreshold(double v) async {
    _energyThreshold = v;
    await _repo.setEnergyThreshold(v);
    notifyListeners();
  }

  Future<void> setSmileThreshold(double v) async {
    _smileThreshold = v;
    await _repo.setSmileThreshold(v);
    notifyListeners();
  }

  Future<void> setEyeOpenThreshold(double v) async {
    _eyeOpenThreshold = v;
    await _repo.setEyeOpenThreshold(v);
    notifyListeners();
  }
}
