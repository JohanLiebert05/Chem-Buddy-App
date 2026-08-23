import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glow_card.dart';
import '../../providers/admin_providers.dart';

class StudentManagementScreen extends ConsumerWidget {
  const StudentManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(studentsProvider.future),
      child: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.purple)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.danger))),
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('No students found', style: TextStyle(color: AppColors.textSecondary)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlowCard(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.purple,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(student['full_name'] ?? 'Unknown', style: const TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text(student['register_number'] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.more_vert, color: AppColors.textMuted),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
