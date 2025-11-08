PROJECT PROMPT — EmotionSense: Real-Time Emotion, Age & Gender Recognition App (Flutter)
🎯 Goal
Build a production-ready Flutter mobile app that detects user emotion, gender, and approximate age from live camera input using pre-trained ML models. This portfolio project demonstrates advanced camera integration, real-time face analysis, state management, and polished UI/UX design.

🏗️ High-Level Overview
App Name: EmotionSense
Target Platforms: Android (local build) + iOS (GitHub Actions CI)
Stack: Flutter stable channel, Dart (null-safety enabled)
Philosophy: Privacy-first (100% on-device processing), offline-capable, accessibility-focused

🧩 Core Features
1. Camera-Based Face Capture

Access front camera by default (with back camera toggle option)
Live preview using camera plugin with optimized frame rate
Auto-focus and exposure control for optimal face detection
Handle camera lifecycle (pause on background, resume on foreground)

2. Emotion Recognition

Detect 6 emotions: 😄 Happy, 😢 Sad, 😠 Angry, 😲 Surprised, 😐 Neutral, 🤣 Funny
Use pre-trained models via:

Primary: google_mlkit_face_detection + tflite_flutter with emotion classification model
Alternative: faceids or equivalent open-source package


Display detected emotion with:

Large animated emoji OR
Lottie character animation (user-selectable)
Confidence percentage indicator


Update smoothly (debounce rapid changes, ~300ms threshold)

3. Age & Gender Estimation

Display approximate age range (e.g., "25-30 years")
Show gender prediction with confidence (e.g., "Female • 87%")
Gracefully handle low-confidence results ("Not detected")
Toggle visibility via settings

4. Real-Time Visualization

Emotion Animator Widget:

Animated background color transitions per emotion
Pulsing/scaling effects on emotion change
Sound feedback (optional, via audioplayers)
Haptic feedback on emotion switch


Face Overlay (Optional Enhancement):

Draw bounding box around detected face
Facial landmark dots (eyes, nose, mouth)



5. Interactive Controls

Camera Controls:

Front/back camera switch button
Flash toggle (if supported)
Capture snapshot button (save to history)


Manual Override (Testing Mode):

Bottom drawer with emotion selector buttons
Useful for debugging or demo purposes



6. Privacy & Permissions

Onboarding Screen:

Clear explanation: "All processing happens on your device"
Camera permission request with context
No data collection disclaimer


Permission Handling:

Use permission_handler for granular control
Graceful degradation if camera denied



7. Settings Page

Toggles:

Show/hide age & gender
Emoji vs Lottie animations
Sound effects on/off
Haptic feedback on/off
Dark mode (system/light/dark)


Advanced:

Detection sensitivity slider
Frame rate adjustment (performance vs accuracy)


Storage: Save preferences with shared_preferences

8. History & Insights (Optional Enhancement)

Save snapshots with timestamp, emotion, age, gender
Gallery view of past detections
Simple stats: "Most common emotion today"
Export history as CSV or JSON


🎨 UI/UX Guidelines
Design Principles

Modern & Minimal: Material 3 design system
Accessibility: Semantic labels, high contrast mode, screen reader support
Responsive: Adapt to all screen sizes (phones, tablets)
Smooth Animations: 60fps target with flutter_animate

Screen Structure

Home Screen (Camera Feed)

Full-screen camera preview
Floating emotion display at top
Age/gender card at bottom (collapsible)
Control buttons overlay (corners)


Settings Screen

Grouped sections with headers
Switch widgets with descriptions
"About" section with library credits


History Screen (Optional)

Grid or list of saved snapshots
Filter by emotion/date
Tap to view details



Color Palette (Emotion-Based)
dartfinal emotionColors = {
  Emotion.happy: Colors.amber,
  Emotion.sad: Colors.blue,
  Emotion.angry: Colors.red,
  Emotion.surprised: Colors.purple,
  Emotion.neutral: Colors.grey,
  Emotion.funny: Colors.green,
};
Typography

Use google_fonts (e.g., Poppins, Inter)
Clear hierarchy: Headlines, body, captions
Large touch targets (min 44x44 dp)


