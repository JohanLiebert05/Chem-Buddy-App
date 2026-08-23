class Announcement {
  final String id;
  final String title;
  final String body;
  final String createdBy;
  final bool published;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdBy,
    this.published = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdBy: json['created_by'] as String,
      published: json['published'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'created_by': createdBy,
      'published': published,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? body,
    String? createdBy,
    bool? published,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdBy: createdBy ?? this.createdBy,
      published: published ?? this.published,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RagDocument {
  final String id;
  final String title;
  final String fileName;
  final String? subject;
  final String? storagePath;
  final int fileSize;
  final String status;
  final String? errorMessage;
  final int chunkCount;
  final String uploadedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RagDocument({
    required this.id,
    required this.title,
    required this.fileName,
    this.subject,
    this.storagePath,
    this.fileSize = 0,
    this.status = 'pending',
    this.errorMessage,
    this.chunkCount = 0,
    required this.uploadedBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory RagDocument.fromJson(Map<String, dynamic> json) {
    return RagDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      fileName: json['file_name'] as String,
      subject: json['subject'] as String?,
      storagePath: json['storage_path'] as String?,
      fileSize: json['file_size'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      errorMessage: json['error_message'] as String?,
      chunkCount: json['chunk_count'] as int? ?? 0,
      uploadedBy: json['uploaded_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'file_name': fileName,
      'subject': subject,
      'storage_path': storagePath,
      'file_size': fileSize,
      'status': status,
      'error_message': errorMessage,
      'chunk_count': chunkCount,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  RagDocument copyWith({
    String? id,
    String? title,
    String? fileName,
    String? subject,
    String? storagePath,
    int? fileSize,
    String? status,
    String? errorMessage,
    int? chunkCount,
    String? uploadedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RagDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      subject: subject ?? this.subject,
      storagePath: storagePath ?? this.storagePath,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      chunkCount: chunkCount ?? this.chunkCount,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
