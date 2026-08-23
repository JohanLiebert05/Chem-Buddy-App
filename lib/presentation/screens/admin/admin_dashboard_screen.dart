import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glow_card.dart';
import '../../providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);
    final docsAsync = ref.watch(ragDocumentsProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Students',
                value: studentsAsync.when(
                  data: (data) => data.length.toString(),
                  loading: () => '...',
                  error: (e, st) => '!',
                ),
                icon: Icons.people,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Documents',
                value: docsAsync.when(
                  data: (data) => data.length.toString(),
                  loading: () => '...',
                  error: (e, st) => '!',
                ),
                icon: Icons.description,
                color: AppColors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: 'Announcements',
          value: announcementsAsync.when(
            data: (data) => data.length.toString(),
            loading: () => '...',
            error: (e, st) => '!',
          ),
          icon: Icons.campaign,
          color: AppColors.success,
        ),
        const SizedBox(height: 32),
        const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GlowCard(
                padding: const EdgeInsets.all(16),
                child: const Column(
                  children: [
                    Icon(Icons.add_alert, color: AppColors.purple, size: 32),
                    SizedBox(height: 8),
                    Text('New Announcement', style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlowCard(
                padding: const EdgeInsets.all(16),
                child: const Column(
                  children: [
                    Icon(Icons.upload_file, color: AppColors.blue, size: 32),
                    SizedBox(height: 8),
                    Text('Upload Document', style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      borderColor: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(title, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
