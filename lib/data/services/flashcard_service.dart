import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../local/local_store.dart';
import '../models/smart_flashcard.dart';
import '../remote/supabase_service.dart';
import 'spaced_repetition_service.dart';

class DeckSrStats {
  const DeckSrStats({
    required this.total,
    required this.due,
    required this.learning,
    required this.newCount,
    required this.mature,
  });

  final int total;
  final int due;
  final int learning;
  final int newCount;
  final int mature;
}

class OverallSrStats {
  const OverallSrStats({
    required this.totalCards,
    required this.dueToday,
    required this.learningToday,
    required this.newToday,
    required this.matureCount,
    required this.reviewedToday,
    required this.retentionRate,
  });

  final int totalCards;
  final int dueToday;
  final int learningToday;
  final int newToday;
  final int matureCount;
  final int reviewedToday;
  final double retentionRate;
}

class FlashcardService {
  FlashcardService({required this.store, SupabaseService? remote}) : remote = remote ?? SupabaseService.instance;

  final LocalStore store;
  final SupabaseService remote;
  final _uuid = const Uuid();
  final scheduler = const SpacedRepetitionService();

  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return result.any((e) => e != ConnectivityResult.none);
  }

  List<SmartFlashcardSet> sets() {
    final list = store.all(store.smartSets).map(SmartFlashcardSet.fromJson).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<SmartFlashcard> allCards() {
    return store.all(store.smartCards).map(SmartFlashcard.fromJson).toList();
  }

  List<SmartFlashcard> cardsFor(String setId) {
    final list = allCards().where((c) => c.setId == setId).toList();
    list.sort((a, b) => a.position.compareTo(b.position));
    return list;
  }

  Future<void> saveSet(SmartFlashcardSet set, List<SmartFlashcard> cards) async {
    await store.put(store.smartSets, set.id, set.toJson());
    for (final card in cards) {
      await store.put(store.smartCards, card.id, card.toJson());
    }
    await _tryRemote(() async {
      await remote.upsert('flashcard_sets', set.toJson());
      for (final card in cards) {
        await remote.upsert('flashcards', {
          ...card.toJson(),
          'user_id': remote.userId,
        });
      }
    }, kind: 'set', payload: set.toJson());
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
        keyTerms: generated[i].keyTerms,
        position: i,
        srState: FlashcardSrState.newCard,
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

  /// Rates a card with Anki / SM-2 spaced repetition calculation.
  Future<SmartFlashcard> applyRating(String cardId, FlashcardRating rating) async {
    final raw = store.all(store.smartCards).map(SmartFlashcard.fromJson);
    final card = raw.firstWhere((c) => c.id == cardId);
    
    final scheduled = scheduler.schedule(card: card, rating: rating);
    await updateCard(scheduled);
    return scheduled;
  }

  /// Legacy compatibility wrapper
  Future<void> updateSpacedRepetition(String cardId, String rating) async {
    FlashcardRating r;
    if (rating == 'easy') {
      r = FlashcardRating.easy;
    } else if (rating == 'difficult' || rating == 'hard') {
      r = FlashcardRating.hard;
    } else if (rating == 'again') {
      r = FlashcardRating.again;
    } else {
      r = FlashcardRating.good;
    }
    await applyRating(cardId, r);
  }

  List<SmartFlashcard> getDueCards([String? setId, int limit = 50]) {
    final cards = setId != null ? cardsFor(setId) : allCards();
    final due = cards.where((c) => c.isDue).toList();
    due.sort((a, b) => (a.nextReviewAt ?? DateTime.now()).compareTo(b.nextReviewAt ?? DateTime.now()));
    return due.take(limit).toList();
  }

  List<SmartFlashcard> getNewCards([String? setId, int limit = 10]) {
    final cards = setId != null ? cardsFor(setId) : allCards();
    final newOnes = cards.where((c) => c.isNew).toList();
    newOnes.sort((a, b) => a.position.compareTo(b.position));
    return newOnes.take(limit).toList();
  }

  List<SmartFlashcard> getLearningCards([String? setId]) {
    final cards = setId != null ? cardsFor(setId) : allCards();
    return cards.where((c) => c.isLearning).toList();
  }

  /// Builds a complete daily spaced repetition queue respecting limits:
  /// Learning cards (top priority) + Due Review cards (up to limit) + New cards (up to limit).
  List<SmartFlashcard> getSpacedRepetitionQueue({
    String? setId,
    int newLimit = SpacedRepetitionService.defaultDailyNewCards,
    int reviewLimit = SpacedRepetitionService.defaultDailyReviews,
  }) {
    final queue = <SmartFlashcard>[];
    final seen = <String>{};

    // 1. Learning / Lapse cards
    for (final c in getLearningCards(setId)) {
      if (seen.add(c.id)) queue.add(c);
    }

    // 2. Due Review cards
    for (final c in getDueCards(setId, reviewLimit)) {
      if (seen.add(c.id)) queue.add(c);
    }

    // 3. New cards
    for (final c in getNewCards(setId, newLimit)) {
      if (seen.add(c.id)) queue.add(c);
    }

    return queue;
  }

  int countDueCards(String setId) {
    return getDueCards(setId).length;
  }

  DeckSrStats getDeckStats(String setId) {
    final cards = cardsFor(setId);
    var due = 0;
    var learning = 0;
    var newCount = 0;
    var mature = 0;

    for (final c in cards) {
      if (c.isDue) due++;
      if (c.isLearning) learning++;
      if (c.isNew) newCount++;
      if (c.isMature) mature++;
    }

    return DeckSrStats(
      total: cards.length,
      due: due,
      learning: learning,
      newCount: newCount,
      mature: mature,
    );
  }

  OverallSrStats getOverallStats() {
    final cards = allCards();
    var due = 0;
    var learning = 0;
    var newCount = 0;
    var mature = 0;

    for (final c in cards) {
      if (c.isDue) due++;
      if (c.isLearning) learning++;
      if (c.isNew) newCount++;
      if (c.isMature) mature++;
    }

    // Calculate reviews done today from attempts
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final attempts = store.all(store.flashcardAttempts).map(FlashcardAttempt.fromJson).where((a) {
      return a.createdAt.isAfter(todayStart);
    }).toList();

    var goodOrEasy = 0;
    for (final a in attempts) {
      if (a.selfRating == 'good' || a.selfRating == 'easy' || a.selfRating == 'Easy') {
        goodOrEasy++;
      }
    }
    final retention = attempts.isNotEmpty ? (goodOrEasy / attempts.length) * 100 : 92.0;

    return OverallSrStats(
      totalCards: cards.length,
      dueToday: due,
      learningToday: learning,
      newToday: newCount,
      matureCount: mature,
      reviewedToday: attempts.length,
      retentionRate: retention,
    );
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
