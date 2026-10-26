import '../../../core/widgets/expressive_motion.dart';

import 'package:flutter/material.dart';

import '../../../core/widgets/hex_background.dart';
import '../../shell/main_shell.dart';
import 'admin_dashboard_screen.dart';
import 'student_management_screen.dart';
import 'content_management_screen.dart';
import 'rag_management_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final PageController _pages = PageController();
  int _currentIndex = 0;
  bool _studentView = false;

  static const _tabs = [
    AdminDashboardScreen(),
    StudentManagementScreen(),
    ContentManagementScreen(),
    RagManagementScreen(),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    setState(() => _currentIndex = i);
    _pages.animateToPage(
      i,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_studentView) {
      return Scaffold(
        body: Stack(
          children: [
            const MainShell(),
            Positioned(
              top: MediaQuery.of(context).padding.top + 4,
              right: 8,
              child: Material(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                child: SpringPress(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _studentView = false),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Admin',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Admin Console',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            SpringPress(
              child: TextButton.icon(
                onPressed: () => setState(() => _studentView = true),
                icon: Icon(
                  Icons.swap_horiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  'Student View',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: PageView(
          controller: _pages,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (i) => setState(() => _currentIndex = i),
          children: _tabs,
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: ColoredBox(
              color: const Color(0xE01A1C22),
              child: NavigationBar(
                height: 68,
                backgroundColor: Colors.transparent,
                indicatorColor: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.22),
                selectedIndex: _currentIndex,
                onDestinationSelected: _goTo,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: 'Students',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.article_outlined),
                    selectedIcon: Icon(Icons.article),
                    label: 'Content',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.auto_awesome_outlined),
                    selectedIcon: Icon(Icons.auto_awesome),
                    label: 'Knowledge',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
