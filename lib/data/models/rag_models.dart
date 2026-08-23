class AiConversation {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AiConversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    this.updatedAt,
  });

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    return AiConversation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

class RagSource {
  final String? documentTitle;
  final String? fileName;
  final String? subject;
  final String? topic;
  final int? pageNumber;
  final double? similarity;

  const RagSource({
    this.documentTitle,
    this.fileName,
    this.subject,
    this.topic,
    this.pageNumber,
    this.similarity,
  });

  factory RagSource.fromJson(Map<String, dynamic> json) {
    return RagSource(
      documentTitle: json['document_title'] as String?,
      fileName: json['file_name'] as String?,
      subject: json['subject'] as String?,
      topic: json['topic'] as String?,
      pageNumber: json['page_number'] as int?,
      similarity: (json['similarity'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (documentTitle != null) 'document_title': documentTitle,
      if (fileName != null) 'file_name': fileName,
      if (subject != null) 'subject': subject,
      if (topic != null) 'topic': topic,
      if (pageNumber != null) 'page_number': pageNumber,
      if (similarity != null) 'similarity': similarity,
    };
  }
}

class AiMessage {
  final String id;
  final String conversationId;
  final String userId;
  final String role;
  final String content;
  final List<RagSource> sources;
  final DateTime createdAt;

  const AiMessage({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.role,
    required this.content,
    this.sources = const [],
    required this.createdAt,
  });

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    final sourcesList = json['sources'] as List<dynamic>? ?? [];
    return AiMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      sources: sourcesList.map((e) => RagSource.fromJson(e as Map<String, dynamic>)).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role,
      'content': content,
      'sources': sources.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class RagResponse {
  final String answer;
  final List<RagSource> sources;
  final bool hasContext;
  final int chunksUsed;

  const RagResponse({
    required this.answer,
    this.sources = const [],
    this.hasContext = false,
    this.chunksUsed = 0,
  });

  factory RagResponse.fromJson(Map<String, dynamic> json) {
    final sourcesList = json['sources'] as List<dynamic>? ?? [];
    return RagResponse(
      answer: json['answer'] as String? ?? '',
      sources: sourcesList.map((e) => RagSource.fromJson(e as Map<String, dynamic>)).toList(),
      hasContext: json['has_context'] as bool? ?? false,
      chunksUsed: json['chunks_used'] as int? ?? 0,
    );
  }
}
