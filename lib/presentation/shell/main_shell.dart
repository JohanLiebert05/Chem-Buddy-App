import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_error_boundary.dart';
import '../../core/widgets/hex_background.dart';
import '../../core/widgets/liquid_glass.dart';
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
    AskChemBuddyScreen(), // 2: Ask AI
    ResourcesScreen(), // 3: Library
    ProfileScreen(), // 4: Profile
  ];

  void _goTo(int i) {
    final current = ref.read(shellTabProvider);
    final clamped = i.clamp(0, _tabs.length - 1);
    if (current == clamped) return;

    if (clamped == 2) {
      AppHaptics.confirm();
    } else {
      AppHaptics.selection();
    }
    ref.read(shellTabProvider.notifier).state = clamped;
  }

  @override
  Widget build(BuildContext context) {
    final rawIndex = ref.watch(shellTabProvider);
    final safeIndex = rawIndex.clamp(0, _tabs.length - 1);

    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: _AnimatedFadeIndexedStack(
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
        bottomNavigationBar: _Material3ExpressiveNavBar(
          selectedIndex: safeIndex,
          onTabSelected: _goTo,
        ),
      ),
    );
  }
}

/// Pixel Material 3 Expressive Bottom Navigation Bar
///
/// Features clean tonal pill indicators, expressive icons, readable typography,
/// and smooth selection states without excessive neon glows.
class _Material3ExpressiveNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _Material3ExpressiveNavBar({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return LiquidGlassContainer(
      enableBlur: true,
      blurSigma: 16,
      borderRadius: 0,
      customBorderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      backgroundColor: AppColors.surfaceContainerLow.withValues(alpha: 0.82),
      borderColor: Colors.white.withValues(alpha: 0.10),
      borderWidth: 0.8,
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ],
      padding: EdgeInsets.fromLTRB(8, 6, 8, bottomInset > 0 ? bottomInset : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month_rounded,
            label: 'Classes',
          ),
          _buildAiNavItem(
            index: 2,
            icon: Icons.auto_awesome_rounded,
            label: 'Ask AI',
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.menu_book_outlined,
            activeIcon: Icons.menu_book_rounded,
            label: 'Library',
          ),
          _buildNavItem(
            index: 4,
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;

    return InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.brandPrimary.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandPrimary.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected ? AppColors.brandBright : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildAiNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;

    return InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.brandPrimary.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandPrimary
                      : AppColors.brandPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : AppColors.brandBright,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.brandBright : AppColors.textSecondary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      );
  }
}

/// Fluid, state-preserving animated switcher that transitions between tabs
/// using Google Pixel Material 3 expressive easing and subtle forward scale.
class _AnimatedFadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _AnimatedFadeIndexedStack({
    required this.index,
    required this.children,
  });

  @override
  State<_AnimatedFadeIndexedStack> createState() => _AnimatedFadeIndexedStackState();
}

class _AnimatedFadeIndexedStackState extends State<_AnimatedFadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  int _activeChildIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeChildIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.99, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _AnimatedFadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _activeChildIndex) {
      setState(() {
        _activeChildIndex = widget.index;
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: IndexedStack(
          index: _activeChildIndex,
          children: widget.children,
        ),
      ),
    );
  }
}
