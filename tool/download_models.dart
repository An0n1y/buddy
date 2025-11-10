// Run with: dart run tool/download_models.dart --emotion=<url> --age=<url> --gender=<url>
import 'dart:io';

// Supports multiple fallback URLs and optional Authorization headers for
// providers like Hugging Face or GitHub. You can set:
//   HUGGINGFACE_TOKEN, GITHUB_TOKEN as environment variables.

Future<void> main(List<String> args) async {
  final argMap = _parseArgs(args);
  final outDir = Directory('assets/models');
  if (!await outDir.exists()) {
    await outDir.create(recursive: true);
  }
  final tasks = <Future<void>>[];
  // Candidate mirrors per model. First working URL wins.
  final emotionCandidates = [
    if (argMap['emotion'] != null) argMap['emotion']!,
    Platform.environment['EMOTION_MODEL_URL'] ?? '',
    // Original repo (may be removed)
    'https://github.com/atulapra/Emotion-detection/raw/master/models/emotion_model.tflite',
    // Alternative mirror: huggingface ferplus (may require token and shape differs)
    'https://huggingface.co/onnx-community/emotion-ferplus/resolve/main/emotion-ferplus.tflite',
  ].where((e) => e.isNotEmpty).toList();
  final ageCandidates = [
    if (argMap['age'] != null) argMap['age']!,
    Platform.environment['AGE_MODEL_URL'] ?? '',
    'https://github.com/yu4u/age-gender-estimation/raw/master/models/age_model.tflite',
    'https://huggingface.co/mikel-brostrom/age-gender-estimation-tflite/resolve/main/age_model.tflite',
  ].where((e) => e.isNotEmpty).toList();
  final genderCandidates = [
    if (argMap['gender'] != null) argMap['gender']!,
    Platform.environment['GENDER_MODEL_URL'] ?? '',
    'https://github.com/yu4u/age-gender-estimation/raw/master/models/gender_model.tflite',
    'https://huggingface.co/mikel-brostrom/age-gender-estimation-tflite/resolve/main/gender_model.tflite',
  ].where((e) => e.isNotEmpty).toList();
  if (emotionCandidates.isEmpty &&
      ageCandidates.isEmpty &&
      genderCandidates.isEmpty) {
    stdout.writeln('No model URLs provided.');
    stdout.writeln('Provide via args: --emotion= --age= --gender=');
    stdout
        .writeln('Or env: EMOTION_MODEL_URL, AGE_MODEL_URL, GENDER_MODEL_URL');
    exit(0);
  }
  final client = HttpClient();
  // Set default headers if tokens provided
  final hfToken = Platform.environment['HUGGINGFACE_TOKEN'];
  final ghToken = Platform.environment['GITHUB_TOKEN'];

  tasks.add(_firstWorking(
      client, emotionCandidates, File('${outDir.path}/emotion_model.tflite'),
      hfToken: hfToken, ghToken: ghToken));
  tasks.add(_firstWorking(
      client, ageCandidates, File('${outDir.path}/age_model.tflite'),
      hfToken: hfToken, ghToken: ghToken));
  tasks.add(_firstWorking(
      client, genderCandidates, File('${outDir.path}/gender_model.tflite'),
      hfToken: hfToken, ghToken: ghToken));

  await Future.wait(tasks);
  client.close();
  stdout.writeln('Done.');
}

Map<String, String> _parseArgs(List<String> args) {
  final map = <String, String>{};
  for (final a in args) {
    final parts = a.split('=');
    if (parts.length == 2) {
      final key = parts[0].replaceAll('--', '').trim();
      map[key] = parts[1].trim();
    }
  }
  return map;
}

Future<void> _download(HttpClient client, String url, File outFile,
    {String? hfToken, String? ghToken}) async {
  stdout.writeln('Downloading ${outFile.path} from $url');
  final uri = Uri.parse(url);
  final req = await client.getUrl(uri);
  // Add Authorization header if matching host and token available
  if (uri.host.contains('huggingface.co') &&
      hfToken != null &&
      hfToken.isNotEmpty) {
    req.headers.set('Authorization', 'Bearer $hfToken');
  }
  if (uri.host.contains('github.com') &&
      ghToken != null &&
      ghToken.isNotEmpty) {
    req.headers.set('Authorization', 'Bearer $ghToken');
  }
  final res = await req.close();
  if (res.statusCode != 200) {
    stderr.writeln('Failed ${outFile.path}: HTTP ${res.statusCode}');
    return;
  }
  final sink = outFile.openWrite();
  await res.pipe(sink);
  await sink.flush();
  await sink.close();
  stdout.writeln('Saved ${outFile.path} (${await outFile.length()} bytes)');
}

Future<void> _firstWorking(
  HttpClient client,
  List<String> candidates,
  File outFile, {
  String? hfToken,
  String? ghToken,
}) async {
  if (await outFile.exists()) {
    stdout.writeln('Already exists: ${outFile.path}');
    return;
  }
  for (final u in candidates) {
    try {
      await _download(client, u, outFile, hfToken: hfToken, ghToken: ghToken);
      if (await outFile.exists() && await outFile.length() > 0) return;
    } catch (e) {
      stderr.writeln('Attempt failed for ${outFile.path} from $u: $e');
    }
  }
  stderr.writeln('All sources failed for ${outFile.path}.');
}
