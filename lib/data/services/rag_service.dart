import '../remote/supabase_service.dart';
import '../models/rag_models.dart';

class RagService {
  final SupabaseService _remote;

  RagService({required SupabaseService remote}) : _remote = remote;

  Future<RagResponse> ask({
    required String question,
    String? subject,
    String? documentText,
    String? documentName,
    List<AiMessage>? history,
  }) async {
    try {
      final response = await _remote.invokeFunction('ask-chembuddy', {
        'question': question,
        if (subject != null) 'subject': subject,
        if (documentText != null) 'document_text': documentText,
        if (documentName != null) 'document_name': documentName,
        if (history != null) 'history': history.map((e) => e.toJson()).toList(),
      });
      return RagResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      if (e is StateError) rethrow;
      throw StateError('Failed to get answer: $e');
    }
  }

  Future<void> ingestDocument({
    required String documentId,
    required String text,
    String? subject,
    String? topic,
    String? fileName,
  }) async {
    try {
      await _remote.invokeFunction('ingest-document', {
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
