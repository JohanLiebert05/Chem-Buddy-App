import 'package:flutter/foundation.dart';
import '../../models/pdf_ocr_models.dart';
import 'chemistry_ocr_normalizer.dart';
import 'handwritten_image_preprocessor.dart';
import 'mlkit_ocr_provider.dart';
import 'ocr_provider.dart';

/// Comprehensive Handwritten Chemistry Notes OCR & Document Understanding Pipeline.
/// Specifically engineered for multi-page photographs, scans, and mixed academic notes.
/// 
/// Preserves:
/// - Exact page order
/// - Chemical formulas (H2SO4 -> H₂SO₄, [Fe(CN)6]4- -> [Fe(CN)₆]⁴⁻, 10^-3 M -> 10⁻³ M)
/// - Reaction arrows (->, <=>, ⇌) and conditions (Δ, hν, °C)
/// - Headings, definitions, mechanisms, and exam-oriented core concepts
/// - Distinguishes academic chemistry from marginal doodles & greetings
class HandwrittenNotesOcrPipeline {
  HandwrittenNotesOcrPipeline({
    OcrProvider? ocrProvider,
  }) : _ocrProvider = ocrProvider ?? MlKitOcrProvider();

  final OcrProvider _ocrProvider;

  /// Processes an ordered sequence of handwritten note images (camera photos or gallery scans)
  /// and produces an ordered, page-aware [DocumentOcrBundle].
  Future<DocumentOcrBundle> processHandwrittenImages({
    required List<String> imagePaths,
    required String docTitle,
    void Function(String status, double progress)? onProgress,
  }) async {
    if (imagePaths.isEmpty) {
      return DocumentOcrBundle(
        docId: 'empty-handwritten',
        docTitle: docTitle,
        pages: const [],
        overallQuality: PageQuality.handwritten,
        processedAt: DateTime.now(),
        totalPages: 0,
      );
    }

    onProgress?.call('Preprocessing ${imagePaths.length} note pages...', 0.05);
    final preprocessor = HandwrittenImagePreprocessor.instance;
    final preparedFiles = await preprocessor.prepareImages(
      imagePaths,
      onProgress: (status, p) => onProgress?.call(status, 0.05 + p * 0.15),
    );

    final results = <PdfPageOcrResult>[];
    final total = preparedFiles.length;

    for (var i = 0; i < total; i++) {
      final file = preparedFiles[i];
      final pageNum = i + 1;
      final stepFrac = 0.20 + (i / total) * 0.70;

      onProgress?.call('Running Handwriting OCR on Page $pageNum of $total...', stepFrac);

      String rawText = '';
      double confidence = 0.85;

      try {
        // Run Google ML Kit on-device text recognition
        rawText = await _ocrProvider.recognizeImage(file);
      } catch (e) {
        debugPrint('[HandwrittenNotesOcrPipeline] OCR error on page $pageNum: $e');
        rawText = '';
      }

      onProgress?.call('Normalizing chemistry formulas & reactions on Page $pageNum...', stepFrac + 0.04);

      // Apply specialized handwriting chemistry normalizer
      final normalized = ChemistryOcrNormalizer.normalizeHandwritten(rawText);
      final detectedFormulas = ChemistryOcrNormalizer.extractDetectedFormulas(normalized);
      final keyTerms = _extractHandwritingKeyTerms(normalized);
      final quality = _assessQuality(rawText, detectedFormulas);

      results.add(PdfPageOcrResult(
        pageNumber: pageNum,
        rawText: rawText,
        cleanedText: normalized,
        quality: quality,
        confidence: confidence,
        detectedFormulas: detectedFormulas,
        keyTerms: keyTerms,
      ));
    }

    onProgress?.call('Structuring multi-page study concepts...', 0.95);

    // Build overall bundle
    final bundle = DocumentOcrBundle(
      docId: 'handwritten_${DateTime.now().millisecondsSinceEpoch}',
      docTitle: docTitle,
      pages: results,
      overallQuality: _computeOverallQuality(results),
      processedAt: DateTime.now(),
      totalPages: results.length,
    );

    onProgress?.call('Handwriting analysis complete ✓', 1.0);
    return bundle;
  }

  /// Extracts chemistry-relevant keywords and conceptual markers from handwritten notes.
  List<String> _extractHandwritingKeyTerms(String text) {
    final terms = <String>{};
    final lower = text.toLowerCase();

    // High-yield MSc Chemistry topic triggers
    const markers = [
      'mechanism', 'synthesis', 'reagent', 'catalyst', 'enolate', 'aldol', 'electrophile',
      'nucleophile', 'carbocation', 'carbanion', 'stereochemistry', 'conformation', 'isomer',
      'hybridization', 'aromaticity', 'pericyclic', 'spectroscopy', 'nmr', 'ir', 'uv-vis',
      'thermodynamics', 'kinetics', 'entropy', 'enthalpy', 'gibbs', 'equilibrium', 'titration',
      'coordination', 'ligand', 'complex', 'oxidation', 'reduction', 'redox', 'half-life',
      'rate constant', 'activation energy', 'transition state', 'hammett', 'markovnikov',
      'zaitsev', 'sn1', 'sn2', 'e1', 'e2', 'pka', 'ph', 'buffer', 'diels-alder',
    ];

    for (final marker in markers) {
      if (lower.contains(marker)) {
        terms.add(marker[0].toUpperCase() + marker.substring(1));
      }
    }

    // Capitalized chemical names or formulas in quotes / headers
    final capMatches = RegExp(r'\b[A-Z][a-z]{3,}\b').allMatches(text);
    for (final m in capMatches.take(8)) {
      final w = m.group(0)!;
      if (!const {'Page', 'Date', 'Chapter', 'Note', 'Important', 'Test', 'Class'}.contains(w)) {
        terms.add(w);
      }
    }

    return terms.take(8).toList();
  }

  PageQuality _assessQuality(String raw, List<String> formulas) {
    final clean = raw.trim();
    if (clean.length < 30) return PageQuality.handwritten;
    if (formulas.isNotEmpty && clean.length >= 100) return PageQuality.scannedImage;
    return PageQuality.handwritten;
  }

  PageQuality _computeOverallQuality(List<PdfPageOcrResult> pages) {
    if (pages.isEmpty) return PageQuality.handwritten;
    final scannedCount = pages.where((p) => p.quality == PageQuality.scannedImage).length;
    if (scannedCount >= (pages.length * 0.7)) return PageQuality.scannedImage;
    return PageQuality.handwritten;
  }
}
