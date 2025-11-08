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
            title: const Text('Show age & gender'),
            value: s.showAgeGender,
            onChanged: (v) => s.setShowAgeGender(v),
          ),
          SwitchListTile(
            title: const Text('Use Lottie animations'),
            subtitle: const Text('Morphing Emoji is default'),
            value: s.useLottie,
            onChanged: (v) => s.setUseLottie(v),
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
