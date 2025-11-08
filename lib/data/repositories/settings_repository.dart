import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _kShowAgeGender = 'show_age_gender';
  static const _kUseLottie = 'use_lottie';
  static const _kSoundOn = 'sound_on';
  static const _kHapticOn = 'haptic_on';
  static const _kThemeMode = 'theme_mode'; // system, light, dark
  static const _kSensitivity = 'detection_sensitivity';
  static const _kFrameRate = 'frame_rate';

  Future<bool> getShowAgeGender() async =>
      (await SharedPreferences.getInstance()).getBool(_kShowAgeGender) ?? true;
  Future<void> setShowAgeGender(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kShowAgeGender, v);

  Future<bool> getUseLottie() async =>
      (await SharedPreferences.getInstance()).getBool(_kUseLottie) ?? false;
  Future<void> setUseLottie(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kUseLottie, v);

  Future<bool> getSoundOn() async =>
      (await SharedPreferences.getInstance()).getBool(_kSoundOn) ?? true;
  Future<void> setSoundOn(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kSoundOn, v);

  Future<bool> getHapticOn() async =>
      (await SharedPreferences.getInstance()).getBool(_kHapticOn) ?? true;
  Future<void> setHapticOn(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kHapticOn, v);

  Future<ThemeMode> getThemeMode() async {
    final s = (await SharedPreferences.getInstance()).getString(_kThemeMode);
    return switch (s) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final s = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    (await SharedPreferences.getInstance()).setString(_kThemeMode, s);
  }

  Future<double> getSensitivity() async =>
      (await SharedPreferences.getInstance()).getDouble(_kSensitivity) ?? 0.6;
  Future<void> setSensitivity(double v) async =>
      (await SharedPreferences.getInstance()).setDouble(_kSensitivity, v);

  Future<int> getFrameRate() async =>
      (await SharedPreferences.getInstance()).getInt(_kFrameRate) ?? 15;
  Future<void> setFrameRate(int v) async =>
      (await SharedPreferences.getInstance()).setInt(_kFrameRate, v);
}
