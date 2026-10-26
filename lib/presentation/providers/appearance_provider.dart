import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/appearance.dart';

// Appearance is a device preference, independent of private account data.
final appearanceStorageProvider = Provider<SharedPreferences?>((ref) => null);
final appearanceProvider = NotifierProvider<AppearanceController, Appearance>(
  AppearanceController.new,
);

class AppearanceController extends Notifier<Appearance> {
  @override
  Appearance build() {
    final storage = ref.watch(appearanceStorageProvider);
    final saved =
        storage?.get('appearance.v2') ?? storage?.get('appearance.v1');
    if (saved is List && (saved.length == 2 || saved.length == 3)) {
      return Appearance.decode(
        int.tryParse(saved[0].toString()),
        saved[1],
        saved.length == 3 ? saved[2] : ThemeMode.dark.name,
      );
    }
    return const Appearance();
  }

  Future<void> apply(Appearance next) async {
    final storage = ref.read(appearanceStorageProvider);
    if (storage == null) {
      throw StateError('Appearance storage is unavailable');
    }
    // Save one record first so a failed write never claims the theme was saved.
    final saved = await storage.setStringList('appearance.v2', [
      next.seed.toARGB32().toString(),
      next.glass.name,
      next.mode.name,
    ]);
    if (!saved) {
      throw StateError('Could not save appearance');
    }
    state = next;
  }
}
