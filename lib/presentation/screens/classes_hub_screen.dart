import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/timetable_entry.dart';
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
  void initState({super.key}) {
    super.initState();
    mainTab = widget.initialTab;
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              if (mainTab == 0)
                IconButton(
                  tooltip: 'Add class',
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
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.purpleBright),
                ),
            ],
          ),
        ),

        // Primary View Toggle: [ 📅 Schedule  |  📊 Attendance ]
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle, width: 0.8),
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
                for (final item in ['Today', 'Week', 'Month', 'Scan'].asMap().entries)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: item.key == 3 ? 0 : 6),
                      child: GestureDetector(
                        onTap: () {
                          AppHaptics.selection();
                          setState(() => timetableTab = item.key);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: timetableTab == item.key ? AppColors.brandPrimary : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: timetableTab == item.key
                                ? Border.all(color: AppColors.borderHighlight, width: 0.8)
                                : null,
                          ),
                          child: Text(
                            item.value,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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
          child: mainTab == 1
              ? const AttendanceScreen(embedded: true)
              : timetableTab == 2
                  ? const CalendarScreen(embedded: true)
                  : timetableTab == 3
                      ? ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), children: const [TimetableScannerCard()])
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          children: _list(entries, todayOnly: timetableTab == 0),
                        ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = mainTab == index;
    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        setState(() => mainTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _list(List<TimetableEntry> all, {required bool todayOnly}) {

    final filtered = todayOnly ? all.where((e) => e.weekdayNumber == DateTime.now().weekday).toList() : all;
    if (filtered.isEmpty) {
      return [
        GlowCard(
          child: Text(
            todayOnly ? 'No classes today. Scan a timetable or add a class.' : 'No weekly classes yet. Scan your timetable to get started.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ];
    }
    return [
      for (final e in filtered)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlowCard(
            onTap: () => TimetableReviewDialog.show(context, ref, replaceAll: false, entries: [e]),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.dayOfWeek} · ${e.startTime}–${e.endTime}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      Text(e.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(
                        [e.type, if (e.room.isNotEmpty) e.room, if (e.teacherName.isNotEmpty) e.teacherName].join(' · '),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ref.read(appControllerProvider.notifier).deleteTimetableEntry(e.id),
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}
