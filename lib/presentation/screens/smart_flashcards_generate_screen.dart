import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/title_cleaner.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/molecule_loader.dart';
import '../../data/services/gemini_flashcard_service.dart';
import '../../data/services/pdf_text_extraction_service.dart';
import '../../data/services/pdf_text_utils.dart';
import '../providers/app_providers.dart';
import 'smart_flashcards_study_screen.dart';

class SmartFlashcardsGenerateScreen extends ConsumerStatefulWidget {
  const SmartFlashcardsGenerateScreen({super.key, this.prefilledTopic, this.prefilledText});
  final String? prefilledTopic;
  final String? prefilledText;

  @override
  ConsumerState<SmartFlashcardsGenerateScreen> createState() => _SmartFlashcardsGenerateScreenState();
}

class _SmartFlashcardsGenerateScreenState extends ConsumerState<SmartFlashcardsGenerateScreen> {
  String? fileName;
  String? filePath;
  int count = 10;
  String stage = '';
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledText != null) {
      fileName = widget.prefilledTopic ?? 'Chat Response';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, title: const Text('Smart Flashcards')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          if (widget.prefilledText == null) ...[
            const Text('Choose your source', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            GlowCard(
              onTap: busy ? null : _pick,
              child: Row(
                children: [
                  const Icon(Icons.upload_file, color: AppColors.purpleBright),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fileName == null ? 'Upload PDF' : 'Selected file:\n$fileName',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (widget.prefilledText != null) ...[
            const Text('Source', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            GlowCard(
              child: Text(
                'Chat Topic: ${widget.prefilledTopic ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 20),
          ],
          const Text('Number of flashcards', style: TextStyle(fontWeight: FontWeight.w800)),
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
          if (stage.isNotEmpty) ...[
            const GlowCard(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              borderColor: AppColors.borderSubtle,
              child: Center(
                child: BenzeneMoleculeLoader(
                  size: 48,
                  messages: ChemistryMicrocopy.flashcards,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (error != null) ...[
            GlowCard(
              borderColor: AppColors.danger.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          PrimaryButton(
            label: error != null ? 'Retry Generating' : 'Create Flashcards',
            loading: busy,
            onPressed: busy ? null : _create,
          ),
        ],
      ),
    );
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf']);
    final file = result?.files.single;
    if (file?.path == null) return;
    setState(() {
      fileName = file!.name;
      filePath = file.path;
      error = null;
    });
  }

  Future<void> _create() async {
    final text = widget.prefilledText;
    final path = filePath;
    if (path == null && text == null) {
      setState(() => error = 'Choose a PDF of your chemistry notes first.');
      return;
    }
    final service = ref.read(flashcardServiceProvider);
    setState(() {
      busy = true;
      error = null;
      stage = 'Reading notes...';
    });
    try {
      String sourceText;
      if (text != null && text.trim().isNotEmpty) {
        sourceText = text;
      } else {
        sourceText = await PdfTextExtractionService.instance.extractFromPath(
          path!,
          onProgress: (status) {
            if (mounted) setState(() => stage = status);
          },
        );
      }

      final cleaned = cleanupExtractedText(sourceText);
      if (cleaned.length < 30) {
        throw StateError(
          'The selected PDF contains very little readable text or appears to be a scanned image without OCR. Please choose a text-based PDF or notes.',
        );
      }

      setState(() => stage = 'Synthesizing chemistry flashcards...');
      final rawTopic = widget.prefilledTopic ?? (fileName != null ? cleanStudyMaterialTitle(fileName!) : 'Chemistry');
      final topic = cleanStudyMaterialTitle(rawTopic);
      
      final cards = await GeminiFlashcardService().generate(
        sourceText: cleaned,
        count: count,
        topic: topic,
      );

      setState(() => stage = 'Saving your new deck...');
      final set = await service.saveGeneratedSet(
        title: topic,
        sourceFileName: cleanStudyMaterialTitle(fileName ?? 'Chemistry Notes'),
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
        });
      }
    }
  }
}
