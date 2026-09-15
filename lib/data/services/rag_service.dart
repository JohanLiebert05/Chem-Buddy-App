import 'package:flutter/foundation.dart';

import '../models/pdf_ocr_models.dart';
import '../remote/supabase_service.dart';
import '../models/rag_models.dart';
import 'chemistry_knowledge_engine.dart';
import 'gemini_orchestrator.dart';


class RagService {
  final SupabaseService remote;

  RagService({required this.remote});

  Future<RagResponse> ask({
    required String question,
    String? subject,
    String? documentText,
    String? documentName,
    String? documentId,
    List<AiMessage>? history,
    String? mode,
  }) async {
    debugPrint('[RAG] Incoming question: "$question" | mode: ${mode ?? "quick"} | subject: ${subject ?? "none"} | doc: ${documentName ?? "none"} | history: ${history?.length ?? 0} msgs');

    // 1. Try remote cloud first if configured
    if (remote.configured) {
      try {
        final response = await remote.invokeFunction('ask-chembuddy', {
          'question': question,
          'subject': ?subject,
          'document_text': ?documentText,
          'document_name': ?documentName,
          // Pass document_id for scoped RAG retrieval
          'document_id': ?documentId,
          // Use pdf_grounded mode when a document is attached and not in general mode
          'mode': documentText != null && documentText.isNotEmpty
              ? (mode == 'simple' || mode == 'general' ? mode : 'pdf_grounded')
              : (mode ?? 'quick'),
          if (history != null) 'history': history.map((e) => e.toJson()).toList(),
        });
        if (response is Map<String, dynamic> && response['answer'] != null) {
          return RagResponse.fromJson(response);
        }
      } catch (e) {
        debugPrint('[RAG] Cloud ask-chembuddy failed, trying direct Gemini Orchestrator: $e');
      }
    }

    // 2. Direct Internet Access via Google Gemini Orchestrator
    try {
      String? systemInstruction;

      if (mode == 'general') {
        systemInstruction = 'You are ChemBuddy AI, an expert, all-knowing general AI tutor powered by Google Gemini.\n'
            'Answer any question comprehensively, clearly, accurately, and intelligently.\n'
            'Provide structured insights, logical explanations, and correct scientific/mathematical notation where applicable.';
      } else if (mode == '2m') {
        systemInstruction = 'Format as a high-scoring 2-Mark university short answer: 1) Crisp definition/answer, 2) Essential points, 3) Balanced reaction or formula. Strictly under 150 words.';
      } else if (mode == '5m') {
        systemInstruction = 'Format as a structured 5-Mark MSc chemistry examination rubric with principle, balanced reactions, mechanism, and applications.';
      } else if (mode == '10m') {
        systemInstruction = 'Format as an exhaustive 10-Mark comprehensive MSc university answer with full theory, mechanisms, stereochemistry, and applications.';
      } else if (mode == 'mscConcept') {
        systemInstruction = 'Focus on deep physical-chemical MSc understanding: molecular orbitals, thermodynamics vs kinetics, Curtin-Hammett, and rigorous notation.';
      } else if (mode == 'mechanisms') {
        systemInstruction = 'Explain the full stepwise reaction mechanism with curved-arrow electron displacement, intermediate structures, and thermodynamic driving forces.';
      } else if (mode == 'fromMyPdf' || (documentText != null && documentText.isNotEmpty && mode != 'general')) {
        systemInstruction = 'Strict Document Grounding Mode: Answer ONLY from the provided study material. Cite the page or section. If the topic is not in the text, clearly state that it is not present in the uploaded document.';
      }

      final geminiRes = await GeminiOrchestrator.instance.ask(
        prompt: question,
        category: subject ?? 'chemistry',
        systemInstruction: systemInstruction,
        history: history,
        documentContext: documentText,
        mode: mode,
      );

      if (geminiRes.text.isNotEmpty && !geminiRes.text.startsWith('Error: All Gemini keys exhausted') && !geminiRes.text.startsWith('Error: No active Gemini API keys')) {
        return RagResponse(
          answer: geminiRes.text,
          sources: documentName != null
              ? [
                  RagSource(
                    documentTitle: documentName,
                    fileName: documentName,
                    pageNumber: 1,
                    subject: subject ?? 'Attached Material',
                    topic: 'Uploaded Study Notes',
                    similarity: 1.0,
                  )
                ]
              : const [],
          hasContext: documentText != null && documentText.isNotEmpty,
          chunksUsed: documentText != null ? 1 : 0,
        );
      }
    } catch (geminiErr) {
      debugPrint('[RAG] Direct Gemini Orchestrator failed: $geminiErr');
    }

    // 3. Zero-connectivity / Airplane Mode: ChemistryKnowledgeEngine
    return ChemistryKnowledgeEngine.generateAcademicResponse(
      question: question,
      subject: subject,
      documentText: documentText,
      documentName: documentName,
      history: history,
      mode: mode,
    );
  }

  /// Ingests a document into the RAG vector store.
  ///
  /// Prefers page-structured input ([bundle]) for accurate page citations.
  /// Falls back to flat [text] for legacy callers.
  Future<void> ingestDocument({
    required String documentId,
    String? text,
    DocumentOcrBundle? bundle,
    String? subject,
    String? topic,
    String? fileName,
    String? documentTitle,
  }) async {
    // Build pages array from bundle (preserves page_number per chunk)
    List<Map<String, dynamic>>? pages;
    if (bundle != null && bundle.pages.isNotEmpty) {
      pages = bundle.pages
          .where((p) => p.cleanedText.trim().length >= 20)
          .map((p) => {
                'pageNumber': p.pageNumber,
                'text': p.cleanedText.trim(),
              })
          .toList();
    }

    final bodyText = text ?? bundle?.fullText ?? '';

    try {
      await remote.invokeFunction('ingest-document', {
        'documentId': documentId,
        if (pages != null && pages.isNotEmpty) 'pages': pages,
        // Legacy flat text as fallback
        if (pages == null || pages.isEmpty) 'text': bodyText,
        'subject': ?subject,
        'topic': ?topic,
        'fileName': ?fileName,
        'documentTitle': ?documentTitle,
      });
    } catch (e) {
      throw StateError('Failed to ingest document: $e');
    }
  }
}