🛠️ Technical Requirements
Dependencies (pubspec.yaml)
yamldependencies:
  flutter:
    sdk: flutter
  
  # Camera & ML
  camera: ^0.10.0
  google_mlkit_face_detection: ^0.10.0
  tflite_flutter: ^0.10.0  # For emotion model
  image: ^4.0.0  # Image processing
  
  # State Management
  provider: ^6.0.0  # OR riverpod: ^2.0.0
  
  # UI/UX
  flutter_animate: ^4.0.0
  lottie: ^3.0.0
  google_fonts: ^6.0.0
  
  # Audio & Haptics
  audioplayers: ^5.0.0
  flutter_vibrate: ^1.3.0
  
  # Storage & Permissions
  shared_preferences: ^2.0.0
  permission_handler: ^11.0.0
  path_provider: ^2.0.0  # For saving images
  
  # Utilities
  intl: ^0.18.0  # Date formatting

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mockito: ^5.0.0  # For testing
```

### **Project Architecture**
```
lib/
├── main.dart
├── app.dart  # Root widget with theme config
├── core/
│   ├── constants/
│   │   ├── emotions.dart  # Enum & mappings
│   │   └── assets.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── emotion_colors.dart
│   └── utils/
│       ├── debouncer.dart
│       └── permission_manager.dart
├── data/
│   ├── models/
│   │   ├── emotion_result.dart
│   │   ├── face_data.dart
│   │   └── detection_history.dart
│   ├── repositories/
│   │   └── settings_repository.dart
│   └── services/
│       ├── camera_service.dart
│       ├── emotion_detection_service.dart
│       └── audio_service.dart
├── presentation/
│   ├── providers/
│   │   ├── emotion_provider.dart
│   │   ├── settings_provider.dart
│   │   └── camera_provider.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── history_screen.dart
│   │   └── onboarding_screen.dart
│   └── widgets/
│       ├── camera_preview_widget.dart
│       ├── emotion_animator.dart
│       ├── emotion_display_card.dart
│       ├── age_gender_card.dart
│       └── face_overlay_painter.dart
└── tests/
    ├── unit/
    │   ├── emotion_detection_test.dart
    │   └── settings_repository_test.dart
    └── widget/
        ├── emotion_animator_test.dart
        └── settings_screen_test.dart
Key Implementation Details
EmotionDetectionService.dart
dartclass EmotionDetectionService {
  final FaceDetector _faceDetector;
  final Interpreter _emotionModel;  // TFLite
  
  Stream<EmotionResult> detectFromFrame(CameraImage image) async* {
    // 1. Convert CameraImage to InputImage
    // 2. Detect faces with MLKit
    // 3. Crop face region
    // 4. Run emotion classification model
    // 5. Parse output (6 emotion probabilities)
    // 6. Yield EmotionResult with confidence
  }
  
  Emotion _mapPredictionToEmotion(List<double> probabilities) {
    // Find max probability index
    // Map to Emotion enum
    // Return Emotion.neutral if confidence < threshold (e.g., 0.6)
  }
}
Emotion Model Integration

Use a pre-trained TFLite model (e.g., FER-2013 trained model)
Model input: 48x48 grayscale face image
Model output: [happy, sad, angry, surprised, neutral, funny] probabilities
Include .tflite file in assets/models/
Load model in service initialization

State Management Pattern (Provider Example)
dartclass EmotionProvider extends ChangeNotifier {
  Emotion _currentEmotion = Emotion.neutral;
  double _confidence = 0.0;
  AgeGenderData? _ageGender;
  
  void updateEmotion(EmotionResult result) {
    if (result.confidence >= _confidenceThreshold) {
      _currentEmotion = result.emotion;
      _confidence = result.confidence;
      notifyListeners();
      _triggerFeedback();  // Haptics + sound
    }
  }
}

🧪 Testing Strategy
1. Unit Tests

EmotionDetectionService:

Test model output parsing
Test confidence thresholding
Mock TFLite interpreter responses


SettingsRepository:

Test preference save/load
Test default values



2. Widget Tests

EmotionAnimator:

Verify color changes per emotion
Test animation triggers


Settings Screen:

Test toggle state changes
Verify persistence



3. Integration Tests

Camera lifecycle handling
Permission flow end-to-end
Emotion detection pipeline (with mock images)

4. Manual Testing Checklist

✅ Camera opens smoothly
✅ Face detection works in various lighting
✅ Emotions update in real-time (<500ms latency)
✅ Age/gender predictions reasonable
✅ Settings persist across app restarts
✅ No memory leaks during extended use
✅ Graceful handling of no-face scenarios
✅ Dark mode renders correctly


📦 Deliverables
1. Git Repository

Clean commit history (conventional commits)
Branches: main, develop, feature branches
.gitignore configured for Flutter

2. Builds

Android APK: Tested locally (min SDK 21)
iOS IPA: Built via GitHub Actions (no local Xcode needed)

