import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_error_boundary.dart';
import '../../core/widgets/hex_background.dart';
import '../providers/app_providers.dart';
import '../screens/ask_chembuddy_screen.dart';
import '../screens/classes_hub_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/resources_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _tabNames = [
    'Home',
    'Classes & Attendance',
    'Ask AI',
    'Library',
    'Profile',
  ];

  static const _tabs = [
    HomeScreen(), // 0: Home
    ClassesHubScreen(), // 1: Classes & Attendance
    AskChemBuddyScreen(), // 2: Ask AI (Center Elevated)
    ResourcesScreen(), // 3: Library
    ProfileScreen(), // 4: Profile
  ];

  void _goTo(int i) {
    final current = ref.read(shellTabProvider);
    final clamped = i.clamp(0, _tabs.length - 1);
    debugPrint('[MainShell] Tab switch: from $current (${_tabNames[current.clamp(0, 4)]}) to $clamped (${_tabNames[clamped]})');
    if (current == clamped) {
      debugPrint('[MainShell] Tab $clamped is already active; ignoring redundant tap');
      return;
    }
    AppHaptics.selection();
    ref.read(shellTabProvider.notifier).state = clamped;
  }

  @override
  Widget build(BuildContext context) {
    final rawIndex = ref.watch(shellTabProvider);
    final safeIndex = rawIndex.clamp(0, _tabs.length - 1);
    if (rawIndex != safeIndex) {
      debugPrint('[MainShell] Warning: raw tab index $rawIndex out of bounds, clamped to $safeIndex');
    }

    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: safeIndex,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                AppErrorBoundary(
                  screenName: _tabNames[i],
                  child: _tabs[i],
                ),
            ],
          ),
        ),
        extendBody: true,
        bottomNavigationBar: _ModernBottomNav(
            selectedIndex: safeIndex,
            onTabSelected: _goTo,
          ),
      ),
    );
  }
}

class _ModernBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _ModernBottomNav({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(14, 0, 14, max(10, bottomInset)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xF2100E20), // bg-1 with high opacity
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderHighlight, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.60),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.16),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 0: Home
          _buildFlatNavItem(
            index: 0,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),

          // 1: Classes & Attendance
          _buildFlatNavItem(
            index: 1,
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month_rounded,
            label: 'Classes',
          ),

          // 2: Center Elevated Floating "Ask AI"
          _buildElevatedAiButton(),

          // 3: Library
          _buildFlatNavItem(
            index: 3,
            icon: Icons.menu_book_outlined,
            activeIcon: Icons.menu_book_rounded,
            label: 'Library',
          ),

          // 4: Profile
          _buildFlatNavItem(
            index: 4,
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildFlatNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTabSelected(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.brandPrimary.withValues(alpha: 0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: AppColors.brandBright.withValues(alpha: 0.35), width: 0.8)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.brandPrimary.withValues(alpha: 0.20),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    size: 20,
                    color: isSelected ? AppColors.brandBright : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    letterSpacing: -0.2,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElevatedAiButton() {
    final isSelected = selectedIndex == 2;
    return GestureDetector(
      onTap: () {
        AppHaptics.confirm();
        onTabSelected(2);
      },
      child: AnimatedScale(
        scale: isSelected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withValues(alpha: isSelected ? 0.65 : 0.35),
                blurRadius: isSelected ? 18 : 10,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.30),
              width: isSelected ? 1.4 : 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 5),
              Text(
                'Ask AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

