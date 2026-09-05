import 'package:flutter/foundation.dart';

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
    List<AiMessage>? history,
  }) async {
    debugPrint('[RAG] Incoming question: "$question" | subject: ${subject ?? "none"} | doc: ${documentName ?? "none"} | history: ${history?.length ?? 0} msgs');

    // 1. Try remote cloud first if configured

    if (remote.configured) {
      try {
        final response = await remote.invokeFunction('ask-chembuddy', {
          'question': question,
          'subject': ?subject,
          'document_text': ?documentText,
          'document_name': ?documentName,
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
    );
  }

  Future<void> ingestDocument({
    required String documentId,
    required String text,
    String? subject,
    String? topic,
    String? fileName,
  }) async {
    try {
      await remote.invokeFunction('ingest-document', {
        'document_id': documentId,
        'text': text,
        'subject': ?subject,
        'topic': ?topic,
        'file_name': ?fileName,
      });
    } catch (e) {
      throw StateError('Failed to ingest document: $e');
    }
  }
}
