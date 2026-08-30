import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../core/utils/chemistry_text_formatter.dart';
import '../models/smart_flashcard.dart';
import '../remote/supabase_service.dart';
import 'pdf_text_utils.dart';

class GeminiFlashcardService {
  GeminiFlashcardService({SupabaseService? remote}) : _remote = remote ?? SupabaseService.instance;

  final SupabaseService _remote;

  /// Generates exam-quality chemistry flashcards with strict schema enforcement,
  /// exponential backoff retries, robust JSON cleanup, and academic fallbacks.
  Future<List<GeneratedCard>> generate({
    required String sourceText,
    required int count,
    String topic = 'Chemistry',
  }) async {
    // 1. Text payload validation & pre-checks
    final cleaned = cleanupExtractedText(sourceText);
    if (cleaned.length < 30) {
      throw StateError(
        'The selected PDF contains very little readable text or appears to be a scanned image without OCR. Please use a text-based PDF or paste notes.',
      );
    }

    final chunks = chunkNotes(cleaned, size: 10000, overlap: 300);
    if (chunks.isEmpty) {
      throw StateError('Could not process readable text chunks from the selected document.');
    }

    final targetCount = count.clamp(5, 30);
    final perChunk = (targetCount / chunks.length).ceil().clamp(5, targetCount);
    final allCards = <GeneratedCard>[];
    final seenQuestions = <String>{};

    for (final chunk in chunks) {
      final remaining = targetCount - allCards.length;
      if (remaining <= 0) break;
      final batchCount = remaining < perChunk ? remaining : perChunk;

      final batch = await _invokeWithRetry(
        sourceText: chunk,
        count: batchCount,
        topic: topic,
      );

      for (final card in batch) {
        final normQ = card.question.toLowerCase().trim();
        if (seenQuestions.add(normQ)) {
          allCards.add(card);
        }
      }
    }

    // 2. If AI call yielded cards, return them
    if (allCards.isNotEmpty) {
      return allCards.take(targetCount).toList();
    }

    // 3. Fallback: Local Chemistry Synthesis from document content
    debugPrint('[GeminiFlashcardService] Invoking Academic Chemistry Fallback Synthesis strictly from document text...');
    final fallback = _synthesizeLocalChemistryCards(cleaned, targetCount, topic);
    if (fallback.isNotEmpty) {
      return fallback;
    }

    throw StateError('Could not synthesize chemistry flashcards from the provided document.');
  }

  /// Dispatches the request with exponential backoff (up to 2 retries) and 45s timeout.
  Future<List<GeneratedCard>> _invokeWithRetry({
    required String sourceText,
    required int count,
    required String topic,
  }) async {
    Object? lastError;

    // Check if cloud backend is available
    if (_remote.configured) {
      final clipped = sourceText.length > 12000 ? sourceText.substring(0, 12000) : sourceText;

      // 1. Primary: dedicated generate-flashcards Edge Function
      for (var attempt = 0; attempt <= 2; attempt++) {
        if (attempt > 0) {
          debugPrint('[GeminiFlashcardService] Backing off retry attempt $attempt after network/rate hiccup...');
          await Future<void>.delayed(Duration(milliseconds: attempt * 1200));
        }

        try {
          final raw = await _remote.invokeFunction(
            'generate-flashcards',
            {
              'sourceText': clipped,
              'count': count,
              'topic': topic,
            },
            timeout: const Duration(seconds: 45),
          );

          final parsed = _parse(raw, topic);
          if (parsed.isNotEmpty) {
            debugPrint('[GeminiFlashcardService] Successfully parsed ${parsed.length} flashcards from AI response.');
            return parsed;
          }
          lastError = StateError('The AI response could not be parsed into flashcard JSON.');
        } catch (e) {
          lastError = e;
          debugPrint('[GeminiFlashcardService] Attempt $attempt failed: $e');
        }
      }

      // 2. Secondary Cloud Fallback: ask-chembuddy Edge Function
      try {
        debugPrint('[GeminiFlashcardService] Trying secondary cloud synthesis via ask-chembuddy...');
        final rawSecondary = await _remote.invokeFunction(
          'ask-chembuddy',
          {
            'question': '''Create exactly $count active-recall flashcards based EXCLUSIVELY and STRICTLY on the attached document "$topic".
Do NOT invent or include unrelated chemistry topics. Every card must test a concept, definition, procedure, parameter, or instrument from the provided document.
Return strictly valid JSON with this shape:
{
  "flashcards": [
    {
      "question": "Question directly about the document content",
      "answer": "Accurate answer from the document",
      "explanation": "Brief context",
      "topic": "$topic"
    }
  ]
}''',
            'document_text': clipped,
            'document_name': topic,
          },
          timeout: const Duration(seconds: 45),
        );

        if (rawSecondary is Map && rawSecondary['answer'] != null) {
          final parsedSec = _parse(rawSecondary['answer'].toString(), topic);
          if (parsedSec.isNotEmpty) {
            return parsedSec;
          }
        }
      } catch (secErr) {
        debugPrint('[GeminiFlashcardService] Secondary cloud synthesis failed: $secErr');
      }
    }

    // If cloud failed or offline, synthesize high-yield cards strictly from the text
    debugPrint('[GeminiFlashcardService] Cloud generation unavailable ($lastError). Using local document extraction.');
    return _synthesizeLocalChemistryCards(sourceText, count, topic);
  }

