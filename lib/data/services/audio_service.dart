import 'package:audioplayers/audioplayers.dart';
import 'package:emotion_sense/core/constants/emotions.dart';

abstract class IAudioService {
  Future<void> playForEmotion(Emotion e);
  Future<void> dispose();
}

class AudioService implements IAudioService {
  final _player = AudioPlayer();

  String? _assetForEmotion(Emotion e) {
    switch (e) {
      case Emotion.happy:
        return 'assets/sounds/chime.mp3';
      case Emotion.sad:
        return 'assets/sounds/piano_low.mp3';
      case Emotion.angry:
        return 'assets/sounds/grunt.mp3';
      case Emotion.surprised:
        return 'assets/sounds/gasp.mp3';
      case Emotion.neutral:
        return null;
      case Emotion.funny:
        return 'assets/sounds/laugh.mp3';
    }
  }

  @override
  Future<void> playForEmotion(Emotion e) async {
    final asset = _assetForEmotion(e);
    if (asset == null) return;
    try {
      await _player.play(AssetSource(asset.replaceFirst('assets/', '')));
    } catch (_) {
      // Silently ignore missing asset errors in dev.
    }
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}
