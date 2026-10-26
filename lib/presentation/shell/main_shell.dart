import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/haptics.dart';
import '../../core/widgets/app_error_boundary.dart';
import '../../core/widgets/hex_background.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/expressive_motion.dart';
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
    if (current == clamped) {
      return;
    }

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
                TickerMode(
                  enabled: i == safeIndex,
                  child: AppErrorBoundary(
                    screenName: _tabNames[i],
                    child: _tabs[i],
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
            ? null
            : _Material3ExpressiveNavBar(
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
  const _Material3ExpressiveNavBar({
    required this.selectedIndex,
    required this.onTabSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  static const labels = ['Home', 'Classes', 'Ask AI', 'Library', 'Profile'];
  static const icons = [
    Icons.home_outlined,
    Icons.calendar_month_outlined,
    Icons.auto_awesome_outlined,
    Icons.menu_book_outlined,
    Icons.person_outline_rounded,
  ];
  static const activeIcons = [
    Icons.home_rounded,
    Icons.calendar_month_rounded,
    Icons.auto_awesome_rounded,
    Icons.menu_book_rounded,
    Icons.person_rounded,
  ];
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 420);
    final height =
        66.0 + (MediaQuery.textScalerOf(context).scale(11) - 11).clamp(0, 30);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: LiquidGlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        borderRadius: 32,
        blurSigma: 20,
        padding: const EdgeInsets.all(5),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / labels.length;
            return SizedBox(
              height: height,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: duration,
                    curve: Curves.easeOutBack,
                    left: selectedIndex * itemWidth + 2,
                    top: 2,
                    bottom: 2,
                    width: itemWidth - 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primaryContainer.withValues(alpha: .85),
                            colors.primaryContainer.withValues(alpha: .5),
                          ],
                        ),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: .16),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(labels.length, (i) {
                      final selected = i == selectedIndex;
                      return Expanded(
                        child: Semantics(
                          button: true,
                          selected: selected,
                          label: labels[i],
                          onTap: () => onTabSelected(i),
                          child: ExcludeSemantics(
                            child: SpringPress(
                              pressedScale: .955,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => onTabSelected(i),
                                  borderRadius: BorderRadius.circular(26),
                                  child: SizedBox(
                                    height: height,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AnimatedScale(
                                          scale: selected ? 1.08 : 1,
                                          duration: duration,
                                          curve: Curves.easeOutBack,
                                          child: Icon(
                                            selected
                                                ? activeIcons[i]
                                                : icons[i],
                                            size: 23,
                                            color: selected
                                                ? colors.onPrimaryContainer
                                                : colors.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          labels[i],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: selected
                                                ? colors.onPrimaryContainer
                                                : colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
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
  State<_AnimatedFadeIndexedStack> createState() =>
      _AnimatedFadeIndexedStackState();
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
      duration: const Duration(milliseconds: 360),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(
      begin: 0.985,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _AnimatedFadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _activeChildIndex) {
      setState(() {
        _activeChildIndex = widget.index;
      });
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0.0);
      }
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
