import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/services/exam_paper_service.dart';

export '../../data/services/exam_paper_service.dart' show ChemistryBranch, ExamQuestionItem;

class ExamPatternQuizScreen extends ConsumerStatefulWidget {
  const ExamPatternQuizScreen({super.key, this.examTitle = 'MSc Chemistry End-Semester Examination'});

  final String examTitle;

  @override
  ConsumerState<ExamPatternQuizScreen> createState() => _ExamPatternQuizScreenState();
}

class _ExamPatternQuizScreenState extends ConsumerState<ExamPatternQuizScreen> {
  ChemistryBranch _selectedBranch = ChemistryBranch.all;
  final Map<int, bool> _revealed = {};
  final Map<int, int> _awardedMarks = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    final progress = await ExamPaperService.instance.loadPaperProgress(_selectedBranch);
    if (mounted) {
      setState(() {
        _awardedMarks.clear();
        _awardedMarks.addAll(progress.marks);
        _revealed.clear();
        _revealed.addAll(progress.revealed);
        _isLoading = false;
      });
    }
  }

  void _switchBranch(ChemistryBranch branch) {
    if (_selectedBranch == branch) return;
    AppHaptics.selection();
    setState(() {
      _selectedBranch = branch;
    });
    _loadProgress();
  }

  void _toggleReveal(int index, bool current) {
    AppHaptics.tap();
    setState(() {
      _revealed[index] = !current;
    });
    ExamPaperService.instance.savePaperProgress(_selectedBranch, _awardedMarks, _revealed);
  }

  void _setAwardedMark(int index, int mark) {
    AppHaptics.selection();
    setState(() {
      _awardedMarks[index] = mark;
    });
    ExamPaperService.instance.savePaperProgress(_selectedBranch, _awardedMarks, _revealed);
  }

  void _resetProgress() {
    AppHaptics.tap();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg1,
        title: const Text('Reset Paper Progress?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'This will clear your self-assessed marks and revealed answers for ${_selectedBranch.name}.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDanger),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _awardedMarks.clear();
                _revealed.clear();
              });
              ExamPaperService.instance.savePaperProgress(_selectedBranch, _awardedMarks, _revealed);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPaper = ExamPaperService.getPaperForBranch(_selectedBranch);
    final totalPossibleMarks = currentPaper.fold(0, (sum, q) => sum + q.marks);
    final currentEarnedMarks = _awardedMarks.values.fold(0, (sum, m) => sum + m);
    final scorePercent = totalPossibleMarks > 0 ? ((currentEarnedMarks / totalPossibleMarks) * 100).clamp(0, 100) : 0;

    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.examTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted, size: 20),
              tooltip: 'Reset Paper',
              onPressed: _resetProgress,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Branch Selection Filter Carousel / Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ChemistryBranch.values.map((branch) {
                  final isSelected = _selectedBranch == branch;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _switchBranch(branch),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.brandPrimary : AppColors.bg1,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.brandBright : AppColors.borderSubtle,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(branch.icon, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              branch.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Branch Description Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bg0.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.brandBright, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedBranch.subtitle,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Exam Header Banner
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded, color: AppColors.brandBright, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedBranch.name} Paper',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Marks: $totalPossibleMarks • Your Score: $currentEarnedMarks / $totalPossibleMarks',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${scorePercent.toStringAsFixed(0)}%',
                      style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else
              // Questions List
              ...List.generate(currentPaper.length, (i) {
                final q = currentPaper[i];
                final isRevealed = _revealed[i] ?? false;
                final score = _awardedMarks[i] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlowCard(
                    padding: const EdgeInsets.all(16),
                    borderColor: isRevealed ? AppColors.brandBright.withValues(alpha: 0.4) : AppColors.borderSubtle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.bg2,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Q${i + 1} • ${q.section}',
                                style: const TextStyle(color: AppColors.brandBright, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '[${q.marks} Marks]',
                                style: const TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ChemistryMarkdownView(
                          text: q.question,
                          textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white, height: 1.4),
                        ),
                        const SizedBox(height: 14),

                        // Model Answer Reveal Button
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isRevealed ? AppColors.statusSuccess : AppColors.brandBright,
                                  side: BorderSide(color: isRevealed ? AppColors.statusSuccess : AppColors.borderHighlight),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _toggleReveal(i, isRevealed),
                                icon: Icon(isRevealed ? Icons.visibility_off : Icons.visibility, size: 16),
                                label: Text(isRevealed ? 'Hide Model Answer' : 'Reveal Model Answer & Rubric'),
                              ),
                            ),
                          ],
                        ),

                        // Answer and Rubric
                        if (isRevealed) ...[
                          const Divider(color: AppColors.borderSubtle, height: 24),
                          const Text('MODEL ACADEMIC ANSWER', style: TextStyle(color: AppColors.statusSuccess, fontSize: 11, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          ChemistryMarkdownView(
                            text: q.modelAnswer,
                            textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.45),
                          ),
                          const SizedBox(height: 12),
                          const Text('EXAMINATION MARKING RUBRIC', style: TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          ...q.markingRubric.map((rubric) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w800)),
                                Expanded(child: Text(rubric, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5))),
                              ],
                            ),
                          )),
                          const SizedBox(height: 12),

                          // Self-grading Bar
                          Row(
                            children: [
                              const Text('Self-Assess Score: ', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                              const Spacer(),
                              ...List.generate(q.marks + 1, (m) {
                                final isSelected = score == m;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: InkWell(
                                    onTap: () => _setAwardedMark(i, m),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.brandPrimary : AppColors.bg2,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: isSelected ? AppColors.brandBright : AppColors.borderSubtle),
                                      ),
                                      child: Text(
                                        '$m',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : AppColors.textMuted,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
