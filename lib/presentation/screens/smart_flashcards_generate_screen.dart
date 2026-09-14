import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/title_cleaner.dart';
import '../../core/widgets/claude_loading_text.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/pdf_ocr_models.dart';
import '../../data/services/gemini_flashcard_service.dart';
import '../../data/services/ocr/handwritten_notes_ocr_pipeline.dart';
import '../../data/services/pdf_text_extraction_service.dart';
import '../../data/services/pdf_text_utils.dart';
import '../providers/app_providers.dart';
import 'smart_flashcards_study_screen.dart';

enum FlashcardSourceMode { pdf, handwriting }

class SmartFlashcardsGenerateScreen extends ConsumerStatefulWidget {
  const SmartFlashcardsGenerateScreen({super.key, this.prefilledTopic, this.prefilledText});
  final String? prefilledTopic;
  final String? prefilledText;

  @override
  ConsumerState<SmartFlashcardsGenerateScreen> createState() => _SmartFlashcardsGenerateScreenState();
}

class _SmartFlashcardsGenerateScreenState extends ConsumerState<SmartFlashcardsGenerateScreen> {
  FlashcardSourceMode mode = FlashcardSourceMode.handwriting;
  String? pdfFileName;
  String? pdfFilePath;
  final List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();

  int count = 10;
  String stage = '';
  double progress = 0.0;
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledText != null) {
      pdfFileName = widget.prefilledTopic ?? 'Chat Response';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Smart Flashcards', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          if (widget.prefilledText == null) ...[
            const Text('Choose Note Format', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 6),
            const Text(
              'Upload handwritten notes (camera/gallery) or a lecture PDF.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),

            // Source Mode Selector
            Row(
              children: [
                Expanded(
                  child: _buildModeTab(
                    title: 'Handwritten Notes',
                    subtitle: 'Camera / Photos',
                    icon: Icons.draw_rounded,
                    selected: mode == FlashcardSourceMode.handwriting,
                    onTap: busy ? null : () => setState(() => mode = FlashcardSourceMode.handwriting),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModeTab(
                    title: 'Digital / PDF',
                    subtitle: 'Textbook / Slides',
                    icon: Icons.picture_as_pdf_rounded,
                    selected: mode == FlashcardSourceMode.pdf,
                    onTap: busy ? null : () => setState(() => mode = FlashcardSourceMode.pdf),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Handwritten Mode UI
            if (mode == FlashcardSourceMode.handwriting) ...[
              GlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.purpleBright, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Chemistry Handwriting OCR',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                        if (_imagePaths.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.purpleBright.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_imagePaths.length} ${_imagePaths.length == 1 ? "page" : "pages"}',
                              style: const TextStyle(
                                color: AppColors.purpleBright,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Deciphers chemical equations, reaction mechanisms, subscripts/charges (e.g. H₂SO₄, [Fe(CN)₆]⁴⁻, ⇌, Δ), and definitions from camera or gallery notes.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                    ),
                    const SizedBox(height: 14),

                    // Action Buttons: Camera & Gallery
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bg1,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.borderHighlight),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: busy ? null : _snapPhoto,
                            icon: const Icon(Icons.photo_camera_rounded, size: 18, color: AppColors.accentCyan),
                            label: const Text('Scan Page', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bg1,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.borderHighlight),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: busy ? null : _pickGalleryImages,
                            icon: const Icon(Icons.photo_library_rounded, size: 18, color: AppColors.purpleBright),
                            label: const Text('Add Photos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),

                    // Selected Pages List
                    if (_imagePaths.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.borderSubtle),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Page Sequence (Preserved)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                          ),
                          TextButton(
                            onPressed: busy ? null : () => setState(() => _imagePaths.clear()),
                            child: const Text('Clear All', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      for (var i = 0; i < _imagePaths.length; i++)
                        _buildPageThumbnailTile(i),
                    ],
                  ],
                ),
              ),
            ],

            // PDF Mode UI
            if (mode == FlashcardSourceMode.pdf) ...[
              GlowCard(
                onTap: busy ? null : _pickPdf,
                child: Row(
                  children: [
                    const Icon(Icons.upload_file, color: AppColors.purpleBright, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pdfFileName == null ? 'Upload Lecture PDF' : 'Selected PDF:',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (pdfFileName != null)
                            Text(
                              pdfFileName!,
                              style: const TextStyle(color: AppColors.accentCyan, fontSize: 12.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (pdfFileName != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                        onPressed: busy ? null : () => setState(() {
                          pdfFileName = null;
                          pdfFilePath = null;
                        }),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],

          if (widget.prefilledText != null) ...[
            const Text('Source', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            GlowCard(
              child: Text(
                'Topic: ${widget.prefilledTopic ?? 'Chemistry Notes'}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 20),
          ],

          const Text('Number of Flashcards', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'We rank and pick the highest-yield exam concepts.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final n in [5, 10, 20])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$n cards'),
                    selected: count == n,
                    onSelected: busy ? null : (_) => setState(() => count = n),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Loading stage and progress
          if (stage.isNotEmpty) ...[
            ClaudeThinkingIndicator(
              thoughts: ClaudeThinkingMicrocopy.flashcards,
              isCard: true,
              thinkingHeader: stage,
            ),
            const SizedBox(height: 12),
          ],

          if (error != null) ...[
            GlowCard(
              borderColor: AppColors.danger.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.danger, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      error!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          PrimaryButton(
            label: error != null ? 'Retry Generating' : 'Generate Smart Flashcards',
            loading: busy,
            onPressed: busy ? null : _create,
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.purpleBright.withValues(alpha: 0.15) : AppColors.bg1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.purpleBright : AppColors.borderSubtle,
            width: selected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.purpleBright : AppColors.textMuted, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: selected ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageThumbnailTile(int index) {
    final path = _imagePaths[index];
    final file = File(path);
    final name = path.split(Platform.pathSeparator).last;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              file,
              width: 38,
              height: 38,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 38,
                height: 38,
                color: Colors.grey.shade900,
                child: const Icon(Icons.image, size: 20, color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                ),
                Text(
                  name,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.danger),
            onPressed: busy
                ? null
                : () {
                    setState(() {
                      _imagePaths.removeAt(index);
                    });
                  },
          ),
        ],
      ),
    );
  }

  Future<void> _snapPhoto() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (photo == null) return;
      setState(() {
        _imagePaths.add(photo.path);
        error = null;
      });
    } catch (e) {
      setState(() => error = 'Could not access camera ($e).');
    }
  }

  Future<void> _pickGalleryImages() async {
    try {
      final photos = await _picker.pickMultiImage(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (photos.isEmpty) return;
      setState(() {
        _imagePaths.addAll(photos.map((p) => p.path));
        error = null;
      });
    } catch (e) {
      setState(() => error = 'Could not access gallery ($e).');
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf']);
    final file = result?.files.single;
    if (file?.path == null) return;
    setState(() {
      pdfFileName = file!.name;
      pdfFilePath = file.path;
      error = null;
    });
  }

  Future<void> _create() async {
    final text = widget.prefilledText;
    final isHwMode = mode == FlashcardSourceMode.handwriting && widget.prefilledText == null;

    if (isHwMode && _imagePaths.isEmpty) {
      setState(() => error = 'Please capture or select at least one page of your handwritten notes.');
      return;
    }

    if (!isHwMode && pdfFilePath == null && text == null) {
      setState(() => error = 'Please choose a lecture PDF or notes first.');
      return;
    }

    final service = ref.read(flashcardServiceProvider);
    setState(() {
      busy = true;
      error = null;
      stage = isHwMode ? 'Preparing handwritten pages...' : 'Reading notes...';
      progress = 0.05;
    });

    try {
      String sourceText = '';
      DocumentOcrBundle? bundle;

      if (text != null && text.trim().isNotEmpty) {
        sourceText = text;
      } else if (isHwMode) {
        // Run dedicated handwriting OCR pipeline across all pages in order
        final pipeline = HandwrittenNotesOcrPipeline();
        final rawTitle = 'Handwritten Chemistry Notes';

        bundle = await pipeline.processHandwrittenImages(
          imagePaths: _imagePaths,
          docTitle: rawTitle,
          onProgress: (status, p) {
            if (mounted) {
              setState(() {
                stage = status;
                progress = p;
              });
            }
          },
        );

        sourceText = bundle.fullText;
      } else {
        sourceText = await PdfTextExtractionService.instance.extractFromPath(
          pdfFilePath!,
          onProgress: (status) {
            if (mounted) setState(() => stage = status);
          },
        );
      }

      final cleaned = cleanupExtractedText(sourceText);
      if (cleaned.length < 25) {
        throw StateError(
          isHwMode
              ? 'Could not recognize enough clear text or chemical formulas from the handwritten photos. Please ensure good lighting, hold the camera steady, and retry.'
              : 'The selected PDF contains very little readable text. Please choose a text-based document or notes.',
        );
      }

      setState(() => stage = 'Synthesizing exam-quality flashcards...');
      final rawTopic = widget.prefilledTopic ??
          (isHwMode
              ? 'Handwritten Chemistry Notes'
              : (pdfFileName != null ? cleanStudyMaterialTitle(pdfFileName!) : 'Chemistry'));
      final topic = cleanStudyMaterialTitle(rawTopic);

      final cards = await GeminiFlashcardService().generate(
        sourceText: cleaned,
        count: count,
        topic: topic,
        bundle: bundle,
        isHandwritten: isHwMode,
        imagePaths: isHwMode ? _imagePaths : const [],
      );

      setState(() => stage = 'Saving your new deck...');
      final set = await service.saveGeneratedSet(
        title: topic,
        sourceFileName: cleanStudyMaterialTitle(isHwMode ? 'Handwritten Notes (${_imagePaths.length} pages)' : (pdfFileName ?? 'Chemistry Notes')),
        topic: topic,
        generated: cards,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => SmartFlashcardsStudyScreen(setId: set.id)),
      );
    } catch (e) {
      String msg;
      if (e is StateError) {
        msg = e.message;
      } else if (e is PdfExtractionException) {
        msg = e.message;
      } else {
        msg = 'Could not generate flashcards ($e). Please retry.';
      }
      setState(() => error = msg);
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          stage = '';
          progress = 0.0;
        });
      }
    }
  }
}
