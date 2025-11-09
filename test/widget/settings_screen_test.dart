import 'package:emotion_sense/presentation/providers/settings_provider.dart';
import 'package:emotion_sense/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('SettingsScreen toggles age & gender visibility', (tester) async {
    final provider = SettingsProvider.test();
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: provider)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final tileFinder = find.widgetWithText(SwitchListTile, 'Show age & gender');
    expect(tileFinder, findsOneWidget);
    final initial = provider.showAgeGender;
    await tester.tap(tileFinder);
    await tester.pumpAndSettle();
    expect(provider.showAgeGender, isNot(initial));
  });
}
