import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../local/local_store.dart';
import '../../models/pdf_ocr_models.dart';
import '../pdf_text_utils.dart';
import 'chemistry_ocr_normalizer.dart';
import 'mlkit_ocr_provider.dart';
import 'ocr_provider.dart';

/// Page-aware PDF OCR and extraction pipeline for ChemBuddy.
/// Efficiently inspects each page, extracting fast native text for digital pages
/// and running domain-specific OCR with chemistry normalization for scanned/handwritten pages.
class PdfPagePipeline {
  PdfPagePipeline({
    OcrProvider? ocrProvider,
    LocalStore? store,
  })  : _ocrProvider = ocrProvider ?? MlKitOcrProvider(),
        _store = store ?? LocalStore();

  final OcrProvider _ocrProvider;
  final LocalStore _store;

  /// Maximum number of pages to process with heavy OCR in one run (to respect memory & battery)
  static const int maxOcrPages = 25;

  /// Processes the entire document page-by-page and returns a complete [DocumentOcrBundle].
  Future<DocumentOcrBundle> processDocument({
    required String filePath,
    required String docId,
    required String docTitle,
    bool forceReprocess = false,
    void Function(String status, double progress)? onProgress,
  }) async {
    // 1. Check local cache first unless forceReprocess is true
    if (!forceReprocess && docId.isNotEmpty) {
      final cached = _store.getDocumentOcrBundle(docId);
      if (cached != null && cached.pages.isNotEmpty) {
        onProgress?.call('Loaded cached OCR pages (${cached.pages.length} pages) ✓', 1.0);
        return cached;
      }
    }

    final file = File(filePath);
    if (!await file.exists()) {
      return DocumentOcrBundle(
        docId: docId,
        docTitle: docTitle,
        pages: [
          PdfPageOcrResult(
            pageNumber: 1,
            rawText: docTitle,
            cleanedText: 'Document: $docTitle\n(File not found at local storage path)',
            quality: PageQuality.digitalText,
          ),
        ],
        overallQuality: PageQuality.digitalText,
        processedAt: DateTime.now(),
        totalPages: 1,
      );
    }

    onProgress?.call('Analyzing PDF page structure...', 0.05);

    PdfDocument? sfDoc;
    pdfx.PdfDocument? pdfxDoc;
    Directory? tempDir;

    final results = <PdfPageOcrResult>[];

    try {
      final bytes = await file.readAsBytes();
      sfDoc = PdfDocument(inputBytes: bytes);
      final totalPages = sfDoc.pages.count;
      final pagesToProcess = min(totalPages, maxOcrPages);

      // Initialize OCR engine if available
      final ocrAvailable = await _ocrProvider.isAvailable;

      for (var pageIndex = 0; pageIndex < pagesToProcess; pageIndex++) {
        final pageNum = pageIndex + 1;
        final progressFrac = 0.05 + (pageIndex / pagesToProcess) * 0.90;

        onProgress?.call('Inspecting page $pageNum of $totalPages...', progressFrac);

        // 1. Attempt fast native text extraction for this specific page
        String nativePageText = '';
        try {
          final extractor = PdfTextExtractor(sfDoc);
          nativePageText = extractor.extractText(
            startPageIndex: pageIndex,
            endPageIndex: pageIndex,
          );
        } catch (_) {}

        final cleanNative = nativePageText.trim();
        final letterCount = RegExp(r'[A-Za-z]').allMatches(cleanNative).length;

        // If native text is clean and substantial, use it directly (Digital Page)
        if (cleanNative.length >= 40 && letterCount >= 25 && !looksLikeScannedPdf(cleanNative)) {
          final normalized = ChemistryOcrNormalizer.normalize(cleanNative);
          final formulas = ChemistryOcrNormalizer.extractDetectedFormulas(normalized);
          final keyTerms = _extractKeyTerms(normalized);

          results.add(PdfPageOcrResult(
            pageNumber: pageNum,
            rawText: cleanNative,
            cleanedText: normalized,
            quality: PageQuality.digitalText,
            confidence: 1.0,
            detectedFormulas: formulas,
            keyTerms: keyTerms,
          ));
          continue;
        }

        // 2. Page has little or no native text -> Render page image and run OCR (Scanned / Handwritten)
        if (ocrAvailable) {
          onProgress?.call('Running OCR on page $pageNum (scanned/handwritten)...', progressFrac);

          try {
            pdfxDoc ??= await pdfx.PdfDocument.openFile(filePath);
            tempDir ??= await getTemporaryDirectory();

            final page = await pdfxDoc.getPage(pageNum);
            final pageImage = await page.render(
              width: page.width * 1.5,
              height: page.height * 1.5,
              format: pdfx.PdfPageImageFormat.jpeg,
              quality: 90,
            );
            await page.close();

            if (pageImage != null) {
              final tempFile = File('${tempDir.path}/chembuddy_ocr_${DateTime.now().millisecondsSinceEpoch}_$pageNum.jpg');
              await tempFile.writeAsBytes(pageImage.bytes);

              try {
                final recognizedRaw = await _ocrProvider.recognizeImage(tempFile);
                final normalizedOcr = ChemistryOcrNormalizer.normalize(recognizedRaw);
                final formulas = ChemistryOcrNormalizer.extractDetectedFormulas(normalizedOcr);
                final keyTerms = _extractKeyTerms(normalizedOcr);

                final pageQuality = _classifyOcrTextQuality(recognizedRaw);

                results.add(PdfPageOcrResult(
                  pageNumber: pageNum,
                  rawText: recognizedRaw,
                  cleanedText: normalizedOcr.isNotEmpty ? normalizedOcr : '(Page $pageNum: Diagram or chemical structure without extractable text)',
                  quality: pageQuality,
                  confidence: recognizedRaw.trim().length > 30 ? 0.88 : 0.60,
                  detectedFormulas: formulas,
                  keyTerms: keyTerms,
                  isDiagramRegion: recognizedRaw.trim().length < 20,
                ));
              } finally {
                if (await tempFile.exists()) {
                  await tempFile.delete();
                }
              }
              continue;
            }
          } catch (_) {
            // OCR execution fallback
          }
        }

        // 3. Fallback for image pages if OCR is unavailable or fails
        final fallbackText = cleanNative.isNotEmpty
            ? ChemistryOcrNormalizer.normalize(cleanNative)
            : 'Page $pageNum: Chemistry diagrams, tables or structures for $docTitle.';

        results.add(PdfPageOcrResult(
          pageNumber: pageNum,
          rawText: cleanNative,
          cleanedText: fallbackText,
          quality: PageQuality.scannedImage,
          confidence: 0.5,
          detectedFormulas: ChemistryOcrNormalizer.extractDetectedFormulas(fallbackText),
          keyTerms: _extractKeyTerms(fallbackText),
        ));
      }

      // Assess overall document quality
      final digitalPages = results.where((p) => p.quality == PageQuality.digitalText).length;
      final handwrittenPages = results.where((p) => p.quality == PageQuality.handwritten).length;
      final scannedPages = results.where((p) => p.quality == PageQuality.scannedImage).length;

      PageQuality overallQuality;
      if (digitalPages == results.length) {
        overallQuality = PageQuality.digitalText;
      } else if (digitalPages == 0 && (handwrittenPages > 0 || scannedPages > 0)) {
        overallQuality = handwrittenPages > scannedPages ? PageQuality.handwritten : PageQuality.scannedImage;
      } else {
        overallQuality = PageQuality.mixed;
      }

      final bundle = DocumentOcrBundle(
        docId: docId,
        docTitle: docTitle,
        pages: results,
        overallQuality: overallQuality,
        processedAt: DateTime.now(),
        totalPages: totalPages,
      );

      // Save to Hive cache
      if (docId.isNotEmpty) {
        await _store.saveDocumentOcrBundle(bundle);
      }

      onProgress?.call('Document processing complete ✓', 1.0);
      return bundle;
    } catch (e) {
      // Graceful fallback bundle
      final fallbackBundle = DocumentOcrBundle(
        docId: docId,
        docTitle: docTitle,
        pages: [
          PdfPageOcrResult(
            pageNumber: 1,
            rawText: '',
            cleanedText: 'MSc Chemistry study material and notes for $docTitle.',
            quality: PageQuality.scannedImage,
          ),
        ],
        overallQuality: PageQuality.scannedImage,
        processedAt: DateTime.now(),
        totalPages: 1,
      );
      return fallbackBundle;
    } finally {
      sfDoc?.dispose();
      await pdfxDoc?.close();
    }
  }

