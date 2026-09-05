import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../data/remote/supabase_service.dart';
import '../../providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  void _showAppConfigSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AppConfigSheet(),
    );
  }

  void _clearAiCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg1,
        title: const Text('Purge AI Cache?'),
        content: const Text('This will delete all cached flashcards, quizzes, and chat answers from the Supabase database.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              final client = SupabaseService.instance.client;
              if (client != null) {
                try {
                  await client.from('ai_cache').delete().neq('cache_key', '');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('AI Cache cleared successfully!'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to clear cache: $e'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              }
            },
            child: const Text('Purge Cache'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);
    final docsAsync = ref.watch(ragDocumentsProvider);
    final announcementsAsync = ref.watch(announcementsProvider);
    final aiUsageTodayAsync = ref.watch(aiUsageTodayProvider);
    final aiCacheStatsAsync = ref.watch(aiCacheStatsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('System Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.purpleBright),
              onPressed: () {
                ref.invalidate(studentsProvider);
                ref.invalidate(ragDocumentsProvider);
                ref.invalidate(announcementsProvider);
                ref.invalidate(aiUsageTodayProvider);
                ref.invalidate(aiCacheStatsProvider);
                AppHaptics.selection();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Stat Cards Grid
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Students',
                value: studentsAsync.when(
                  data: (data) => data.length.toString(),
                  loading: () => '...',
                  error: (_, _) => '0',
                ),
                icon: Icons.people,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'RAG Documents',
                value: docsAsync.when(
                  data: (data) => data.length.toString(),
                  loading: () => '...',
                  error: (_, _) => '0',
                ),
                icon: Icons.description,
                color: AppColors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Announcements',
                value: announcementsAsync.when(
                  data: (data) => data.length.toString(),
                  loading: () => '...',
                  error: (_, _) => '0',
                ),
                icon: Icons.campaign,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'AI Requests Today',
                value: aiUsageTodayAsync.when(
                  data: (count) => count.toString(),
                  loading: () => '...',
                  error: (_, _) => '0',
                ),
                icon: Icons.auto_awesome,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // AI Cache Performance Card
        GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt, color: AppColors.warning, size: 20),
                  SizedBox(width: 8),
                  Text('Free-Tier AI Protection & Cache', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              aiCacheStatsAsync.when(
                data: (stats) {
                  final totalCached = stats.values.fold<int>(0, (a, b) => a + b);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$totalCached responses cached across features (Saving free-tier tokens)', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: stats.entries.map((e) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bg0,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text('${e.key}: ${e.value} entries', style: const TextStyle(fontSize: 11, color: AppColors.purpleBright, fontWeight: FontWeight.w600)),
                        )).toList(),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (_, _) => const Text('Cache metrics unavailable', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Quick Admin Actions
        const Text('Administrative Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlowCard(
                onTap: () => _showAppConfigSheet(context, ref),
                padding: const EdgeInsets.all(16),
                child: const Column(
                  children: [
                    Icon(Icons.tune, color: AppColors.purpleBright, size: 28),
                    SizedBox(height: 8),
                    Text('App Limits & Config', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlowCard(
                onTap: () => _clearAiCache(context),
                padding: const EdgeInsets.all(16),
                child: const Column(
                  children: [
                    Icon(Icons.cleaning_services, color: AppColors.danger, size: 28),
                    SizedBox(height: 8),
                    Text('Purge AI Cache', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
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
      borderColor: color.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _AppConfigSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(appConfigProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      height: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System App Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Configure daily limits and model assignments directly in Supabase:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Expanded(
            child: configsAsync.when(
              data: (configs) {
                if (configs.isEmpty) {
                  return const Center(child: Text('No app_config entries found in database. Run migration 003.', style: TextStyle(color: AppColors.textMuted)));
                }
                return ListView.separated(
                  itemCount: configs.length,
                  separatorBuilder: (_, _) => const Divider(color: AppColors.borderSubtle),
                  itemBuilder: (ctx, idx) {
                    final item = configs[idx];
                    final key = item['key']?.toString() ?? '';
                    final val = item['value']?.toString() ?? '';
                    final desc = item['description']?.toString() ?? '';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: desc.isNotEmpty ? Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)) : null,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.bg0, borderRadius: BorderRadius.circular(6)),
                        child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purpleBright)),
                      ),
                      onTap: () {
                        final controller = TextEditingController(text: val);
                        showDialog(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            backgroundColor: AppColors.bg1,
                            title: Text('Edit $key'),
                            content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'New Value')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(dCtx);
                                  final client = SupabaseService.instance.client;
                                  if (client != null) {
                                    await client.from('app_config').update({'value': controller.text.trim()}).eq('key', key);
                                    ref.invalidate(appConfigProvider);
                                  }
                                },
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading config: $e', style: const TextStyle(color: AppColors.danger))),
            ),
          ),
        ],
      ),
    );
  }
}
