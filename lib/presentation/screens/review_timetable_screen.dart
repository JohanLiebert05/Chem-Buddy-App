import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'dart:math';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/models/timetable_entry.dart';
import '../../data/services/timetable_parser_service.dart';
import '../providers/app_providers.dart';

class ReviewTimetableScreen extends ConsumerStatefulWidget {
  const ReviewTimetableScreen({
    super.key,
    required this.initialEntries,
    this.rawText = '',
    this.replaceAll = true,
    this.metadata,
  });

  final List<TimetableEntry> initialEntries;
  final String rawText;
  final bool replaceAll;
  final TimetableMetadata? metadata;

  static Route<bool> route({
    required List<TimetableEntry> initialEntries,
    String rawText = '',
    bool replaceAll = true,
    TimetableMetadata? metadata,
  }) {
    return MaterialPageRoute<bool>(
      builder: (_) => ReviewTimetableScreen(
        initialEntries: initialEntries,
        rawText: rawText,
        replaceAll: replaceAll,
        metadata: metadata,
      ),
    );
  }


  @override
  ConsumerState<ReviewTimetableScreen> createState() => _ReviewTimetableScreenState();
}

class _ReviewTimetableScreenState extends ConsumerState<ReviewTimetableScreen> {
  late List<_EditableSlot> _slots;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  static const _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _classTypes = ['lecture', 'lab', 'tutorial', 'other'];

  @override
  void initState() {
    super.initState();
    if (widget.initialEntries.isEmpty) {
      _slots = [
        _EditableSlot(
          id: const Uuid().v4(),
          dayOfWeek: 'Monday',
          startTime: '09:00 AM',
          endTime: '10:00 AM',
          subjectCode: '',
          subjectName: '',
          teacherName: '',
          room: '',
          type: 'lecture',
        ),
      ];
    } else {
      _slots = widget.initialEntries
          .map(
            (e) => _EditableSlot(
              id: e.id.isNotEmpty ? e.id : const Uuid().v4(),
              dayOfWeek: _normalizeDay(e.dayOfWeek),
              startTime: e.startTime.isNotEmpty ? e.startTime : '09:00 AM',
              endTime: e.endTime.isNotEmpty ? e.endTime : '10:00 AM',
              subjectCode: e.subjectCode,
              subjectName: e.subject,
              teacherName: e.teacherName,
              room: e.room,
              type: _classTypes.contains(e.type.toLowerCase()) ? e.type.toLowerCase() : 'lecture',
            ),
          )
          .toList();
    }
  }

  static String _normalizeDay(String raw) {
    final lower = raw.trim().toLowerCase();
    for (final day in _daysOfWeek) {
      if (day.toLowerCase() == lower || lower.startsWith(day.substring(0, 3).toLowerCase())) {
        return day;
      }
    }
    return 'Monday';
  }

  void _addSlot() {
    AppHaptics.tap();
    setState(() {
      final lastDay = _slots.isNotEmpty ? _slots.last.dayOfWeek : 'Monday';
      _slots.add(
        _EditableSlot(
          id: const Uuid().v4(),
          dayOfWeek: lastDay,
          startTime: '10:00 AM',
          endTime: '11:00 AM',
          subjectCode: '',
          subjectName: '',
          teacherName: '',
          room: '',
          type: 'lecture',
        ),
      );
    });
  }

