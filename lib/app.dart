import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emotion_sense/presentation/screens/home_screen.dart';
import 'package:emotion_sense/presentation/screens/onboarding_screen.dart';
import 'package:emotion_sense/presentation/screens/settings_screen.dart';
import 'package:emotion_sense/presentation/screens/history_screen.dart';
import 'package:provider/provider.dart';
import 'package:emotion_sense/presentation/providers/emotion_provider.dart';
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
        ChangeNotifierProvider(create: (_) => EmotionProvider()),
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
            routes: {
              '/': (_) => const OnboardingScreen(),
              '/home': (_) => const HomeScreen(),
              '/settings': (_) => const SettingsScreen(),
              '/history': (_) => const HistoryScreen(),
            },
          );
        },
      ),
    );
  }
}
