import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  static const defaultUrl = 'https://tqhrvvcxrrkppdfrbxnz.supabase.co';
  static const defaultAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxaHJ2dmN4cnJrcHBkZnJieG56Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY4MTQxOTksImV4cCI6MjEwMjM5MDE5OX0.ulLIKMS13JTOSgNA5V4btIjLZy98aB5aFWoQ4Qx4U4s';

  bool configured = false;

  Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env.example', isOptional: true);
      await dotenv.load(fileName: '.env', isOptional: true);
    } catch (_) {}

    const dartUrl = String.fromEnvironment('SUPABASE_URL');
    const dartKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    
    var url = dartUrl.isNotEmpty ? dartUrl : (dotenv.env['SUPABASE_URL'] ?? '');
    var key = dartKey.isNotEmpty ? dartKey : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

    if (url.isEmpty || url.contains('YOUR_PROJECT')) {
      url = defaultUrl;
    }
    if (key.isEmpty || key.contains('YOUR_ANON')) {
      key = defaultAnonKey;
    }

    try {
      await Supabase.initialize(url: url, publishableKey: key);
      configured = true;
    } catch (_) {
      configured = false;
    }
  }

  Future<bool> checkConnection() async {
    final c = client;
    if (c == null) return false;
    try {
      final res = await c.from('profiles').select('id').limit(1);
      return res.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient? get client => configured ? Supabase.instance.client : null;

  String? get userId => client?.auth.currentUser?.id;

  Future<AuthResponse?> signUp(String email, String password) async {
    return client?.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse?> signIn(String email, String password) async {
    return client?.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse?> signUpWithRegisterNumber(String fullName, String registerNumber, String password) async {
    final email = '${registerNumber.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}@chembuddy.local';
    final res = await client?.auth.signUp(email: email, password: password, data: {'full_name': fullName, 'register_number': registerNumber});
    final user = res?.user;
    if (user != null) {
      await upsert('profiles', {'id': user.id, 'register_number': registerNumber, 'full_name': fullName});
    }
    return res;
  }

  Future<AuthResponse?> signInWithRegisterNumber(String registerNumber, String password) async {
    final email = '${registerNumber.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}@chembuddy.local';
    return client?.auth.signInWithPassword(email: email, password: password);
  }

  Future<bool> registerNumberExists(String registerNumber) async {
    final c = client;
    if (c == null) return false;
    try {
      final res = await c.from('profiles').select('id').eq('register_number', registerNumber).maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    final c = client;
    final uid = userId;
    if (c == null || uid == null) return null;
    try {
      return await c.from('profiles').select().eq('id', uid).maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final c = client;
    final uid = userId;
    if (c == null || uid == null) return;
    try {
      await c.from('profiles').update(data).eq('id', uid);
    } catch (_) {}
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

  /// Calls a Supabase Edge Function with automatic exponential backoff retry for 429 rate limits,
  /// jitter, and network resilience.
  Future<dynamic> invokeFunction(
    String name,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 45),
    int maxRetries = 3,
  }) async {
    final c = client;
    if (c == null) {
      throw StateError('Unable to connect to cloud services. Please check your internet connection and try again.');
    }

    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final response = await c.functions.invoke(name, body: body).timeout(
          timeout,
          onTimeout: () => throw StateError('Request timed out while waiting for $name (${timeout.inSeconds}s). Please check your network.'),
        );
        if (response.status >= 400) {
          if (response.status == 429 && attempt <= maxRetries) {
            // Exponential backoff + jitter (e.g., attempt 1: ~1000-1350ms, attempt 2: ~2000-2350ms, attempt 3: ~4000-4350ms)
            final jitterMs = math.Random().nextInt(350);
            final delayMs = (1000 * math.pow(2, attempt - 1)).toInt() + jitterMs;
            await Future<void>.delayed(Duration(milliseconds: delayMs));
            continue;
          }
          final data = response.data;
          if (data is Map && data['error'] != null) {
            final detail = data['detail'] != null ? ' (${data['detail']})' : '';
            throw StateError('${data['error']}$detail');
          }
          throw StateError('The $name service encountered an issue (HTTP ${response.status}). Please try again.');
        }
        return response.data;
      } on FunctionException catch (fe) {
        if (fe.status == 429 && attempt <= maxRetries) {
          final jitterMs = math.Random().nextInt(350);
          final delayMs = (1000 * math.pow(2, attempt - 1)).toInt() + jitterMs;
          await Future<void>.delayed(Duration(milliseconds: delayMs));
          continue;
        }
        if (fe.details is Map && fe.details['error'] != null) {
          throw StateError(fe.details['error'].toString());
        }
        if (fe.status == 401) {
          throw StateError('Sign in required to use cloud AI features.');
        }
        if (fe.status == 429) {
          throw StateError('AI service rate limit reached. Please wait a moment and retry.');
        }
        throw StateError('Cloud service temporarily unavailable (${fe.status}).');
      } catch (e) {
        if (attempt <= maxRetries &&
            (e.toString().contains('429') ||
             e.toString().contains('rate limit') ||
             e.toString().contains('RESOURCE_EXHAUSTED'))) {
          final jitterMs = math.Random().nextInt(350);
          final delayMs = (1000 * math.pow(2, attempt - 1)).toInt() + jitterMs;
          await Future<void>.delayed(Duration(milliseconds: delayMs));
          continue;
        }
        if (e is StateError) rethrow;
        throw StateError('Network connection issue ($e). Please check your internet and try again.');
      }
    }
  }
}
