import 'package:flutter_test/flutter_test.dart';
import 'package:emotion_sense/data/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsRepository', () {
    late SettingsRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = SettingsRepository();
    });

    test('default values', () async {
      expect(await repo.getShowAgeGender(), true);
      expect(await repo.getSoundOn(), true);
      expect(await repo.getHapticOn(), true);
      expect(await repo.getThemeMode(), ThemeMode.system);
      expect(await repo.getSensitivity(), 0.6);
      expect(await repo.getFrameRate(), 15);
    });

    test('set & get toggles', () async {
      await repo.setShowAgeGender(false);
      await repo.setSoundOn(false);
      await repo.setHapticOn(false);
      await repo.setThemeMode(ThemeMode.dark);
      await repo.setSensitivity(0.75);
      await repo.setFrameRate(24);

      expect(await repo.getShowAgeGender(), false);
      expect(await repo.getSoundOn(), false);
      expect(await repo.getHapticOn(), false);
      expect(await repo.getThemeMode(), ThemeMode.dark);
      expect(await repo.getSensitivity(), 0.75);
      expect(await repo.getFrameRate(), 24);
    });
  });
}
