// Local preview of the real Appearance screen; no account or cloud connection.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chem_buddy/core/theme/app_theme.dart';
import 'package:chem_buddy/presentation/providers/appearance_provider.dart';
import 'package:chem_buddy/presentation/screens/appearance_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [appearanceStorageProvider.overrideWithValue(storage)],
      child: const AppearancePreview(),
    ),
  );
}

class AppearancePreview extends ConsumerWidget {
  const AppearancePreview({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ChemBuddy · Appearance preview',
    theme: AppTheme.fromAppearance(
      ref.watch(appearanceProvider),
      brightness: Brightness.light,
    ),
    darkTheme: AppTheme.fromAppearance(
      ref.watch(appearanceProvider),
      brightness: Brightness.dark,
    ),
    themeMode: ref.watch(appearanceProvider).mode,
    builder: (context, child) {
      final media = MediaQuery.of(context);
      final width = media.size.width.clamp(0.0, 480.0).toDouble();
      final scale =
          (double.tryParse(Uri.base.queryParameters['scale'] ?? '') ?? 1)
              .clamp(1.0, 2.0)
              .toDouble();
      return Center(
        child: SizedBox(
          width: width,
          child: MediaQuery(
            data: media.copyWith(
              size: Size(width, media.size.height),
              textScaler: TextScaler.linear(scale),
              highContrast:
                  Uri.base.queryParameters['contrast'] == 'high' ||
                  media.highContrast,
            ),
            child: child!,
          ),
        ),
      );
    },
    home: const AppearanceScreen(),
  );
}
