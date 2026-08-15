import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/hex_background.dart';
import '../providers/app_providers.dart';
import '../screens/attendance_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/resources_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _pages = [
    HomeScreen(),
    AttendanceScreen(),
    CalendarScreen(),
    ResourcesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellTabProvider);
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: _pages[index]),
        extendBody: true,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: ColoredBox(
              color: const Color(0xE01A1C22),
              child: NavigationBar(
                height: 68,
                backgroundColor: Colors.transparent,
                indicatorColor: AppColors.purple.withValues(alpha: 0.22),
                selectedIndex: index,
                onDestinationSelected: (i) => ref.read(shellTabProvider.notifier).state = i,
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                  NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: 'Attendance'),
                  NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Classes'),
                  NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Resources'),
                  NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
