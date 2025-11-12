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
  static const _imagesDirName = 'Pictures';

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

  /// Copy a captured image from a temporary path to a persistent app-managed
  /// folder under ApplicationDocumentsDirectory/Pictures and return the new path.
  Future<String> persistImage(String tempPath) async {
    try {
      final src = File(tempPath);
      if (!await src.exists()) return tempPath;

      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/$_imagesDirName');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final ts = DateTime.now();
      final filename = 'IMG_${ts.year.toString().padLeft(4, '0')}'
          '${ts.month.toString().padLeft(2, '0')}'
          '${ts.day.toString().padLeft(2, '0')}_'
          '${ts.hour.toString().padLeft(2, '0')}'
          '${ts.minute.toString().padLeft(2, '0')}'
          '${ts.second.toString().padLeft(2, '0')}'
          '${ts.millisecond.toString().padLeft(3, '0')}.jpg';
      final destPath = '${dir.path}/$filename';
      await src.copy(destPath);
      return destPath;
    } catch (_) {
      return tempPath;
    }
  }

  /// Delete an image file at the given path. Errors are ignored.
  Future<void> deleteImageAtPath(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
  }
}
