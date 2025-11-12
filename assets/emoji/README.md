# 3D Emoji Avatar Assets

Place your GLB/GLTF models here to enable the real-time 3D emoji avatar.

Supported layouts:

1. Single GLB with multiple animations

   - Path: `assets/emoji/emoji_avatar.glb`
   - Expected animation names (case-insensitive): `Happy`, `Sad`, `Angry`, `Surprised`, `Neutral`, `Funny`

2. Separate GLB per emotion
   - Files: `assets/emoji/happy.glb`, `assets/emoji/sad.glb`, `assets/emoji/angry.glb`, `assets/emoji/surprised.glb`, `assets/emoji/neutral.glb`, `assets/emoji/funny.glb`

If no GLB is found at runtime, the app falls back to the built-in 2D MorphingEmoji widget.

Notes:

- Keep models lightweight (<2–3MB each) for mobile performance.
- Ensure the model's default camera framing is appropriate; the viewer disables zoom/controls.
- If using a single GLB, ensure each animation loops and is named as listed above.
