import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/chemistry_text_formatter.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/benzene_loading_indicator.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../core/widgets/claude_loading_text.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/models/models.dart';
import '../../data/models/rag_models.dart';
import '../../data/models/smart_flashcard.dart';
import '../../data/services/pdf_text_extraction_service.dart';
import '../../data/services/reaction_mechanism_service.dart';
import '../providers/app_providers.dart';
import '../providers/rag_providers.dart';
import '../widgets/pdf_quiz_setup_dialog.dart';
import '../widgets/reaction_mechanisms_card.dart';
import '../widgets/viva_practice_dialog.dart';
import 'pdf_quiz_screen.dart';
import 'reaction_mechanism_screen.dart';
import 'smart_flashcards_generate_screen.dart';
import 'smart_flashcards_study_screen.dart';

enum ChemBuddyAiMode {
  normal,
  exam2M,
  exam5M,
  exam10M,
  mscConcept,
  mechanisms,
}

class AskChemBuddyScreen extends ConsumerStatefulWidget {
  const AskChemBuddyScreen({super.key});

  @override
  ConsumerState<AskChemBuddyScreen> createState() => _AskChemBuddyScreenState();
}

class _AskChemBuddyScreenState extends ConsumerState<AskChemBuddyScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  late final AnimationController _micPulseController;

  ChemBuddyAiMode _currentMode = ChemBuddyAiMode.normal;
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _extracting = false;
  String _extractingStatus = 'Reading document...';
  String? _lastSentQuestion;

  static const List<String> _voiceShortcuts = [
    'SN1 vs SN2 mechanism',
    'Hückel 4n+2 rule',
    'Diels-Alder reaction',
    '¹H NMR splitting',
    'Thermodynamic vs kinetic control',
  ];

  @override
  void initState() {
    super.initState();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _initSpeech();
  }

  @override
  void dispose() {
    _micPulseController.dispose();
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
          final normalized = ChemistryTextFormatter.normalizeSpeechQuery(result.recognizedWords);
          setState(() {
            _controller.text = normalized;
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
    if (ref.read(chatControllerProvider).isLoading) return;
    final rawText = textOverride ?? _controller.text.trim();
    if (rawText.isEmpty) return;
    AppHaptics.confirm();

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
    String modeString = 'quick';
    if (_currentMode == ChemBuddyAiMode.normal) {
      modeString = 'quick';
      // Default Quick Answer Mode: concise, direct, intelligent response
      modelPrompt = null;
    } else if (_currentMode == ChemBuddyAiMode.exam2M) {
      modeString = '2m';
      modelPrompt = '[Format as a concise 2-Mark University Exam Answer: Provide 1) Definition / Direct Statement (1-2 sentences), 2) Core Essential Points, 3) Balanced Reaction or Key Formula if applicable. DO NOT over-explain]: $rawText';
    } else if (_currentMode == ChemBuddyAiMode.exam5M) {
      modeString = '5m';
      modelPrompt = '[Format as a structured 5-Mark MSc Chemistry University Rubric: 1) Principle & Definition, 2) Balanced Reaction, 3) Step-by-Step Mechanism/Intermediates, 4) Applications & Synthetic Scope, 5) Summary]: $rawText';
    } else if (_currentMode == ChemBuddyAiMode.exam10M) {
      modeString = '10m';
      modelPrompt = '[Format as a comprehensive 10-Mark MSc Chemistry Exam Answer with detailed headings, mechanisms with curved arrow electron pushing notes, transition states, stereochemistry, and laboratory synthesis applications]: $rawText';
    } else if (_currentMode == ChemBuddyAiMode.mscConcept) {
      modeString = 'mscConcept';
      modelPrompt = '[Explain in Academic MSc Concept Mode: Focus on deep understanding, physical/chemical intuition, orbital or thermodynamic principles, and clear chemical notation]: $rawText';
    } else if (_currentMode == ChemBuddyAiMode.mechanisms) {
      modeString = 'mechanisms';
      modelPrompt = 'Explain the full stepwise reaction mechanism, curved arrow electron displacement, intermediates, and driving force for: $rawText';
    }

    _lastSentQuestion = rawText;
    ref.read(chatControllerProvider.notifier).sendMessage(
      rawText,
      modelPrompt: modelPrompt,
      mode: modeString,
    );
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC0D0B1A),
        border: const Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 0.8)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _AiModeChip(
              icon: Icons.bolt_rounded,
              label: '⚡ Quick Answer',
              selected: _currentMode == ChemBuddyAiMode.normal,
              onTap: () => setState(() => _currentMode = ChemBuddyAiMode.normal),
            ),
            const SizedBox(width: 8),
            _AiModeChip(
              icon: Icons.view_headline_rounded,
              label: '≡ 2M Answer',
              selected: _currentMode == ChemBuddyAiMode.exam2M,
              onTap: () => setState(() => _currentMode = ChemBuddyAiMode.exam2M),
            ),
            const SizedBox(width: 8),
            _AiModeChip(
              icon: Icons.format_list_bulleted_rounded,
              label: '≡ 5M Answer',
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
              icon: Icons.school_outlined,
              label: 'MSc In-Depth',
              selected: _currentMode == ChemBuddyAiMode.mscConcept,
              onTap: () => setState(() => _currentMode = ChemBuddyAiMode.mscConcept),
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
        Navigator.pop(context);
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
            content: Text(e.toString().contains('Exception:') ? e.toString().replaceFirst('Exception: ', '') : 'Could not read PDF text. Make sure it contains readable text.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
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

            // Extracting banner with Benzene indicator
            if (_extracting)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GlowCard(
                  borderColor: AppColors.purpleBright.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      const BenzeneLoadingIndicator(size: 32, showMicrocopy: false),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _extractingStatus.isNotEmpty ? _extractingStatus : 'Parsing PDF study notes...',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Attached PDF Badge (Strict PDF Grounding Active)
            if (chatState.hasActiveDocument && !_extracting)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: GlowCard(
                  borderColor: AppColors.purpleBright.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.purpleBright, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.purple.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.purpleBright.withValues(alpha: 0.5), width: 0.6),
                                  ),
                                  child: const Text('🔒 Strict PDF Mode', style: TextStyle(color: AppColors.purpleBright, fontSize: 10, fontWeight: FontWeight.w800)),
                                ),
                                const SizedBox(width: 6),
                                const Text('Grounded 🟢', style: TextStyle(color: AppColors.success, fontSize: 10.5, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              chatState.activeDocumentName ?? 'Attached PDF Material',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.purple.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.quiz_outlined, size: 14, color: AppColors.purpleBright),
                        label: const Text('Quiz', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        onPressed: () {
                          if (chatState.activeDocumentText != null) {
                            PdfQuizSetupDialog.show(
                              context,
                              documentTitle: chatState.activeDocumentName ?? 'Attached PDF',
                              sourceText: chatState.activeDocumentText!,
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                        tooltip: 'Detach PDF (Switch to General Chemistry AI)',
                        onPressed: () => ref.read(chatControllerProvider.notifier).detachDocument(),
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
                            // Dynamic Benzene Bond Formation Animation (No mascot)
                            const BenzeneLoadingIndicator(
                              size: 110,
                              showMicrocopy: false,
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
                            const SizedBox(height: 18),
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
                            const SizedBox(height: 22),
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
                              text: 'How does Hückel\'s rule (4n+2) determine aromaticity?',
                              onTap: () => _sendMessage('How does Hückel\'s rule (4n+2) determine aromaticity?'),
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
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        final isUser = msg.role == 'user';

                        final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.88;

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                            width: isUser ? null : double.infinity,
                            child: isUser
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                        bottomLeft: Radius.circular(20),
                                        bottomRight: Radius.circular(4),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.brandPrimary.withValues(alpha: 0.28),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: AppColors.brandBright.withValues(alpha: 0.35),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      msg.content,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.bg1,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                        bottomLeft: Radius.circular(4),
                                        bottomRight: Radius.circular(20),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: AppColors.borderHighlight,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (msg.sources.isNotEmpty) ...[
                                          Container(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: AppColors.brandPrimary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.brandBright.withValues(alpha: 0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.menu_book_rounded, size: 13, color: AppColors.brandBright),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    'Answering from: ${msg.sources.first.fileName ?? msg.sources.first.documentTitle ?? "Study Notes"}',
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(color: AppColors.brandBright, fontSize: 11.5, fontWeight: FontWeight.w700),
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
                                          textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, height: 1.55),
                                          selectable: true,
                                        ),
                                        _buildAutoFlashcardBanner(context, msg),
                                        const SizedBox(height: 12),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          physics: const BouncingScrollPhysics(),
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
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
            ),

            // Benzene Bond Loading Indicator while AI is formulating response
            if (chatState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: BenzeneThinkingBubble(
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

            // Smart Voice Recognition Assistant Panel
            if (_isListening)
              AnimatedBuilder(
                animation: _micPulseController,
                builder: (context, child) {
                  return Container(
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.5 + 0.4 * _micPulseController.value),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.15 * _micPulseController.value),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.2 + 0.15 * _micPulseController.value),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.mic, color: AppColors.danger, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Smart Mic Active • Speak formula or query',
                                    style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    _controller.text.isEmpty ? 'Say e.g. "H2SO4" or "SN1 mechanism"' : _controller.text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _controller.text.isEmpty ? AppColors.textMuted : AppColors.brandBright,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _voiceShortcuts.map((shortcut) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  backgroundColor: AppColors.surface,
                                  side: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
                                  label: Text(shortcut, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  onPressed: () {
                                    _controller.text = shortcut;
                                    _stopListening();
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Input Bar snugly seated directly next to the bottom navigation bar
            Builder(
              builder: (context) {
                final isKeyboardOpen = View.of(context).viewInsets.bottom > 0;
                final safeBottom = MediaQuery.paddingOf(context).bottom;
                final bottomPadding = isKeyboardOpen ? 6.0 : max(8.0, safeBottom);

                return Container(
                  padding: EdgeInsets.fromLTRB(14, 8, 14, bottomPadding),
                  decoration: BoxDecoration(
                    color: const Color(0xF20A0914),
                    border: const Border(
                      top: BorderSide(color: AppColors.borderSubtle, width: 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, height: 1.4),
                          decoration: InputDecoration(
                            hintText: _isListening
                                ? 'Listening to your voice...'
                                : chatState.hasActiveDocument
                                    ? 'Ask about ${chatState.activeDocumentName}...'
                                    : 'Ask any chemistry question...',
                            hintStyle: TextStyle(
                              color: _isListening ? AppColors.statusDanger : AppColors.textMuted,
                              fontSize: 13.5,
                              fontWeight: _isListening ? FontWeight.w600 : FontWeight.normal,
                            ),
                            filled: true,
                            fillColor: AppColors.bg2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: _isListening ? AppColors.statusDanger : AppColors.borderSubtle,
                                width: 0.8,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: _isListening ? AppColors.statusDanger : AppColors.borderSubtle,
                                width: 0.8,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: _isListening ? AppColors.statusDanger : AppColors.brandPrimary,
                                width: 1.2,
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
                            ? AppColors.statusDanger.withValues(alpha: 0.2)
                            : AppColors.bg2,
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
                                    ? AppColors.statusDanger
                                    : AppColors.borderSubtle,
                                width: _isListening ? 1.5 : 0.8,
                              ),
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none_rounded,
                              color: _isListening ? AppColors.statusDanger : AppColors.brandBright,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: chatState.isLoading
                              ? null
                              : const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          color: chatState.isLoading ? AppColors.brandPrimary.withValues(alpha: 0.35) : null,
                          shape: BoxShape.circle,
                          boxShadow: chatState.isLoading
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.brandPrimary.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: IconButton(
                          icon: chatState.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                          onPressed: chatState.isLoading
                              ? null
                              : () {
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
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : AppColors.bg2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.brandBright : AppColors.borderSubtle,
            width: selected ? 1.0 : 0.8,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13.5,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.1,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
