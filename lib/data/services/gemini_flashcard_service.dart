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

  /// Classifies a text chunk into one of 5 content types for targeted flashcard generation.
  static _ChunkType _classifyChunk(String text) {
    final lower = text.toLowerCase();

    // Reaction mechanism markers
    if (lower.contains('mechanism') ||
        lower.contains('reaction') ||
        lower.contains('intermediate') ||
        lower.contains('catalyst') ||
        lower.contains('nucleophilic') ||
        lower.contains('electrophilic') ||
        lower.contains('disproportionation') ||
        lower.contains('hydride transfer') ||
        lower.contains('oxidation state') ||
        lower.contains('electron') ||
        lower.contains('arrow-pushing') ||
        lower.contains('transition state')) {
      return _ChunkType.reactionMechanism;
    }

    // Formula / derivation markers
    if (lower.contains('formula') ||
        lower.contains('equation') ||
        lower.contains('derivation') ||
        lower.contains('mathematically') ||
        lower.contains('concentration') ||
        lower.contains('molarity') ||
        lower.contains('normality') ||
        lower.contains('pH =') ||
        lower.contains('ka') ||
        lower.contains('kb') ||
        lower.contains('delta g') ||
        lower.contains('rate law') ||
        lower.contains('half life') ||
        lower.contains('arrhenius') ||
        lower.contains('beer') ||
        lower.contains('lambert') ||
        RegExp(r'=\s*[\d\[\\\{\-]').hasMatch(lower)) {
      return _ChunkType.formulaDerivation;
    }

    // Procedure / method markers (instrumentation, chromatography, titration)
    if (lower.contains('procedure') ||
        lower.contains('method') ||
        lower.contains('column') ||
        lower.contains('flow rate') ||
        lower.contains('mobile phase') ||
        lower.contains('stationary phase') ||
        lower.contains('detector') ||
        lower.contains('retention') ||
        lower.contains('injection') ||
        lower.contains('calibration') ||
        lower.contains('titration') ||
        lower.contains('standardize') ||
        lower.contains('suitability') ||
        lower.contains('separation') ||
        lower.contains('chromatography') ||
        lower.contains('instrument') ||
        lower.contains('spectrophotom') ||
        lower.contains('sample preparation')) {
      return _ChunkType.procedureMethod;
    }

    // Data / reference markers (tables, values, pKa, NMR shifts)
    if (lower.contains('table') ||
        lower.contains('pka') ||
        lower.contains('shift') ||
        lower.contains('wavenumber') ||
        lower.contains('standard potential') ||
        lower.contains('boiling point') ||
        lower.contains('melting point') ||
        lower.contains('solubility') ||
        lower.contains('permissible limit') ||
        lower.contains('ppm') ||
        RegExp(r'\d+\s*(nm|cm|hz|ppm|°c|kj|mhz|ev)').hasMatch(lower)) {
      return _ChunkType.dataReference;
    }

    // Default: definition / concept
    return _ChunkType.definitionConcept;
  }

  /// Generates a grounded, type-specific flashcard question for a given chunk.
  static ({String question, String answer, List<String> terms})? _generateTypedCard(
    String chunk,
    _ChunkType type,
    String topic,
  ) {
    final clean = chunk.replaceAll(RegExp(r'^[#\-*•\d\.\s]+'), '').trim();
    if (clean.length < 15) return null;

    final words = clean.split(RegExp(r'\s+')).where((w) => w.length > 3).take(4).join(' ');
    if (words.isEmpty) return null;

    switch (type) {
      case _ChunkType.reactionMechanism:
        return (
          question: 'What is the mechanistic pathway and key intermediate(s) involved in $words?',
          answer: '$clean',
          terms: [words, 'Mechanism', 'Intermediate', topic],
        );
      case _ChunkType.formulaDerivation:
        return (
          question: 'State and derive the governing equation for $words, including all variables and units.',
          answer: '$clean',
          terms: [words, 'Formula', 'Units', topic],
        );
      case _ChunkType.procedureMethod:
        // Extract the "label: value" key if this is a parameter specification
        if (clean.contains(':')) {
          final colonIdx = clean.indexOf(':');
          final key = clean.substring(0, colonIdx).replaceAll(RegExp(r'^[#\-*•\d\.\s]+'), '').trim();
          final val = clean.substring(colonIdx + 1).trim();
          if (key.length >= 2 && key.length <= 60 && val.length >= 2) {
            return (
              question: 'What is the recommended specification and analytical purpose of "$key" in $topic?',
              answer: 'The specification for $key is: $val. Correct optimization ensures analytical reproducibility and system suitability.',
              terms: [key, 'System Suitability', 'Analytical Method', topic],
            );
          }
        }
        return (
          question: 'Describe the procedure and analytical rationale for $words in $topic.',
          answer: '$clean',
          terms: [words, 'Procedure', 'Analytical Method', topic],
        );
      case _ChunkType.dataReference:
        return (
          question: 'What are the key reference values, limits, or spectroscopic data associated with $words?',
          answer: '$clean',
          terms: [words, 'Reference Value', 'Spectroscopy', topic],
        );
      case _ChunkType.definitionConcept:
        // Try to extract "X is defined as Y" patterns
        final defPattern = RegExp(
          r'^(.*?)\s+(?:is defined as|refers to|is used for|is used to|is called|consists of)\s+(.*)$',
          caseSensitive: false,
        ).firstMatch(clean);
        if (defPattern != null) {
          final subject = defPattern.group(1)?.trim() ?? '';
          final predicate = defPattern.group(2)?.trim() ?? '';
          if (subject.length >= 2 && subject.length <= 80) {
            return (
              question: 'Define "$subject" and explain its significance in $topic.',
              answer: '$subject $predicate.',
              terms: [subject, 'Definition', topic],
            );
          }
        }
        return (
          question: 'Explain the concept of $words and its role in $topic.',
          answer: '$clean',
          terms: [words, 'Concept', topic],
        );
    }
  }

  /// Validates that a generated card answer is actually grounded in the source text.
  /// Rejects filler that doesn't reference any real source content.
  static bool _isGrounded(String answer, String sourceText) {
    // Extract keywords from answer and check they exist in source
    final answerWords = answer
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 4)
        .toSet();
    final sourceLower = sourceText.toLowerCase();
    var matchCount = 0;
    for (final w in answerWords) {
      if (sourceLower.contains(w)) matchCount++;
    }
    // At least 40% of significant answer words must appear in source
    return answerWords.isEmpty || (matchCount / answerWords.length) >= 0.40;
  }

  /// Synthesizes high-yield academic MSc Chemistry flashcards strictly from the provided document text.
  /// Uses content-type classification for targeted, grounded question generation.
  List<GeneratedCard> _synthesizeLocalChemistryCards(String sourceText, int count, String topic) {
    final cards = <GeneratedCard>[];
    final seenQuestions = <String>{};

    void tryAddCard(String q, String a, List<String> terms) {
      final cleanQ = ChemistryTextFormatter.format(q.trim());
      final cleanA = ChemistryTextFormatter.format(a.trim());
      if (cleanQ.length > 8 &&
          cleanA.length > 10 &&
          seenQuestions.add(cleanQ.toLowerCase()) &&
          _isGrounded(cleanA, sourceText)) {
        final keyTerms = terms.isNotEmpty ? terms : _extractKeywordsFromText('$cleanQ $cleanA', topic);
        cards.add(GeneratedCard(
          question: cleanQ,
          answer: cleanA,
          topic: topic,
          keyTerms: keyTerms.take(5).toList(),
        ));
      }
    }

    // 1. Classify each paragraph/line and generate a typed card
    final paragraphs = sourceText
        .split(RegExp(r'\n\s*\n|\r\n\s*\r\n'))
        .map((p) => p.trim())
        .where((p) => p.length >= 20)
        .toList();

    for (final para in paragraphs) {
      if (cards.length >= count) break;
      final type = _classifyChunk(para);
      final result = _generateTypedCard(para, type, topic);
      if (result != null) {
        tryAddCard(result.question, result.answer, result.terms);
      }
    }

    // 2. Line-by-line pass for parameter specs missed by paragraph pass
    if (cards.length < count) {
      final lines = sourceText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      for (final line in lines) {
        if (cards.length >= count) break;
        if (line.contains(':') && !line.startsWith('http')) {
          final type = _classifyChunk(line);
          final result = _generateTypedCard(line, type, topic);
          if (result != null) {
            tryAddCard(result.question, result.answer, result.terms);
          }
        }
      }
    }

    // 3. Sentence-level fallback
    if (cards.length < count) {
      final sentences = sourceText
          .split(RegExp(r'(?<=[.!?])\s+|\n+'))
          .map((s) => s.replaceAll(RegExp(r'#{1,6}'), '').trim())
          .where((s) => s.length >= 20 && s.length <= 400)
          .toList();
      for (final sentence in sentences) {
        if (cards.length >= count) break;
        final type = _classifyChunk(sentence);
        final result = _generateTypedCard(sentence, type, topic);
        if (result != null) {
          tryAddCard(result.question, result.answer, result.terms);
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

/// Content type classification for targeted flashcard generation.
enum _ChunkType {
  /// Organic/inorganic reaction pathways, electron movement, mechanisms
  reactionMechanism,
  /// Laws, theories, principles, definitions, academic concepts
  definitionConcept,
  /// Mathematical equations, thermodynamic derivations, rate equations
  formulaDerivation,
  /// Instrumentation, chromatography, titrations, analytical methods
  procedureMethod,
  /// Spectroscopy tables, pKa values, NMR shifts, reference data
  dataReference,
}

