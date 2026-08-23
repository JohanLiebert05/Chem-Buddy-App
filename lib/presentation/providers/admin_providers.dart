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
