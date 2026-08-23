import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glow_card.dart';
import '../../providers/admin_providers.dart';

class ContentManagementScreen extends ConsumerStatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  ConsumerState<ContentManagementScreen> createState() => _ContentManagementScreenState();
}

class _ContentManagementScreenState extends ConsumerState<ContentManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.purple,
          labelColor: AppColors.purple,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Announcements'),
            Tab(text: 'Other Content'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AnnouncementsTab(),
              const Center(child: Text('Coming Soon', style: TextStyle(color: AppColors.textSecondary))),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnnouncementsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: PrimaryButton(
            onPressed: () {
              // Add announcement logic
            },
            label: 'Add Announcement',
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(announcementsProvider.future),
            child: announcementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.purple)),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.danger))),
              data: (items) {
                if (items.isEmpty) return const Center(child: Text('No announcements', style: TextStyle(color: AppColors.textSecondary)));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlowCard(
                        child: ListTile(
                          title: Text(item.title, style: const TextStyle(color: AppColors.textPrimary)),
                          subtitle: Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
                          trailing: Switch(
                            value: item.published,
                            activeThumbColor: AppColors.purple,
                            onChanged: (val) {
                              // Toggle publish logic
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
