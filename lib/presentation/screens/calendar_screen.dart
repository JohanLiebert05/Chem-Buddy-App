import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/models.dart';
import '../providers/app_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _visible = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final repo = ref.watch(chemRepositoryProvider);
    final slots = repo.slotsFor(_selected);
    final dayEvents = state.events.where((e) => _sameDay(e.dueDate, _selected)).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(20, widget.embedded ? 0 : 12, 20, 100),
      children: [
        if (!widget.embedded) ...[
          const Text('Classes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
        ],
        GlowCard(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _visible = DateTime(_visible.year, _visible.month - 1)),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_visible),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _visible = DateTime(_visible.year, _visible.month + 1)),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map((d) => Expanded(
                          child: Text(d, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              _MonthGrid(
                visible: _visible,
                selected: _selected,
                markedDays: {
                  for (final r in state.attendance) DateTime(r.date.year, r.date.month, r.date.day),
                  for (final e in state.events) DateTime(e.dueDate.year, e.dueDate.month, e.dueDate.day),
                },
                onSelect: (d) => setState(() => _selected = d),
              ),
            ],
          ),
        ),
        SectionTitle(DateFormat('EEEE, d MMM').format(_selected)),
        if (slots.isEmpty)
          const GlowCard(child: Text('No classes this day.', style: TextStyle(color: AppColors.textSecondary))),
        ...slots.map((slot) {
          Subject? subject;
          for (final s in state.subjects) {
            if (s.id == slot.subjectId) subject = s;
          }
          final current = repo.recordFor(slotId: slot.id, date: _selected);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject?.name ?? 'Class', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(slot.timeLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final status in AttendanceStatus.values)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _MiniStatus(
                              label: status.name,
                              selected: current?.status == status,
                              onTap: () => ref.read(appControllerProvider.notifier).mark(
                                    subjectId: slot.subjectId,
                                    date: _selected,
                                    status: status,
                                    slotId: slot.id,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SectionTitle('Tests, assignments & seminars'),
        if (dayEvents.isEmpty)
          const GlowCard(child: Text('Nothing due on this date.', style: TextStyle(color: AppColors.textSecondary))),
        ...dayEvents.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              child: Text('${e.type.name.toUpperCase()} · ${e.title}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visible,
    required this.selected,
    required this.markedDays,
    required this.onSelect,
  });

  final DateTime visible;
  final DateTime selected;
  final Set<DateTime> markedDays;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(visible.year, visible.month, 1);
    final daysInMonth = DateTime(visible.year, visible.month + 1, 0).day;
    final leading = first.weekday % 7;
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    return Column(
      children: List.generate(rows, (r) {
        return Row(
          children: List.generate(7, (c) {
            final idx = r * 7 + c;
            final dayNum = idx - leading + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 40));
            }
            final date = DateTime(visible.year, visible.month, dayNum);
            final isSelected = date.year == selected.year && date.month == selected.month && date.day == selected.day;
            final marked = markedDays.any((d) => d.year == date.year && d.month == date.month && d.day == date.day);
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(date),
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.purple : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$dayNum', style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
                      if (marked)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppColors.purpleBright,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}

class _MiniStatus extends StatelessWidget {
  const _MiniStatus({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.purple.withValues(alpha: 0.25) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label[0].toUpperCase() + label.substring(1),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
