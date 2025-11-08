import 'package:emotion_sense/data/models/emotion_result.dart';

class DetectionHistoryEntry {
  DetectionHistoryEntry({required this.result});
  final EmotionResult result;
}

class DetectionHistory {
  final List<DetectionHistoryEntry> _entries = [];

  List<DetectionHistoryEntry> get entries => List.unmodifiable(_entries);

  void add(EmotionResult result) {
    _entries.add(DetectionHistoryEntry(result: result));
    if (_entries.length > 500) {
      _entries.removeAt(0); // simple cap
    }
  }
}