  /// Classifies OCR text into handwritten notes vs printed/scanned textbook text.
  PageQuality _classifyOcrTextQuality(String text) {
    if (text.trim().isEmpty) return PageQuality.scannedImage;

    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return PageQuality.scannedImage;

    // Handwritten text tends to have irregular line lengths and occasional symbol mixups
    final avgLineLen = lines.map((l) => l.length).reduce((a, b) => a + b) / lines.length;
    final hasHandwritingPatterns = avgLineLen < 35 && lines.length > 4;

    if (hasHandwritingPatterns) {
      return PageQuality.handwritten;
    }
    return PageQuality.scannedImage;
  }

  /// Extracts chemistry keywords and key terms from page text.
  List<String> _extractKeyTerms(String text) {
    final lower = text.toLowerCase();
    final candidateKeywords = [
      'Mechanism', 'Synthesis', 'Kinetics', 'Thermodynamics', 'Enthalpy', 'Entropy',
      'Gibbs Free Energy', 'Activation Energy', 'Arrhenius', 'Rate Constant', 'Half Life',
      'Stereochemistry', 'Chirality', 'Enantiomer', 'Diastereomer', 'Racemic',
      'Spectroscopy', 'NMR', 'Chemical Shift', 'Coupling Constant', 'IR Spectroscopy',
      'Carbonyl', 'UV-Vis', 'Chromatography', 'HPLC', 'Retention Time', 'Mobile Phase',
      'Stationary Phase', 'Coordination', 'Crystal Field', 'CFSE', 'd-Orbitals',
      'Nucleophile', 'Electrophile', 'Aldol', 'Cannizzaro', 'Wittig', 'Grignard',
      'Diels-Alder', 'Pericyclic', 'Electrocyclic', 'Conrotatory', 'Disrotatory',
      'Nernst Equation', 'Beer-Lambert', 'Bragg\'s Law', 'pH', 'pKa', 'Buffer',
    ];

    final found = <String>[];
    for (final kw in candidateKeywords) {
      if (lower.contains(kw.toLowerCase())) {
        found.add(kw);
      }
      if (found.length >= 6) break;
    }
    return found;
  }
}
