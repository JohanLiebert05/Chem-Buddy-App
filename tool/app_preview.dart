import 'package:chem_buddy/presentation/screens/beginner_tutorial_dialog.dart';
import 'package:chem_buddy/presentation/screens/chemistry_toolkit_screen.dart';
import 'package:chem_buddy/presentation/screens/spectroscopy_hub_screen.dart';
import 'package:chem_buddy/presentation/screens/pericyclic_hub_screen.dart';
import 'package:chem_buddy/presentation/screens/profile_screen.dart';
// Browser-only preview using the real app screens and isolated sample data.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chem_buddy/core/theme/app_theme.dart';
import 'package:chem_buddy/core/theme/appearance.dart';
import 'package:chem_buddy/data/local/local_store.dart';
import 'package:chem_buddy/data/models/models.dart';
import 'package:chem_buddy/data/models/timetable_entry.dart';
import 'package:chem_buddy/presentation/providers/appearance_provider.dart';
import 'package:chem_buddy/presentation/screens/appearance_screen.dart';
import 'package:chem_buddy/presentation/screens/onboarding_flow.dart';
import 'package:chem_buddy/presentation/providers/app_providers.dart';
import 'package:chem_buddy/core/widgets/exit_confirmation.dart';
import 'package:chem_buddy/presentation/shell/main_shell.dart';

final previewNavigator = GlobalKey<NavigatorState>();

