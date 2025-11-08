import 'package:emotion_sense/core/utils/permission_manager.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _checked = false;
  bool _requesting = false;

  Future<void> _continue() async {
    setState(() => _requesting = true);
    final manager = PermissionManager();
    final granted = await manager.ensureCamera();
    setState(() => _requesting = false);
    if (!mounted) return;
    if (granted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // If permission is denied, guide the user to Settings to enable it.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Camera permission is required. Opening Settings so you can enable it.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Privacy-first',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                  'All processing happens on your device. No data is collected or sent.'),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _checked,
                onChanged: (v) => setState(() => _checked = v ?? false),
                title: const Text('I understand and agree'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checked && !_requesting ? _continue : null,
                  child: _requesting
                      ? const CircularProgressIndicator()
                      : const Text('Continue'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _requesting
                      ? null
                      : () async {
                          final manager = PermissionManager();
                          await manager.openSettings();
                        },
                  child: const Text('Open Settings'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
