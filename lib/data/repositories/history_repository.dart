import 'dart:convert';
import 'dart:io';

import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/data/models/age_gender_data.dart';
import 'package:path_provider/path_provider.dart';

class HistoryEntry {
  HistoryEntry({
    required this.imagePath,
    required this.emotion,
    required this.confidence,
    required this.timestamp,
    this.ageGender,
  });

  final String imagePath;
  final Emotion emotion;
  final double confidence;
  final DateTime timestamp;
  final AgeGenderData? ageGender;

  Map<String, dynamic> toJson() => {
        'imagePath': imagePath,
        'emotion': emotion.name,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
        'ageRange': ageGender?.ageRange,
        'gender': ageGender?.gender,
        'ageGenderConfidence': ageGender?.confidence,
      };

  static HistoryEntry fromJson(Map<String, dynamic> json) => HistoryEntry(
        imagePath: json['imagePath'] as String,
        emotion: Emotion.values.firstWhere(
            (e) => e.name == (json['emotion'] as String? ?? 'neutral'),
            orElse: () => Emotion.neutral),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        ageGender: (json['ageRange'] == null || json['gender'] == null)
            ? null
            : AgeGenderData(
                ageRange: json['ageRange'] as String? ?? 'Unknown',
                gender: json['gender'] as String? ?? 'Unknown',
                confidence:
                    (json['ageGenderConfidence'] as num?)?.toDouble() ?? 0.0,
              ),
      );
}

class HistoryRepository {
  static const _fileName = 'history.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<HistoryEntry>> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      final text = await f.readAsString();
      final list =
          (jsonDecode(text) as List<dynamic>).cast<Map<String, dynamic>>();
      return list.map(HistoryEntry.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<HistoryEntry> entries) async {
    final f = await _file();
    final jsonList = entries.map((e) => e.toJson()).toList();
    await f.writeAsString(jsonEncode(jsonList));
  }
}
