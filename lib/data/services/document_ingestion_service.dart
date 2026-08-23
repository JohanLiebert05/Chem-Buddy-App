import 'dart:io';
import 'package:uuid/uuid.dart';
import '../remote/supabase_service.dart';
import '../models/admin_models.dart';
import 'rag_service.dart';

class DocumentIngestionService {
  final SupabaseService _remote;

  DocumentIngestionService({required SupabaseService remote}) : _remote = remote;

  Future<String> uploadDocument({
    required String filePath,
    required String fileName,
    required String title,
    String? subject,
  }) async {
    final client = _remote.client;
    final userId = _remote.userId;
    if (client == null || userId == null) {
      throw StateError('Not authenticated');
    }

    final id = const Uuid().v4();
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final storagePath = 'rag/$id/$fileName';

    await client.storage.from('documents').uploadBinary(storagePath, bytes);

    final doc = RagDocument(
      id: id,
      title: title,
      fileName: fileName,
      subject: subject,
      storagePath: storagePath,
      fileSize: bytes.length,
      status: 'pending',
      uploadedBy: userId,
      createdAt: DateTime.now(),
    );

    await client.from('rag_documents').insert(doc.toJson());

    return id;
  }

  Future<void> triggerIngestion({
    required String documentId,
    required String extractedText,
    String? subject,
    String? topic,
    String? fileName,
  }) async {
    final ragService = RagService(remote: _remote);
    final client = _remote.client;
    if (client == null) throw StateError('Not authenticated');

    try {
      await client.from('rag_documents').update({'status': 'processing'}).eq('id', documentId);
      await ragService.ingestDocument(
        documentId: documentId,
        text: extractedText,
        subject: subject,
        topic: topic,
        fileName: fileName,
      );
      await client.from('rag_documents').update({'status': 'ready'}).eq('id', documentId);
    } catch (e) {
      await client.from('rag_documents').update({'status': 'error', 'error_message': e.toString()}).eq('id', documentId);
      rethrow;
    }
  }

  Future<List<RagDocument>> listDocuments() async {
    final client = _remote.client;
    if (client == null) return [];

    final response = await client.from('rag_documents').select().order('created_at', ascending: false);
    return (response as List).map((e) => RagDocument.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteDocument(String id) async {
    final client = _remote.client;
    if (client == null) return;

    final docData = await client.from('rag_documents').select('storage_path').eq('id', id).maybeSingle();
    if (docData != null && docData['storage_path'] != null) {
      try {
        await client.storage.from('documents').remove([docData['storage_path']]);
      } catch (_) {}
    }
    
    await _remote.remove('rag_documents', id);
  }
}
