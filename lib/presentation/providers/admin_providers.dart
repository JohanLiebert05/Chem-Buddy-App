import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/local_store.dart';
import '../../data/remote/supabase_service.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/services/document_ingestion_service.dart';
import '../../data/services/rag_service.dart';
import '../../data/models/admin_models.dart';

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(
    store: ref.watch(localStoreProvider),
    remote: SupabaseService.instance,
  );
});

final documentIngestionServiceProvider = Provider<DocumentIngestionService>((ref) {
  return DocumentIngestionService(remote: SupabaseService.instance);
});

final ragServiceProvider = Provider<RagService>((ref) {
  return RagService(remote: SupabaseService.instance);
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  return ref.read(adminRepositoryProvider).announcements();
});

final studentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).listStudents();
});

final ragDocumentsProvider = FutureProvider<List<RagDocument>>((ref) async {
  return ref.read(documentIngestionServiceProvider).listDocuments();
});

final aiUsageTodayProvider = FutureProvider<int>((ref) async {
  final client = SupabaseService.instance.client;
  if (client == null || !SupabaseService.instance.configured) return 0;
  try {
    final today = DateTime.now().toIso8601String().split('T').first;
    final rows = await client.from('ai_usage').select('request_count').eq('date', today);
    return List<Map<String, dynamic>>.from(rows)
        .fold<int>(0, (sum, r) => sum + (r['request_count'] as int? ?? 0));
  } catch (_) {
    return 0;
  }
});

final aiCacheStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final client = SupabaseService.instance.client;
  if (client == null || !SupabaseService.instance.configured) return {};
  try {
    final rows = await client.from('ai_cache').select('feature, hit_count');
    final stats = <String, int>{};
    for (final row in List<Map<String, dynamic>>.from(rows)) {
      final feature = row['feature'] as String? ?? 'general';
      stats[feature] = (stats[feature] ?? 0) + 1;
    }
    return stats;
  } catch (_) {
    return {};
  }
});

final appConfigProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = SupabaseService.instance.client;
  if (client == null || !SupabaseService.instance.configured) return [];
  try {
    final rows = await client.from('app_config').select().order('key');
    return List<Map<String, dynamic>>.from(rows);
  } catch (_) {
    return [];
  }
});
