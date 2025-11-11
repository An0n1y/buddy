# Face Detection Fix - November 11, 2025

## Problem

The app was showing continuous errors:

```
E/MethodChannel#google_mlkit_face_detector: Failed to handle method call
java.lang.IllegalArgumentException: Image dimension, ByteBuffer size and format don't match.
```

**Root Cause**: The `FaceDetectionService` was passing only the Y plane (`image.planes.first.bytes`) to Google ML Kit, but ML Kit expects the complete YUV420 image data properly formatted.

## Solution

Updated `lib/services/face_detection_service.dart` to properly convert YUV420 camera frames to NV21 format:

### Key Changes:

1. **Proper YUV to NV21 conversion**:

   - Added Y plane (luminance)
   - Added UV planes interleaved as VU (NV21 format)
   - Used `WriteBuffer` to efficiently combine all planes

2. **Correct metadata**:

   - Changed format from `InputImageFormat.yuv420` to `InputImageFormat.nv21`
   - Set `bytesPerRow` to `image.width` for NV21 format

3. **Added proper imports**:
   - `import 'package:flutter/foundation.dart';` for `WriteBuffer`

## Expected Result

- ✅ Face detection should now work without ByteBuffer errors
- ✅ Emoji should change based on detected emotion (happy, sad, angry, surprised, neutral)
- ✅ Capsule should show actual age, gender, and ethnicity when face is detected
- ✅ Capsule shows "---" placeholders when no face detected

## Testing Steps

1. Run `flutter clean` (completed)
2. Run `flutter pub get` (completed)
3. Launch app on device/emulator
4. Point camera at face
5. Verify:
   - No ML Kit errors in logs
   - Emoji changes with facial expressions
   - Capsule shows detected attributes

## UI Elements

- **Emoji**: Top-center, always visible, defaults to neutral
- **Capsule**: Bottom-right, single row, blackish transparent background
  - Format: `[Calendar Icon] Age | [Gender Icon] Gender | [Globe Icon] Ethnicity`

## Technical Details

### NV21 Format

NV21 is a YUV 4:2:0 format where:

- Y plane (full resolution): width × height bytes
- UV plane (half resolution): width × height / 2 bytes, interleaved as VUVU...

This is the format Google ML Kit expects on Android for efficient processing.
