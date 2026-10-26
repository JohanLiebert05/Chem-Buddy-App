import '../../core/widgets/expressive_motion.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_error_boundary.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/timetable_entry.dart';
import '../../data/services/timetable_parser_service.dart';
import '../providers/app_providers.dart';
import '../screens/attendance_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/review_timetable_screen.dart';
import '../widgets/timetable_review_dialog.dart';
import '../widgets/timetable_scanner_card.dart';

class ClassesHubScreen extends ConsumerStatefulWidget {
  final int initialTab; // 0: Schedule, 1: Attendance

  const ClassesHubScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<ClassesHubScreen> createState() => _ClassesHubScreenState();
}

class _ClassesHubScreenState extends ConsumerState<ClassesHubScreen> {
  late int mainTab;
  int timetableTab = 0;

  @override
  void initState() {
    super.initState();
    mainTab = widget.initialTab;
  }

  void _showTimetablePhotoDialog(BuildContext context, TimetablePreset preset) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${preset.title} Timetable',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${preset.department} • ${preset.semester}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SpringPress(
                    child: IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.60,
              ),
              color: Colors.black,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Image.asset(
                    preset.imageAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, st) => Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Timetable image not found',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pinch or drag to inspect faculty & slot codes.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  SpringPress(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(appControllerProvider).entries;
    return Column(
      children: [
        // Top Header with Screen Title & Add Class Shortcut
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  mainTab == 0 ? 'Classes & Schedule' : 'Attendance Tracker',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (mainTab == 0)
                SpringPress(
                  child: IconButton.filledTonal(
                    tooltip: 'Add class',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHigh,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => Navigator.push<bool>(
                      context,
                      ReviewTimetableScreen.route(
                        replaceAll: false,
                        initialEntries: [
                          TimetableEntry(
                            id: const Uuid().v4(),
                            dayOfWeek: 'Monday',
                            startTime: '10:00 AM',
                            endTime: '11:00 AM',
                            subjectCode: '',
                          ),
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                  ),
                ),
            ],
          ),
        ),

        // Primary View Toggle: [ Schedule  |  Attendance ]
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.6,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentButton(
                    index: 0,
                    icon: Icons.calendar_today_rounded,
                    label: 'Schedule',
                  ),
                ),
                Expanded(
                  child: _buildSegmentButton(
                    index: 1,
                    icon: Icons.how_to_reg_rounded,
                    label: 'Attendance',
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sub-navigation for Schedule (Today, Week, Month, Scan)
        if (mainTab == 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                for (final item in [
                  'Today',
                  'Week',
                  'Month',
                  'Scan',
                ].asMap().entries)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: item.key == 3 ? 0 : 6),
                      child: SpringPress(
                        child: InkWell(
                          onTap: () {
                            AppHaptics.selection();
                            setState(() => timetableTab = item.key);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: timetableTab == item.key
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: timetableTab == item.key
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              item.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: timetableTab == item.key
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 12,
                                color: timetableTab == item.key
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Active Content Body
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey('classes_hub_${mainTab}_$timetableTab'),
              child: mainTab == 1
                  ? AppErrorBoundary(
                      screenName: 'Attendance',
                      onRetry: () => setState(() {}),
                      child: const AttendanceScreen(embedded: true),
                    )
                  : timetableTab == 2
                  ? const CalendarScreen(embedded: true)
                  : timetableTab == 3
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      children: const [TimetableScannerCard()],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      children: [
                        _buildPresetSelector(entries),
                        ..._list(entries, todayOnly: timetableTab == 0),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetSelector(List<TimetableEntry> entries) {
    final isInorganic = entries.any(
      (e) =>
          e.id.startsWith('inorg_') ||
          e.subjectCode.toUpperCase().contains('ICH') ||
          e.subject.toLowerCase().contains('inorganic'),
    );
    final isOrganic = entries.any(
      (e) =>
          e.id.startsWith('org_') ||
          e.subjectCode.toUpperCase().contains('OCH') ||
          e.subject.toLowerCase().contains('organic'),
    );
    final isOrgActive = !isInorganic || isOrganic;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'BCU Central College • Sem III (2026-27)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SpringPress(
                child: InkWell(
                  onTap: () => _showTimetablePhotoDialog(
                    context,
                    isInorganic && !isOrganic
                        ? TimetablePreset.inorganic
                        : TimetablePreset.organic,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 0.6,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'View Photo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildPresetCard(
                  preset: TimetablePreset.organic,
                  isActive: isOrgActive,
                  icon: Icons.biotech_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPresetCard(
                  preset: TimetablePreset.inorganic,
                  isActive: isInorganic && !isOrganic,
                  icon: Icons.science_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetCard({
    required TimetablePreset preset,
    required bool isActive,
    required IconData icon,
  }) {
    return SpringPress(
      child: InkWell(
        onTap: () async {
          AppHaptics.selection();
          if (!isActive) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHigh,
                title: Text(
                  'Switch to ${preset.title}?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  'This will set your active attendance & timetable schedule to ${preset.title} (BCU Central College Sem III w.e.f. 24-08-2026).',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      foregroundColor: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      'Apply Timetable',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await ref
                  .read(appControllerProvider.notifier)
                  .applyPresetTimetable(preset);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${preset.title} timetable activated as default schedule.',
                    ),
                  ),
                );
              }
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
                : Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: isActive ? 1.2 : 0.6,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.title,
                      style: TextStyle(
                        color: isActive
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: isActive
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                    Text(
                      isActive ? 'Default Active' : 'Tap to switch',
                      style: TextStyle(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = mainTab == index;
    return SpringPress(
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          setState(() => mainTab = index);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _list(List<TimetableEntry> all, {required bool todayOnly}) {
    final filtered = todayOnly
        ? all.where((e) => e.weekdayNumber == DateTime.now().weekday).toList()
        : all;
    if (filtered.isEmpty) {
      return [
        GlowCard(
          child: Text(
            todayOnly
                ? 'No classes today. Scan a timetable or add a class.'
                : 'No weekly classes yet. Scan your timetable to get started.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }
    return [
      for (final e in filtered)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlowCard(
            onTap: () => TimetableReviewDialog.show(
              context,
              ref,
              replaceAll: false,
              entries: [e],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.dayOfWeek} · ${e.startTime}–${e.endTime}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        e.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        [
                          e.type,
                          if (e.room.isNotEmpty) e.room,
                          if (e.teacherName.isNotEmpty) e.teacherName,
                        ].join(' · '),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SpringPress(
                  child: IconButton(
                    onPressed: () => ref
                        .read(appControllerProvider.notifier)
                        .deleteTimetableEntry(e.id),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.adaptive(
                        context,
                        AppColors.statusDanger,
                      ),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}