3. GitHub Actions CI
yaml# .github/workflows/ci.yml
name: Flutter CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
  
  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: app-release.apk
          path: build/app/outputs/flutter-apk/app-release.apk
  
  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build ios --release --no-codesign
      - uses: actions/upload-artifact@v3
        with:
          name: Runner.app
          path: build/ios/iphoneos/Runner.app
4. README.md
markdown# EmotionSense

Real-time emotion, age, and gender detection app built with Flutter.

## Features
- 📷 Live camera emotion recognition
- 👤 Age & gender estimation
- 🎨 Animated UI with Lottie characters
- 🔒 100% on-device processing (privacy-first)
- 🌙 Dark mode support

## Setup
1. Install Flutter SDK (stable channel)
2. Clone repo: `git clone <repo-url>`
3. Install dependencies: `flutter pub get`
4. Download emotion model:
   - Place `emotion_model.tflite` in `assets/models/`
   - [Model source link]
5. Run: `flutter run`

## Architecture
- **Pattern:** MVVM with Provider
- **Layers:** Presentation → Services → Data

## Gesture → Emotion Mapping
N/A (camera-based detection)

## Detection Libraries
- `google_mlkit_face_detection` - Face detection
- `tflite_flutter` - Emotion classification model (FER-2013)
- Model: [Credit source, license]

