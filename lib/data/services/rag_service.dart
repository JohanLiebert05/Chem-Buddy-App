import 'package:flutter/foundation.dart';

import '../models/pdf_ocr_models.dart';
import '../remote/supabase_service.dart';
import '../models/rag_models.dart';
import 'chemistry_knowledge_engine.dart';


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
          // Use pdf_grounded mode when a document is attached
          'mode': documentText != null && documentText.isNotEmpty
              ? (mode == 'simple' ? mode : 'pdf_grounded')
              : (mode ?? 'quick'),
          if (history != null) 'history': history.map((e) => e.toJson()).toList(),
        });
        if (response is Map<String, dynamic> && response['answer'] != null) {
          return RagResponse.fromJson(response);
        }
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('sign in') || msg.contains('401')) {
          rethrow;
        }
        debugPrint('[RAG] Cloud ask failed, using local engine: $e');
      }
    }

    // 2. Authoritative MSc Chemistry Knowledge Engine fallback
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
