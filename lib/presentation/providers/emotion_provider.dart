import 'dart:async';
import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/core/utils/debouncer.dart';
import 'package:emotion_sense/data/models/age_gender_data.dart';
import 'package:emotion_sense/data/models/emotion_result.dart';
import 'package:emotion_sense/data/models/face_bounds.dart';
import 'package:emotion_sense/data/services/face_analysis_service.dart';
import 'package:emotion_sense/data/services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmotionProvider extends ChangeNotifier {
  EmotionProvider(
      {Debouncer? debouncer,
      IAudioService? audioService,
      FaceAnalysisService? analysisService})
      : _debouncer =
            debouncer ?? Debouncer(duration: const Duration(milliseconds: 250)),
        _audio = audioService ?? AudioService(),
        _analysis = analysisService {
    // Start analysis stream when available
    if (_analysis != null) {
      _analysis.start();
      _subscription = _analysis.stream.listen(_onEvent);
    }
  }

  final FaceAnalysisService? _analysis;
  final IAudioService _audio;
  final Debouncer _debouncer;
  StreamSubscription<DetectionEvent>? _subscription;

  Emotion _current = Emotion.neutral;
  double _confidence = 0.0;
  AgeGenderData? _ageGender; // stub data
  FaceBounds? _faceBounds; // normalized face rect
  FaceBounds? _smoothedBounds; // EMA smoothed rect
  int _missingFrames = 0;
  int maxMissingBeforeNeutral = 45; // ~3s at 15fps
  double smoothingAlpha = 0.4; // EMA weight
  final List<double> _confidenceWindow = [];
  int confidenceWindowSize = 12; // sliding window length

  double confidenceThreshold = 0.6;
  bool soundOn = true;
  bool hapticOn = true;

  Emotion get current => _current;
  double get confidence => _confidence;
  AgeGenderData? get ageGender => _ageGender;
  FaceBounds? get faceBounds => _faceBounds;
  FaceBounds? get smoothedFaceBounds => _smoothedBounds ?? _faceBounds;

  void _onEvent(DetectionEvent event) {
    final result = event.emotion;
    _faceBounds = event.bounds;
    _ageGender = event.ageGender ?? _ageGender; // keep last known if null
    // Bounds smoothing & missing frame tracking
    if (_faceBounds != null) {
      _missingFrames = 0;
      final r = _faceBounds!.rect;
      if (_smoothedBounds == null) {
        _smoothedBounds = _faceBounds;
      } else {
        final old = _smoothedBounds!.rect;
        final newRect = Rect.fromLTWH(
          old.left + (r.left - old.left) * smoothingAlpha,
          old.top + (r.top - old.top) * smoothingAlpha,
          old.width + (r.width - old.width) * smoothingAlpha,
          old.height + (r.height - old.height) * smoothingAlpha,
        );
        _smoothedBounds = FaceBounds(rect: newRect, timestamp: DateTime.now());
      }
    } else {
      _missingFrames++;
      if (_missingFrames > maxMissingBeforeNeutral) {
        _current = Emotion.neutral;
        _confidence = 0.0;
        notifyListeners();
        return;
      }
    }

    // Confidence smoothing window
    _confidenceWindow.add(result.confidence);
    if (_confidenceWindow.length > confidenceWindowSize) {
      _confidenceWindow.removeAt(0);
    }
    final avgConfidence =
        _confidenceWindow.reduce((a, b) => a + b) / _confidenceWindow.length;

    if (avgConfidence < confidenceThreshold) {
      notifyListeners();
      return;
    }
    _debouncer(() {
      final changed = result.emotion != _current;
      _current = result.emotion;
      _confidence = avgConfidence;
      if (changed) _triggerFeedback();
      notifyListeners();
    });
  }

  void manualOverride(Emotion emotion, {double confidence = 0.95}) {
    _onEvent(DetectionEvent(
      emotion: EmotionResult(emotion: emotion, confidence: confidence),
      bounds: _faceBounds,
      imageSize: const Size(0, 0),
      ageGender: _ageGender,
    ));
  }

  void updateSettings({
    double? threshold,
    bool? sound,
    bool? haptic,
    double? smoothing,
    int? windowSize,
    int? missingFramesToNeutral,
    int? frameRate,
  }) {
    if (threshold != null) confidenceThreshold = threshold;
    if (sound != null) soundOn = sound;
    if (haptic != null) hapticOn = haptic;
    if (smoothing != null) smoothingAlpha = smoothing.clamp(0.05, 0.95);
    if (windowSize != null && windowSize > 0) confidenceWindowSize = windowSize;
    if (missingFramesToNeutral != null && missingFramesToNeutral > 0) {
      maxMissingBeforeNeutral = missingFramesToNeutral;
    }
    if (frameRate != null && frameRate > 0) {
      if (_analysis != null) {
        _analysis.targetFps = frameRate;
      }
    }
  }

  // For tests: inject a detection event
  @visibleForTesting
  void debugInjectEvent(DetectionEvent event) => _onEvent(event);

  Future<void> _triggerFeedback() async {
    if (soundOn) await _audio.playForEmotion(_current);
    if (hapticOn) {
      // Uses Flutter's built-in haptics, avoiding external plugins.
      await HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _analysis?.dispose();
    _audio.dispose();
    _debouncer.dispose();
    super.dispose();
  }
}
