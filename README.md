# EmotionSense (no-ML mode)

Real-time camera app scaffold with a unique morphing-emoji UI, privacy-first (no network, no analytics). This repo is configured to build an unsigned iOS IPA via GitHub Actions for side-loading tools.

## Run locally

- Prereqs: Flutter (stable), Android SDK/Emulator or iOS (Xcode/simulator).
- Install packages:

```bash
flutter pub get
```

- Android emulator example (fix device id typos):

```bash
# List devices
flutter devices
# Launch on a running emulator by id
flutter run -d emulator-5554
```

If you see “AndroidManifest.xml could not be found”, generate platform folders once:

```bash
flutter create .
```

- Windows desktop or Web are also available (debug only):

```bash
flutter run -d windows
# or
flutter run -d chrome
```

## iOS unsigned IPA (CI)

The workflow `.github/workflows/ci.yml` builds iOS only and produces an unsigned IPA without code signing.

Steps:

1. Push to `main` or `develop` (or open a PR).
2. Open the workflow run → Artifacts → download `Runner-unsigned.ipa`.
3. Side-load with your preferred tool (e.g., TrollStore) on your device.

Notes:

- The job uses `flutter build ios --release --no-codesign` and zips `Runner.app` into `Runner-unsigned.ipa`.
- No Apple developer account or signing is used in CI.

## Project structure

- `lib/`
  - `app.dart`, `main.dart`
  - `core/` (constants, utils)
  - `data/` (models, services, repositories)
  - `presentation/` (providers, screens, widgets)
- `.github/workflows/ci.yml` (iOS-only unsigned build)

## Features implemented

- **Real-time emotion avatar**: Camera preview displays a live morphing emoji that mirrors detected facial expressions (happy, sad, angry, surprised, funny, neutral)
- **Morphing Emoji widget** (`lib/presentation/widgets/morphing_emoji.dart`):
  - Programmatically drawn face (eyes, eyebrows, mouth) with smooth transitions
  - Emotion-based colors, shapes, and decorations (tears for sad, sparkles for surprised, etc.)
  - Autonomous blinking with emotion-dependent frequency
  - Rare double-blink and pre-blink squint for happy/funny emotions
  - Pure Flutter CustomPainter—no external assets or 3D models needed
- **Face detection integration**: Google ML Kit face detection with age/gender/ethnicity attributes
- Onboarding (privacy-first), Settings, History
- Provider state management

## Success criteria

- **Real-time emotion mirroring**: Live morphing emoji avatar in camera view reflects detected facial expressions with smooth animations
- Face detection: Google ML Kit detects faces and estimates emotion, age, gender, ethnicity
- Privacy-first: no network calls, no analytics/telemetry, no third-party SDK tracking
- iOS CI produces unsigned IPA: GitHub Actions builds with `--no-codesign` and packages `Runner-unsigned.ipa`
- Morphing Emoji animation: smooth morphs per emotion, blinking with emotion-dependent frequency, occasional double-blink and pre-blink squint
- Settings persistence: toggles and sliders stored via `SharedPreferences` through `SettingsRepository`
- Dark and light theme support: switchable in Settings
- Lints pass: project follows `flutter_lints` with extra rules (package imports, debouncer disposal, etc.)

## Privacy

- The app does not collect, transmit, or store personal data beyond local settings (theme/feedback toggles).
- Camera frames are not uploaded or analyzed by ML models; preview is shown locally only.
- No network requests are performed; you can verify by searching for `http`, `dio`, or `socket` usages (none present).

## Troubleshooting

- Device id typos: use `emulator-5554` (not `emulato-5554`). Run `flutter devices` to confirm ids.
- Missing Android/iOS folders: run `flutter create .` once at repo root.
- Permissions: the app requests camera permission at onboarding.
- Analyzer lints: run `flutter analyze`. Most are enforced via `analysis_options.yaml`.

## License

MIT
