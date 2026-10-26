import 'package:uuid/uuid.dart';

import '../local/local_store.dart';
import '../remote/supabase_service.dart';

/// Persist before sending; remove only the exact acknowledged revision.
class PendingSyncService {
  PendingSyncService(this.store, this.remote);
  final LocalStore store;
  final SupabaseService remote;
  static final Set<String?> _flushing = {};

  Future<void> upsert(String table, Map<String, dynamic> payload) async {
    final uid = remote.userId;
    final id = payload['id'] as String?;
    if (id == null) {
      throw ArgumentError('Sync records require an id.');
    }
    if (uid == null) {
      return;
    }
    final row = <String, dynamic>{...payload};
    if (table == 'profiles') {
      row['id'] = uid;
    } else {
      row['user_id'] = uid;
    }
    await store.pendingSync.put('$table:$id', {
      'table': table,
      'operation': 'upsert',
      'user_id': uid,
      'payload': row,
      'revision': const Uuid().v4(),
    });
    await flush();
  }

  Future<void> remove(String table, String id) async {
    if (remote.userId == null) {
      return;
    }
    await store.pendingSync.put('$table:$id', {
      'table': table,
      'operation': 'delete',
      'user_id': remote.userId,
      'payload': {'id': id},
      'revision': const Uuid().v4(),
    });
    await flush();
  }

  Future<void> flush() async {
    final uid = remote.userId;
    final account = HiveBoxes.activeAccount;
    if (!remote.configured || uid == null || !_flushing.add(account)) {
      return;
    }
    final box = store.pendingSync;
    try {
      for (final key in box.keys.toList()) {
        if (remote.userId != uid || HiveBoxes.activeAccount != account) {
          break;
        }
        final raw = box.get(key);
        if (raw is! Map || raw['payload'] is! Map) {
          continue;
        }
        final payload = Map<String, dynamic>.from(raw['payload'] as Map);
        // Legacy jobs are only retried when their recorded owner matches.
        final owner = raw['user_id'] ?? payload['user_id'];
        if (owner != uid) {
          continue;
        }
        final table = raw['table'] as String?;
        if (table == null) {
          continue;
        }
        try {
          if (raw['operation'] == 'delete') {
            await remote.remove(table, payload['id'] as String);
          } else {
            await remote.upsert(table, payload);
          }
          final current = box.get(key);
          if (current is Map && current['revision'] == raw['revision']) {
            await box.delete(key);
          }
        } catch (_) {
          // Preserve ordering (e.g. parent set before cards) and retry later.
          break;
        }
      }
    } finally {
      _flushing.remove(account);
    }
  }
}
