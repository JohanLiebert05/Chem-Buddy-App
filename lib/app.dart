import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/hex_background.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/admin/admin_shell.dart';
import 'presentation/screens/onboarding_flow.dart';
import 'presentation/shell/main_shell.dart';

class ChemBuddyApp extends ConsumerWidget {
  const ChemBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appControllerProvider).profile;
    Widget home;
    if (profile.loggedIn) {
      if (profile.role == 'admin') {
        home = const AdminShell();
      } else {
        home = const MainShell();
      }
    } else if (profile.onboarded) {
      home = const HexBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(child: LoginPage()),
        ),
      );
    } else {
      home = const OnboardingFlow();
    }

    return MaterialApp(
      title: 'Chem Buddy by Prajwal A Kambar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: home,
    );
  }
}
