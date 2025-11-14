# EmotionSense

Real-time emotion detection app with morphing emoji UI. Uses Google ML Kit for simple, accurate emotion recognition.

## Features

- **Real-time emotion detection**: Live morphing emoji mirrors your facial expressions
- **Simple ML logic**: Smile-based detection (>70% = Happy, 40-70% = Neutral, <40% = Sad)
- **Privacy-first**: All processing on-device, no network calls
- **Morphing Emoji**: Animated face with smooth emotional transitions

## Quick Start

```bash
flutter pub get
flutter run -d emulator-5554   # Android
flutter run -d iPhone          # iOS
```

## Emotion Detection Logic

Uses **Google ML Kit Face Detection** with smile analysis:

- **Happy** ���: `smilingProbability > 0.70`
- **Neutral** ���: `smilingProbability 0.40-0.70`
- **Sad** ���: `smilingProbability < 0.40`

Real-time processing at ~5 FPS with hysteresis to prevent flickering.

## Project Structure

```
lib/
├── ui/camera_view.dart              # Main camera + emoji overlay
├── presentation/
│   ├── providers/
│   │   └── face_attributes_provider.dart  # Emotion detection
│   └── widgets/
│       └── morphing_emoji.dart      # Animated emoji
└── services/
    └── face_detection_service.dart  # ML Kit wrapper
```

## Privacy

✅ All processing on-device  
✅ No network requests  
✅ No analytics/telemetry  
✅ Photos saved locally only  

## iOS Build

```bash
flutter build ios --release --no-codesign
# Produces Runner-unsigned.ipa for side-loading
```

## License

MIT
