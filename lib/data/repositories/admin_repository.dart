import '../local/local_store.dart';
import '../remote/supabase_service.dart';
import '../models/admin_models.dart';

class AdminRepository {
  final LocalStore? _store;
  final SupabaseService _remote;

  AdminRepository({
    LocalStore? store,
    required SupabaseService remote,
  })  : _store = store,
        _remote = remote;

  LocalStore? get store => _store;

  Future<List<Announcement>> announcements({bool studentView = false}) async {
    final client = _remote.client;
    if (client == null) return [];

    final response = await (studentView
        ? client.from('announcements').select().eq('published', true).order('created_at', ascending: false)
        : client.from('announcements').select().order('created_at', ascending: false));

    return (response as List).map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> upsertAnnouncement(Announcement a) async {
    await _remote.upsert('announcements', a.toJson());
  }

  Future<void> deleteAnnouncement(String id) async {
    await _remote.remove('announcements', id);
  }

  Future<List<Map<String, dynamic>>> listStudents() async {
    final client = _remote.client;
    if (client == null) return [];

    final response = await client.from('profiles').select().eq('role', 'student').order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateStudentRole(String userId, String role) async {
    final client = _remote.client;
    if (client == null) return;

    await client.from('profiles').update({'role': role}).eq('id', userId);
  }
}
