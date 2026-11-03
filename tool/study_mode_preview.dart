// Standalone local preview. It never reads production accounts or calls AI.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chem_buddy/core/theme/app_theme.dart';
import 'package:chem_buddy/core/theme/appearance.dart';
import 'package:chem_buddy/core/widgets/hex_background.dart';
import 'package:chem_buddy/data/services/organic_progress_repository.dart';
import 'package:chem_buddy/presentation/screens/study_mode_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final repository = OrganicProgressRepository(
    read: () {
      try {
        return jsonDecode(
          preferences.getString('organic_study_preview_v1') ?? 'null',
        );
      } catch (_) {
        return null;
      }
    },
    write: (value) async {
      final ok = await preferences.setString(
        'organic_study_preview_v1',
        jsonEncode(value),
      );
      if (!ok) throw StateError('Browser storage unavailable');
    },
  );
  runApp(_Preview(repository));
}

class _Preview extends StatefulWidget {
  const _Preview(this.repository);
  final OrganicProgressRepository repository;
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  bool dark = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ChemBuddy · Study Mode & Curious',
    theme: AppTheme.fromAppearance(
      const Appearance(),
      brightness: Brightness.light,
    ),
    darkTheme: AppTheme.fromAppearance(
      const Appearance(),
      brightness: Brightness.dark,
    ),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: Builder(
      builder: (context) => HexBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('ChemBuddy'),
            actions: [
              IconButton(
                tooltip: 'Switch theme',
                icon: Icon(
                  dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
                onPressed: () => setState(() => dark = !dark),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Build understanding. Keep going.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Local preview • progress stays in this browser. Your app account data is separate.',
                  ),
                  const SizedBox(height: 24),
                  OrganicStudyEntrypoints(repository: widget.repository),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
