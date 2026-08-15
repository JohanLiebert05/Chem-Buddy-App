import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/local/local_store.dart';
import 'data/remote/notification_service.dart';
import 'data/remote/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.openAll();
  await SupabaseService.instance.init();
  await NotificationService.instance.init();
  runApp(const ProviderScope(child: ChemBuddyApp()));
}
