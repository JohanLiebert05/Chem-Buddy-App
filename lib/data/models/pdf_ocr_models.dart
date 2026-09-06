import 'package:uuid/uuid.dart';

enum PageQuality {
  digitalText,
  scannedImage,
  handwritten,
  mixed,
}

extension PageQualityExtension on PageQuality {
  String get label {
    switch (this) {
      case PageQuality.digitalText:
        return 'Digital Text';
      case PageQuality.scannedImage:
        return 'Scanned Document';
      case PageQuality.handwritten:
        return 'Handwritten Notes';
      case PageQuality.mixed:
        return 'Mixed Document';
    }
  }

  String get icon {
    switch (this) {
      case PageQuality.digitalText:
        return '📄';
      case PageQuality.scannedImage:
        return '📷';
      case PageQuality.handwritten:
        return '📝';
      case PageQuality.mixed:
        return '📑';
    }
  }
}

class PdfPageOcrResult {
  const PdfPageOcrResult({
    required this.pageNumber,
    required this.rawText,
    required this.cleanedText,
    required this.quality,
    this.confidence = 1.0,
    this.detectedFormulas = const [],
    this.keyTerms = const [],
    this.isDiagramRegion = false,
  });

  final int pageNumber;
  final String rawText;
  final String cleanedText;
  final PageQuality quality;
  final double confidence;
  final List<String> detectedFormulas;
  final List<String> keyTerms;
  final bool isDiagramRegion;

  PdfPageOcrResult copyWith({
    int? pageNumber,
    String? rawText,
    String? cleanedText,
    PageQuality? quality,
    double? confidence,
    List<String>? detectedFormulas,
    List<String>? keyTerms,
    bool? isDiagramRegion,
  }) {
    return PdfPageOcrResult(
      pageNumber: pageNumber ?? this.pageNumber,
      rawText: rawText ?? this.rawText,
      cleanedText: cleanedText ?? this.cleanedText,
      quality: quality ?? this.quality,
      confidence: confidence ?? this.confidence,
      detectedFormulas: detectedFormulas ?? this.detectedFormulas,
      keyTerms: keyTerms ?? this.keyTerms,
      isDiagramRegion: isDiagramRegion ?? this.isDiagramRegion,
    );
  }

  Map<String, dynamic> toJson() => {
        'page_number': pageNumber,
        'raw_text': rawText,
        'cleaned_text': cleanedText,
        'quality': quality.name,
        'confidence': confidence,
        'detected_formulas': detectedFormulas,
        'key_terms': keyTerms,
        'is_diagram_region': isDiagramRegion,
      };

  factory PdfPageOcrResult.fromJson(Map<String, dynamic> json) {
    final rawQ = '${json['quality'] ?? 'digitalText'}';
    final quality = PageQuality.values.firstWhere(
      (e) => e.name.toLowerCase() == rawQ.toLowerCase(),
      orElse: () => PageQuality.digitalText,
    );

    return PdfPageOcrResult(
      pageNumber: json['page_number'] as int? ?? 1,
      rawText: json['raw_text'] as String? ?? '',
      cleanedText: json['cleaned_text'] as String? ?? '',
      quality: quality,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      detectedFormulas: List<String>.from(json['detected_formulas'] as List? ?? const []),
      keyTerms: List<String>.from(json['key_terms'] as List? ?? const []),
      isDiagramRegion: json['is_diagram_region'] as bool? ?? false,
    );
  }
}

class DocumentOcrBundle {
  const DocumentOcrBundle({
    required this.docId,
    required this.docTitle,
    required this.pages,
    required this.overallQuality,
    required this.processedAt,
    required this.totalPages,
  });

  final String docId;
  final String docTitle;
  final List<PdfPageOcrResult> pages;
  final PageQuality overallQuality;
  final DateTime processedAt;
  final int totalPages;

  int get pageCount => pages.length;

  /// Compiles all pages into a unified text document with page citations.
  String get fullText {
    if (pages.isEmpty) return '';
    return pages
        .where((p) => p.cleanedText.trim().isNotEmpty)
        .map((p) => '--- Page ${p.pageNumber} ---\n${p.cleanedText.trim()}')
        .join('\n\n');
  }

  /// Retrieves extracted text for a specific 1-indexed page.
  String textForPage(int pageNumber) {
    final match = pages.where((p) => p.pageNumber == pageNumber);
    return match.isNotEmpty ? match.first.cleanedText : '';
  }

  /// All unique chemistry formulas detected across all pages.
  List<String> get allDetectedFormulas {
    final formulas = <String>{};
    for (final p in pages) {
      formulas.addAll(p.detectedFormulas);
    }
    return formulas.toList();
  }

  /// Percentage of pages that are scanned or handwritten.
  double get ocrPageRatio {
    if (pages.isEmpty) return 0.0;
    final ocrPages = pages.where((p) => p.quality != PageQuality.digitalText).length;
    return ocrPages / pages.length;
  }

  Map<String, dynamic> toJson() => {
        'doc_id': docId,
        'doc_title': docTitle,
        'pages': pages.map((p) => p.toJson()).toList(),
        'overall_quality': overallQuality.name,
        'processed_at': processedAt.toIso8601String(),
        'total_pages': totalPages,
      };

  factory DocumentOcrBundle.fromJson(Map<String, dynamic> json) {
    final rawQ = '${json['overall_quality'] ?? 'digitalText'}';
    final overallQuality = PageQuality.values.firstWhere(
      (e) => e.name.toLowerCase() == rawQ.toLowerCase(),
      orElse: () => PageQuality.digitalText,
    );

    final rawPages = json['pages'] as List? ?? const [];
    final pages = rawPages
        .map((e) => PdfPageOcrResult.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return DocumentOcrBundle(
      docId: json['doc_id'] as String? ?? const Uuid().v4(),
      docTitle: json['doc_title'] as String? ?? 'Chemistry Document',
      pages: pages,
      overallQuality: overallQuality,
      processedAt: DateTime.tryParse('${json['processed_at'] ?? ''}') ?? DateTime.now(),
      totalPages: json['total_pages'] as int? ?? pages.length,
    );
  }

  DocumentOcrBundle copyWith({
    String? docId,
    String? docTitle,
    List<PdfPageOcrResult>? pages,
    PageQuality? overallQuality,
    DateTime? processedAt,
    int? totalPages,
  }) {
    return DocumentOcrBundle(
      docId: docId ?? this.docId,
      docTitle: docTitle ?? this.docTitle,
      pages: pages ?? this.pages,
      overallQuality: overallQuality ?? this.overallQuality,
      processedAt: processedAt ?? this.processedAt,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
