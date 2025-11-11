import 'package:emotion_sense/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable ethnicity classification'),
            subtitle: const Text('Sensitive attribute – opt-in only'),
            value: s.ethnicityEnabled,
            onChanged: (v) => s.setEthnicityEnabled(v),
          ),
          SwitchListTile(
            title: const Text('Show age & gender'),
            value: s.showAgeGender,
            onChanged: (v) => s.setShowAgeGender(v),
          ),
          SwitchListTile(
            title: const Text('Sound effects'),
            value: s.soundOn,
            onChanged: (v) => s.setSoundOn(v),
          ),
          SwitchListTile(
            title: const Text('Haptic feedback'),
            value: s.hapticOn,
            onChanged: (v) => s.setHapticOn(v),
          ),
          const Divider(),
          ListTile(
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: s.themeMode,
              onChanged: (v) => v != null ? s.setThemeMode(v) : null,
              items: const [
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ),
          ListTile(
            title: const Text('Detection sensitivity'),
            subtitle: Slider(
              value: s.sensitivity,
              min: 0.3,
              max: 0.9,
              onChanged: (v) => s.setSensitivity(v),
            ),
          ),
          ListTile(
            title: const Text('Frame rate'),
            subtitle: Slider(
              value: s.frameRate.toDouble(),
              min: 10,
              max: 30,
              divisions: 4,
              label: '${s.frameRate} fps',
              onChanged: (v) => s.setFrameRate(v.round()),
            ),
          ),
          ListTile(
            title: const Text('Analysis target FPS'),
            subtitle: Slider(
              value: s.targetFps.toDouble(),
              min: 10,
              max: 30,
              divisions: 4,
              label: '${s.targetFps} fps',
              onChanged: (v) => s.setTargetFps(v.round()),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Auto capture on emotion change'),
            value: s.autoCapture,
            onChanged: (v) => s.setAutoCapture(v),
          ),
          ListTile(
            title: const Text('Auto capture confidence'),
            subtitle: Slider(
              value: s.autoCaptureConfidence,
              min: 0.5,
              max: 0.95,
              divisions: 9,
              label: s.autoCaptureConfidence.toStringAsFixed(2),
              onChanged: (v) => s.setAutoCaptureConfidence(v),
            ),
          ),
          ListTile(
            title: const Text('Auto capture cooldown (sec)'),
            subtitle: Slider(
              value: s.autoCaptureCooldownSec.toDouble(),
              min: 3,
              max: 20,
              divisions: 17,
              label: '${s.autoCaptureCooldownSec}s',
              onChanged: (v) => s.setAutoCaptureCooldownSec(v.round()),
            ),
          ),
          ListTile(
            title: const Text('Smoothing alpha'),
            subtitle: Slider(
              value: s.smoothingAlpha,
              min: 0.1,
              max: 0.8,
              divisions: 14,
              label: s.smoothingAlpha.toStringAsFixed(2),
              onChanged: (v) => s.setSmoothingAlpha(v),
            ),
          ),
          ListTile(
            title: const Text('Confidence window size'),
            subtitle: Slider(
              value: s.confidenceWindow.toDouble(),
              min: 4,
              max: 24,
              divisions: 20,
              label: s.confidenceWindow.toString(),
              onChanged: (v) => s.setConfidenceWindow(v.round()),
            ),
          ),
          ListTile(
            title: const Text('Frames missing before neutral'),
            subtitle: Slider(
              value: s.missingFramesNeutral.toDouble(),
              min: 10,
              max: 120,
              divisions: 11,
              label: s.missingFramesNeutral.toString(),
              onChanged: (v) => s.setMissingFramesNeutral(v.round()),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('About'),
            subtitle: Text(
                'EmotionSense — On-device, privacy-first.\nLibraries: camera, provider, google_fonts, audioplayers.'),
          ),
        ],
      ),
    );
  }
}
