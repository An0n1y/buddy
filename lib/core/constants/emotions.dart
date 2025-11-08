import 'package:flutter/material.dart';

/// Enumeration of supported emotions in the app.
/// Maintains original spec ordering for mapping indices (if ML added later).
enum Emotion { happy, sad, angry, surprised, neutral, funny }

extension EmotionDisplay on Emotion {
  String get label => switch (this) {
        Emotion.happy => 'Happy',
        Emotion.sad => 'Sad',
        Emotion.angry => 'Angry',
        Emotion.surprised => 'Surprised',
        Emotion.neutral => 'Neutral',
        Emotion.funny => 'Funny',
      };

  String get emoji => switch (this) {
        Emotion.happy => '😄',
        Emotion.sad => '😢',
        Emotion.angry => '😠',
        Emotion.surprised => '😲',
        Emotion.neutral => '😐',
        Emotion.funny => '🤣',
      };
}

/// Primary color mapping per spec.
final Map<Emotion, Color> emotionColors = {
  Emotion.happy: Colors.amber,
  Emotion.sad: Colors.blue,
  Emotion.angry: Colors.red,
  Emotion.surprised: Colors.purple,
  Emotion.neutral: Colors.grey,
  Emotion.funny: Colors.green,
};
