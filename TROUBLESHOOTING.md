# Troubleshooting Guide

## Issue: Emoji and Capsule Not Showing (Nov 11, 2025)

### Problem

Camera preview works, but:

- ❌ No real-time morphing emoji at bottom
- ❌ No age/gender/ethnicity capsule at top-right
- ❌ No face bounding boxes

### Root Cause

Face detection wasn't starting properly due to initialization race condition.

### Fix Applied

**File:** `lib/ui/camera_view.dart`

**Changes:**

1. Made initialization `async` and properly await camera
2. Ensured face detection starts **after** camera is ready
3. Added debug logging to track face detection

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final cam = context.read<CameraProvider>();

    // Initialize camera FIRST
    await cam.initialize();

    // THEN start face detection
    final attrs = FaceAttributesProvider(cam.service);
    _attrs = attrs;
    _attrs!.addListener(() {
      if (mounted) setState(() {});
    });

    await _attrs!.start();

    if (mounted) setState(() {});
  });
}
```

### How to Verify the Fix

**After hot reload (press `r` in terminal), you should see:**

1. **In terminal logs:**

   ```
   ✅ Detected 1 face(s) - Emotion: happy
   ✅ Detected 1 face(s) - Emotion: neutral
   ```

2. **On screen (when face detected):**

   - **Top-right:** Beautiful gradient capsule with:
     ```
     🎂 25-30
     ⚧ Male
     🌍 Asian
     ```
   - **Bottom-center:** Large morphing emoji (180px) that changes expression
   - **Around face:** Yellow bounding box with age/gender/ethnicity text

3. **If no face detected:**
   - No emoji, no capsule (this is expected behavior)
   - Try:
     - Moving closer to camera
     - Better lighting
     - Face the camera directly
     - Ensure camera permission granted

### Quick Test Commands

```bash
# Hot reload (if app running)
# Press 'r' in the terminal

# Or restart app
flutter run -d emulator-5554

# Check debug logs
# Look for "✅ Detected X face(s)" messages
```

### What Should Happen

**When face detected:**

- 5-8 times per second, face detection runs
- Emoji smoothly morphs between emotions
- Capsule updates age/gender/ethnicity
- Bounding box tracks face position

**Emotions detected:**

- 😊 Happy (big smile)
- 😢 Sad (frown + droopy eyebrows)
- 😠 Angry (narrowed eyes + low smile)
- 😲 Surprised (wide eyes + mouth)
- 😐 Neutral (balanced expression)
- 😆 Funny (huge smile + squint)

### Still Not Working?

**Check permissions:**

```bash
# Verify camera permission granted in app
# Android: Settings > Apps > EmotionSense > Permissions > Camera ✅
```

**Check logs for errors:**

```bash
# Run with verbose logging
flutter run -v -d emulator-5554

# Look for:
# - "MlKitException" (face detection failed)
# - "CameraException" (camera access denied)
# - "PlatformException" (permission denied)
```

**Try different camera:**

- Tap the switch camera button (left icon)
- Some cameras have better face detection support

**Verify Google ML Kit:**

```dart
// Should see in logs when face detected:
// D/FaceDetector: Face detected at [x, y, w, h]
```

### Performance Notes

- **Target FPS:** 5 (to reduce buffer warnings)
- **Expected latency:** 200-250ms from expression to emoji change
- **Processing:** Only largest face (multi-face not supported)

---

**Last updated:** Nov 11, 2025  
**Status:** Fixed initialization race condition ✅
