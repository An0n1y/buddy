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

- Camera preview with basic controls (no ML processing)
- Morphing Emoji widget with:
  - emotion-based color/shape
  - blinking (frequency varies per emotion)
  - rare double-blink and pre-blink squint (happy/funny)
- Onboarding (privacy-first), Settings, History (stub)
- Provider state management

## Troubleshooting

- Device id typos: use `emulator-5554` (not `emulato-5554`). Run `flutter devices` to confirm ids.
- Missing Android/iOS folders: run `flutter create .` once at repo root.
- Permissions: the app requests camera permission at onboarding.
- Analyzer lints: run `flutter analyze`. Most are enforced via `analysis_options.yaml`.

## License

MIT
