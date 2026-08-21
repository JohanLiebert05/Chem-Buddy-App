import 'dart:convert';

import '../models/smart_flashcard.dart';
import '../remote/supabase_service.dart';
import 'pdf_text_utils.dart';

class GeminiFlashcardService {
  GeminiFlashcardService({SupabaseService? remote}) : _remote = remote ?? SupabaseService.instance;

  final SupabaseService _remote;

  Future<List<GeneratedCard>> generate({
    required String sourceText,
    required int count,
    String topic = 'Chemistry',
  }) async {
    if (!_remote.configured || _remote.userId == null) {
      throw StateError('Sign in with cloud sync (Supabase) to generate AI flashcards.');
    }
    final chunks = chunkNotes(sourceText);
    if (chunks.isEmpty) {
      throw StateError('Not enough readable text to generate flashcards.');
    }
    final perChunk = (count / chunks.length).ceil().clamp(5, count);
    final all = <GeneratedCard>[];
    final seen = <String>{};
    for (final chunk in chunks) {
      final remaining = count - all.length;
      if (remaining <= 0) break;
      final batch = await _invoke(chunk, remaining < perChunk ? remaining : perChunk, topic);
      for (final card in batch) {
        final key = card.question.toLowerCase();
        if (seen.add(key)) all.add(card);
      }
    }
    if (all.isEmpty) {
      throw StateError('Could not create valid chemistry flashcards from that document.');
    }
    return all.take(count).toList();
  }

  Future<List<GeneratedCard>> _invoke(String sourceText, int count, String topic) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final raw = await _remote.invokeFunction('generate-flashcards', {
          'sourceText': sourceText,
          'count': count,
          'topic': topic,
        });
        final cards = _parse(raw);
        if (cards.isNotEmpty) return cards;
        lastError = StateError('The AI response was not valid flashcard JSON.');
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? StateError('Could not generate flashcards.');
  }

  List<GeneratedCard> _parse(dynamic raw) {
    Map<String, dynamic>? map;
    if (raw is Map<String, dynamic>) {
      map = raw;
    } else if (raw is String) {
      map = jsonDecode(raw) as Map<String, dynamic>?;
    }
    if (map == null) return const [];
    if (map['error'] != null) {
      throw StateError(map['error'].toString());
    }
    final list = map['flashcards'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(
          (e) => GeneratedCard(
            question: '${e['question'] ?? ''}'.trim(),
            answer: '${e['answer'] ?? ''}'.trim(),
            topic: '${e['topic'] ?? 'Chemistry'}'.trim(),
          ),
        )
        .where((e) => e.question.length > 3 && e.answer.length > 1)
        .toList();
  }
}
