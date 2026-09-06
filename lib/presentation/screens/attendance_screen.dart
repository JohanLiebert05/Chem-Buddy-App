import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/attendance_math.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/atom_logo.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/models.dart';
import '../../data/models/timetable_entry.dart';
import '../../data/services/timetable_parser_service.dart';
import '../providers/app_providers.dart';
import 'smart_flashcards_generate_screen.dart';
import 'smart_flashcards_hub.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const AttendanceScreen({super.key, this.embedded = false});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  late DateTime _selectedDate;
  double _targetPercent = 75.0;
  bool _showSimulator = false;
  TimetablePreset _selectedPhotoPreset = TimetablePreset.organic;

  // Simulator state
  int _simAttend = 3;
  int _simMiss = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  TimetablePreset _detectActivePreset(List<TimetableEntry> entries) {
    final hasInorganic = entries.any((e) =>
        e.subjectCode.toUpperCase().contains('ICH') ||
        e.subject.toUpperCase().contains('INORGANIC'));
    return hasInorganic ? TimetablePreset.inorganic : TimetablePreset.organic;
  }

  void _showTimetablePhotoDialog(BuildContext context, TimetablePreset preset) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceElevated,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.table_chart_rounded, color: AppColors.purpleBright, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${preset.title} Timetable',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        Text('${preset.department} • ${preset.effectiveDate}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: Container(
                color: Colors.black,
                constraints: const BoxConstraints(maxHeight: 480),
                child: ClipRRect(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.8,
                    maxScale: 5.0,
                    child: Center(
                      child: Image.asset(
                        preset.imageAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => const Center(
                          child: Text('Timetable image loading...',
                              style: TextStyle(color: AppColors.textMuted)),
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
                  const Icon(Icons.touch_app_rounded, size: 14, color: AppColors.brandBright),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Pinch to zoom & drag to inspect slots & teacher names.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done',
                        style: TextStyle(color: AppColors.brandBright, fontWeight: FontWeight.w700)),
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
    final state = ref.watch(appControllerProvider);
    final repo = ref.watch(chemRepositoryProvider);
    final overall = repo.overallStats();
    final week = repo.lastSevenDayPercents();
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final slots = repo.slotsFor(_selectedDate);
    final remaining = repo.remainingClasses();
    final projected = overall.projectedPercent(remaining: remaining);

    final isTodaySelected = _isSameDay(_selectedDate, todayNormalized);
    final nextSlot = repo.nextUpcomingSlot(today);
    final activePreset = _detectActivePreset(state.entries);

    // Unmarked slots for today (for quick check-in banner)
    final unmarkedSlotsToday = isTodaySelected
        ? slots.where((s) => repo.recordFor(slotId: s.id, date: todayNormalized) == null).toList()
        : <TimetableSlot>[];

    // Subjects in danger below target
    final dangerSubjects = state.subjects.where((s) {
      final stats = repo.statsFor(s.id);
      return stats.counted > 0 && stats.percent < _targetPercent;
    }).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(20, widget.embedded ? 4 : 12, 20, 100),
      children: [
        if (!widget.embedded) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Attendance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              if (!isTodaySelected)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.purpleBright,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  onPressed: () {
                    AppHaptics.tap();
                    setState(() => _selectedDate = todayNormalized);
                  },
                  icon: const Icon(Icons.today, size: 16),
                  label: const Text('Today', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // 1. Live Next Class Spotlight (if today has upcoming lecture)
        if (nextSlot != null && isTodaySelected) ...[
          _buildNextClassSpotlight(context, nextSlot, state, repo, todayNormalized),
          const SizedBox(height: 12),
        ],

        // 2. Main Stats GlowCard with Circular Meter & Target Selector
        GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircularAttendance(percent: overall.percent, size: 110),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatChip(
                              label: 'Can Skip',
                              value: '${overall.canSkipForTarget(_targetPercent)}',
                              color: overall.canSkipForTarget(_targetPercent) > 0 ? AppColors.present : AppColors.warning,
                            ),
                            _StatChip(
                              label: 'Catch-up',
                              value: '${overall.attendToReachTarget(_targetPercent)}',
                              color: overall.attendToReachTarget(_targetPercent) == 0 ? AppColors.present : AppColors.absent,
                            ),
                            _StatChip(label: 'Streak', value: '${repo.streak()}d'),
                            _StatChip(label: 'Projected', value: '${projected.round()}%'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 22),

              // Target Selector Row
              Row(
                children: [
                  const Text('Target Goal:', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [75.0, 80.0, 85.0, 90.0].map((t) {
                          final selected = _targetPercent == t;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text('${t.round()}%${t == 75 ? ' (Min)' : t == 85 ? ' (Dist)' : ''}'),
                              selected: selected,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                color: selected ? Colors.white : AppColors.textSecondary,
                              ),
                              selectedColor: AppColors.purpleDeep,
                              backgroundColor: AppColors.surfaceElevated,
                              side: BorderSide(
                                color: selected ? AppColors.purpleBright : AppColors.border,
                                width: selected ? 1.5 : 1,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              onSelected: (_) {
                                AppHaptics.tap();
                                setState(() => _targetPercent = t);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'What-If Simulator',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      _showSimulator ? Icons.calculate : Icons.calculate_outlined,
                      color: _showSimulator ? AppColors.brandBright : AppColors.textMuted,
                      size: 22,
                    ),
                    onPressed: () {
                      AppHaptics.tap();
                      setState(() => _showSimulator = !_showSimulator);
                    },
                  ),
                ],
              ),

              // 3. Interactive What-If Simulator (Collapsible)
              if (_showSimulator) ...[
                const Divider(color: AppColors.border, height: 16),
                _buildSimulatorCard(overall),
              ],
            ],
          ),
        ),

        // 4. Timetable Photo Reference Banner with Preset Selector & Zoom Viewer
        const SizedBox(height: 12),
        _buildTimetablePhotoBanner(context, state.entries, activePreset),

        // 5. Academic Recovery / Danger Alert Banner
        if (dangerSubjects.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDangerBanner(context, dangerSubjects, repo),
        ],

        // 6. Today's Timetable Check-In Banner (if today has unmarked slots)
        if (isTodaySelected && slots.isNotEmpty && unmarkedSlotsToday.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildTodayCheckInBanner(context, slots, unmarkedSlotsToday, todayNormalized),
        ],

        // 7. Horizontal Date Ribbon / Carousel
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isTodaySelected
                  ? 'Schedule & Attendance (Today)'
                  : 'Schedule & Attendance (${DateFormat('EEE, MMM d').format(_selectedDate)})',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
            ),
            if (slots.isNotEmpty)
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  foregroundColor: AppColors.present,
                ),
                onPressed: () => _handleMarkAllPresent(context, slots, _selectedDate),
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text('Mark All Present', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildDateRibbon(todayNormalized, repo),

        const SizedBox(height: 12),

        // 8. Slots for Selected Date with Teacher Attribution & Interactive Attendance Prompts
        if (slots.isEmpty)
          GlowCard(
            child: Row(
              children: [
                const Icon(Icons.event_busy, color: AppColors.textMuted, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No classes scheduled for ${DateFormat('EEEE').format(_selectedDate)}.',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Classes sync automatically from your university timetable. Switch between Organic and Inorganic presets above anytime.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        ...slots.map((slot) {
          final subject = state.subjects.where((s) => s.id == slot.subjectId).firstOrNull;
          final entry = state.entries.where((e) => e.id == slot.id).firstOrNull;
          final current = repo.recordFor(slotId: slot.id, date: _selectedDate);

          final teacher = (entry?.teacherName.isNotEmpty == true)
              ? entry!.teacherName
              : (slot.room.isNotEmpty && !slot.room.toLowerCase().startsWith('room') ? slot.room : '');
          final code = (entry?.subjectCode.isNotEmpty == true) ? entry!.subjectCode : (subject?.code ?? '');
          final title = (entry?.subject.isNotEmpty == true)
              ? entry!.subject
              : (subject?.name ?? (entry?.displayName.isNotEmpty == true ? entry!.displayName : 'Chemistry Class'));
          final timeStr = slot.timeLabel.isNotEmpty ? slot.timeLabel : (entry != null ? '${entry.startTime} – ${entry.endTime}' : '');
          final roomStr = (entry?.room.isNotEmpty == true) ? entry!.room : '';
          final isUnmarked = current == null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlowCard(
              borderColor: isUnmarked
                  ? AppColors.purpleBright.withValues(alpha: 0.45)
                  : _statusColor(current.status).withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Title & Subject Code Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (code.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.purpleBright.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              color: AppColors.purpleBright,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  [timeStr, if (roomStr.isNotEmpty) 'Room: $roomStr'].where((s) => s.isNotEmpty).join(' • '),
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (current != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(current.status).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _statusColor(current.status).withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            _statusBadgeText(current.status),
                            style: TextStyle(
                              color: _statusColor(current.status),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Faculty Teacher Chip
                  if (teacher.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.brandBright),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Faculty: $teacher',
                              style: const TextStyle(
                                color: AppColors.brandBright,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Interactive Attendance Question Prompt
                  const SizedBox(height: 10),
                  if (isUnmarked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.brandBright.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.help_outline_rounded, color: AppColors.brandBright, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Were you present or absent for ${teacher.isNotEmpty ? teacher : (code.isNotEmpty ? code : title)}\'s class?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: _statusColor(current.status).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            current.status == AttendanceStatus.present
                                ? Icons.check_circle
                                : (current.status == AttendanceStatus.absent ? Icons.cancel : Icons.info_outline),
                            size: 14,
                            color: _statusColor(current.status),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Recorded ${_statusLabelText(current.status)} for ${teacher.isNotEmpty ? teacher : title}${current.markedAt != null ? ' • ${DateFormat('h:mm a').format(current.markedAt!)}' : ''}',
                              style: TextStyle(
                                color: _statusColor(current.status),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 4 Status Buttons
                  Row(
                    children: [
                      for (final status in AttendanceStatus.values)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: _StatusButton(
                              status: status,
                              selected: current?.status == status,
                              onTap: () => ref.read(appControllerProvider.notifier).mark(
                                    subjectId: subject?.id ?? slot.subjectId,
                                    date: _selectedDate,
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

        // 9. Weekly Trend Chart
        const SizedBox(height: 16),
        const SectionTitle('7-Day Trend'),
        GlowCard(
          child: SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final day = DateTime.now().subtract(Duration(days: 6 - v.toInt()));
                        return Text(DateFormat('E').format(day), style: const TextStyle(fontSize: 10, color: AppColors.textMuted));
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < week.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: week[i],
                          width: 14,
                          borderRadius: BorderRadius.circular(6),
                          color: AppColors.attendanceColor(week[i] == 0 ? 75 : week[i]),
                        ),
                      ],
                    ),
                ],
                maxY: 100,
              ),
            ),
          ),
        ),

        // 10. Subject Breakdown with Multi-Target Metrics & Assigned Faculty
        const SizedBox(height: 16),
        const SectionTitle('Subject Breakdown'),
        if (state.subjects.isEmpty)
          const GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.book, size: 48, color: AppColors.purpleBright),
                SizedBox(height: 12),
                Text('No subjects added.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                SizedBox(height: 8),
                Text('Add subjects to start tracking attendance.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ...state.subjects.map((s) {
          final stats = repo.statsFor(s.id);
          final skips = stats.canSkipForTarget(_targetPercent);
          final catchUp = stats.attendToReachTarget(_targetPercent);
          final isSafe = stats.percent >= _targetPercent;

          // Find faculty members teaching this subject from timetable entries
          final facultyList = state.entries
              .where((e) =>
                  (s.code.isNotEmpty && e.subjectCode.toUpperCase() == s.code.toUpperCase()) ||
                  (s.name.isNotEmpty && e.subject.toUpperCase() == s.name.toUpperCase()))
              .map((e) => e.teacherName.trim())
              .where((t) => t.isNotEmpty)
              .toSet()
              .toList();

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5))),
                            const SizedBox(width: 8),
                            _buildRiskBadge(stats.riskTier(_targetPercent)),
                          ],
                        ),
                      ),
                      Text(
                        '${stats.percent.round()}%',
                        style: TextStyle(
                          color: AppColors.attendanceColor(stats.percent),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (facultyList.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '👨‍🏫 Faculty: ${facultyList.join(", ")}',
                      style: const TextStyle(color: AppColors.brandBright, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    isSafe
                        ? 'You can safely skip $skips more class${skips == 1 ? '' : 'es'} without dropping below ${_targetPercent.round()}%.'
                        : 'Attend $catchUp more consecutive class${catchUp == 1 ? '' : 'es'} to recover to ${_targetPercent.round()}%.',
                    style: TextStyle(
                      color: isSafe ? AppColors.textSecondary : AppColors.absent,
                      fontSize: 12.5,
                      fontWeight: isSafe ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Attended: ${stats.present}/${stats.counted} • Postponed: ${stats.postponed} • Excused: ${stats.excused}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          foregroundColor: AppColors.purple,
                          side: const BorderSide(color: AppColors.purple),
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SmartFlashcardsHub())),
                        icon: const Icon(Icons.menu_book, size: 16),
                        label: const Text('Study', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          foregroundColor: AppColors.purple,
                          side: const BorderSide(color: AppColors.purple),
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => SmartFlashcardsGenerateScreen(prefilledTopic: s.name))),
                        icon: const Icon(Icons.style, size: 16),
                        label: const Text('Flashcards', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- SUB-WIDGETS & HELPERS ---

  Widget _buildTimetablePhotoBanner(
    BuildContext context,
    List<TimetableEntry> entries,
    TimetablePreset activePreset,
  ) {
    return GlowCard(
      borderColor: AppColors.purpleBright.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.table_chart_rounded, color: AppColors.purpleBright, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'University Timetable Photo 📷',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.white),
                    ),
                    Text(
                      'Bengaluru City University • M.Sc. Chemistry Sem III',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Preset Selection Chips
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('🧪 Organic Timetable'),
                  selected: _selectedPhotoPreset == TimetablePreset.organic,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: _selectedPhotoPreset == TimetablePreset.organic ? FontWeight.w800 : FontWeight.w600,
                    color: _selectedPhotoPreset == TimetablePreset.organic ? Colors.white : AppColors.textSecondary,
                  ),
                  selectedColor: AppColors.purpleDeep,
                  backgroundColor: AppColors.surfaceElevated,
                  side: BorderSide(
                    color: _selectedPhotoPreset == TimetablePreset.organic ? AppColors.purpleBright : AppColors.border,
                  ),
                  onSelected: (_) {
                    AppHaptics.tap();
                    setState(() => _selectedPhotoPreset = TimetablePreset.organic);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('🧬 Inorganic Timetable'),
                  selected: _selectedPhotoPreset == TimetablePreset.inorganic,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: _selectedPhotoPreset == TimetablePreset.inorganic ? FontWeight.w800 : FontWeight.w600,
                    color: _selectedPhotoPreset == TimetablePreset.inorganic ? Colors.white : AppColors.textSecondary,
                  ),
                  selectedColor: AppColors.purpleDeep,
                  backgroundColor: AppColors.surfaceElevated,
                  side: BorderSide(
                    color: _selectedPhotoPreset == TimetablePreset.inorganic ? AppColors.purpleBright : AppColors.border,
                  ),
                  onSelected: (_) {
                    AppHaptics.tap();
                    setState(() => _selectedPhotoPreset = TimetablePreset.inorganic);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Photo Preview Thumbnail & Zoom Prompt
          InkWell(
            onTap: () => _showTimetablePhotoDialog(context, _selectedPhotoPreset),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          _selectedPhotoPreset.imageAsset,
                          width: 80,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            width: 80,
                            height: 60,
                            color: AppColors.background,
                            child: const Icon(Icons.broken_image, size: 20, color: AppColors.textMuted),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 60,
                          color: Colors.black38,
                          child: const Icon(Icons.zoom_in, color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _selectedPhotoPreset.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Pinch to Zoom 🔍', style: TextStyle(color: AppColors.purpleBright, fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _selectedPhotoPreset == TimetablePreset.organic
                              ? 'Faculty: RK (Roopesh Kumar), HP (Hari Prasad), KSS (Shivashankar), MAA (Mary Anne)'
                              : 'Faculty: VG (Gayathri), MP (Pandurangappa), HP (Hari Prasad), PRC (Chetana)',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (activePreset != _selectedPhotoPreset) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandBright,
                  side: const BorderSide(color: AppColors.brandBright),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  AppHaptics.confirm();
                  ref.read(appControllerProvider.notifier).applyPresetTimetable(_selectedPhotoPreset);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched timetable to ${_selectedPhotoPreset.title}'),
                      backgroundColor: AppColors.surfaceElevated,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.sync_alt, size: 16),
                label: Text('Set ${_selectedPhotoPreset.title} as Active Schedule', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayCheckInBanner(
    BuildContext context,
    List<TimetableSlot> slots,
    List<TimetableSlot> unmarkedSlots,
    DateTime today,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandBright.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandBright.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fact_check_outlined, color: AppColors.brandBright, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Timetable Check-In 📋',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  '${unmarkedSlots.length} of ${slots.length} classes pending attendance confirmation',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.present,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _handleMarkAllPresent(context, slots, today),
            child: const Text('Mark All Present', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildNextClassSpotlight(
    BuildContext context,
    TimetableSlot nextSlot,
    dynamic state,
    dynamic repo,
    DateTime today,
  ) {
    final entry = state.entries.where((e) => e.id == nextSlot.id).firstOrNull;
    final subject = state.subjects.where((s) => s.id == nextSlot.subjectId).firstOrNull;
    final title = (entry?.subject.isNotEmpty == true)
        ? entry!.subject
        : (subject?.name ?? (entry?.displayName.isNotEmpty == true ? entry!.displayName : 'Upcoming Lecture'));
    final teacher = entry?.teacherName.isNotEmpty == true ? entry!.teacherName : '';
    final code = entry?.subjectCode.isNotEmpty == true ? entry!.subjectCode : (subject?.code ?? '');
    final current = repo.recordFor(slotId: nextSlot.id, date: today);
    final isMarked = current != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandBright.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandBright.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, color: AppColors.brandBright, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('UPCOMING LECTURE',
                        style: TextStyle(color: AppColors.brandBright, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    const SizedBox(width: 6),
                    Text('• ${nextSlot.timeLabel}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
                Text(
                  code.isNotEmpty ? '$code: $title' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (teacher.isNotEmpty)
                  Text('👨‍🏫 Faculty: $teacher',
                      style: const TextStyle(color: AppColors.brandBright, fontSize: 11.5, fontWeight: FontWeight.w600))
                else if (nextSlot.room.isNotEmpty)
                  Text('Room: ${nextSlot.room}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          if (!isMarked)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.present,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                AppHaptics.tap();
                ref.read(appControllerProvider.notifier).mark(
                      subjectId: nextSlot.subjectId,
                      date: today,
                      status: AttendanceStatus.present,
                      slotId: nextSlot.id,
                    );
              },
              child: const Text('Present', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }

  Widget _buildSimulatorCard(SubjectAttendanceStats overall) {
    final simulatedPercent = overall.simulateFuture(
      attendAdditional: _simAttend,
      missAdditional: _simMiss,
    );
    final delta = simulatedPercent - overall.percent;
    final isHigher = delta >= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: AppColors.brandBright, size: 16),
              SizedBox(width: 6),
              Text('Interactive What-If Simulator', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Upcoming classes to attend: $_simAttend', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Row(
                children: [
                  _simButton('-', () => setState(() => _simAttend = (_simAttend - 1).clamp(0, 30))),
                  const SizedBox(width: 4),
                  _simButton('+', () => setState(() => _simAttend = (_simAttend + 1).clamp(0, 30))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Upcoming classes to skip: $_simMiss', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Row(
                children: [
                  _simButton('-', () => setState(() => _simMiss = (_simMiss - 1).clamp(0, 20))),
                  const SizedBox(width: 4),
                  _simButton('+', () => setState(() => _simMiss = (_simMiss + 1).clamp(0, 20))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Predicted Standing', style: TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
                    Text(
                      '${simulatedPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: AppColors.attendanceColor(simulatedPercent),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isHigher ? AppColors.present : AppColors.absent).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${isHigher ? '+' : ''}${delta.toStringAsFixed(1)}% vs Current',
                    style: TextStyle(
                      color: isHigher ? AppColors.present : AppColors.absent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _simButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        AppHaptics.tap();
        onTap();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    );
  }

  Widget _buildDangerBanner(BuildContext context, List<Subject> dangerList, dynamic repo) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.absent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.absent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.absent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dangerList.length} Subject${dangerList.length == 1 ? '' : 's'} Below ${_targetPercent.round()}% Target',
                  style: const TextStyle(color: AppColors.absent, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  dangerList.map((s) {
                    final stats = repo.statsFor(s.id);
                    return '${s.name} (${stats.percent.round()}%: need +${stats.attendToReachTarget(_targetPercent)})';
                  }).join(' • '),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRibbon(DateTime today, dynamic repo) {
    // 15 days window: 7 days before, today, 7 days after
    final days = List.generate(15, (i) => today.subtract(Duration(days: 7 - i)));

    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final d = days[index];
          final isSelected = _isSameDay(d, _selectedDate);
          final isToday = _isSameDay(d, today);

          // Check if any attendance was marked on date d
          final hasMarked = repo.attendance().any((r) => _isSameDay(r.date, d));

          return GestureDetector(
            onTap: () {
              AppHaptics.tap();
              setState(() => _selectedDate = d);
            },
            child: Container(
              width: 48,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.purpleDeep
                    : isToday
                        ? AppColors.brandPrimary.withValues(alpha: 0.2)
                        : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.purpleBright
                      : isToday
                          ? AppColors.brandBright
                          : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(d).substring(0, 3).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (hasMarked)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.present,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleMarkAllPresent(BuildContext context, List<TimetableSlot> slots, DateTime date) {
    AppHaptics.confirm();
    ref.read(appControllerProvider.notifier).markAllForDate(
          date: date,
          status: AttendanceStatus.present,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked all ${slots.length} classes as Present for ${DateFormat('EEE, MMM d').format(date)}'),
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildRiskBadge(AttendanceRiskTier tier) {
    final (label, color) = switch (tier) {
      AttendanceRiskTier.critical => ('Critical', AppColors.absent),
      AttendanceRiskTier.warning => ('Warning', AppColors.warning),
      AttendanceRiskTier.safe => ('Safe', AppColors.present),
      AttendanceRiskTier.exemplary => ('Honors', AppColors.brandBright),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  Color _statusColor(AttendanceStatus status) {
    return switch (status) {
      AttendanceStatus.present => AppColors.present,
      AttendanceStatus.absent => AppColors.absent,
      AttendanceStatus.postponed => AppColors.warning,
      AttendanceStatus.excused => AppColors.excused,
    };
  }

  String _statusBadgeText(AttendanceStatus status) {
    return switch (status) {
      AttendanceStatus.present => '✓ Present',
      AttendanceStatus.absent => '✗ Absent',
      AttendanceStatus.postponed => '⏸ Postponed',
      AttendanceStatus.excused => '📋 Excused',
    };
  }

  String _statusLabelText(AttendanceStatus status) {
    return switch (status) {
      AttendanceStatus.present => 'Present',
      AttendanceStatus.absent => 'Absent',
      AttendanceStatus.postponed => 'Postponed',
      AttendanceStatus.excused => 'On-Duty / Excused',
    };
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: color ?? Colors.white,
            ),
          ),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({required this.status, required this.selected, required this.onTap});
  final AttendanceStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status) {
      AttendanceStatus.present => (AppColors.present, Icons.check_circle_outline, 'Present'),
      AttendanceStatus.absent => (AppColors.absent, Icons.cancel_outlined, 'Absent'),
      AttendanceStatus.postponed => (AppColors.warning, Icons.pause_circle_outline, 'Postponed'),
      AttendanceStatus.excused => (AppColors.excused, Icons.assignment_turned_in_outlined, 'Excused'),
    };
    return Material(
      color: selected ? color.withValues(alpha: 0.2) : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (status == AttendanceStatus.absent) {
            AppHaptics.warn();
          } else {
            AppHaptics.tap();
          }
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.border.withValues(alpha: 0.6),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: selected ? color : AppColors.textMuted),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
