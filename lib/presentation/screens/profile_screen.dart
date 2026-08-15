import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_by_prajwal.dart';
import '../../core/widgets/atom_logo.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/models.dart';
import '../../data/remote/supabase_service.dart';
import '../providers/app_providers.dart';

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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${s.code}${s.teacher.isEmpty ? '' : ' · ${s.teacher}'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('About', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Chem Buddy 1.0.0', style: TextStyle(color: AppColors.textSecondary)),
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

  Future<void> _addSubject(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final code = TextEditingController();
    final teacher = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Custom subject', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: const InputDecoration(hintText: 'Name')),
              const SizedBox(height: 8),
              TextField(controller: code, decoration: const InputDecoration(hintText: 'Code')),
              const SizedBox(height: 8),
              TextField(controller: teacher, decoration: const InputDecoration(hintText: 'Teacher')),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Save',
                onPressed: () async {
                  if (name.text.trim().isEmpty || code.text.trim().isEmpty) return;
                  final id = ref.read(chemRepositoryProvider).newId();
                  await ref.read(appControllerProvider.notifier).saveSubject(
                        Subject(
                          id: id,
                          name: name.text.trim(),
                          code: code.text.trim(),
                          teacher: teacher.text.trim(),
                        ),
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