## Assets
- Lottie animations: [LottieFiles](https://lottiefiles.com) (CC BY 4.0)
- Icons: [Lucide Icons](https://lucide.dev) (ISC License)
- Sounds: [Freesound](https://freesound.org) (CC0)

## Screenshots
[3 screenshots: Home, Detection Active, Settings]

## Demo Video
[Link to 30-60s screencast on YouTube/Drive]

## Privacy
All processing happens locally. No data is sent to external servers.

## License
MIT License - See LICENSE file

## CI Status
![Build Status](https://github.com/<user>/<repo>/workflows/Flutter%20CI/badge.svg)
```

### **5. Demo Assets**
- **Screenshots:** 3 phone-sized (1080x2400px)
  - Home screen with camera preview
  - Emotion detected (happy) with animation
  - Settings page
- **Video:** 30-60s screencast showing:
  - App launch & permissions
  - Face detection in action
  - Emotion changes (smile → neutral → surprised)
  - Age/gender display
  - Settings toggle

### **6. LICENSE File**
```
MIT License

Copyright (c) 2025 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy...
```

---

## 🚀 Step-by-Step Milestones

### **Phase 1: Project Setup (Day 1)**
- [ ] Run `flutter create emotion_sense`
- [ ] Initialize Git with `.gitignore`
- [ ] Add all dependencies to `pubspec.yaml`
- [ ] Create folder structure
- [ ] Setup GitHub repo with initial commit

### **Phase 2: Core Detection (Days 2-3)**
- [ ] Implement `CameraService` (camera initialization, frame capture)
- [ ] Integrate `google_mlkit_face_detection`
- [ ] Download & integrate TFLite emotion model
- [ ] Create `EmotionDetectionService` with preprocessing pipeline
- [ ] Test detection with sample images
- [ ] Define `Emotion` enum and `EmotionResult` model

### **Phase 3: State Management (Day 4)**
- [ ] Setup Provider (or Riverpod)
- [ ] Create `EmotionProvider`, `CameraProvider`, `SettingsProvider`
- [ ] Implement debouncing for emotion updates
- [ ] Add confidence thresholding logic

### **Phase 4: UI Implementation (Days 5-7)**
- [ ] Build `HomeScreen` with camera preview
- [ ] Create `EmotionAnimator` widget (color transitions, animations)
- [ ] Implement `EmotionDisplayCard` (emoji/Lottie switcher)
- [ ] Build `AgeGenderCard` (collapsible, styled)
- [ ] Add camera controls (switch, flash)
- [ ] Create `SettingsScreen` with all toggles
- [ ] Implement dark mode theming

### **Phase 5: Enhancements (Days 8-9)**
- [ ] Add sound effects (emotion change triggers)
- [ ] Implement haptic feedback
- [ ] Create onboarding/permission screens
- [ ] Add "no face detected" placeholder
- [ ] Optimize performance (reduce frame rate if needed)
- [ ] Add accessibility labels

### **Phase 6: Testing (Day 10)**
- [ ] Write unit tests for `EmotionDetectionService`
- [ ] Write widget tests for key components
- [ ] Manual testing on emulator + physical device
- [ ] Test edge cases (low light, multiple faces, no face)

### **Phase 7: Polish & Documentation (Days 11-12)**
- [ ] Refine animations (timing, easing)
- [ ] Add loading states
- [ ] Create all demo assets (screenshots, video)
- [ ] Write comprehensive README
- [ ] Add inline code comments
- [ ] Setup GitHub Actions CI
- [ ] Generate release APK

### **Phase 8: Optional Enhancements (Day 13+)**
- [ ] History feature (save snapshots)
- [ ] Face overlay with landmarks
- [ ] Emotion statistics/insights
- [ ] Export history data

---

## 🎨 Emotion → Visual Mapping

| Emotion      | Color       | Icon | Lottie Animation           | Sound Effect    |
|--------------|-------------|------|----------------------------|-----------------|
| 😄 Happy     | Amber/Gold  | 😄   | `happy_face.json`          | `chime.mp3`     |
| 😢 Sad       | Blue        | 😢   | `sad_rain.json`            | `piano_low.mp3` |
| 😠 Angry     | Red/Orange  | 😠   | `angry_steam.json`         | `grunt.mp3`     |
| 😲 Surprised | Purple      | 😲   | `surprised_sparkle.json`   | `gasp.mp3`      |
| 😐 Neutral   | Grey        | 😐   | `neutral_idle.json`        | None            |
| 🤣 Funny     | Green/Lime  | 🤣   | `laughing_emoji.json`      | `laugh.mp3`     |

---

## 🔒 Privacy & Ethics Considerations

1. **No Data Collection:**
   - No analytics, crash reporting, or telemetry
   - No network requests (fully offline)
   - Camera frames processed in memory only

2. **User Control:**
   - Clear permission explanations
   - Easy toggle for age/gender (potentially sensitive)
   - Option to disable all sound/haptics

3. **Model Bias Awareness:**
   - Acknowledge that age/gender models may have biases
   - Display predictions as "estimates" not "facts"
   - Consider adding disclaimer in settings

4. **Accessibility:**
   - Support TalkBack/VoiceOver
   - High contrast mode
   - Large text support

---

## 🎓 Learning Outcomes (Portfolio Value)

This project demonstrates:
- ✅ **Advanced Flutter:** Camera integration, ML Kit, TFLite
- ✅ **State Management:** Provider/Riverpod patterns
- ✅ **Real-Time Processing:** Frame-by-frame analysis
- ✅ **Polished UI/UX:** Animations, theming, responsiveness
- ✅ **Testing:** Unit, widget, integration tests
- ✅ **CI/CD:** GitHub Actions for cross-platform builds
- ✅ **Privacy-First Design:** On-device ML
- ✅ **Documentation:** Comprehensive README, code comments

---

## 🔗 Useful Resources

- [Flutter Camera Plugin Docs](https://pub.dev/packages/camera)
- [Google ML Kit Face Detection](https://pub.dev/packages/google_mlkit_face_detection)
- [TFLite Flutter Guide](https://pub.dev/packages/tflite_flutter)
- [Pre-trained Emotion Models](https://www.kaggle.com/models?search=emotion+detection)
- [Material 3 Design System](https://m3.material.io/)
- [Flutter Animation Guide](https://docs.flutter.dev/development/ui/animations)

---

## ⚡ Quick Start Command (For AI Agent)
```
Build a Flutter app called **EmotionSense** that uses the device camera to detect emotions (happy, sad, angry, surprised, neutral, funny), age, and gender in real-time. Use `google_mlkit_face_detection` for face detection and `tflite_flutter` with a pre-trained FER-2013 emotion model. Implement Provider for state management. UI should feature animated emotion displays (emoji or Lottie), collapsible age/gender cards, camera controls, and a settings page. Include dark mode, sound effects, haptic feedback, and full privacy (on-device only). Follow Material 3 design, write unit/widget tests, setup GitHub Actions CI for Android/iOS builds, and create a comprehensive README with screenshots and demo video. Structure code with MVVM architecture: services, providers, screens, widgets. Make it portfolio-ready with clean commits and professional documentation.

📊 Success Criteria

✅ App detects emotions in <500ms from face appearance
✅ Confidence threshold prevents flickering (≥60% required)
✅ Age/gender predictions display reasonably (±5 years accuracy acceptable)
✅ All permissions handled gracefully with fallbacks
✅ No crashes during 10-minute continuous use
✅ Settings persist correctly across app restarts
✅ Dark mode has proper contrast ratios (WCAG AA)
✅ GitHub Actions builds complete successfully
✅ README is clear enough for new developers to run app in <5 minutes