Future<void> main() async {
  if (!kIsWeb) {
    throw StateError('Run this sample preview in a browser.');
  }
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    debugPrint('Preview error: ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  };
  final storage = await SharedPreferences.getInstance();
  if (!storage.containsKey('full-preview.light-intro')) {
    final old = storage.get('appearance.v2') ?? storage.get('appearance.v1');
    await storage.setStringList('appearance.v2', [
      old is List && old.isNotEmpty
          ? old.first.toString()
          : const Appearance().seed.toARGB32().toString(),
      GlassStyle.crystal.name,
      ThemeMode.light.name,
    ]);
    await storage.setBool('full-preview.light-intro', true);
  }
  await HiveBoxes.openAll();
  final firstRun = Uri.base.queryParameters['screen'] == 'welcome';
  final loginOnly = Uri.base.queryParameters['screen'] == 'login';
  await HiveBoxes.switchAccount(
    firstRun || loginOnly ? 'preview:setup' : 'preview:glass-ui',
  );
  final store = LocalStore();
  await store.saveProfile(
    const UserProfile(
      fullName: 'Prajwal',
      registerNumber: 'PREVIEW',
      university: 'ChemBuddy demo',
      semester: 3,
      loggedIn: true,
      onboarded: true,
    ).toJson(),
  );
  if (firstRun || loginOnly) {
    await store.saveProfile(UserProfile(onboarded: loginOnly).toJson());
  }
  await store.appTutorialState.put('completed', true);
  if (!firstRun && !loginOnly && store.subjects.isEmpty) {
    const subjects = [
      Subject(
        id: 'demo-organic',
        name: 'Organic Reaction Mechanisms',
        code: 'CH 301 OC',
        teacher: 'Sample instructor',
        colorHex: 0xFF9474F5,
      ),
      Subject(
        id: 'demo-spectroscopy',
        name: 'Organic Spectroscopy',
        code: 'CH 303 OC',
        colorHex: 0xFF26A69A,
      ),
      Subject(
        id: 'demo-inorganic',
        name: 'Inorganic Chemistry',
        code: 'CH 301 IC',
        colorHex: 0xFF527DEA,
      ),
    ];
    final now = DateTime.now();
    for (var i = 0; i < subjects.length; i++) {
      final subject = subjects[i];
      await store.put(store.subjects, subject.id, subject.toJson());
      for (var day = 1; day <= 12; day++) {
        final id = 'demo-attendance-$i-$day';
        await store.put(
          store.attendance,
          id,
          AttendanceRecord(
            id: id,
            subjectId: subject.id,
            date: now.subtract(Duration(days: day)),
            status: day % (i + 5) == 0
                ? AttendanceStatus.absent
                : AttendanceStatus.present,
          ).toJson(),
        );
      }
    }
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    for (final day in days) {
      for (var i = 0; i < subjects.length; i++) {
        final entry = TimetableEntry(
          id: 'demo-$day-$i',
          dayOfWeek: day,
          startTime: '${9 + i}:00',
          endTime: '${10 + i}:00',
          subjectCode: subjects[i].code,
          subject: subjects[i].name,
          room: 'Science block · ${101 + i}',
          colorHex: subjects[i].colorHex,
        );
        await store.put(store.timetableEntries, entry.id, entry.toJson());
      }
    }
    final event = AcademicEvent(
      id: 'demo-assignment',
      title: 'Reaction mechanisms review',
      type: EventType.assignment,
      subjectId: subjects.first.id,
      dueDate: now.add(const Duration(days: 3)),
      description: 'Sample deadline for exploring the app preview.',
    );
    await store.put(store.events, event.id, event.toJson());
    final note = NoteItem(
      id: 'demo-note',
      title: 'Aromaticity essentials',
      body: 'A cyclic, planar, conjugated system follows Hückel’s 4n + 2 rule.\n\nTry opening the chemistry tools and reaction library.',
      updatedAt: now,
      subjectId: subjects.first.id,
    );
    await store.put(store.notes, note.id, note.toJson());
  }
  runApp(
    ProviderScope(
      overrides: [appearanceStorageProvider.overrideWithValue(storage)],
      child: const AppPreview(),
    ),
  );
}

class AppPreview extends ConsumerWidget {
  const AppPreview({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    return MaterialApp(
      navigatorKey: previewNavigator,
      debugShowCheckedModeBanner: false,
      title: 'ChemBuddy · Full app preview',
      theme: AppTheme.fromAppearance(appearance, brightness: Brightness.light),
      darkTheme: AppTheme.fromAppearance(
        appearance,
        brightness: Brightness.dark,
      ),
      themeMode: appearance.mode,
      themeAnimationDuration: const Duration(milliseconds: 360),
      themeAnimationCurve: Curves.easeInOutCubic,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final width = media.size.width.clamp(0.0, 480.0).toDouble();
        final colors = Theme.of(context).colorScheme;
        final scale =
            (double.tryParse(Uri.base.queryParameters['scale'] ?? '') ?? 1)
                .clamp(1.0, 2.0)
                .toDouble();
        return ColoredBox(
          color: colors.surfaceContainer,
          child: Center(
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  Material(
                    color: colors.surface,
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'App preview · sample data',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              colors.brightness == Brightness.light
                                  ? Icons.dark_mode_outlined
                                  : Icons.light_mode_outlined,
                              size: 20,
                            ),
                            onPressed: () => ref
                                .read(appearanceProvider.notifier)
                                .apply(
                                  appearance.copyWith(
                                    mode: colors.brightness == Brightness.light
                                        ? ThemeMode.dark
                                        : ThemeMode.light,
                                  ),
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.palette_outlined, size: 20),
                            onPressed: () =>
                                previewNavigator.currentState?.push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const AppearanceScreen(),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: MediaQuery(
                      data: media.copyWith(
                        size: Size(
                          width,
                          (media.size.height - 44).clamp(0.0, double.infinity),
                        ),
                        textScaler: TextScaler.linear(scale),
                        highContrast:
                            Uri.base.queryParameters['contrast'] == 'high' ||
                            media.highContrast,
                      ),
                      child: child!,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      home: const _PreviewHome(),
    );
  }
}

class _PreviewHome extends ConsumerWidget {
  const _PreviewHome();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appControllerProvider).profile;
    final screen = Uri.base.queryParameters['screen'];
    if (screen == 'tour') {
      return const Scaffold(body: BeginnerTutorialDialog());
    }
    if (screen == 'toolkit') {
      return const ChemistryToolkitScreen();
    }
    if (screen == 'spectroscopy') {
      return const SpectroscopyHubScreen();
    }
    if (screen == 'pericyclic') {
      return const PericyclicHubScreen();
    }
    if (screen == 'profile') {
      return const Scaffold(body: SafeArea(child: ProfileScreen()));
    }
    return ExitConfirmation(
      child: profile.loggedIn
          ? const MainShell()
          : profile.onboarded
          ? const Scaffold(body: SafeArea(child: LoginPage()))
          : const OnboardingFlow(),
    );
  }
}
