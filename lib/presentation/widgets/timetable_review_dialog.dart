import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/timetable_entry.dart';
import '../providers/app_providers.dart';

/// Lets the student fix OCR mistakes before writing the weekly routine to Hive.
class TimetableReviewDialog {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required List<TimetableEntry> entries,
    String rawText = '',
    bool replaceAll = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReviewSheet(initial: entries, rawText: rawText, replaceAll: replaceAll),
    );
  }
}

class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.initial, required this.rawText, required this.replaceAll});

  final List<TimetableEntry> initial;
  final String rawText;
  final bool replaceAll;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  late List<TimetableEntry> _rows;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rows = List.of(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 14),
            const Text('Review timetable', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            const Text(
              'Correct any OCR mistakes, then save to your daily routine.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            if (widget.rawText.isNotEmpty && widget.rawText.length < 1200) ...[
              const SizedBox(height: 8),
              Text(
                widget.rawText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _rows.length,
                itemBuilder: (context, i) {
                  final row = _rows[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlowCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Class ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _rows.removeAt(i)),
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                              ),
                            ],
                          ),
                          _field('Day', row.dayOfWeek, (v) {
                            _rows[i] = _rows[i].copyWith(dayOfWeek: v);
                          }),
                          _field('Start', row.startTime, (v) {
                            _rows[i] = _rows[i].copyWith(startTime: v);
                          }),
                          _field('End', row.endTime, (v) {
                            _rows[i] = _rows[i].copyWith(endTime: v);
                          }),
                          _field('Subject', row.subject, (v) {
                            _rows[i] = _rows[i].copyWith(subject: v);
                          }),
                          _field('Subject code', row.subjectCode, (v) {
                            _rows[i] = _rows[i].copyWith(subjectCode: v);
                          }),
                          _field('Teacher', row.teacherName, (v) {
                            _rows[i] = _rows[i].copyWith(teacherName: v);
                          }),
                          _field('Room', row.room, (v) {
                            _rows[i] = _rows[i].copyWith(room: v);
                          }),
                          _field('Type (lecture/lab/tutorial)', row.type, (v) {
                            _rows[i] = _rows[i].copyWith(type: v);
                          }),
                          _field('Notes', row.notes, (v) {
                            _rows[i] = _rows[i].copyWith(notes: v);
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _rows.add(
                    TimetableEntry(
                      id: const Uuid().v4(),
                      dayOfWeek: 'Monday',
                      startTime: '10:00 AM',
                      endTime: '11:00 AM',
                      subjectCode: '',
                      teacherName: '',
                    ),
                  );
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add class'),
            ),
            PrimaryButton(
              label: 'Save to my timetable',
              loading: _saving,
              onPressed: () async {
                setState(() => _saving = true);
                final messenger = ScaffoldMessenger.of(context);
                final controller = ref.read(appControllerProvider.notifier);
                if (widget.replaceAll) {
                  await controller.applyScannedTimetable(_rows);
                } else {
                  for (final row in _rows) {
                    await controller.saveTimetableEntry(row);
                  }
                }
                if (!context.mounted) return;
                Navigator.pop(context);
                messenger.showSnackBar(
                  SnackBar(content: Text(widget.replaceAll ? 'Timetable saved.' : 'Class saved.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
  }
}
