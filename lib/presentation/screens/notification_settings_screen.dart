import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/library_models.dart';
import '../../data/remote/notification_service.dart';
import '../providers/app_providers.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appControllerProvider).notificationPrefs;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          GlowCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable all notifications'),
                  value: prefs.enabled,
                  activeThumbColor: AppColors.purpleBright,
                  onChanged: (v) => _save(ref, prefs.copyWith(enabled: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Class reminders'),
                  value: prefs.classReminders,
                  onChanged: (v) => _save(ref, prefs.copyWith(classReminders: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Daily timetable'),
                  subtitle: const Text('Morning overview at 7:30 AM'),
                  value: prefs.dailyTimetable,
                  onChanged: (v) => _save(ref, prefs.copyWith(dailyTimetable: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Assignment reminders'),
                  value: prefs.assignmentReminders,
                  onChanged: (v) => _save(ref, prefs.copyWith(assignmentReminders: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Exam reminders'),
                  value: prefs.examReminders,
                  onChanged: (v) => _save(ref, prefs.copyWith(examReminders: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Default reminder time', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final m in [5, 10, 15, 30, 60])
                      ChoiceChip(
                        label: Text(m == 60 ? '1 hour' : '$m min'),
                        selected: prefs.defaultMinutesBefore == m,
                        onSelected: (_) => _save(ref, prefs.copyWith(defaultMinutesBefore: m)),
                      ),
                    ActionChip(
                      label: const Text('Custom'),
                      onPressed: () async {
                        final c = TextEditingController(text: '${prefs.defaultMinutesBefore}');
                        final next = await showDialog<int>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Minutes before class'),
                            content: TextField(controller: c, keyboardType: TextInputType.number),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, int.tryParse(c.text.trim())),
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                        if (next != null && next > 0) _save(ref, prefs.copyWith(defaultMinutesBefore: next));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Request notification permission',
            onPressed: () async {
              final status = await Permission.notification.request();
              await NotificationService.instance.requestPermission();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(status.isGranted ? 'Notifications allowed.' : 'Notifications were denied. Class reminders will stay off until you allow them in system settings.')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _save(WidgetRef ref, NotificationPrefs prefs) {
    ref.read(appControllerProvider.notifier).saveNotificationPrefs(prefs);
  }
}
