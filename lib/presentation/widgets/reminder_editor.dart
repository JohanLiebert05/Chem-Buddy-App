import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/library_models.dart';
import '../providers/app_providers.dart';

class ReminderEditor {
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    var kind = 'study';
    var when = DateTime.now().add(const Duration(hours: 2));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add reminder', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 12),
                  TextField(controller: title, decoration: const InputDecoration(hintText: 'Title')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: kind,
                    items: const [
                      DropdownMenuItem(value: 'assignment', child: Text('Assignment')),
                      DropdownMenuItem(value: 'exam', child: Text('Exam')),
                      DropdownMenuItem(value: 'practical', child: Text('Practical')),
                      DropdownMenuItem(value: 'seminar', child: Text('Seminar')),
                      DropdownMenuItem(value: 'study', child: Text('Study')),
                    ],
                    onChanged: (v) => setModal(() => kind = v ?? kind),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('When: $when'),
                    trailing: const Icon(Icons.schedule),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: when,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                      );
                      if (date == null || !context.mounted) return;
                      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(when));
                      if (time == null) return;
                      setModal(() => when = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    },
                  ),
                  PrimaryButton(
                    label: 'Save reminder',
                    onPressed: () async {
                      if (title.text.trim().isEmpty) return;
                      await ref.read(appControllerProvider.notifier).saveReminder(
                            AppReminder(id: const Uuid().v4(), title: title.text.trim(), when: when, kind: kind),
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
