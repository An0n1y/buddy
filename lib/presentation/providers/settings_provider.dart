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

  bool get showAgeGender => _showAgeGender;
  bool get useLottie => _useLottie;
  bool get soundOn => _soundOn;
  bool get hapticOn => _hapticOn;
  ThemeMode get themeMode => _themeMode;
  double get sensitivity => _sensitivity;
  int get frameRate => _frameRate;

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
}
