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
    // 1. Try remote cloud first if configured
    if (remote.configured) {
      try {
        final response = await remote.invokeFunction('ask-chembuddy', {
          'question': question,
          if (subject != null) 'subject': subject,
          if (documentText != null) 'document_text': documentText,
          if (documentName != null) 'document_name': documentName,
          if (history != null) 'history': history.map((e) => e.toJson()).toList(),
        });
        if (response is Map<String, dynamic> && response['answer'] != null) {
          return RagResponse.fromJson(response);
        }
      } catch (_) {
        // Fall back seamlessly to local academic chemistry knowledge engine
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
        if (subject != null) 'subject': subject,
        if (topic != null) 'topic': topic,
        if (fileName != null) 'file_name': fileName,
      });
    } catch (e) {
      throw StateError('Failed to ingest document: $e');
    }
  }
}
