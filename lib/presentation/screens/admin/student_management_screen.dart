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
        loading: () =>  Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
        error: (err, stack) => Center(child: Text('Error: $err', style:  TextStyle(color: AppColors.adaptive(context, AppColors.danger)))),
        data: (students) {
          if (students.isEmpty) {
            return  Center(child: Text('No students found', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
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
                    leading:  CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                    title: Text(student['full_name'] ?? 'Unknown', style:  TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    subtitle: Text(student['register_number'] ?? '', style:  TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    trailing:  Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
