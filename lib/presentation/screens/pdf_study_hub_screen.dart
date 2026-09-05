import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/branding/chembuddy_mascot.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../core/widgets/claude_loading_text.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/models/library_models.dart';
import '../../data/models/pdf_study_models.dart';
import '../../data/services/gemini_flashcard_service.dart';
import '../../data/services/pdf_text_utils.dart';
import '../providers/app_providers.dart';
import '../providers/rag_providers.dart';
import '../widgets/contextual_hint_card.dart';
import 'pdf_quiz_screen.dart';
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

class _PdfStudyHubScreenState extends ConsumerState<PdfStudyHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _extractedText;
  DocumentQuality _documentQuality = DocumentQuality.digitalText;
  bool _loading = false;
  String _progressStatus = '';
  String? _errorMessage;

  PdfSummary? _summary;
  List<ImportantTopic>? _topics;
  ChemistryQuiz? _quiz;

  int _quizCount = 10;
  int _flashcardCount = 10;
  final TextEditingController _askController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTab);
    if (widget.initialExtractedText != null && widget.initialExtractedText!.trim().isNotEmpty) {
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
    final repo = ref.read(chemRepositoryProvider);
    _summary = repo.getPdfSummary(widget.doc.id);
    _topics = repo.getPdfTopics(widget.doc.id);
    final quizzes = repo.getPdfQuizzes(widget.doc.id);
    if (quizzes.isNotEmpty) {
      _quiz = quizzes.first;
    }

    if (_extractedText == null) {
      await _extractText();
    } else {
      // If we already have the text, auto-populate if missing
      if (widget.initialTab == 1 && _summary == null) {
        _fetchSummary();
      } else if (_topics == null || _topics!.isEmpty) {
        _fetchTopics();
      }
    }
  }

  Future<void> _extractText() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _progressStatus = 'Reading document structure...';
    });

    try {
      final service = ref.read(pdfAiStudyServiceProvider);
      final text = await service.extractText(
        widget.doc.localPath,
        onProgress: (status) {
          if (mounted) setState(() => _progressStatus = status);
        },
      );
      _extractedText = text;
      _documentQuality = assessDocumentQuality(text);

      if (widget.initialTab == 1 && _summary == null) {
        await _fetchSummary();
      } else if (_topics == null || _topics!.isEmpty) {
        await _fetchTopics();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e is PdfExtractionException
            ? e.message
            : 'Could not extract text from this PDF. Ensure the file contains readable notes.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _progressStatus = '';
        });
      }
    }
  }

  Future<void> _fetchSummary() async {
    final text = (_extractedText != null && _extractedText!.trim().isNotEmpty)
        ? _extractedText!
        : 'Chemistry Study Material for ${widget.doc.displayName}';

    setState(() {
      _loading = true;
      _errorMessage = null;
      _progressStatus = 'Synthesizing structured academic summary...';
    });

    try {
      final service = ref.read(pdfAiStudyServiceProvider);
      final summary = await service.generateSummary(
        sourceText: text,
        documentTitle: widget.doc.displayName,
        docId: widget.doc.id,
        onProgress: (status) {
          if (mounted) setState(() => _progressStatus = status);
        },
      );
      await ref.read(appControllerProvider.notifier).savePdfSummary(summary);
      setState(() => _summary = summary);
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not generate summary. Please retry.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchTopics() async {
    final text = (_extractedText != null && _extractedText!.trim().isNotEmpty)
        ? _extractedText!
        : 'Chemistry Study Material for ${widget.doc.displayName}';

    setState(() {
      _loading = true;
      _errorMessage = null;
      _progressStatus = 'Analyzing document depth and ranking topics...';
    });

    try {
      final service = ref.read(pdfAiStudyServiceProvider);
      final topics = await service.analyzeImportantTopics(
        sourceText: text,
        documentTitle: widget.doc.displayName,
        onProgress: (status) {
          if (mounted) setState(() => _progressStatus = status);
        },
      );
      await ref.read(appControllerProvider.notifier).savePdfTopics(widget.doc.id, topics);
      setState(() => _topics = topics);
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not analyze topics. Please retry.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generateQuiz() async {
    final text = (_extractedText != null && _extractedText!.trim().isNotEmpty)
        ? _extractedText!
        : 'Chemistry Study Material for ${widget.doc.displayName}';

    setState(() {
      _loading = true;
      _errorMessage = null;
      _progressStatus = 'Generating $_quizCount MSc Chemistry exam questions...';
    });

    try {
      final service = ref.read(pdfAiStudyServiceProvider);
      final quiz = await service.generateQuiz(
        sourceText: text,
        documentTitle: widget.doc.displayName,
        docId: widget.doc.id,
        count: _quizCount,
        onProgress: (status) {
          if (mounted) setState(() => _progressStatus = status);
        },
      );
      await ref.read(appControllerProvider.notifier).saveQuiz(quiz);
      setState(() => _quiz = quiz);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => PdfQuizScreen(quiz: quiz, docName: widget.doc.displayName),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not create quiz. Please retry.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
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
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showStudyOptionsForTopic(ImportantTopic topic) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(topic.priorityEmoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      topic.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('How would you like to study this topic?', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              _StudyOptionTile(
                icon: Icons.chat_bubble_outline,
                title: 'Ask ChemBuddy about this topic',
                subtitle: 'Get a clear explanation and mechanism breakdown',
                onTap: () {
                  Navigator.pop(ctx);
                  _tabController.animateTo(4);
                  _askController.text = 'Explain the key principles, mechanisms, and exam questions for: ${topic.title}';
                },
              ),
              _StudyOptionTile(
                icon: Icons.style_outlined,
                title: 'Generate Flashcards for this topic',
                subtitle: 'Practice active recall specifically on ${topic.title}',
                onTap: () {
                  Navigator.pop(ctx);
                  _tabController.animateTo(3);
                },
              ),
              _StudyOptionTile(
                icon: Icons.quiz_outlined,
                title: 'Test myself with a Quiz',
                subtitle: 'Take MSc Chemistry practice questions on ${topic.title}',
                onTap: () {
                  Navigator.pop(ctx);
                  _tabController.animateTo(2);
                },
              ),
            ],
          ),
        );
      },
    );
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
              const Text('Study with ChemBuddy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              Text(
                widget.doc.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined, color: AppColors.blue),
              tooltip: 'Read PDF',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => PdfReaderScreen(doc: widget.doc)),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppColors.purpleBright,
            labelColor: AppColors.purpleBright,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            tabs: const [
              Tab(text: '🔥 Topics'),
              Tab(text: '✨ Summary'),
              Tab(text: '📝 Quiz'),
              Tab(text: '🃏 Flashcards'),
              Tab(text: '💬 Ask AI'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_loading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF18122B).withValues(alpha: 0.92),
                  border: const Border(
                    bottom: BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                child: ClaudeThinkingIndicator(
                  thoughts: _progressStatus.isNotEmpty
                      ? [_progressStatus, ...ClaudeThinkingMicrocopy.summary]
                      : ClaudeThinkingMicrocopy.summary,
                  isCard: false,
                  showSparkle: true,
                  fontSize: 12.5,
                ),
              ),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5))),
                    TextButton(
                      onPressed: _extractText,
                      child: const Text('Try Again', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              )
            else if (_documentQuality == DocumentQuality.scannedImage)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚠️', style: TextStyle(fontSize: 15)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This document appears to be a scanned PDF. Chemistry structures, equations and symbols may not be extracted accurately. Some study-generation features may be limited.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTopicsTab(),
                  _buildSummaryTab(),
                  _buildQuizTab(),
                  _buildFlashcardsTab(),
                  _buildAskAiTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. IMPORTANT TOPICS TAB
  Widget _buildTopicsTab() {
    if (_loading && (_topics == null || _topics!.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: MascotLoading(
            title: _progressStatus.isEmpty ? 'Analyzing Chemistry Document...' : _progressStatus,
            subtitle: 'Extracting key concepts, formulas and exam priorities',
            size: MascotSize.medium,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        const ContextualHintCard(
          hintKey: 'topics_hint',
          title: 'Important Topics',
          message: 'ChemBuddy analyzes depth and exam relevance to pinpoint high-yield concepts.',
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Identified Key Topics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            TextButton.icon(
              onPressed: _loading ? null : _fetchTopics,
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.purpleBright),
              label: const Text('Re-Analyze', style: TextStyle(color: AppColors.purpleBright, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_topics == null || _topics!.isEmpty)
          MascotEmptyState(
            title: 'No Topics Extracted Yet',
            description: 'Analyze this MSc Chemistry document to extract key reaction schemes, theorems, and exam weightages.',
            buttonLabel: 'Analyze Topics with AI',
            onAction: _fetchTopics,
            size: MascotSize.medium,
          )
        else
          ..._topics!.map((topic) {
            Color badgeColor;
            switch (topic.priority) {
              case TopicPriority.veryHigh:
                badgeColor = AppColors.danger;
                break;
              case TopicPriority.high:
                badgeColor = AppColors.warning;
                break;
              case TopicPriority.medium:
                badgeColor = AppColors.blue;
                break;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlowCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(topic.priorityEmoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            topic.title,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.white),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            topic.priorityLabel,
                            style: TextStyle(color: badgeColor, fontWeight: FontWeight.w800, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ChemistryMarkdownView(
                      text: topic.explanation,
                      textStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
                    ),
                    if (topic.keyFormulas.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: topic.keyFormulas.map((f) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ChemistryMarkdownView(
                            text: f,
                            textStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        )).toList(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _showStudyOptionsForTopic(topic),
                        icon: const Icon(Icons.school_outlined, size: 15),
                        label: const Text('Study Topic', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple.withValues(alpha: 0.2),
                          foregroundColor: AppColors.purpleBright,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // 2. ACADEMIC SUMMARY TAB
  Widget _buildSummaryTab() {
    if (_summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_loading)
                const MascotLoading(
                  title: 'Distilling Academic Summary...',
                  subtitle: 'Synthesizing definitions, mechanisms, and exam weightages',
                  size: MascotSize.medium,
                )
              else
                MascotEmptyState(
                  title: 'Structured Academic Summary',
                  description: 'Generate an executive postgraduate summary with definitions, reaction pathways, and exam focus points.',
                  buttonLabel: 'Generate Summary with AI',
                  onAction: _fetchSummary,
                  size: MascotSize.medium,
                ),
            ],
          ),
        ),
      );
    }

    final s = _summary!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Academic Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            TextButton.icon(
              onPressed: _loading ? null : _fetchSummary,
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.purpleBright),
              label: const Text('Regenerate', style: TextStyle(color: AppColors.purpleBright, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Overview
        _SummarySection(title: 'Overview', icon: Icons.description_outlined, content: [s.overview]),

        // Core Concepts
        if (s.coreConcepts.isNotEmpty)
          _SummarySection(title: 'Core Concepts', icon: Icons.lightbulb_outline, content: s.coreConcepts),

        // Important Definitions
        if (s.definitions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bookmark_border, color: AppColors.purpleBright, size: 18),
                      SizedBox(width: 8),
                      Text('Important Definitions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...s.definitions.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ChemistryMarkdownView(
                      text: '**${d["term"] ?? ""}**: ${d["definition"] ?? ""}',
                      textStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
                    ),
                  )),
                ],
              ),
            ),
          ),

        // Reactions & Equations
        if (s.reactionsAndEquations.isNotEmpty)
          _SummarySection(title: 'Important Reactions & Equations', icon: Icons.science_outlined, content: s.reactionsAndEquations),

        // Key Points
        if (s.keyPoints.isNotEmpty)
          _SummarySection(title: 'Key Takeaways', icon: Icons.check_circle_outline, content: s.keyPoints),

        // Exam Focus
        if (s.examFocus.isNotEmpty)
          _SummarySection(title: 'Exam Focus & High-Probability Patterns', icon: Icons.local_fire_department_outlined, content: s.examFocus),

        // Quick Revision
        if (s.quickRevision.isNotEmpty)
          _SummarySection(title: 'Quick 1-Line Revision', icon: Icons.bolt, content: s.quickRevision),
      ],
    );
  }

  // 3. QUIZ TAB
  Widget _buildQuizTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        const ContextualHintCard(
          hintKey: 'quiz_hint',
          title: 'Exam Practice Quiz 📝',
          message: 'Generate real MSc Chemistry questions directly from this PDF covering mechanisms, spectral interpretation, and numerical problems.',
        ),

        GlowCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Configure Chemistry Quiz', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Select the number of exam-style questions to generate:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                children: [10, 20, 30].map((n) {
                  final active = _quizCount == n;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text('$n Questions'),
                      selected: active,
                      onSelected: _loading ? null : (_) => setState(() => _quizCount = n),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const ClaudeThinkingIndicator(
                  thoughts: ClaudeThinkingMicrocopy.quiz,
                  isCard: true,
                  thinkingHeader: 'Assembling Chemistry Quiz',
                )
              else
                ElevatedButton.icon(
                  onPressed: _generateQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Generate & Start Quiz ($_quizCount Qs)', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ),

        if (_quiz != null) ...[
          const SizedBox(height: 20),
          const Text('Previous Quiz on this PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          GlowCard(
            child: Row(
              children: [
                const Icon(Icons.history_edu, color: AppColors.purpleBright, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_quiz!.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('${_quiz!.questionCount} questions available', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => PdfQuizScreen(quiz: _quiz!, docName: widget.doc.displayName),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceElevated),
                  child: const Text('Resume / Retake'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 4. FLASHCARDS TAB
  Widget _buildFlashcardsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        const ContextualHintCard(
          hintKey: 'flashcards_hint',
          title: 'Active Spaced Recall 🃏',
          message: 'Start with 10 flashcards to reinforce reactions, named reagents, and definitions before moving to a larger deck.',
        ),

        GlowCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Smart Flashcard Deck', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Generate tailored flashcards from this PDF:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                children: [10, 20, 30].map((n) {
                  final active = _flashcardCount == n;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text('$n Cards'),
                      selected: active,
                      onSelected: _loading ? null : (_) => setState(() => _flashcardCount = n),
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
                ElevatedButton.icon(
                  onPressed: _generateFlashcards,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.style),
                  label: Text('Generate & Study Deck ($_flashcardCount Cards)', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. ASK AI TAB
  Widget _buildAskAiTab() {
    final chatState = ref.watch(chatControllerProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.purple.withValues(alpha: 0.1),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.purpleBright, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Answering directly from: ${widget.doc.displayName}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            children: [
              const GlowCard(
                child: Text(
                  '💡 Ask any doubt about this document. ChemBuddy references your notes first. If a concept is outside this document, it will notify you and offer general chemistry principles.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
                ),
              ),
              const SizedBox(height: 12),
              ...chatState.messages.map((m) {
                final isUser = m.role == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                    child: GlowCard(
                      borderColor: isUser ? AppColors.purple.withValues(alpha: 0.6) : AppColors.border,
                      padding: const EdgeInsets.all(12),
                      child: isUser
                          ? Text(
                              m.content,
                              style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35),
                            )
                          : ChemistryMarkdownView(
                              text: m.content,
                              textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, height: 1.45),
                              selectable: true,
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.purple),
                onPressed: () {
                  final q = _askController.text.trim();
                  if (q.isEmpty) return;
                  _askController.clear();
                  ref.read(chatControllerProvider.notifier).attachDocument(
                    name: widget.doc.displayName,
                    text: _extractedText ?? '',
                    path: widget.doc.localPath,
                    size: widget.doc.fileSize,
                  );
                  ref.read(chatControllerProvider.notifier).sendMessage(q);
                },
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.title, required this.icon, required this.content});
  final String title;
  final IconData icon;
  final List<String> content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.purpleBright, size: 18),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 10),
            ...content.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.bold, fontSize: 14)),
                    Expanded(
                      child: ChemistryMarkdownView(
                        text: c,
                        textStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyOptionTile extends StatelessWidget {
  const _StudyOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlowCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.purpleBright, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Colors.white)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
