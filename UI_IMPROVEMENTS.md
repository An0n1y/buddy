# UI Improvements Log

## Age/Gender/Ethnicity Capsule (Nov 11, 2025)

### New Design

Replaced the basic Card widget with a modern, gradient-styled capsule that displays:

**Visual hierarchy:**

```
┌─────────────────────────┐
│  🎂  25-30              │  ← Age (prominent, bold)
│                         │
│  ⚧  Male                │  ← Gender (medium weight)
│                         │
│  🌍  Asian              │  ← Ethnicity (lighter)
└─────────────────────────┘
```

### Features

1. **Gradient Background**

   - Light mode: White → Light grey
   - Dark mode: Blue-grey 800 → Blue-grey 900
   - 95% opacity for subtle transparency over camera preview

2. **Icon-based Labels**

   - 🎂 Cake icon for age (amber color)
   - ⚧ Gender icons (male/female/person) for gender (blue color)
   - 🌍 Globe icon for ethnicity (green color)

3. **Elevation & Depth**

   - Soft drop shadow (12px blur, 4px offset)
   - Subtle border (white in dark mode, black in light mode)
   - Rounded corners (24px radius) for capsule shape

4. **Typography**

   - Age: `titleSmall`, bold
   - Gender: `bodySmall`, semi-bold
   - Ethnicity: `bodySmall`, medium weight
   - Colors adapt to theme brightness

5. **Positioning**
   - Top-right corner of camera preview
   - 16px padding from edges
   - Auto-sized to content

### Theme Support

**Light Mode:**

- White gradient background
- Dark text (black87, black54)
- Colored icons (amber, blue, green 700 shades)

**Dark Mode:**

- Blue-grey gradient background
- Light text (white, white70, white60)
- Colored icons (amber, blue, green 300 shades)

### Code Location

File: `lib/ui/camera_view.dart`
Widget: `_AgeGenderEthnicityCard`
Lines: ~236-340

### Before vs After

**Before:**

- Simple Card with rounded corners
- Plain text layout: "25-30" over "Male • Asian"
- Minimal styling

**After:**

- Gradient capsule with shadow and border
- Icon + text rows for each attribute
- Visual hierarchy with colors and weights
- Theme-aware styling

---

## Performance Optimization (Nov 11, 2025)

### Buffer Warning Fix

**Issue:** ImageReader buffer overflow warnings flooding logs

**Solution:** Reduced frame processing rate from 8 FPS → 5 FPS

**File:** `lib/presentation/providers/face_attributes_provider.dart`
**Change:**

```dart
int targetFps = 5; // Reduced from 8 to minimize buffer warnings
```

**Impact:**

- Fewer buffer warnings (expect ~90% reduction)
- Still responsive (emotion updates every ~200ms)
- Lower CPU/battery usage
- Camera preview remains 30 FPS

**Trade-off:**

- Slightly slower emotion detection response (~40ms extra latency)
- Acceptable for real-time emotion mirroring use case

---

**Last updated:** Nov 11, 2025