  /// Parses JSON responses, handles markdown fences, schemas, and alternative key names.
  List<GeneratedCard> _parse(dynamic raw, String defaultTopic) {
    if (raw == null) return const [];
    Map<String, dynamic>? data;

    if (raw is Map<String, dynamic>) {
      data = raw;
    } else if (raw is String) {
      var text = raw.trim();

      // Clean/strip markdown code fence blocks (```json ... ``` or ``` ...)
      final fenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```', caseSensitive: false).firstMatch(text);
      if (fenceMatch != null && fenceMatch.group(1) != null) {
        text = fenceMatch.group(1)!.trim();
      }

      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is List) {
          data = {'flashcards': decoded};
        }
      } catch (e) {
        // Robust substring JSON recovery
        final startIdx = text.indexOf('{');
        final endIdx = text.lastIndexOf('}');
        if (startIdx >= 0 && endIdx > startIdx) {
          try {
            final sub = text.substring(startIdx, endIdx + 1);
            final decoded = jsonDecode(sub);
            if (decoded is Map<String, dynamic>) data = decoded;
          } catch (_) {}
        }

        if (data == null) {
          final startArr = text.indexOf('[');
          final endArr = text.lastIndexOf(']');
          if (startArr >= 0 && endArr > startArr) {
            try {
              final subArr = text.substring(startArr, endArr + 1);
              final decodedArr = jsonDecode(subArr);
              if (decodedArr is List) data = {'flashcards': decodedArr};
            } catch (_) {}
          }
        }
      }
    }

    if (data == null) return const [];
    if (data['error'] != null && data['flashcards'] == null) {
      debugPrint('[GeminiFlashcardService] API reported error: ${data['error']}');
      return const [];
    }

    final rawList = data['flashcards'];
    if (rawList is! List) return const [];

    return rawList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map((e) {
          final q = (e['question'] ?? e['front'] ?? e['prompt'] ?? '').toString().trim();
          final a = (e['answer'] ?? e['back'] ?? e['response'] ?? '').toString().trim();
          final expl = (e['explanation'] ?? '').toString().trim();
          final top = (e['topic'] ?? defaultTopic).toString().trim();

          final finalAnswer = expl.isNotEmpty && !a.contains(expl) ? '$a\n\n*Key Note: $expl*' : a;

          return GeneratedCard(
            question: ChemistryTextFormatter.format(q),
            answer: ChemistryTextFormatter.format(finalAnswer),
            topic: top.isEmpty ? defaultTopic : top,
          );
        })
        .where((e) => e.question.length > 3 && e.answer.length > 1)
        .toList();
  }

  /// Synthesizes high-yield academic chemistry flashcards strictly and solely from the provided document text.
  /// NEVER injects hardcoded external questions (e.g. SN1/SN2 or Laporte) that are not in the document.
  List<GeneratedCard> _synthesizeLocalChemistryCards(String sourceText, int count, String topic) {
    final cards = <GeneratedCard>[];
    final seenQuestions = <String>{};

    void addCard(String q, String a) {
      final cleanQ = ChemistryTextFormatter.format(q.trim());
      final cleanA = ChemistryTextFormatter.format(a.trim());
      if (cleanQ.length > 5 && cleanA.length > 2 && seenQuestions.add(cleanQ.toLowerCase())) {
        cards.add(GeneratedCard(question: cleanQ, answer: cleanA, topic: topic));
      }
    }

    final rawLines = sourceText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // 1. Key-Value pairs & Parameter specs (e.g. "Column: C18", "Flow Rate: 1.0 mL/min", "Wavelength: 254 nm")
    for (final line in rawLines) {
      if (cards.length >= count) break;
      if (line.contains(':') && !line.startsWith('http')) {
        final colonIdx = line.indexOf(':');
        final key = line.substring(0, colonIdx).replaceAll(RegExp(r'^[#\-*•\d\.\s]+'), '').trim();
        final val = line.substring(colonIdx + 1).trim();
        if (key.length >= 2 && key.length <= 60 && val.length >= 2 && val.length <= 400) {
          addCard('What is the specification or detail for "$key" in this document?', val);
        }
      }
    }

    // 2. Headings with following descriptions
    for (var i = 0; i < rawLines.length - 1; i++) {
      if (cards.length >= count) break;
      final line = rawLines[i];
      if (line.startsWith('#') || (line.length <= 50 && !line.endsWith('.') && line.length > 3)) {
        final heading = line.replaceAll(RegExp(r'^[#\-*•\d\.\s]+'), '').trim();
        final nextLine = rawLines[i + 1].trim();
        if (heading.length >= 3 && nextLine.length >= 15 && !nextLine.startsWith('#')) {
          addCard('Explain the concept of "$heading" as described in this material.', nextLine);
        }
      }
    }

    // 3. Definition & explanatory sentences in paragraphs
    final sentences = sourceText.split(RegExp(r'(?<=[.!?])\s+|\n+')).map((s) => s.trim()).where((s) => s.length >= 15 && s.length <= 400).toList();

    for (final s in sentences) {
      if (cards.length >= count) break;
      final lower = s.toLowerCase();

      // Definitions: "X is defined as Y", "X refers to Y", "X is a Y", "X means Y"
      if (lower.contains(' is defined as ') || lower.contains(' refers to ') || lower.contains(' is used for ') || lower.contains(' is used to ') || lower.contains(' is called ') || lower.contains(' consists of ')) {
        final match = RegExp(r'^(.*?)\s+(?:is defined as|refers to|is used for|is used to|is called|consists of)\s+(.*)$', caseSensitive: false).firstMatch(s);
        if (match != null) {
          final subject = match.group(1)?.replaceAll(RegExp(r'^[#\-*•\d\.\s]+'), '').trim() ?? '';
          if (subject.length >= 2 && subject.length <= 60) {
            addCard('What is the function or definition of $subject in this material?', s);
            continue;
          }
        }
      }

      // Principle & mechanism sentences
      if (lower.contains('because') || lower.contains('due to') || lower.contains('principle') || lower.contains('method') || lower.contains('mechanism') || lower.contains('reaction') || lower.contains('procedure') || lower.contains('step') || lower.contains('parameter') || lower.contains('result') || lower.contains('requires') || lower.contains('retention') || lower.contains('calibration')) {
        final preview = s.length > 55 ? '${s.substring(0, 55)}...' : s;
        addCard('Explain the following point from the document: "$preview"', s);
      }
    }

    // 4. Fill with remaining sentence chunks if needed — STILL STRICTLY FROM THE TEXT
    if (cards.length < count) {
      for (final s in sentences) {
        if (cards.length >= count) break;
        final words = s.split(RegExp(r'\s+'));
        if (words.length >= 4) {
          final firstWords = words.take(5).join(' ');
          addCard('What does the document state regarding "$firstWords..."?', s);
        }
      }
    }

    return cards.take(count).toList();
  }
}
