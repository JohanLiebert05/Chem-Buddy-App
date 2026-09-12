import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/admin_models.dart';
import '../models/pdf_ocr_models.dart';
import '../remote/supabase_service.dart';
import 'rag_service.dart';

class DocumentIngestionService {
  final SupabaseService remote;

  DocumentIngestionService({required this.remote});

  Future<String> uploadDocument({
    required String filePath,
    required String fileName,
    required String title,
    String? subject,
  }) async {
    final client = remote.client;
    final userId = remote.userId;
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
    String? extractedText,
    DocumentOcrBundle? bundle,
    String? subject,
    String? topic,
    String? fileName,
    String? documentTitle,
  }) async {
    final ragService = RagService(remote: remote);
    final client = remote.client;
    if (client == null) throw StateError('Not authenticated');

    try {
      await client.from('rag_documents').update({'status': 'processing'}).eq('id', documentId);
      await ragService.ingestDocument(
        documentId: documentId,
        text: extractedText,
        bundle: bundle,
        subject: subject,
        topic: topic,
        fileName: fileName,
        documentTitle: documentTitle,
      );
      // Status update is handled by the edge function itself on success
    } catch (e) {
      await client.from('rag_documents').update({
        'status': 'error',
        'error_message': e.toString().length > 500 ? e.toString().substring(0, 500) : e.toString(),
      }).eq('id', documentId);
      rethrow;
    }
  }

  Future<List<RagDocument>> listDocuments() async {
    final client = remote.client;
    if (client == null) return [];

    final response = await client.from('rag_documents').select().order('created_at', ascending: false);
    return (response as List).map((e) => RagDocument.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteDocument(String id) async {
    final client = remote.client;
    if (client == null) return;

    final docData = await client.from('rag_documents').select('storage_path').eq('id', id).maybeSingle();
    if (docData != null && docData['storage_path'] != null) {
      try {
        await client.storage.from('documents').remove([docData['storage_path']]);
      } catch (_) {}
    }
    
    await remote.remove('rag_documents', id);
  }
}
