import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emotion_sense/ui/camera_view.dart';
import 'package:provider/provider.dart';
import 'package:emotion_sense/presentation/providers/history_provider.dart';
import 'package:emotion_sense/data/repositories/history_repository.dart';
import 'package:emotion_sense/presentation/providers/settings_provider.dart';
import 'package:emotion_sense/presentation/providers/camera_provider.dart';

class EmotionApp extends StatelessWidget {
  const EmotionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(
            create: (_) => HistoryProvider(HistoryRepository())),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final themeMode = settings.themeMode;
          return MaterialApp(
            title: 'EmotionSense',
            themeMode: themeMode,
            theme: ThemeData(
              colorSchemeSeed: Colors.amber,
              brightness: Brightness.light,
              textTheme: GoogleFonts.poppinsTextTheme(),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorSchemeSeed: Colors.amber,
              brightness: Brightness.dark,
              textTheme:
                  GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
              useMaterial3: true,
            ),
            home: const CameraView(),
          );
        },
      ),
    );
  }
}
