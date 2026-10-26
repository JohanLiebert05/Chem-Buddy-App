import '../../core/widgets/expressive_motion.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../core/widgets/claude_loading_text.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/models/library_models.dart';
import '../../data/models/pdf_ocr_models.dart';
import '../../data/remote/supabase_service.dart';
import '../../data/services/gemini_flashcard_service.dart';
import '../../data/services/pdf_text_utils.dart';
import '../providers/admin_providers.dart' show ragServiceProvider;
import '../providers/app_providers.dart';
import '../providers/rag_providers.dart';
import '../widgets/contextual_hint_card.dart';
import '../widgets/pdf_quiz_setup_dialog.dart';
import 'pdf_reader_screen.dart';
import 'smart_flashcards_study_screen.dart';

class PdfStudyHubScreen extends ConsumerStatefulWidget {
  const PdfStudyHubScreen({
    super.key,
    required this.doc,
    this.initialTab = 0,
    this.initialExtractedText,
  });

  final PdfDoc doc;
  final int initialTab;
  final String? initialExtractedText;

  @override
  ConsumerState<PdfStudyHubScreen> createState() => _PdfStudyHubScreenState();
}

class _PdfStudyHubScreenState extends ConsumerState<PdfStudyHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _extractedText;
  DocumentOcrBundle? _ocrBundle;
  DocumentQuality _documentQuality = DocumentQuality.digitalText;
  bool _loading = false;
  String _progressStatus = '';
  double _progressFraction = 0.0;
  String? _errorMessage;

  int _flashcardCount = 10;
  final TextEditingController _askController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final safeInitial = widget.initialTab.clamp(0, 1);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: safeInitial,
    );
    if (widget.initialExtractedText != null &&
        widget.initialExtractedText!.trim().isNotEmpty) {
      _extractedText = widget.initialExtractedText;
      _documentQuality = assessDocumentQuality(widget.initialExtractedText!);
    }
    _loadCachedOrExtract();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _askController.dispose();
    super.dispose();
  }

  Future<void> _loadCachedOrExtract() async {
    final store = ref.read(localStoreProvider);
    _ocrBundle = store.getDocumentOcrBundle(widget.doc.id);
    if (_ocrBundle != null) {
      _extractedText = _ocrBundle!.fullText;
      _documentQuality = _ocrBundle!.overallQuality;
    }

    if (_extractedText == null) {
      await _extractText();
    } else {
      _autoAttachDocToChat();
    }
  }

  void _autoAttachDocToChat() {
    if (_extractedText != null && _extractedText!.isNotEmpty) {
      ref
          .read(chatControllerProvider.notifier)
          .attachDocument(
            name: widget.doc.displayName,
            text: _extractedText!,
            path: widget.doc.localPath,
            documentId: widget.doc.id,
            size: widget.doc.fileSize,
            pages: _ocrBundle?.totalPages,
          );
    }
  }

  Future<void> _extractText({bool forceReprocess = false}) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _progressStatus = 'Reading document structure...';
      _progressFraction = 0.05;
    });

    try {
      final service = ref.read(pdfAiStudyServiceProvider);
      final bundle = await service.extractBundle(
        widget.doc.localPath,
        docId: widget.doc.id,
        docTitle: widget.doc.displayName,
        forceReprocess: forceReprocess,
        onProgress: (status, frac) {
          if (mounted) {
            setState(() {
              _progressStatus = status;
              _progressFraction = frac;
            });
          }
        },
      );

      _ocrBundle = bundle;
      _extractedText = bundle.fullText;
      _documentQuality = bundle.overallQuality;
      _autoAttachDocToChat();

      // Auto-index PDF pages into RAG vector store in background when online & authenticated
      if (SupabaseService.instance.configured &&
          SupabaseService.instance.userId != null) {
        ref
            .read(ragServiceProvider)
            .ingestDocument(
              documentId: widget.doc.id,
              bundle: bundle,
              documentTitle: widget.doc.displayName,
              fileName: widget.doc.filename,
            )
            .catchError((e) {
              debugPrint('[AutoIngest] Background ingestion note: $e');
            });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e is PdfExtractionException ? e.message : 'Could not extract text from this PDF. Ensure the file contains readable notes.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _progressStatus = '';
          _progressFraction = 0.0;
        });
      }
    }
  }

  Future<void> _generateFlashcards() async {
    final text = (_extractedText != null && _extractedText!.trim().isNotEmpty)
        ? _extractedText!
        : 'Chemistry Study Material for ${widget.doc.displayName}';

    setState(() {
      _loading = true;
      _errorMessage = null;
      _progressStatus = 'Creating $_flashcardCount Chemistry flashcards...';
    });

    try {
      final flashcardService = ref.read(flashcardServiceProvider);
      final cards = await GeminiFlashcardService().generate(
        sourceText: text,
        count: _flashcardCount,
        topic: widget.doc.displayName,
        bundle: _ocrBundle,
      );

      final set = await flashcardService.saveGeneratedSet(
        title: widget.doc.displayName,
        sourceFileName: widget.doc.displayName,
        topic: widget.doc.displayName,
        generated: cards,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => SmartFlashcardsStudyScreen(setId: set.id),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not create flashcards. Please check connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Study with ChemBuddy',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              Text(
                widget.doc.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            SpringPress(
              child: IconButton(
                icon: Icon(
                  Icons.visibility_outlined,
                  color: AppColors.adaptive(context, AppColors.blue),
                ),
                tooltip: 'Read PDF',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => PdfReaderScreen(doc: widget.doc),
                    ),
                  );
                },
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 18),
                text: 'Ask PDF AI',
              ),
              Tab(
                icon: Icon(Icons.style_outlined, size: 18),
                text: 'Smart Flashcards',
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_loading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF18122B).withValues(alpha: 0.92),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClaudeThinkingIndicator(
                      thoughts: _progressStatus.isNotEmpty
                          ? [
                              _progressStatus,
                              ...ClaudeThinkingMicrocopy.summary,
                            ]
                          : ClaudeThinkingMicrocopy.summary,
                      isCard: false,
                      showSparkle: true,
                      fontSize: 12.5,
                    ),
                    if (_progressFraction > 0.0 && _progressFraction < 1.0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progressFraction,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHigh,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.adaptive(
                    context,
                    AppColors.danger,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.adaptive(
                      context,
                      AppColors.danger,
                    ).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.adaptive(context, AppColors.danger),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppColors.adaptive(context, AppColors.danger),
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    SpringPress(
                      child: TextButton(
                        onPressed: () => _extractText(forceReprocess: true),
                        child: Text(
                          'Try Again',
                          style: TextStyle(
                            color: AppColors.adaptive(
                              context,
                              AppColors.danger,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _buildOcrStatusBanner(),
              _buildQuickActionMenu(),
            ],

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildAskAiTab(), _buildFlashcardsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOcrStatusBanner() {
    final pageCount = _ocrBundle?.pageCount ?? 1;
    final formulaCount = _ocrBundle?.allDetectedFormulas.length ?? 0;

    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (_documentQuality) {
      case PageQuality.digitalText:
        icon = Icons.text_snippet_outlined;
        color = AppColors.adaptive(context, AppColors.accentCyan);
        title = 'Digital Text PDF (Native Text)';
        subtitle = '$pageCount Pages · Instant Text Parsing';
        break;
      case PageQuality.scannedImage:
        icon = Icons.document_scanner_outlined;
        color = Theme.of(context).colorScheme.primary;
        title = 'Scanned Document (OCR Processed)';
        subtitle =
            '$pageCount Pages · Chemistry Normalized${formulaCount > 0 ? ' · $formulaCount Formulas Detected' : ''}';
        break;
      case PageQuality.handwritten:
        icon = Icons.draw_outlined;
        color = Theme.of(context).colorScheme.primary;
        title = 'Handwritten Notes (OCR Processed)';
        subtitle =
            '$pageCount Pages · Chemistry Normalized${formulaCount > 0 ? ' · $formulaCount Formulas Detected' : ''}';
        break;
      case PageQuality.mixed:
        icon = Icons.auto_stories_outlined;
        color = AppColors.adaptive(context, AppColors.accentGold);
        title = 'Mixed PDF (Native Text + OCR)';
        subtitle = '$pageCount Pages · Hybrid OCR Processing';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.readableText(context, color),
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          if (_ocrBundle != null && _ocrBundle!.pages.isNotEmpty)
            SpringPress(
              child: TextButton.icon(
                onPressed: _showExtractedPagesSheet,
                icon: Icon(
                  Icons.visibility_outlined,
                  size: 13,
                  color: AppColors.adaptive(context, AppColors.blue),
                ),
                label: Text(
                  'Pages',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.adaptive(context, AppColors.blue),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          SpringPress(
            child: IconButton(
              onPressed: _loading
                  ? null
                  : () => _extractText(forceReprocess: true),
              tooltip: 'Re-scan Document',
              icon: Icon(
                Icons.refresh,
                size: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionMenu() {
    final actions = [
      (
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Ask PDF AI',
        color: Theme.of(context).colorScheme.primary,
        onTap: () => _tabController.animateTo(0),
      ),
      (
        icon: Icons.quiz_outlined,
        label: 'Smart Quiz',
        color: AppColors.adaptive(context, AppColors.accentGold),
        onTap: () => PdfQuizSetupDialog.show(
          context,
          documentTitle: widget.doc.displayName,
          docId: widget.doc.id,
          doc: widget.doc,
        ),
      ),
      (
        icon: Icons.style_outlined,
        label: 'Smart Flashcards',
        color: AppColors.adaptive(context, AppColors.accentCyan),
        onTap: () => _tabController.animateTo(1),
      ),
      (
        icon: Icons.auto_stories_outlined,
        label: 'Summarize',
        color: Theme.of(context).colorScheme.primary,
        onTap: () {
          _tabController.animateTo(0);
          _autoAttachDocToChat();
          ref
              .read(chatControllerProvider.notifier)
              .sendMessage(
                'Provide a clear, structured summary of the key chemistry concepts, equations, and topics in this document.',
              );
        },
      ),
      (
        icon: Icons.school_outlined,
        label: 'Exam Revision',
        color: AppColors.adaptive(context, AppColors.statusWarning),
        onTap: () {
          _tabController.animateTo(0);
          _autoAttachDocToChat();
          ref
              .read(chatControllerProvider.notifier)
              .sendMessage(
                'Extract high-yield 2-mark definitions and 5-mark explanation questions with model answers from this document for university exam revision.',
              );
        },
      ),
      (
        icon: Icons.menu_book_rounded,
        label: 'Read Document',
        color: AppColors.adaptive(context, AppColors.blue),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => PdfReaderScreen(doc: widget.doc),
            ),
          );
        },
      ),
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final a = actions[index];
          return SpringPress(
            child: InkWell(
              onTap: a.onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: a.color.withValues(alpha: 0.3),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(a.icon, size: 14, color: a.color),
                    const SizedBox(width: 6),
                    Text(
                      a.label,
                      style: TextStyle(
                        color: AppColors.readableText(context, a.color),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showExtractedPagesSheet() {
    final pages = _ocrBundle?.pages ?? const [];
    if (pages.isEmpty) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Extracted Document Pages',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${pages.length} Pages',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Page-by-page OCR text with chemistry formula normalization for ${widget.doc.displayName}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        final page = pages[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlowCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Page ${page.pageNumber}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${page.quality.icon} ${page.quality.label}',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (page.confidence < 1.0)
                                      Text(
                                        'OCR Confidence: ${(page.confidence * 100).toInt()}%',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                  ],
                                ),
                                if (page.detectedFormulas.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: page.detectedFormulas
                                        .take(6)
                                        .map(
                                          (f) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              f,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                    ),
                                  ),
                                  child: Text(
                                    page.cleanedText.isNotEmpty
                                        ? page.cleanedText
                                        : '(No text extracted for this page)',
                                    maxLines: 8,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 11.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: SpringPress(
                                    child: TextButton.icon(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (_) => PdfReaderScreen(
                                              doc: widget.doc,
                                              initialPage: page.pageNumber,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: Icon(
                                        Icons.open_in_new,
                                        size: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      label: Text(
                                        'Jump to Page ${page.pageNumber} in Reader',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 1. ASK AI TAB
  Widget _buildAskAiTab() {
    final chatState = ref.watch(chatControllerProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Strict Grounding Active: ${widget.doc.displayName}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            children: [
              GlowCard(
                child: Text(
                  '💡 Ask any question about this PDF. ChemBuddy uses this document as the single authoritative source of truth. If a concept is not present in these notes, ChemBuddy will inform you clearly.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...chatState.messages.map((m) {
                final isUser = m.role == 'user';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                    ),
                    child: GlowCard(
                      borderColor: isUser
                          ? Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.6)
                          : Theme.of(context).colorScheme.outlineVariant,
                      padding: const EdgeInsets.all(12),
                      child: isUser
                          ? Text(
                              m.content,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 13.5,
                                height: 1.35,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ChemistryMarkdownView(
                                  text: m.content,
                                  textStyle: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    fontSize: 13.5,
                                    height: 1.45,
                                  ),
                                  selectable: true,
                                ),
                                ...() {
                                  // Extract page citations like "Page 3", "[Page 3]", "p. 3", "(p. 3)"
                                  final pageMatches = RegExp(
                                    r'(?:\[|\()?(?:Page|p\.)\s*(\d+)(?:\]|\))?',
                                    caseSensitive: false,
                                  ).allMatches(m.content);
                                  final pageNums = <int>{};
                                  for (final match in pageMatches) {
                                    final p = int.tryParse(match.group(1)!);
                                    if (p != null) {
                                      pageNums.add(p);
                                    }
                                  }
                                  if (pageNums.isEmpty) {
                                    return const <Widget>[];
                                  }
                                  return [
                                    const SizedBox(height: 8),
                                    Divider(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                      height: 12,
                                    ),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: pageNums.map((pn) {
                                        return SpringPress(
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      PdfReaderScreen(
                                                        doc: widget.doc,
                                                        initialPage: pn,
                                                      ),
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .bookmark_added_rounded,
                                                    size: 12,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Jump to Page $pn',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ];
                                }(),
                              ],
                            ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _askController,
                  decoration: const InputDecoration(
                    hintText: 'Ask a question about this PDF...',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SpringPress(
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                  ),
                  onPressed: () {
                    final q = _askController.text.trim();
                    if (q.isEmpty) {
                      return;
                    }
                    _askController.clear();
                    _autoAttachDocToChat();
                    ref.read(chatControllerProvider.notifier).sendMessage(q);
                  },
                  icon: Icon(
                    Icons.send_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. FLASHCARDS TAB
  Widget _buildFlashcardsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        const ContextualHintCard(
          hintKey: 'flashcards_hint',
          title: 'Active Spaced Recall 🃏',
          message: 'Generate high-yield MSc chemistry flashcards grounded strictly in this document.',
        ),

        GlowCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generate Smart Flashcard Deck',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Select number of cards to synthesize from this PDF:',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [10, 15, 20].map((n) {
                  final active = _flashcardCount == n;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SpringPress(
                      child: ChoiceChip(
                        label: Text('$n Cards'),
                        selected: active,
                        onSelected: _loading
                            ? null
                            : (_) => setState(() => _flashcardCount = n),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const ClaudeThinkingIndicator(
                  thoughts: ClaudeThinkingMicrocopy.flashcards,
                  isCard: true,
                  thinkingHeader: 'Synthesizing Flashcards',
                )
              else
                SpringPress(
                  child: ElevatedButton.icon(
                    onPressed: _generateFlashcards,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      foregroundColor: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.style),
                    label: Text(
                      'Generate & Study Deck ($_flashcardCount Cards)',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
