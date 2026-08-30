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
            'question': '''Act as an expert MSc Chemistry academic tutor.
Create exactly $count rigorous, high-yield active-recall flashcards based EXCLUSIVELY and STRICTLY on the attached document "$topic".

RULES:
1. QUESTION FORMAT: Formulate standalone, high-yield conceptual interrogative questions (e.g., reaction mechanisms, stereochemistry, regioselectivity, rate laws, analytical parameters, instrumentation, and thermodynamic principles).
2. FORBIDDEN: NEVER quote verbatim snippets with trailing ellipses (e.g., NEVER write 'Explain the following point: "..."' or 'What does the document state regarding "..."'). Every question must be a complete, standalone question.
3. ANSWER FORMAT: Provide accurate, comprehensive explanations using clean chemical equations and inline LaTeX notation where applicable.
4. KEY TERMS: For each card, provide 3 to 5 mandatory chemical concepts or keywords required for a complete answer.

Return strictly valid JSON with this shape:
{
  "flashcards": [
    {
      "question": "Standalone conceptual question?",
      "answer": "Accurate explanation with inline LaTeX notation",
      "key_terms": ["Keyword 1", "Keyword 2", "Keyword 3", "Keyword 4"],
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

  /// Parses JSON responses, handles markdown fences, schemas, and extracts key_terms.
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

          final rawTerms = e['key_terms'] ?? e['keyTerms'] ?? e['keywords'];
          var terms = <String>[];
          if (rawTerms is List) {
            terms = rawTerms.map((t) => t.toString().trim()).where((t) => t.isNotEmpty).toList();
          }

          // If no key terms provided by AI, extract 3-5 salient chemistry keywords from question/answer
          if (terms.isEmpty) {
            terms = _extractKeywordsFromText('$q $a', top);
          }

          final finalAnswer = expl.isNotEmpty && !a.contains(expl) ? '$a\n\n*Key Note: $expl*' : a;

          return GeneratedCard(
            question: ChemistryTextFormatter.format(q),
            answer: ChemistryTextFormatter.format(finalAnswer),
            topic: top.isEmpty ? defaultTopic : top,
            keyTerms: terms.take(5).toList(),
          );
        })
        .where((e) => e.question.length > 5 && e.answer.length > 1)
        .toList();
  }

  /// Synthesizes high-yield academic MSc Chemistry flashcards strictly and solely from the provided document text.
  /// Generates standalone conceptual questions and 3-5 mandatory key terms without ellipses quotes.
  List<GeneratedCard> _synthesizeLocalChemistryCards(String sourceText, int count, String topic) {
    final cards = <GeneratedCard>[];
    final seenQuestions = <String>{};

    void addCard(String q, String a, [List<String>? terms]) {
      final cleanQ = ChemistryTextFormatter.format(q.trim());
      final cleanA = ChemistryTextFormatter.format(a.trim());
      if (cleanQ.length > 8 && cleanA.length > 3 && seenQuestions.add(cleanQ.toLowerCase())) {
        final keyTerms = (terms != null && terms.isNotEmpty) ? terms : _extractKeywordsFromText('$cleanQ $cleanA', topic);
        cards.add(
          GeneratedCard(
            question: cleanQ,
            answer: cleanA,
            topic: topic,
            keyTerms: keyTerms.take(5).toList(),
          ),
        );
      }
    }

    final rawLines = sourceText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // 1. Parameter Specifications and Instrumental Conditions (e.g. Column, Flow Rate, Mobile Phase, Detector)
    for (final line in rawLines) {
      if (cards.length >= count) break;
      if (line.contains(':') && !line.startsWith('http')) {
        final colonIdx = line.indexOf(':');
        final key = line.substring(0, colonIdx).replaceAll(RegExp(r'^[#\-*•\d\.\s]+'), '').trim();
        final val = line.substring(colonIdx + 1).trim();
        if (key.length >= 2 && key.length <= 60 && val.length >= 2 && val.length <= 400) {
          final q = 'What is the operational role and recommended specification for $key in $topic?';
          final a = 'The specification for $key is $val. Proper optimization ensures analytical reproducibility, system suitability, and baseline stability.';
          addCard(q, a, [key, 'System Suitability', topic]);
        }
      }
    }

    // 2. Conceptual Headings & Core Principles
    for (var i = 0; i < rawLines.length - 1; i++) {
      if (cards.length >= count) break;
      final line = rawLines[i];
      if (line.startsWith('#') || (line.length <= 50 && !line.endsWith('.') && line.length > 3)) {
        final heading = line.replaceAll(RegExp(r'^[#\-*•\d\.\s]+'), '').trim();
        final nextLine = rawLines[i + 1].trim();
        if (heading.length >= 3 && nextLine.length >= 15 && !nextLine.startsWith('#')) {
          final q = 'What is the fundamental chemical principle and theoretical significance of $heading?';
          final a = '$nextLine In academic chemistry, understanding $heading is essential for reaction pathway determination and quantitative analysis.';
          addCard(q, a, [heading, 'Mechanism', 'Reaction Pathway']);
        }
      }
    }

    // 3. Definitions and Explanatory Paragraphs
    final rawSentences = sourceText
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((s) => s.replaceAll(RegExp(r'#{1,6}'), '').trim())
        .where((s) => s.length >= 15 && s.length <= 400)
        .toList();

    for (final s in rawSentences) {
      if (cards.length >= count) break;
      final cleanText = s.replaceAll(RegExp(r'^[#\-*•\d\.\s]+'), '').trim();
      final lower = cleanText.toLowerCase();

      // Definitions: "X is defined as Y", "X refers to Y", "X is used for Y"
      if (lower.contains(' is defined as ') ||
          lower.contains(' refers to ') ||
          lower.contains(' is used for ') ||
          lower.contains(' is used to ') ||
          lower.contains(' is called ') ||
          lower.contains(' consists of ')) {
        final match = RegExp(
          r'^(.*?)\s+(?:is defined as|refers to|is used for|is used to|is called|consists of)\s+(.*)$',
          caseSensitive: false,
        ).firstMatch(cleanText);

        if (match != null) {
          final subject = match.group(1)?.trim() ?? '';
          final predicate = match.group(2)?.trim() ?? '';
          if (subject.length >= 2 && subject.length <= 60 && predicate.isNotEmpty) {
            final q = 'Define the term "$subject" and state its significance in $topic.';
            final a = '$subject $predicate. This concept is fundamental for exam preparation and practical laboratory application.';
            addCard(q, a, [subject, topic, 'Definition']);
            continue;
          }
        }
      }

      // Reaction Mechanisms, Kinetics, and Analytical Principles
      if (lower.contains('mechanism') ||
          lower.contains('reaction') ||
          lower.contains('retention') ||
          lower.contains('calibration') ||
          lower.contains('kinetics') ||
          lower.contains('rate') ||
          lower.contains('intermediate') ||
          lower.contains('catalyst') ||
          lower.contains('disproportionation') ||
          lower.contains('hydride') ||
          lower.contains('spectroscopy') ||
          lower.contains('detector') ||
          lower.contains('suitability') ||
          lower.contains('separation')) {
        // Extract main subject words
        final words = cleanText.split(RegExp(r'\s+')).where((w) => w.length > 3).take(4).join(' ');
        final q = 'What is the mechanism and chemical rationale governing $words in $topic?';
        final a = '$cleanText This represents a key mechanistic concept in advanced MSc chemistry.';
        addCard(q, a, [words, topic, 'Kinetics', 'Mechanism']);
      }
    }

    // 4. Standalone High-Yield Fallback if count still not reached
    if (cards.length < count) {
      for (final s in rawSentences) {
        if (cards.length >= count) break;
        final cleanText = s.replaceAll(RegExp(r'^[#\-*•\d\.\s]+'), '').trim();
        final words = cleanText.split(RegExp(r'\s+')).where((w) => w.length > 3).take(3).join(' ');
        if (words.isNotEmpty) {
          final q = 'Explain the key chemical concepts associated with $words in $topic.';
          final a = '$cleanText';
          addCard(q, a, [words, topic]);
        }
      }
    }

    return cards.take(count).toList();
  }

  /// Extracts 3 to 5 salient chemistry keywords from question/answer text.
  static List<String> _extractKeywordsFromText(String text, String topic) {
    final terms = <String>{};
    if (topic.isNotEmpty && topic.toLowerCase() != 'chemistry') {
      terms.add(topic);
    }

    final chemistryLexicon = [
      'Mechanism', 'Kinetics', 'Regioselectivity', 'Stereochemistry', 'Enolate',
      'Hydride Transfer', 'Disproportionation', 'HPLC', 'Chromatography',
      'Retention Time', 'System Suitability', 'Theoretical Plates', 'Calibration Curve',
      'Mobile Phase', 'Stationary Phase', 'C18 Column', 'UV-Vis Detector',
      'Electrophile', 'Nucleophile', 'Equilibrium', 'Rate Constant', 'Activation Energy',
      'Isotope Effect', 'Catalyst', 'Transition State', 'Intermediate', 'Oxidation',
      'Reduction', 'Spectroscopy', 'NMR', 'Absorbance', 'Partition Coefficient',
    ];

    for (final term in chemistryLexicon) {
      if (terms.length >= 5) break;
      if (text.toLowerCase().contains(term.toLowerCase())) {
        terms.add(term);
      }
    }

    // If still under 3 terms, extract capitalized nouns
    if (terms.length < 3) {
      final matches = RegExp(r'\b[A-Z][a-zA-Z0-9_\-]{3,}\b').allMatches(text);
      for (final m in matches) {
        if (terms.length >= 4) break;
        final word = m.group(0)!;
        if (!['What', 'Explain', 'Which', 'When', 'Where', 'Define', 'State', 'Show', 'This', 'That', 'From', 'With', 'Your', 'Their'].contains(word)) {
          terms.add(word);
        }
      }
    }

    if (terms.isEmpty) {
      terms.addAll(['MSc Chemistry', 'Reaction Mechanism', 'Chemical Principles']);
    }

    return terms.take(5).toList();
  }
}
