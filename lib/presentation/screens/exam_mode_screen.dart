import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/services/chemistry_knowledge_engine.dart';
import '../../data/services/exam_paper_service.dart';
import '../providers/app_providers.dart';
import 'pdf_study_hub_screen.dart';

class ExamModeScreen extends ConsumerStatefulWidget {
  const ExamModeScreen({super.key, this.initialBranch});

  final ChemistryBranch? initialBranch;

  @override
  ConsumerState<ExamModeScreen> createState() => _ExamModeScreenState();
}

class _ExamModeScreenState extends ConsumerState<ExamModeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1: Blueprint Practice State
  ChemistryBranch _selectedBranch = ChemistryBranch.all;
  String _selectedSection = 'All';
  final Map<int, bool> _revealed = {};
  final Map<int, int> _awardedMarks = {};
  final Map<int, Set<int>> _checkedRubrics = {};
  bool _isLoadingBlueprint = true;

  // Timer Mode
  bool _timerActive = false;
  int _secondsRemaining = 10800; // 3 hours (70 marks)
  Timer? _examTimer;

  // Student Self-Assessment Mode State
  final Map<int, TextEditingController> _studentAnswerControllers = {};
  final Map<int, bool> _selfAssessmentOpen = {};
  final Map<int, ExamEvaluationResult> _evaluationResults = {};

  TextEditingController _getAnswerController(int index) {
    return _studentAnswerControllers.putIfAbsent(index, () => TextEditingController());
  }

  // Tab 2: Exam Answer Generator State
  final TextEditingController _questionController = TextEditingController();
  int _selectedMarkType = 5; // 2, 5, or 10
  String? _generatedAnswer;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.initialBranch ?? ChemistryBranch.all;
    _tabController = TabController(length: 3, vsync: this);
    _loadBlueprint();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    _examTimer?.cancel();
    for (final controller in _studentAnswerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBlueprint() async {
    setState(() => _isLoadingBlueprint = true);
    final progress = await ExamPaperService.instance.loadPaperProgress(_selectedBranch);
    if (mounted) {
      setState(() {
        _awardedMarks.clear();
        _awardedMarks.addAll(progress.marks);
        _revealed.clear();
        _revealed.addAll(progress.revealed);
        _checkedRubrics.clear();
        _isLoadingBlueprint = false;
      });
    }
  }

  void _toggleTimer() {
    AppHaptics.confirm();
    setState(() {
      _timerActive = !_timerActive;
      if (_timerActive) {
        _examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_secondsRemaining > 0) {
            setState(() => _secondsRemaining--);
          } else {
            timer.cancel();
            _timerActive = false;
          }
        });
      } else {
        _examTimer?.cancel();
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _generateAnswer() {
    final query = _questionController.text.trim();
    if (query.isEmpty) return;

    AppHaptics.confirm();
    setState(() {
      _isGenerating = true;
      _generatedAnswer = null;
    });

    final modeString = _selectedMarkType == 2 ? '2m' : (_selectedMarkType == 5 ? '5m' : '10m');
    final response = ChemistryKnowledgeEngine.generateAcademicResponse(
      question: query,
      mode: modeString,
    );

    setState(() {
      _generatedAnswer = response.answer;
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exam Mode 🎯',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
              ),
              Text(
                'University Rubrics & Model Answers',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
              ),
            ],
          ),
          actions: [
            // Timer button
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: InkWell(
                  onTap: _toggleTimer,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _timerActive ? AppColors.danger.withValues(alpha: 0.15) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _timerActive ? AppColors.danger : AppColors.borderSubtle,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _timerActive ? Icons.timer : Icons.timer_outlined,
                          size: 15,
                          color: _timerActive ? AppColors.danger : AppColors.accentGold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTimer(_secondsRemaining),
                          style: TextStyle(
                            color: _timerActive ? AppColors.danger : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.purpleBright,
            labelColor: AppColors.purpleBright,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.menu_book_rounded, size: 17), text: 'Blueprint Paper'),
              Tab(icon: Icon(Icons.edit_note_rounded, size: 17), text: 'Answer Generator'),
              Tab(icon: Icon(Icons.picture_as_pdf_outlined, size: 17), text: 'From My PDF'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBlueprintTab(),
            _buildGeneratorTab(),
            _buildPdfRevisionTab(),
          ],
        ),
      ),
    );
  }

  String _formatSectionBadge(String section, int marks) {
    if (section.toLowerCase().contains('part a') || section.toLowerCase().contains('section a')) {
      return 'Part A · ${marks}M';
    }
    if (section.toLowerCase().contains('part b') || section.toLowerCase().contains('section b')) {
      return 'Part B · ${marks}M';
    }
    if (section.toLowerCase().contains('part c') || section.toLowerCase().contains('section c')) {
      return 'Part C · ${marks}M';
    }
    final clean = section.split('—').first.trim();
    return clean.isNotEmpty ? '$clean · ${marks}M' : '${marks}M';
  }

  // ==========================================
  // TAB 1: BLUEPRINT PAPER PRACTICE
  // ==========================================
  Widget _buildBlueprintTab() {
    final questions = ExamPaperService.getPaperForBranch(_selectedBranch);
    final maxPaperScore = questions.fold<int>(0, (sum, q) => sum + q.marks);
    final filtered = _selectedSection == 'All'
        ? questions
        : questions.where((q) {
            if (_selectedSection == 'Part A' || _selectedSection == 'Section A') return q.marks == 2;
            if (_selectedSection == 'Part B' || _selectedSection == 'Section B') return q.marks == 5;
            if (_selectedSection == 'Part C' || _selectedSection == 'Section C') return q.marks == 10;
            return true;
          }).toList();

    int totalScore = 0;
    for (final marks in _awardedMarks.values) {
      totalScore += marks;
    }

    return Column(
      children: [
        // Branch Selector Chips
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: const Color(0x990D0B1A),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ChemistryBranch.values.map((b) {
                final isSelected = b == _selectedBranch;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${b.icon} ${b.name}'),
                    selected: isSelected,
                    selectedColor: AppColors.purple.withValues(alpha: 0.25),
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.purpleBright : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      AppHaptics.selection();
                      setState(() => _selectedBranch = b);
                      _loadBlueprint();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Section & Score Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 0.8)),
          ),
          child: Row(
            children: [
              // Section Filter Chips (Horizontally scrollable for responsiveness)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ('All', 'All'),
                      ('Part A (2M)', 'Part A'),
                      ('Part B (5M)', 'Part B'),
                      ('Part C (10M)', 'Part C'),
                    ].map((sec) {
                      final label = sec.$1;
                      final code = sec.$2;
                      final isSel = _selectedSection == code;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () {
                            AppHaptics.selection();
                            setState(() => _selectedSection = code);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.brandPrimary.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel ? AppColors.brandBright : AppColors.borderSubtle,
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isSel ? AppColors.brandBright : AppColors.textMuted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Score badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Score: $totalScore / $maxPaperScore',
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Questions List
        Expanded(
          child: _isLoadingBlueprint
              ? const Center(child: CircularProgressIndicator(color: AppColors.purpleBright))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isRevealed = _revealed[index] ?? false;
                    final awarded = _awardedMarks[index] ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlowCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Section, Marks, Frequency
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.purple.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _formatSectionBadge(item.section, item.marks),
                                    style: const TextStyle(
                                      color: AppColors.purpleBright,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.frequency,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                    ),
                                  ),
                                ),
                                if (awarded > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusSuccess.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '+$awarded Marks',
                                      style: const TextStyle(
                                        color: AppColors.statusSuccess,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Question Title
                            ChemistryMarkdownView(
                              text: item.question,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: Colors.white,
                                height: 1.35,
                              ),
                              selectable: false,
                            ),
                            const SizedBox(height: 6),

                            // Exam Tips
                            if (item.examTips.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.bg2,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.accentGold),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: ChemistryMarkdownView(
                                        text: item.examTips,
                                        textStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.3),
                                        selectable: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 10),

                            // Action Row: Self-Assessment & View Model Answer
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    AppHaptics.tap();
                                    setState(() {
                                      _selfAssessmentOpen[index] = !(_selfAssessmentOpen[index] ?? false);
                                    });
                                  },
                                  icon: Icon(
                                    (_selfAssessmentOpen[index] ?? false)
                                        ? Icons.edit_note_rounded
                                        : Icons.rate_review_outlined,
                                    size: 16,
                                    color: AppColors.accentGold,
                                  ),
                                  label: Text(
                                    (_selfAssessmentOpen[index] ?? false)
                                        ? 'Hide Rubric Test'
                                        : '✍️ Self-Assessment',
                                    style: const TextStyle(
                                      color: AppColors.accentGold,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                TextButton.icon(
                                  onPressed: () {
                                    AppHaptics.tap();
                                    setState(() {
                                      _revealed[index] = !isRevealed;
                                    });
                                    ExamPaperService.instance.savePaperProgress(_selectedBranch, _awardedMarks, _revealed);
                                  },
                                  icon: Icon(
                                    isRevealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 16,
                                    color: AppColors.brandBright,
                                  ),
                                  label: Text(
                                    isRevealed ? 'Hide Model' : 'Model Answer',
                                    style: const TextStyle(
                                      color: AppColors.brandBright,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Self-evaluation marks dropdown
                                if (isRevealed || (_evaluationResults[index] != null)) ...[
                                  const Text(
                                    'Award: ',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                                  ),
                                  DropdownButton<int>(
                                    value: awarded,
                                    dropdownColor: AppColors.bg2,
                                    underline: const SizedBox.shrink(),
                                    items: List.generate(item.marks + 1, (i) => i).map((m) {
                                      return DropdownMenuItem(
                                        value: m,
                                        child: Text(
                                          '$m',
                                          style: TextStyle(
                                            color: m > 0 ? AppColors.statusSuccess : AppColors.textMuted,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (newMarks) {
                                      if (newMarks != null) {
                                        setState(() => _awardedMarks[index] = newMarks);
                                        ExamPaperService.instance.savePaperProgress(_selectedBranch, _awardedMarks, _revealed);
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),

                            // Student Self-Assessment Panel
                            if (_selfAssessmentOpen[index] ?? false) ...[
                              const Divider(color: AppColors.borderSubtle, height: 18),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.bg2,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.accentGold.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.edit_document, size: 15, color: AppColors.accentGold),
                                        SizedBox(width: 6),
                                        Text(
                                          'STUDENT SELF-ASSESSMENT & RUBRIC MATCHER',
                                          style: TextStyle(
                                            color: AppColors.accentGold,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _getAnswerController(index),
                                      maxLines: 4,
                                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
                                      decoration: InputDecoration(
                                        hintText: 'Draft your MSc chemistry answer here (mention key terms, equations, stereochemistry, or mechanisms)...',
                                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                        filled: true,
                                        fillColor: AppColors.surfaceElevated,
                                        contentPadding: const EdgeInsets.all(10),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.accentGold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            AppHaptics.confirm();
                                            final text = _getAnswerController(index).text;
                                            final eval = ExamPaperService.evaluateStudentAnswer(
                                              question: item,
                                              studentAnswer: text,
                                            );
                                            setState(() {
                                              _evaluationResults[index] = eval;
                                            });
                                          },
                                          icon: const Icon(Icons.analytics_outlined, size: 15),
                                          label: const Text(
                                            'Evaluate Against Rubric',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.accentGold,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                            _getAnswerController(index).clear();
                                            setState(() {
                                              _evaluationResults.remove(index);
                                            });
                                          },
                                          child: const Text('Clear', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                        ),
                                      ],
                                    ),

                                    // Diagnostic Scorecard
                                    if (_evaluationResults[index] != null) ...[
                                      const SizedBox(height: 12),
                                      _buildDiagnosticScorecard(
                                        item: item,
                                        index: index,
                                        result: _evaluationResults[index]!,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            // Model Answer (revealed)
                            if (isRevealed) ...[
                              const Divider(color: AppColors.borderSubtle, height: 20),
                              const Text(
                                'MODEL ANSWER (Evaluator Rubric):',
                                style: TextStyle(
                                  color: AppColors.brandBright,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ChemistryMarkdownView(
                                text: item.modelAnswer,
                                textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.45),
                                selectable: true,
                              ),
                              const SizedBox(height: 10),

                              // Marking Rubric Points
                              if (item.markingRubric.isNotEmpty) ...[
                                const Text(
                                  'MARKING BREAKDOWN:',
                                  style: TextStyle(
                                    color: AppColors.accentGold,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...item.markingRubric.map((r) => Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('• ', style: TextStyle(color: AppColors.accentGold)),
                                          Expanded(
                                            child: ChemistryMarkdownView(
                                              text: r,
                                              textStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                              selectable: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticScorecard({
    required ExamQuestionItem item,
    required int index,
    required ExamEvaluationResult result,
  }) {
    final scoreColor = result.percentage >= 75
        ? AppColors.statusSuccess
        : (result.percentage >= 50 ? AppColors.accentGold : AppColors.danger);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scoreColor.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score Header & Accept Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${result.score.toStringAsFixed(1)} / ${result.maxScore.toInt()} Marks',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scoreColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        result.grade,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  AppHaptics.confirm();
                  final rounded = result.score.round().clamp(0, item.marks);
                  setState(() {
                    _awardedMarks[index] = rounded;
                  });
                  ExamPaperService.instance.savePaperProgress(_selectedBranch, _awardedMarks, _revealed);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Recorded $rounded / ${item.marks} marks to exam total!'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline, size: 14),
                label: const Text('Accept Score', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusSuccess,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Mandatory Keywords Checklist
          const Text(
            'MANDATORY KEYWORDS & CONCEPTS:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...result.matchedKeywords.map((kw) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.statusSuccess.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 12, color: AppColors.statusSuccess),
                      const SizedBox(width: 4),
                      Text(
                        kw,
                        style: const TextStyle(
                          color: AppColors.statusSuccess,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              ...result.missingKeywords.map((kw) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.close, size: 12, color: AppColors.danger),
                      const SizedBox(width: 4),
                      Text(
                        kw,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),

          // Detailed Rubric Criteria Breakdown
          if (result.rubricBreakdown.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'RUBRIC CRITERIA BREAKDOWN:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            ...result.rubricBreakdown.map((rb) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      rb.met ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 13,
                      color: rb.met ? AppColors.statusSuccess : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ChemistryMarkdownView(
                        text: rb.criterion,
                        textStyle: TextStyle(
                          color: rb.met ? Colors.white : AppColors.textMuted,
                          fontSize: 11.5,
                        ),
                        selectable: false,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${rb.marksAwarded.toStringAsFixed(1)}M',
                      style: TextStyle(
                        color: rb.met ? AppColors.statusSuccess : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Pitfalls Detected
          if (result.detectedPitfalls.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.danger),
                      SizedBox(width: 6),
                      Text(
                        'EXAMINER PITFALLS TRIGGERED (MARKS DEDUCTED):',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...result.detectedPitfalls.map((p) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: ChemistryMarkdownView(
                          text: '• $p',
                          textStyle: const TextStyle(color: Colors.white, fontSize: 11.5),
                          selectable: false,
                        ),
                      )),
                ],
              ),
            ),
          ],

          // Feedback notes
          if (result.feedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'EXAMINER RUBRIC FEEDBACK:',
              style: TextStyle(
                color: AppColors.accentGold,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: ChemistryMarkdownView(
                text: result.feedback,
                textStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.3),
                selectable: false,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: EXAM ANSWER GENERATOR
  // ==========================================
  Widget _buildGeneratorTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      children: [
        const GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Indian University MSc Rubric Generator 📝',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
              ),
              SizedBox(height: 4),
              Text(
                'Enter any MSc chemistry topic, reaction, or past paper question. ChemBuddy generates the precise answer structure expected by university examiners.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Mark Selector (2M, 5M, 10M)
        Row(
          children: [2, 5, 10].map((marks) {
            final isSel = _selectedMarkType == marks;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () {
                    AppHaptics.selection();
                    setState(() => _selectedMarkType = marks);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.brandPrimary.withValues(alpha: 0.25) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? AppColors.brandBright : AppColors.borderSubtle,
                        width: isSel ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$marks Marks',
                          style: TextStyle(
                            color: isSel ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          marks == 2 ? 'Definition' : (marks == 5 ? 'Mechanism' : 'Comprehensive'),
                          style: TextStyle(
                            color: isSel ? AppColors.brandBright : AppColors.textMuted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Input Field
        TextField(
          controller: _questionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. Discuss the mechanism and stereochemistry of Diels-Alder reaction...',
            labelText: 'Chemistry Question or Topic',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () => _questionController.clear(),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Quick Topic Suggestions
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            'Diels-Alder reaction',
            'Jahn-Teller distortion',
            'Beer-Lambert Law',
            'Hückel 4n+2 Rule',
            'Claisen rearrangement',
            'SN1 vs SN2 kinetics',
          ].map((topic) {
            return ActionChip(
              label: Text(topic, style: const TextStyle(fontSize: 11)),
              backgroundColor: AppColors.bg2,
              onPressed: () {
                _questionController.text = topic;
                _generateAnswer();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Generate Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isGenerating ? null : _generateAnswer,
          icon: _isGenerating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(
            _isGenerating ? 'Generating Model Rubric...' : 'Generate $_selectedMarkType-Mark Model Answer',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
          ),
        ),
        const SizedBox(height: 16),

        // Generated Output
        if (_generatedAnswer != null)
          GlowCard(
            borderColor: AppColors.brandBright.withValues(alpha: 0.4),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$_selectedMarkType-MARK MODEL ANSWER',
                        style: const TextStyle(
                          color: AppColors.brandBright,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: AppColors.textMuted),
                      tooltip: 'Copy Answer',
                      onPressed: () {
                        AppHaptics.tap();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Model answer copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ChemistryMarkdownView(
                  text: _generatedAnswer!,
                  textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, height: 1.45),
                  selectable: true,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==========================================
  // TAB 3: FROM MY PDF
  // ==========================================
  Widget _buildPdfRevisionTab() {
    final state = ref.watch(appControllerProvider);
    final pdfs = state.pdfs;

    if (pdfs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.picture_as_pdf_outlined, size: 48, color: AppColors.textMuted),
              SizedBox(height: 14),
              Text(
                'No uploaded PDFs found',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 6),
              Text(
                'Upload your lecture slides or study notes to generate customized exam practice questions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      children: [
        const GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PDF-Grounded Exam Revision 📄',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
              ),
              SizedBox(height: 4),
              Text(
                'Select any uploaded document to open its Study Hub with exam revision shortcuts, 2M/5M questions, and model answers strictly extracted from your notes.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        ...pdfs.map((doc) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => PdfStudyHubScreen(doc: doc),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.purpleBright, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tap to open Exam Revision & Quiz →',
                          style: TextStyle(color: AppColors.purpleBright, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
