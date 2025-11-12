# iOS Crash Fix - November 11, 2025

## Problem

App crashes after a few minutes on iOS devices.

## Root Causes Identified

### 1. **Platform-Specific Image Format**

- **Android**: Uses YUV420/NV21 format
- **iOS**: Uses BGRA8888 format
- Previous code forced NV21 format on all platforms, causing iOS to crash

### 2. **Memory Leaks**

- Stream subscriptions not properly canceled
- Buffers not cleared on dispose
- No lifecycle management for background/foreground transitions

### 3. **Missing App Lifecycle Handling**

- iOS is strict about resource usage when app goes to background
- Camera and ML processing must be paused when app is inactive

## Solutions Implemented

### 1. Platform-Specific Image Processing

**File**: `lib/services/face_detection_service.dart`

```dart
if (Platform.isIOS) {
  // iOS uses BGRA8888 - pass directly without conversion
  inputImage = InputImage.fromBytes(
    bytes: image.planes[0].bytes,
    metadata: InputImageMetadata(
      format: InputImageFormat.bgra8888,
      bytesPerRow: image.planes[0].bytesPerRow,
      ...
    ),
  );
} else {
  // Android: Convert YUV420 to NV21
  ...
}
```

### 2. Proper Memory Management

**File**: `lib/presentation/providers/face_attributes_provider.dart`

**Added**:

- `StreamSubscription<CameraImage>? _imageStreamSubscription`
- Proper cancellation of stream subscription in `stop()`
- Clear buffers and caches: `_rgbBuffer = null`, `_faces.clear()`, `_emaConfidence.clear()`
- Close detector in `dispose()`: `_detector.close()`

### 3. App Lifecycle Management

**File**: `lib/ui/camera_view.dart`

**Added**:

- `WidgetsBindingObserver` mixin to camera view
- `didChangeAppLifecycleState()` override to pause/resume processing
- Automatic pause when app goes to background
- Automatic resume when app returns to foreground

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.paused:
    case AppLifecycleState.inactive:
    case AppLifecycleState.detached:
      _attrs?.stop(); // Stop processing
      break;
    case AppLifecycleState.resumed:
      _attrs?.start(); // Resume processing
      break;
  }
}
```

## Testing Checklist

### iOS Specific Tests:

1. ✅ Launch app and verify face detection works
2. ✅ Leave app running for 5+ minutes
3. ✅ Switch to another app (background) and return
4. ✅ Lock device and unlock
5. ✅ Receive phone call while app is running
6. ✅ Check for memory leaks in Instruments

### Memory Leak Check:

```bash
# Build in Profile mode for better performance testing
flutter build ios --profile
# Then test with Xcode Instruments
```

## Expected Behavior

- ✅ App runs indefinitely without crashes
- ✅ Smooth pause/resume when switching apps
- ✅ No memory growth over time
- ✅ Face detection works consistently on iOS
- ✅ Resources properly released when app is in background

## Additional iOS-Specific Considerations

### Info.plist Requirements

Ensure these permissions are set in `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for emotion detection</string>
```

### Performance Mode

Current settings optimize for iOS:

- FPS throttle: 5 FPS (prevents overload)
- Performance mode: `FaceDetectorMode.accurate`
- Process only largest face (reduces CPU load)

## Debugging iOS Crashes

If crashes still occur, check:

1. **Xcode Console** for native crash logs
2. **Memory usage** with Instruments
3. **CPU usage** - should stay below 50%
4. **Frame drops** - camera preview should be smooth

### Common iOS Crash Patterns:

- **Memory pressure**: App terminated by iOS for using too much memory
- **Background timeout**: App killed for taking too long in background
- **Camera permission**: Crash if permission denied after grant

## Performance Metrics (iOS)

Target metrics:

- Memory usage: < 150 MB
- CPU usage: < 40% average
- Battery impact: Low
- Frame rate: Stable 5 FPS for ML processing
- UI frame rate: 60 FPS

## Files Modified

1. `lib/services/face_detection_service.dart` - Platform-specific image format handling
2. `lib/presentation/providers/face_attributes_provider.dart` - Memory management
3. `lib/ui/camera_view.dart` - App lifecycle management