  void _removeSlot(int index) {
    AppHaptics.tap();
    final removed = _slots[index];
    setState(() {
      _slots.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${removed.subjectName.isNotEmpty ? removed.subjectName : "Class Slot"}'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.purpleBright,
          onPressed: () {
            setState(() {
              _slots.insert(index, removed);
            });
          },
        ),
      ),
    );
  }

  /// Parses strings like "09:00 AM", "1:30 PM", "14:00" to minutes from midnight
  int? _parseTimeToMinutes(String timeStr) {
    final clean = timeStr.trim().toUpperCase();
    final isPm = clean.contains('PM');
    final isAm = clean.contains('AM');

    final stripped = clean.replaceAll(RegExp(r'[^\d:]'), '');
    final parts = stripped.split(':');
    if (parts.isEmpty) return null;

    final hour = int.tryParse(parts[0]);
    if (hour == null) return null;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    var totalHours = hour;
    if (isPm && totalHours != 12) totalHours += 12;
    if (isAm && totalHours == 12) totalHours = 0;

    return totalHours * 60 + minute;
  }

  bool _isTimeRangeValid(String start, String end) {
    final startMin = _parseTimeToMinutes(start);
    final endMin = _parseTimeToMinutes(end);
    if (startMin == null || endMin == null) return true; // If unparseable, don't hard-block
    return startMin < endMin;
  }

  List<int> _findOverlappingSlots(int slotIndex) {
    if (slotIndex >= _slots.length) return const [];
    final current = _slots[slotIndex];
    final currentStart = _parseTimeToMinutes(current.startTime);
    final currentEnd = _parseTimeToMinutes(current.endTime);
    if (currentStart == null || currentEnd == null || currentStart >= currentEnd) {
      return const [];
    }

    final overlaps = <int>[];
    for (var i = 0; i < _slots.length; i++) {
      if (i == slotIndex) continue;
      final other = _slots[i];
      if (other.dayOfWeek.trim().toLowerCase() != current.dayOfWeek.trim().toLowerCase()) {
        continue;
      }

      final otherStart = _parseTimeToMinutes(other.startTime);
      final otherEnd = _parseTimeToMinutes(other.endTime);
      if (otherStart == null || otherEnd == null || otherStart >= otherEnd) {
        continue;
      }

      if (currentStart < otherEnd && otherStart < currentEnd) {
        overlaps.add(i);
      }
    }
    return overlaps;
  }

  bool get _hasAnyValidationErrors {
    for (final slot in _slots) {
      if (slot.subjectCode.trim().isEmpty && slot.subjectName.trim().isEmpty) {
        return true;
      }
      if (slot.dayOfWeek.trim().isEmpty) {
        return true;
      }
      if (!_isTimeRangeValid(slot.startTime, slot.endTime)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _pickTime(BuildContext context, _EditableSlot slot, bool isStart) async {
    AppHaptics.tap();
    final currentStr = isStart ? slot.startTime : slot.endTime;
    TimeOfDay initialTime = TimeOfDay.now();

    final minutes = _parseTimeToMinutes(currentStr);
    if (minutes != null) {
      initialTime = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.purpleBright,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final min = picked.minute.toString().padLeft(2, '0');
      final formatted = '$hour:$min $period';

      setState(() {
        if (isStart) {
          slot.startTime = formatted;
        } else {
          slot.endTime = formatted;
        }
      });
    }
  }

  Future<void> _confirmAndSave() async {
    AppHaptics.confirm();
    if (_slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one class slot before saving.')),
      );
      return;
    }

    // Validate slots
    for (var i = 0; i < _slots.length; i++) {
      final s = _slots[i];
      if (s.subjectCode.trim().isEmpty && s.subjectName.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Slot #${i + 1} requires a Subject Name or Subject Code.')),
        );
        return;
      }
      if (!_isTimeRangeValid(s.startTime, s.endTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Slot #${i + 1} (${s.subjectName.isNotEmpty ? s.subjectName : s.subjectCode}) has an invalid time range (Start must be before End).')),
        );
        return;
      }
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(appControllerProvider.notifier);

    final entries = _slots.map((s) {
      return TimetableEntry(
        id: s.id,
        dayOfWeek: s.dayOfWeek,
        startTime: s.startTime,
        endTime: s.endTime,
        subjectCode: s.subjectCode.trim(),
        subject: s.subjectName.trim(),
        teacherName: s.teacherName.trim(),
        room: s.room.trim(),
        type: s.type,
      );
    }).toList();

    try {
      if (widget.replaceAll) {
        await controller.applyScannedTimetable(entries);
      } else {
        for (final entry in entries) {
          await controller.saveTimetableEntry(entry);
        }
      }

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('✓ Saved ${entries.length} class slots to your timetable schedule!'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Error saving timetable: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final validSlotsCount = _slots.where((s) => (s.subjectCode.isNotEmpty || s.subjectName.isNotEmpty) && _isTimeRangeValid(s.startTime, s.endTime)).length;

    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Review Timetable',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.purpleBright.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${_slots.length} Slots',
                    style: const TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              // Institutional Metadata Card (if detected)
              if (widget.metadata != null &&
                  (widget.metadata!.institution.isNotEmpty ||
                      widget.metadata!.department.isNotEmpty ||
                      widget.metadata!.semester.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: GlowCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    borderColor: AppColors.brandPrimary.withValues(alpha: 0.35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.school_rounded, color: AppColors.purpleBright, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.metadata!.institution.isNotEmpty
                                    ? widget.metadata!.institution
                                    : widget.metadata!.department,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (widget.metadata!.semester.isNotEmpty || widget.metadata!.department.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (widget.metadata!.department.isNotEmpty && widget.metadata!.institution.isNotEmpty)
                                widget.metadata!.department,
                              if (widget.metadata!.semester.isNotEmpty) widget.metadata!.semester,
                              if (widget.metadata!.effectiveDate.isNotEmpty) 'w.e.f. ${widget.metadata!.effectiveDate}',
                            ].join(' • '),
                            style: const TextStyle(color: AppColors.purpleBright, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // OCR Summary banner
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: GlowCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  borderColor: AppColors.purple.withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_outlined, color: AppColors.purpleBright, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.rawText.isNotEmpty
                              ? 'OCR recognized ${_slots.length} class slots with auto-resolved faculty. Edit, correct, or add lectures.'
                              : 'Edit, correct, and organize your weekly chemistry routine.',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              // Editable Class Slots List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: _slots.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _slots.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.purpleBright,
                            side: const BorderSide(color: AppColors.purpleBright, width: 1.2),
                            backgroundColor: AppColors.purple.withValues(alpha: 0.08),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _addSlot,
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text(
                            '+ Add Class Slot',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                      );
                    }

                    final slot = _slots[index];
                    final isTimeValid = _isTimeRangeValid(slot.startTime, slot.endTime);
                    final isSubjectValid = slot.subjectCode.trim().isNotEmpty || slot.subjectName.trim().isNotEmpty;
                    final overlaps = _findOverlappingSlots(index);
                    final hasOverlap = overlaps.isNotEmpty;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GlowCard(
                        borderColor: (!isTimeValid || !isSubjectValid)
                            ? AppColors.danger.withValues(alpha: 0.6)
                            : hasOverlap
                                ? AppColors.warning.withValues(alpha: 0.8)
                                : AppColors.border,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Slot Header: Day Dropdown, Type Selector & Delete Icon
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.purple.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '#${index + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.purpleBright, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: slot.dayOfWeek,
                                        isDense: true,
                                        dropdownColor: AppColors.surfaceElevated,
                                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted, size: 18),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                        items: _daysOfWeek.map((day) {
                                          return DropdownMenuItem(
                                            value: day,
                                            child: Text(day),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => slot.dayOfWeek = val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
                                  tooltip: 'Delete Slot',
                                  onPressed: () => _removeSlot(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Time Selection Row (Start → End)
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _pickTime(context, slot, true),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: isTimeValid ? AppColors.border : AppColors.danger),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 16, color: AppColors.purpleBright),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('START', style: TextStyle(color: AppColors.textMuted, fontSize: 9.5, fontWeight: FontWeight.w800)),
                                              Text(slot.startTime, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 16),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _pickTime(context, slot, false),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: isTimeValid ? AppColors.border : AppColors.danger),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time_filled, size: 16, color: AppColors.blue),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('END', style: TextStyle(color: AppColors.textMuted, fontSize: 9.5, fontWeight: FontWeight.w800)),
                                              Text(slot.endTime, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!isTimeValid) ...[
                              const SizedBox(height: 6),
                              const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Start time must be before End time.',
                                    style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                            if (hasOverlap) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 15),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Time Conflict: Overlaps with Slot #${overlaps.map((i) => i + 1).join(', #')} on ${slot.dayOfWeek}',
                                        style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // Subject Name & Code Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    initialValue: slot.subjectName,
                                    onChanged: (v) => slot.subjectName = v,
                                    minLines: 1,
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 13.5, color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Subject Name',
                                      hintText: 'e.g. Organic Chemistry',
                                      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      filled: true,
                                      fillColor: AppColors.surfaceElevated,
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isSubjectValid ? AppColors.border : AppColors.danger)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: slot.subjectCode,
                                    onChanged: (v) => slot.subjectCode = v,
                                    style: const TextStyle(fontSize: 13.5, color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Code',
                                      hintText: 'CHE-501',
                                      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      filled: true,
                                      fillColor: AppColors.surfaceElevated,
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isSubjectValid ? AppColors.border : AppColors.danger)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!isSubjectValid) ...[
                              const SizedBox(height: 6),
                              const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Subject Name or Subject Code is required.',
                                    style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),

                            // Teacher & Room Row
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: slot.teacherName,
                                    onChanged: (v) => slot.teacherName = v,
                                    minLines: 1,
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 12.5, color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Teacher',
                                      hintText: 'e.g. Dr. Sharma',
                                      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                                      filled: true,
                                      fillColor: AppColors.surfaceElevated,
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: slot.room,
                                    onChanged: (v) => slot.room = v,
                                    minLines: 1,
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 12.5, color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Room / Hall',
                                      hintText: 'e.g. Lab 3 / Room 204',
                                      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                                      filled: true,
                                      fillColor: AppColors.surfaceElevated,
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Class Type selector chips
                            Row(
                              children: [
                                const Text('Type: ', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 6),
                                ...['lecture', 'lab', 'tutorial'].map((type) {
                                  final isSelected = slot.type.toLowerCase() == type;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(
                                        type[0].toUpperCase() + type.substring(1),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? Colors.white : AppColors.textSecondary,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: AppColors.purple,
                                      backgroundColor: AppColors.surfaceElevated,
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                      visualDensity: VisualDensity.compact,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => slot.type = type);
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomSheet: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.purple.withValues(alpha: 0.3))),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, -2)),
            ],
          ),
          padding: EdgeInsets.fromLTRB(16, 12, 16, max(14.0, MediaQuery.paddingOf(context).bottom)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$validSlotsCount of ${_slots.length} Slots Valid',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: (validSlotsCount == _slots.length && !_hasAnyValidationErrors) ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.replaceAll ? 'Overwrites routine' : 'Appends to routine',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                onPressed: (_saving || _hasAnyValidationErrors) ? null : _confirmAndSave,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Confirm & Save Schedule →',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableSlot {
  _EditableSlot({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subjectCode,
    required this.subjectName,
    required this.teacherName,
    required this.room,
    required this.type,
  });

  String id;
  String dayOfWeek;
  String startTime;
  String endTime;
  String subjectCode;
  String subjectName;
  String teacherName;
  String room;
  String type;
}
