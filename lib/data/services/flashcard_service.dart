import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../local/local_store.dart';
import '../models/smart_flashcard.dart';
import '../remote/supabase_service.dart';

class FlashcardService {
  FlashcardService({required this.store, SupabaseService? remote}) : remote = remote ?? SupabaseService.instance;

  final LocalStore store;
  final SupabaseService remote;
  final _uuid = const Uuid();

  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return result.any((e) => e != ConnectivityResult.none);
  }

  List<SmartFlashcardSet> sets() {
    final list = store.all(store.smartSets).map(SmartFlashcardSet.fromJson).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<SmartFlashcard> cardsFor(String setId) {
    final list = store
        .all(store.smartCards)
        .map(SmartFlashcard.fromJson)
        .where((c) => c.setId == setId)
        .toList();
    list.sort((a, b) => a.position.compareTo(b.position));
    return list;
  }

  Future<SmartFlashcardSet> saveGeneratedSet({
    required String title,
    required String sourceFileName,
    required String topic,
    required List<GeneratedCard> generated,
  }) async {
    final set = SmartFlashcardSet(
      id: _uuid.v4(),
      userId: remote.userId,
      title: title,
      sourceFileName: sourceFileName,
      topic: topic,
      cardCount: generated.length,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await store.put(store.smartSets, set.id, set.toJson());
    for (var i = 0; i < generated.length; i++) {
      final card = SmartFlashcard(
        id: _uuid.v4(),
        setId: set.id,
        question: generated[i].question,
        answer: generated[i].answer,
        topic: generated[i].topic,
        position: i,
      );
      await store.put(store.smartCards, card.id, card.toJson());
    }
    await _tryRemote(() async {
      await remote.upsert('flashcard_sets', set.toJson());
      for (final card in cardsFor(set.id)) {
        await remote.upsert('flashcards', {
          ...card.toJson(),
          'user_id': remote.userId,
        });
      }
    }, kind: 'set', payload: set.toJson());
    return set;
  }

  Future<void> updateCard(SmartFlashcard card) async {
    await store.put(store.smartCards, card.id, card.toJson());
    await _tryRemote(() async {
      await remote.upsert('flashcards', {...card.toJson(), 'user_id': remote.userId});
    }, kind: 'card', payload: card.toJson());
  }

  Future<void> saveAttempt(FlashcardAttempt attempt) async {
    await store.put(store.flashcardAttempts, attempt.id, attempt.toJson());
    await _tryRemote(() async {
      await remote.upsert('flashcard_attempts', attempt.toJson());
    }, kind: 'attempt', payload: attempt.toJson());
  }

  Future<void> saveSession(StudySession session) async {
    await store.put(store.studySessions, session.id, session.toJson());
    await _tryRemote(() async {
      await remote.upsert('study_sessions', session.toJson());
    }, kind: 'session', payload: session.toJson());
  }

  StudySession? latestSession(String setId) {
    final list = store.all(store.studySessions).map(StudySession.fromJson).where((s) => s.flashcardSetId == setId).toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list.first;
  }

  Future<void> syncPending() async {
    if (!await isOnline || !remote.configured || remote.userId == null) return;
    final pending = store.all(store.pendingSync);
    for (final item in pending) {
      final id = item['id'] as String?;
      final table = item['table'] as String?;
      final payload = item['payload'];
      if (id == null || table == null || payload is! Map) continue;
      try {
        await remote.upsert(table, Map<String, dynamic>.from(payload));
        await store.delete(store.pendingSync, id);
      } catch (_) {}
    }
  }

  Future<void> _tryRemote(Future<void> Function() action, {required String kind, required Map<String, dynamic> payload}) async {
    try {
      if (await isOnline && remote.configured && remote.userId != null) {
        await action();
        return;
      }
    } catch (_) {}
    final id = _uuid.v4();
    await store.put(store.pendingSync, id, {
      'id': id,
      'kind': kind,
      'table': switch (kind) {
        'set' => 'flashcard_sets',
        'card' => 'flashcards',
        'attempt' => 'flashcard_attempts',
        _ => 'study_sessions',
      },
      'payload': {
        ...payload,
        'user_id': remote.userId,
      },
    });
  }
}
