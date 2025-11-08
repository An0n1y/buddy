import 'package:flutter/material.dart';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/presentation/widgets/morphing_emoji.dart';

class EmotionDisplayCard extends StatelessWidget {
  const EmotionDisplayCard(
      {super.key, required this.emotion, required this.confidence});
  final Emotion emotion;
  final double confidence;

  Color _color(Emotion e) => switch (e) {
        Emotion.happy => Colors.amber,
        Emotion.sad => Colors.blue,
        Emotion.angry => Colors.red,
        Emotion.surprised => Colors.purple,
        Emotion.neutral => Colors.grey,
        Emotion.funny => Colors.green,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(emotion);
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MorphingEmoji(emotion: emotion, size: 80, showFaceCircle: false),
            const SizedBox(height: 16),
            Text(
              emotion.name.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: confidence.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(color),
            ),
            const SizedBox(height: 6),
            Text('${(confidence * 100).toInt()}% confident',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
