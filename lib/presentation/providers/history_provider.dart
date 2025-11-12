import 'dart:io';

import 'package:emotion_sense/core/constants/emotions.dart';
import 'package:emotion_sense/data/models/age_gender_data.dart';
import 'package:emotion_sense/data/repositories/history_repository.dart';
import 'package:flutter/foundation.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this._repo);
  final HistoryRepository _repo;

  final List<HistoryEntry> _entries = [];
  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  bool _loaded = false;
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _entries.clear();
    _entries.addAll(await _repo.load());
    _loaded = true;
    notifyListeners();
  }

  Future<String> addCapture({
    required String imagePath,
    required Emotion emotion,
    required double confidence,
    AgeGenderData? ageGender,
  }) async {
    // Persist image into an app-managed folder; fall back to original path on error.
    if (!await File(imagePath).exists()) return imagePath;
    final persistedPath = await _repo.persistImage(imagePath);
    final entry = HistoryEntry(
      imagePath: persistedPath,
      emotion: emotion,
      confidence: confidence,
      timestamp: DateTime.now(),
      ageGender: ageGender,
    );
    _entries.add(entry);
    await _repo.save(_entries);
    notifyListeners();
    return persistedPath;
  }

  Future<void> deleteEntry(HistoryEntry entry) async {
    _entries.remove(entry);
    await _repo.save(_entries);
    await _repo.deleteImageAtPath(entry.imagePath);
    notifyListeners();
  }
}
