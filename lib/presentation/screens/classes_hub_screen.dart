import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/timetable_entry.dart';
import '../providers/app_providers.dart';
import '../screens/calendar_screen.dart';
import '../screens/review_timetable_screen.dart';
import '../widgets/timetable_review_dialog.dart';
import '../widgets/timetable_scanner_card.dart';

class ClassesHubScreen extends ConsumerStatefulWidget {
  const ClassesHubScreen({super.key});

  @override
  ConsumerState<ClassesHubScreen> createState() => _ClassesHubScreenState();
}

class _ClassesHubScreenState extends ConsumerState<ClassesHubScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(appControllerProvider).entries;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              const Expanded(child: Text('Timetable', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              for (final item in ['Today', 'Week', 'Month', 'Scan'].asMap().entries)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: item.key == 3 ? 0 : 6),
                    child: GestureDetector(
                      onTap: () => setState(() => tab = item.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: tab == item.key ? AppColors.purple : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(item.value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: tab == 2
              ? const CalendarScreen(embedded: true)
              : tab == 3
                  ? ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), children: const [TimetableScannerCard()])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      children: _list(entries, todayOnly: tab == 0),
                    ),
        ),
      ],
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
