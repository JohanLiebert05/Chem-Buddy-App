import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glow_card.dart';
import '../../providers/admin_providers.dart';

class RagManagementScreen extends ConsumerWidget {
  const RagManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(ragDocumentsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: PrimaryButton(
            onPressed: () async {
              // File upload and extraction logic
            },
            label: 'Upload Document',
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(ragDocumentsProvider.future),
            child: docsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.purple)),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.danger))),
              data: (docs) {
                if (docs.isEmpty) return const Center(child: Text('No documents uploaded', style: TextStyle(color: AppColors.textSecondary)));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlowCard(
                        child: ListTile(
                          leading: const Icon(Icons.description, color: AppColors.purple),
                          title: Text(doc.title, style: const TextStyle(color: AppColors.textPrimary)),
                          subtitle: Text('Status: ${doc.status} | Chunks: ${doc.chunkCount}', style: const TextStyle(color: AppColors.textSecondary)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                            onPressed: () {
                              // Delete document logic
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
