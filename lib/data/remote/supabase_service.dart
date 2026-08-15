import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  bool configured = false;

  Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env.example', isOptional: true);
      await dotenv.load(fileName: '.env', isOptional: true);
    } catch (_) {}

    const dartUrl = String.fromEnvironment('SUPABASE_URL');
    const dartKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    final url = dartUrl.isNotEmpty ? dartUrl : (dotenv.env['SUPABASE_URL'] ?? '');
    final key = dartKey.isNotEmpty ? dartKey : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

    if (url.isEmpty ||
        key.isEmpty ||
        url.contains('YOUR_PROJECT') ||
        key.contains('YOUR_ANON')) {
      configured = false;
      return;
    }

    await Supabase.initialize(url: url, publishableKey: key);
    configured = true;
  }

  SupabaseClient? get client => configured ? Supabase.instance.client : null;

  String? get userId => client?.auth.currentUser?.id;

  Future<AuthResponse?> signUp(String email, String password) async {
    return client?.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse?> signIn(String email, String password) async {
    return client?.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client?.auth.signOut();
  }

  Future<void> upsert(String table, Map<String, dynamic> row) async {
    final c = client;
    if (c == null) return;
    try {
      await c.from(table).upsert(row);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> fetchOwn(String table) async {
    final c = client;
    final uid = userId;
    if (c == null || uid == null) return [];
    try {
      final data = await c.from(table).select().eq('user_id', uid);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  Future<void> remove(String table, String id) async {
    final c = client;
    if (c == null) return;
    try {
      await c.from(table).delete().eq('id', id);
    } catch (_) {}
  }
}
