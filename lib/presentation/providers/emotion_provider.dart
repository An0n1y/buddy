import 'dart:async';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/core/utils/debouncer.dart';
import 'package:emotion_sense/data/models/age_gender_data.dart';
import 'package:emotion_sense/data/models/emotion_result.dart';
import 'package:emotion_sense/data/services/emotion_detection_service.dart';
import 'package:emotion_sense/data/services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class EmotionProvider extends ChangeNotifier {
  EmotionProvider() {
    _service.start();
    _subscription = _service.stream.listen(_onResult);
  }

  final EmotionDetectionService _service = EmotionDetectionService();
  final AudioService _audio = AudioService();
  final Debouncer _debouncer =
      Debouncer(duration: const Duration(milliseconds: 250));
  StreamSubscription<EmotionResult>? _subscription;

  Emotion _current = Emotion.neutral;
  double _confidence = 0.0;
  AgeGenderData? _ageGender; // stub data

  double confidenceThreshold = 0.6;
  bool soundOn = true;
  bool hapticOn = true;

  Emotion get current => _current;
  double get confidence => _confidence;
  AgeGenderData? get ageGender => _ageGender;

  void _onResult(EmotionResult result) {
    if (result.confidence < confidenceThreshold) return;
    _debouncer(() {
      final changed = result.emotion != _current;
      _current = result.emotion;
      _confidence = result.confidence;
      if (changed) _triggerFeedback();
      notifyListeners();
    });
  }

  void manualOverride(Emotion emotion, {double confidence = 0.95}) {
    _service.setManual(emotion, confidence: confidence);
  }

  void updateSettings({double? threshold, bool? sound, bool? haptic}) {
    if (threshold != null) confidenceThreshold = threshold;
    if (sound != null) soundOn = sound;
    if (haptic != null) hapticOn = haptic;
  }

  Future<void> _triggerFeedback() async {
    if (soundOn) await _audio.playForEmotion(_current);
    if (hapticOn && await Vibrate.canVibrate) {
      Vibrate.feedback(FeedbackType.light);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    _audio.dispose();
    _debouncer.dispose();
    super.dispose();
  }
}
