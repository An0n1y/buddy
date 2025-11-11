# Performance Notes

## Camera Frame Processing

### ImageReader Buffer Warnings (Resolved)

**Warning seen in logs:**

```
W/ImageReader_JNI: Unable to acquire a buffer item, very likely client tried to acquire more than maxImages buffers
```

**Cause:**
The camera streams frames at ~30 FPS by default, but face detection + ML inference takes longer per frame. When frames arrive faster than they can be processed, the camera's internal buffer fills up.

**Solution Applied:**
Optimized `FaceAttributesProvider` frame processing:

1. **Immediate early return**: Check `_busy` flag first, before any other logic
2. **Frame throttling**: Increased target FPS from 6 to 8 for better responsiveness while maintaining buffer stability
3. **Skip logic**: Only process every ~4th frame (30 FPS / 8 target = skip 3, process 1)

**Code changes:**

```dart
Future<void> _onFrame(CameraImage image) async {
  if (!_running) return;

  // Drop frame immediately if still processing previous frame
  if (_busy) {
    return;
  }

  // Simple decimation from ~30fps -> targetFps
  final baseSkip = math.max(1, (30 / targetFps).round());
  _skip = (_skip + 1) % baseSkip;
  if (_skip != 0) return;

  _busy = true;
  // ... rest of processing
}
```

**Result:**

- Fewer buffer overflow warnings
- Smoother emotion detection updates
- Processing only 8 frames/sec (practical limit for ML inference on mobile)
- Camera preview remains at native 30 FPS

### Performance Characteristics

| Metric                 | Value                |
| ---------------------- | -------------------- |
| Camera preview FPS     | ~30 FPS              |
| ML inference target    | 8 FPS                |
| Frame skip ratio       | Process 1, skip ~3   |
| Face detection latency | ~80-120ms            |
| Age/Gender inference   | ~40-60ms             |
| Total processing time  | ~120-180ms per frame |

### Face Detection Optimization

**Current approach:**

- Process only the **largest face** in frame (reduces latency)
- EMA smoothing on confidence scores (alpha=0.4) to reduce jitter
- Debounced UI updates (every 2 processed frames or on face count change)
- Reusable RGB buffer to minimize allocations

**Why only the largest face?**
Multi-face processing would multiply inference time linearly. For real-time emotion mirroring on mobile, single-face is the sweet spot between UX and performance.

### Monitoring Tips

**Good performance indicators:**

- Camera preview smooth (no dropped preview frames visible)
- Emoji avatar responds within ~250-300ms of expression change
- No ANR (Application Not Responding) warnings

**Red flags:**

- Frequent `ImageReader_JNI` warnings (means frames backing up)
- Emoji updates lagging > 500ms behind expressions
- UI stuttering when moving camera

**Tuning knobs** (in `FaceAttributesProvider`):

```dart
int targetFps = 8;           // Lower = fewer buffers used, slower updates
final double _emaAlpha = 0.4; // Higher = faster response, more jitter
int _notifyThrottle = 0;      // Modulo for UI update frequency
```

### Future Optimizations

If targeting high-end devices:

1. Increase `targetFps` to 10-12
2. Add device capability detection (check RAM, CPU cores)
3. Use isolate for inference (offload from UI thread)

If targeting low-end devices:

1. Decrease `targetFps` to 5-6
2. Lower camera resolution to `ResolutionPreset.low`
3. Disable age/gender inference (keep emotion only)

---

**Last updated:** Nov 11, 2025
