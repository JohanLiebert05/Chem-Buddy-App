import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_by_prajwal.dart';
import '../../core/widgets/atom_logo.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/models.dart';
import '../../data/remote/supabase_service.dart';
import '../providers/app_providers.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final p = state.profile;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        const Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        GlowCard(
          child: Column(
            children: [
              const AtomLogo(size: 72),
              const SizedBox(height: 8),
              Text(p.fullName.isEmpty ? 'MSc Chemistry' : p.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(p.email, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text('${p.university} · Semester ${p.semester}', style: const TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
        const SectionTitle('Subjects'),
        ...state.subjects.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              onTap: () => _addSubject(context, ref, existing: s),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(s.colorHex), shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${s.code}${s.teacher.isEmpty ? '' : ' · ${s.teacher}'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.read(appControllerProvider.notifier).deleteSubject(s.id),
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  ),
                ],
              ),
            ),
          ),
        ),
        PrimaryButton(
          label: 'Add custom subject',
          onPressed: () => _addSubject(context, ref),
        ),
        const SectionTitle('Settings'),
        GlowCard(
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const NotificationSettingsScreen())),
          child: const Row(
            children: [
              Icon(Icons.notifications_outlined, color: AppColors.purpleBright),
              SizedBox(width: 12),
              Expanded(child: Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700))),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('About', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Chem Buddy 2.0 by Prajwal A Kambar', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text(
                SupabaseService.instance.configured
                    ? 'Cloud sync is on.'
                    : 'Offline Hive mode. Add keys in .env to enable Supabase.',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlowCard(
          child: Row(
            children: [
              Icon(SupabaseService.instance.configured ? Icons.cloud_done : Icons.cloud_off, color: AppColors.purpleBright),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  SupabaseService.instance.configured
                      ? 'Supabase connected — data syncs when you are online.'
                      : 'Preferences stay on this device until you connect Supabase.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => ref.read(appControllerProvider.notifier).logout(),
          child: const Text('Log out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 28),
        const Center(child: AppByPrajwal(large: true)),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _addSubject(BuildContext context, WidgetRef ref, {Subject? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final code = TextEditingController(text: existing?.code ?? '');
    final teacher = TextEditingController(text: existing?.teacher ?? '');
    var color = existing?.colorHex ?? AppColors.subjectPalette.first.toARGB32();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(existing == null ? 'Custom subject' : 'Edit subject', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 12),
                  TextField(controller: name, decoration: const InputDecoration(hintText: 'Name')),
                  const SizedBox(height: 8),
                  TextField(controller: code, decoration: const InputDecoration(hintText: 'Code')),
                  const SizedBox(height: 8),
                  TextField(controller: teacher, decoration: const InputDecoration(hintText: 'Teacher')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in AppColors.subjectPalette)
                        GestureDetector(
                          onTap: () => setModal(() => color = c.toARGB32()),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: c,
                            child: color == c.toARGB32() ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Save',
                    onPressed: () async {
                      if (name.text.trim().isEmpty || code.text.trim().isEmpty) return;
                      final id = existing?.id ?? ref.read(chemRepositoryProvider).newId();
                      await ref.read(appControllerProvider.notifier).saveSubject(
                            Subject(
                              id: id,
                              name: name.text.trim(),
                              code: code.text.trim(),
                              teacher: teacher.text.trim(),
                              colorHex: color,
                              isElective: existing?.isElective ?? false,
                            ),
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
