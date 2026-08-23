import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
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
              for (final n in [10, 20])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$n'),
                    selected: count == n,
                    onSelected: busy ? null : (_) => setState(() => count = n),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (stage.isNotEmpty) ...[
            GlowCard(
              child: Row(
                children: [
                  const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purpleBright)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(stage, style: const TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(error!, style: const TextStyle(color: AppColors.danger)),
            ),
          PrimaryButton(
            label: 'Create Flashcards',
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
      stage = 'Checking connection.';
    });
    try {
      if (!await service.isOnline) {
        throw StateError('Internet connection required to generate new AI flashcards.');
      }
      
      String sourceText;
      if (text != null) {
        sourceText = text;
      } else {
        setState(() => stage = 'Analyzing your notes.');
        sourceText = await PdfTextExtractionService.instance.extractFromPath(path!);
      }
      
      final chunks = chunkNotes(sourceText);
      if (chunks.isEmpty) {
        throw StateError('Not enough readable text to generate flashcards.');
      }
      setState(() => stage = 'Creating Chemistry questions.');
      final topic = widget.prefilledTopic ?? p.basenameWithoutExtension(fileName ?? 'Chemistry');
      final cards = await GeminiFlashcardService().generate(sourceText: sourceText, count: count, topic: topic);
      setState(() => stage = 'Organizing flashcards.');
      setState(() => stage = 'Saving your flashcards.');
      final set = await service.saveGeneratedSet(
        title: topic,
        sourceFileName: fileName ?? 'notes.pdf',
        topic: topic,
        generated: cards,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => SmartFlashcardsStudyScreen(setId: set.id)),
      );
    } catch (e) {
      setState(() => error = e is StateError || e is PdfExtractionException ? e.toString() : 'Could not create flashcards. Please try another PDF.');
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
