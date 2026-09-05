import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/chemistry_text_formatter.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/models/models.dart';
import '../../data/models/library_models.dart';
import '../../data/models/rag_models.dart';
import '../../data/services/pdf_text_extraction_service.dart';
import '../../data/services/pdf_text_utils.dart';
import '../../data/services/reaction_mechanism_service.dart';
import '../providers/app_providers.dart';
import '../providers/rag_providers.dart';
import '../widgets/reaction_mechanisms_card.dart';
import '../widgets/viva_practice_dialog.dart';
import 'pdf_quiz_screen.dart';
import 'pdf_study_hub_screen.dart';
import 'reaction_mechanism_screen.dart';
import 'smart_flashcards_generate_screen.dart';
import 'smart_flashcards_study_screen.dart';
import '../../data/models/smart_flashcard.dart';
import '../../core/widgets/claude_loading_text.dart';


enum ChemBuddyAiMode {
  concept,
  exam2M,
  exam5M,
  exam10M,
  mechanisms,
}

class AskChemBuddyScreen extends ConsumerStatefulWidget {
  const AskChemBuddyScreen({super.key});

  @override
  ConsumerState<AskChemBuddyScreen> createState() => _AskChemBuddyScreenState();
}

class _AskChemBuddyScreenState extends ConsumerState<AskChemBuddyScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  ChemBuddyAiMode _currentMode = ChemBuddyAiMode.concept;
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _extracting = false;
  String _extractingStatus = 'Reading document...';
  String? _lastSentQuestion;


  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (val) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (mounted) setState(() {});
    } catch (_) {
      _speechEnabled = false;
    }
  }

  Future<void> _startListening() async {
    AppHaptics.tap();
    if (!_speechEnabled) {
      final available = await _speech.initialize(
        onError: (val) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.danger,
              content: Text('Microphone permission or speech service is unavailable on this device.'),
            ),
          );
        }
        return;
      }
      _speechEnabled = true;
    }

    if (mounted) setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          });
        }
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _stopListening() async {
    AppHaptics.tap();
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _sendMessage([String? textOverride]) {
    final rawText = textOverride ?? _controller.text.trim();
    if (rawText.isEmpty) return;

    if (_currentMode == ChemBuddyAiMode.mechanisms) {
      final hit = ReactionMechanismService.instance.find(rawText);
      if (hit != null) {
        _lastSentQuestion = rawText;
        if (textOverride == null) _controller.clear();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReactionMechanismsScreen(initialReactionId: hit.id),
          ),
        );
        return;
      }
    }

    String? modelPrompt;
    if (_currentMode == ChemBuddyAiMode.concept) {
      modelPrompt = '[Explain in Academic Concept Mode: Focus on deep understanding, physical/chemical intuition, orbital or thermodynamic principles, and clear chemical notation]: $rawText';
    } else if (_currentMode == ChemBuddyAiMode.exam2M) {
      modelPrompt = '[Format as a concise 2-Mark University Exam Answer: Provide 1) Definition (1-2 sentences), 2) Balanced Reaction or Equation, 3) Key Condition/Nuance. DO NOT over-explain]: $rawText';
    } else if (_currentMode == ChemBuddyAiMode.exam5M) {
      modelPrompt = '''[Format as a structured 5-Mark MSc Chemistry University Rubric:
- Definition & Statement of Principle
- Main Explanation & Driving Force
- Balanced Chemical Reaction / Equation
- Step-by-Step Mechanism / Intermediates
- Important Points & Synthetic Applications
- Concise Conclusion]: $rawText''';
    } else if (_currentMode == ChemBuddyAiMode.exam10M) {
      modelPrompt = '''[Format as a comprehensive 10-Mark MSc Chemistry Exam Answer:
1. Definition & Core Concept
2. Chemical Principle & Thermodynamics
3. Reaction Equation & Conditions
4. Step-by-Step Reaction Mechanism with Curved Arrow Notes
5. Transition States & Intermediate Stability
6. Concrete Laboratory Examples
7. Regio- & Stereoselectivity
8. Synthetic & Industrial Applications
9. Limitations & Side Reactions
10. Academic Conclusion]: $rawText''';
    } else if (_currentMode == ChemBuddyAiMode.mechanisms) {
      modelPrompt = 'Explain the full stepwise reaction mechanism, curved arrow electron displacement, intermediates, and driving force for: $rawText';
    }

    _lastSentQuestion = rawText;
    ref.read(chatControllerProvider.notifier).sendMessage(rawText, modelPrompt: modelPrompt);
    if (textOverride == null) _controller.clear();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildModeBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _AiModeChip(
              icon: Icons.lightbulb_outline,
              label: 'Concept',
              selected: _currentMode == ChemBuddyAiMode.concept,
              onTap: () => setState(() => _currentMode = ChemBuddyAiMode.concept),
            ),
            const SizedBox(width: 8),
            _AiModeChip(
              icon: Icons.edit_note,
              label: '2M Answer',
              selected: _currentMode == ChemBuddyAiMode.exam2M,
              onTap: () => setState(() => _currentMode = ChemBuddyAiMode.exam2M),
            ),
            const SizedBox(width: 8),
            _AiModeChip(
              icon: Icons.edit_note,
              label: '5M Answer',
              selected: _currentMode == ChemBuddyAiMode.exam5M,
              onTap: () => setState(() => _currentMode = ChemBuddyAiMode.exam5M),
            ),
            const SizedBox(width: 8),
            _AiModeChip(
              icon: Icons.article_outlined,
              label: '10M Answer',
              selected: _currentMode == ChemBuddyAiMode.exam10M,
              onTap: () => setState(() => _currentMode = ChemBuddyAiMode.exam10M),
            ),
            const SizedBox(width: 8),
            _AiModeChip(
              icon: Icons.record_voice_over_outlined,
              label: 'Viva Practice',
              selected: false,
              onTap: () => VivaPracticeDialog.show(context),
            ),
            const SizedBox(width: 8),
            _AiModeChip(
              icon: Icons.science_outlined,
              label: '⚗️ Mechanisms',
              selected: _currentMode == ChemBuddyAiMode.mechanisms,
              onTap: () => setState(() => _currentMode = ChemBuddyAiMode.mechanisms),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startQuizForMessage(AiMessage msg) async {
    AppHaptics.tap();
    final rawLines = msg.content.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final firstLine = rawLines.firstWhere(
      (l) => !l.startsWith('#') && l.length < 60,
      orElse: () => 'Chemistry Topic',
    ).replaceAll(RegExp(r'^[#*\s]+'), '');
    final topicTitle = ChemistryTextFormatter.format(firstLine.isEmpty ? 'Chemistry Topic' : firstLine);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          child: ClaudeThinkingIndicator(
            thoughts: [
              'Generating Chemistry Quiz on "$topicTitle"...',
              ...ClaudeThinkingMicrocopy.quiz,
            ],
            isCard: true,
            thinkingHeader: 'Creating Quiz',
          ),
        ),
      ),
    );

    try {
      final quiz = await ref.read(pdfAiStudyServiceProvider).generateQuiz(
        sourceText: msg.content,
        documentTitle: topicTitle,
        count: 10,
      );

      if (mounted) {
        Navigator.pop(context); // close loading dialog
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => PdfQuizScreen(quiz: quiz, docName: topicTitle),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate quiz: $e')),
        );
      }
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final path = file.path;
      if (path == null || path.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access that PDF path on this device.')),
          );
        }
        return;
      }

      setState(() {
        _extracting = true;
        _extractingStatus = 'Reading document structure...';
      });

      final text = await PdfTextExtractionService.instance.extractFromPath(
        path,
        onProgress: (status) {
          if (mounted) setState(() => _extractingStatus = status);
        },
      );

      ref.read(chatControllerProvider.notifier).attachDocument(
        name: file.name,
        text: text,
        path: path,
        size: file.size,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Attached: ${file.name}\nChemBuddy is ready to answer questions from it.')),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(e is PdfExtractionException ? e.message : 'Could not read PDF text. Make sure it contains readable text.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);

    return HexBackground(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            children: const [
              Icon(Icons.auto_awesome, color: AppColors.purpleBright, size: 22),
              SizedBox(width: 8),
              Text('Ask ChemBuddy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: AppColors.purpleBright),
              tooltip: 'Attach PDF Study Material',
              onPressed: _extracting ? null : _pickPdf,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
              tooltip: 'Clear Chat',
              onPressed: () => ref.read(chatControllerProvider.notifier).clearChat(),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildModeBar(),

            // Extracting banner
            if (_extracting)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ClaudeThinkingIndicator(
                  thoughts: [
                    _extractingStatus.isNotEmpty ? _extractingStatus : 'Parsing PDF study notes...',
                    'Extracting chemical formulas & syllabus chapters...',
                    'Cataloging reaction mechanisms & key definitions...',
                  ],
                  isCard: true,
                  thinkingHeader: 'Reading Notes',
                ),
              ),

            // Active Attached PDF Banner & Quick Actions
            if (chatState.hasActiveDocument && !_extracting)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: GlowCard(
                  borderColor: AppColors.purpleBright.withValues(alpha: 0.4),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.purpleBright, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Based on: ${chatState.activeDocumentName ?? "Study Material"}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                                  ),
                                  Row(
                                    children: [
                                      const Text('Ready 🟢', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                                      if (chatState.activeDocumentSize != null)
                                        Text(' · ${_formatSize(chatState.activeDocumentSize)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          if (chatState.activeDocumentPath != null)
                            IconButton(
                              icon: const Icon(Icons.school, size: 18, color: AppColors.purpleBright),
                              tooltip: 'Open Study Hub',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => PdfStudyHubScreen(
                                      doc: PdfDoc(
                                        id: const Uuid().v4(),
                                        filename: chatState.activeDocumentName ?? 'document.pdf',
                                        displayName: chatState.activeDocumentName ?? 'Study Material',
                                        subjectId: '',
                                        localPath: chatState.activeDocumentPath!,
                                        dateAdded: DateTime.now(),
                                        fileSize: chatState.activeDocumentSize ?? 0,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                            tooltip: 'Remove Attached PDF',
                            onPressed: () => ref.read(chatControllerProvider.notifier).detachDocument(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _ActionChip(
                              icon: Icons.local_fire_department_outlined,
                              label: 'Important Topics',
                              onTap: () {
                                if (chatState.activeDocumentPath != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => PdfStudyHubScreen(
                                        doc: PdfDoc(
                                          id: const Uuid().v4(),
                                          filename: chatState.activeDocumentName ?? 'document.pdf',
                                          displayName: chatState.activeDocumentName ?? 'Study Material',
                                          subjectId: '',
                                          localPath: chatState.activeDocumentPath!,
                                          dateAdded: DateTime.now(),
                                          fileSize: chatState.activeDocumentSize ?? 0,
                                        ),
                                        initialTab: 0,
                                        initialExtractedText: chatState.activeDocumentText,
                                      ),
                                    ),
                                  );
                                } else {
                                  _sendMessage('Extract and rank the most important topics from this study material with explanations.');
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            _ActionChip(
                              icon: Icons.summarize_outlined,
                              label: 'Summarize',
                              onTap: () {
                                if (chatState.activeDocumentPath != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => PdfStudyHubScreen(
                                        doc: PdfDoc(
                                          id: const Uuid().v4(),
                                          filename: chatState.activeDocumentName ?? 'document.pdf',
                                          displayName: chatState.activeDocumentName ?? 'Study Material',
                                          subjectId: '',
                                          localPath: chatState.activeDocumentPath!,
                                          dateAdded: DateTime.now(),
                                          fileSize: chatState.activeDocumentSize ?? 0,
                                        ),
                                        initialTab: 1,
                                        initialExtractedText: chatState.activeDocumentText,
                                      ),
                                    ),
                                  );
                                } else {
                                  _sendMessage('Please give me a clear, structured summary of this study material with major topics, definitions, and reaction mechanisms.');
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            _ActionChip(
                              icon: Icons.quiz_outlined,
                              label: 'Quiz',
                              onTap: () {
                                if (chatState.activeDocumentPath != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => PdfStudyHubScreen(
                                        doc: PdfDoc(
                                          id: const Uuid().v4(),
                                          filename: chatState.activeDocumentName ?? 'document.pdf',
                                          displayName: chatState.activeDocumentName ?? 'Study Material',
                                          subjectId: '',
                                          localPath: chatState.activeDocumentPath!,
                                          dateAdded: DateTime.now(),
                                          fileSize: chatState.activeDocumentSize ?? 0,
                                        ),
                                        initialTab: 2,
                                        initialExtractedText: chatState.activeDocumentText,
                                      ),
                                    ),
                                  );
                                } else {
                                  _sendMessage('Generate 5 MSc-level exam practice questions with model answers based on this study material.');
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            _ActionChip(
                              icon: Icons.style,
                              label: 'Flashcards',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => SmartFlashcardsGenerateScreen(
                                      prefilledTopic: chatState.activeDocumentName,
                                      prefilledText: chatState.activeDocumentText,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Messages
            Expanded(
              child: chatState.messages.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.science_outlined, size: 48, color: AppColors.purpleBright),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Ask ChemBuddy',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Ask chemistry questions or attach your course notes to study from them.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.purple.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onPressed: _pickPdf,
                              icon: const Icon(Icons.upload_file, color: AppColors.purpleBright, size: 18),
                              label: const Text('Attach PDF Study Material', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(height: 24),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Suggested Topics:', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 8),
                            _SuggestionTile(
                              text: 'Explain SN1 vs SN2 reaction mechanisms and stereochemistry.',
                              onTap: () => _sendMessage('Explain SN1 vs SN2 reaction mechanisms and stereochemistry.'),
                            ),
                            const SizedBox(height: 6),
                            _SuggestionTile(
                              text: 'How does Huckel\'s rule (4n+2) determine aromaticity?',
                              onTap: () => _sendMessage('How does Huckel\'s rule (4n+2) determine aromaticity?'),
                            ),
                            const SizedBox(height: 6),
                            _SuggestionTile(
                              text: 'Differentiate between thermodynamic and kinetic control.',
                              onTap: () => _sendMessage('Differentiate between thermodynamic and kinetic control.'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        final isUser = msg.role == 'user';
                        
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                            child: GlowCard(
                              borderColor: isUser ? AppColors.purple.withValues(alpha: 0.6) : AppColors.border,
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isUser)
                                    Text(
                                      msg.content,
                                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                                    )
                                  else ...[
                                    if (msg.sources.isNotEmpty) ...[
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.purple.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.menu_book, size: 13, color: AppColors.purpleBright),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'Answering from: ${msg.sources.first.fileName ?? msg.sources.first.documentTitle ?? "Study Notes"}',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: AppColors.purpleBright, fontSize: 11.5, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (msg.content.toLowerCase().contains('mechanism') ||
                                        msg.content.toLowerCase().contains('sn1') ||
                                        msg.content.toLowerCase().contains('sn2') ||
                                        msg.content.toLowerCase().contains('aldol') ||
                                        msg.content.toLowerCase().contains('wittig') ||
                                        msg.content.toLowerCase().contains('diels-alder'))
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 12),
                                        child: ReactionMechanismsCard(compact: true),
                                      ),
                                    ChemistryMarkdownView(
                                      text: msg.content,
                                      textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.45),
                                      selectable: true,
                                    ),
                                    _buildAutoFlashcardBanner(context, msg),
                                    const SizedBox(height: 12),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _ActionChip(
                                            icon: Icons.style,
                                            label: 'Flashcards',
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute<void>(
                                                  builder: (_) => SmartFlashcardsGenerateScreen(
                                                    prefilledTopic: 'Chat Topic',
                                                    prefilledText: ChemistryTextFormatter.format(msg.content),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionChip(
                                            icon: Icons.quiz,
                                            label: 'Quiz',
                                            onTap: () => _startQuizForMessage(msg),
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionChip(
                                            icon: Icons.auto_awesome,
                                            label: 'Simpler',
                                            onTap: () {
                                              ref.read(chatControllerProvider.notifier).sendMessage(
                                                'Explain this more simply and concisely for an exam summary: ${msg.content.substring(0, min(400, msg.content.length))}',
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionChip(
                                            icon: Icons.bookmark_add,
                                            label: 'Save Note',
                                            onTap: () {
                                              final rawTitle = msg.content.split('\n').firstWhere(
                                                (line) => line.trim().isNotEmpty,
                                                orElse: () => 'Chemistry Note',
                                              ).replaceAll(RegExp(r'^[#*\s]+'), '');
                                              final title = ChemistryTextFormatter.format(rawTitle);
                                              
                                              final note = NoteItem(
                                                id: const Uuid().v4(),
                                                title: title.isEmpty ? 'Chemistry Note' : (title.length > 50 ? title.substring(0, 50) : title),
                                                body: ChemistryTextFormatter.format(msg.content),
                                                updatedAt: DateTime.now(),
                                              );
                                              ref.read(appControllerProvider.notifier).saveNote(note);
                                              
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Saved to your Notes library!')),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (chatState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClaudeThinkingBubble(
                  thoughts: ClaudeThinkingMicrocopy.askAi,
                ),
              ),


    if (chatState.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GlowCard(
                  borderColor: AppColors.danger.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(chatState.error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                      ),
                      if (_lastSentQuestion != null)
                        TextButton(
                          onPressed: chatState.isLoading ? null : () => _sendMessage(_lastSentQuestion),
                          child: const Text('Retry', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
              ),

            if (_isListening)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: GlowCard(
                  borderColor: AppColors.danger.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic, color: AppColors.danger, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Listening... Speak your question',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _stopListening,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),

            // Input Bar with responsive spacing above bottom navigation bar
            Builder(
              builder: (context) {
                final isKeyboardOpen = View.of(context).viewInsets.bottom > 0;
                final safeBottom = MediaQuery.paddingOf(context).bottom;
                final bottomPadding = isKeyboardOpen ? 8.0 : (64.0 + safeBottom);

                return Container(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
                  decoration: BoxDecoration(
                    color: const Color(0xE8141620),
                    border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.4))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: _isListening
                                ? 'Listening to your voice...'
                                : chatState.hasActiveDocument
                                    ? 'Ask about ${chatState.activeDocumentName}...'
                                    : 'Ask any chemistry question...',
                            hintStyle: TextStyle(
                              color: _isListening ? AppColors.danger : AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: _isListening ? FontWeight.w600 : FontWeight.normal,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: _isListening ? AppColors.danger : AppColors.border,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          onSubmitted: (_) {
                            if (_isListening) _stopListening();
                            _sendMessage();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: _isListening
                            ? AppColors.danger.withValues(alpha: 0.25)
                            : AppColors.surfaceElevated,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _toggleListening,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isListening
                                    ? AppColors.danger
                                    : AppColors.border.withValues(alpha: 0.7),
                                width: _isListening ? 1.6 : 1.0,
                              ),
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none_rounded,
                              color: _isListening ? AppColors.danger : AppColors.purpleBright,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.purple,
                        radius: 22,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 18),
                          onPressed: () {
                            if (_isListening) _stopListening();
                            _sendMessage();
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<String> _extractKeyTerms(String content) {
    final terms = <String>{};
    final boldRegex = RegExp(r'\*\*([^*]+)\*\*');
    for (final m in boldRegex.allMatches(content)) {
      final term = m.group(1)?.trim() ?? '';
      if (term.isNotEmpty && term.length > 3 && term.length < 35 && !term.toLowerCase().contains('step') && !term.toLowerCase().contains('note')) {
        terms.add(term);
      }
    }
    if (terms.length < 2) {
      final lower = content.toLowerCase();
      if (lower.contains('sn1')) terms.add('SN1 Mechanism');
      if (lower.contains('sn2')) terms.add('SN2 Mechanism');
      if (lower.contains('aldol')) terms.add('Aldol Condensation');
      if (lower.contains('nmr')) terms.add('¹H NMR Shifts');
      if (lower.contains('diels-alder')) terms.add('Diels-Alder Cycloaddition');
      if (lower.contains('pericyclic')) terms.add('Woodward-Hoffmann Rules');
      if (lower.contains('enolate')) terms.add('Enolate Chemistry');
      if (lower.contains('spectroscopy')) terms.add('Spectroscopy');
    }
    return terms.take(4).toList();
  }

  Widget _buildAutoFlashcardBanner(BuildContext context, AiMessage msg) {
    if (msg.content.length < 80) return const SizedBox.shrink();
    final terms = _extractKeyTerms(msg.content);
    if (terms.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandBright.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.brandBright, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Extracted Key Concepts 💡',
                  style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  terms.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.brandBright, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () => _oneTapSaveFlashcards(msg, terms),
            child: const Text('1-Tap Deck', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  void _oneTapSaveFlashcards(AiMessage msg, List<String> terms) {
    AppHaptics.confirm();
    final setId = const Uuid().v4();
    final topic = terms.firstOrNull ?? 'Chemistry Concepts';
    final rawTitle = msg.content.split('\n').firstWhere(
      (line) => line.trim().isNotEmpty,
      orElse: () => topic,
    ).replaceAll(RegExp(r'^[#*\s]+'), '');
    final title = rawTitle.length > 36 ? '${rawTitle.substring(0, 36)}...' : rawTitle;

    final newSet = SmartFlashcardSet(
      id: setId,
      title: title,
      sourceFileName: 'Ask AI Chat',
      topic: topic,
      cardCount: terms.length,
      createdAt: DateTime.now(),
    );

    final cards = <SmartFlashcard>[];
    for (var i = 0; i < terms.length; i++) {
      final term = terms[i];
      cards.add(
        SmartFlashcard(
          id: const Uuid().v4(),
          setId: setId,
          position: i,
          topic: topic,
          question: 'What are the key chemical principles, mechanism, and significance of $term?',
          answer: ChemistryTextFormatter.format(msg.content),
          keyTerms: terms,
          sourceBacklink: msg.content,
        ),
      );
    }

    final service = ref.read(flashcardServiceProvider);
    service.saveSet(newSet, cards);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.statusSuccess, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Created flashcard deck with ${cards.length} cards! 🎉',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Study Now →',
          textColor: AppColors.brandBright,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SmartFlashcardsStudyScreen(setId: setId),
              ),
            );
          },
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderHighlight, width: 0.8),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionTile({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.subdirectory_arrow_right, size: 16, color: AppColors.purpleBright),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
          ],
        ),
      ),
    );
  }
}



class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.purpleBright),
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiModeChip extends StatelessWidget {
  const _AiModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
        decoration: BoxDecoration(
          color: selected ? AppColors.purple.withValues(alpha: 0.3) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.purpleBright : AppColors.border,
            width: selected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13.5,
              color: selected ? AppColors.purpleBright : AppColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

