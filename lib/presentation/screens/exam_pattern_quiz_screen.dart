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
  String _selectedSectionFilter = 'All';
  final Map<int, bool> _revealed = {};
  final Map<int, int> _awardedMarks = {};
  final Map<int, Set<int>> _checkedRubrics = {};
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
        _checkedRubrics.clear();
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

  void _toggleRubricCheck(int qIndex, int rubricIndex, ExamQuestionItem q) {
    AppHaptics.selection();
    setState(() {
      final currentSet = _checkedRubrics.putIfAbsent(qIndex, () => <int>{});
      if (currentSet.contains(rubricIndex)) {
        currentSet.remove(rubricIndex);
      } else {
        currentSet.add(rubricIndex);
      }

      if (q.markingRubric.isNotEmpty) {
        final ratio = currentSet.length / q.markingRubric.length;
        final autoMark = (ratio * q.marks).round().clamp(0, q.marks);
        _awardedMarks[qIndex] = autoMark;
      }
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
                _checkedRubrics.clear();
              });
              ExamPaperService.instance.savePaperProgress(_selectedBranch, _awardedMarks, _revealed);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAiStrategyDialog(ExamQuestionItem q, int qNumber) {
    AppHaptics.selection();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology_rounded, color: AppColors.brandBright, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q$qNumber • Exam Blueprint', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(q.topic.isNotEmpty ? q.topic : q.section, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Intelligence Metadata Row
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bar_chart_rounded, size: 14, color: AppColors.accentGold),
                        const SizedBox(width: 6),
                        const Text('Difficulty: ', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                        Text(q.difficulty.isNotEmpty ? q.difficulty : 'University Standard', style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.history_edu_rounded, size: 14, color: AppColors.brandBright),
                        const SizedBox(width: 6),
                        const Text('Pattern: ', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                        Expanded(
                          child: Text(
                            q.frequency.isNotEmpty ? q.frequency : 'Standard University Syllabus Question',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.brandBright, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('💡 EXAMINER TIPS & HIGH-SCORING STRATEGY', style: TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.25)),
                ),
                child: Text(
                  q.examTips.isNotEmpty ? q.examTips : 'Always draw clean chemical structures, state conditions (temperature, catalyst, solvent), and write step-by-step mechanisms.',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5, height: 1.45),
                ),
              ),
              const SizedBox(height: 14),
              const Text('🎯 KEY EVALUATION CRITERIA', style: TextStyle(color: AppColors.statusSuccess, fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              ...q.markingRubric.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✓ ', style: TextStyle(color: AppColors.statusSuccess, fontWeight: FontWeight.w800, fontSize: 12)),
                    Expanded(child: Text(r, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  (String grade, String label, Color color) _calculateGrade(double percent) {
    if (percent >= 90) return ('O', 'Outstanding (10.0 GPA)', AppColors.accentGold);
    if (percent >= 80) return ('A+', 'Excellent (9.0 GPA)', AppColors.statusSuccess);
    if (percent >= 70) return ('A', 'Very Good (8.0 GPA)', AppColors.brandBright);
    if (percent >= 60) return ('B+', 'Good (7.0 GPA)', AppColors.purpleBright);
    if (percent >= 50) return ('B', 'Above Average (6.0 GPA)', AppColors.textSecondary);
    return ('RA', 'Re-Appear / Revision Needed', AppColors.statusDanger);
  }

  @override
  Widget build(BuildContext context) {
    final fullPaper = ExamPaperService.getPaperForBranch(_selectedBranch);
    final totalPossibleMarks = fullPaper.fold(0, (sum, q) => sum + q.marks);
    final currentEarnedMarks = _awardedMarks.values.fold(0, (sum, m) => sum + m);
    final scorePercent = totalPossibleMarks > 0 ? ((currentEarnedMarks / totalPossibleMarks) * 100.0).clamp(0.0, 100.0) : 0.0;
    final (projectedGrade, gradeLabel, gradeColor) = _calculateGrade(scorePercent);

    // Apply Section Filter
    final filteredPaperWithIndices = <(int originalIndex, ExamQuestionItem question)>[];
    for (var i = 0; i < fullPaper.length; i++) {
      final q = fullPaper[i];
      if (_selectedSectionFilter == 'All') {
        filteredPaperWithIndices.add((i, q));
      } else if (_selectedSectionFilter == 'Part A (2M)' && (q.marks == 2 || q.section.contains('A'))) {
        filteredPaperWithIndices.add((i, q));
      } else if (_selectedSectionFilter == 'Part B (5M)' && (q.marks == 5 || q.section.contains('B'))) {
        filteredPaperWithIndices.add((i, q));
      } else if (_selectedSectionFilter == 'Part C (10M)' && (q.marks >= 10 || q.section.contains('C'))) {
        filteredPaperWithIndices.add((i, q));
      }
    }

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
            // Branch Selection Filter Row
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

            // Smart Exam Header Banner with Projected Grade GPA
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
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
                              '${_selectedBranch.name} Exam Blueprint',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: $totalPossibleMarks Marks • Self-Assessed: $currentEarnedMarks / $totalPossibleMarks',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: gradeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: gradeColor.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Grade: $projectedGrade',
                              style: TextStyle(color: gradeColor, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                            Text(
                              '${scorePercent.toStringAsFixed(0)}%',
                              style: TextStyle(color: gradeColor, fontWeight: FontWeight.w700, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Projected University Standard: $gradeLabel',
                        style: TextStyle(color: gradeColor, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Section Filter Tabs (All, Part A, Part B, Part C)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in ['All', 'Part A (2M)', 'Part B (5M)', 'Part C (10M)'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: _selectedSectionFilter == filter,
                        selectedColor: AppColors.brandPrimary,
                        backgroundColor: AppColors.bg2,
                        labelStyle: TextStyle(
                          color: _selectedSectionFilter == filter ? Colors.white : AppColors.textSecondary,
                          fontWeight: _selectedSectionFilter == filter ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) {
                            AppHaptics.selection();
                            setState(() => _selectedSectionFilter = filter);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else
              // Questions List
              ...List.generate(filteredPaperWithIndices.length, (idx) {
                final item = filteredPaperWithIndices[idx];
                final origIndex = item.$1;
                final q = item.$2;
                final isRevealed = _revealed[origIndex] ?? false;
                final score = _awardedMarks[origIndex] ?? 0;
                final checkedSet = _checkedRubrics[origIndex] ?? <int>{};

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlowCard(
                    padding: const EdgeInsets.all(16),
                    borderColor: isRevealed ? AppColors.brandBright.withValues(alpha: 0.4) : AppColors.borderSubtle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Meta: Section, Marks, Topic & AI Blueprint Button
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.bg2,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Q${origIndex + 1} • ${q.section}',
                                style: const TextStyle(color: AppColors.brandBright, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (q.topic.isNotEmpty)
                              Expanded(
                                child: Text(
                                  q.topic,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              )
                            else
                              const Spacer(),
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
                        const SizedBox(height: 10),

                        // Question Text
                        ChemistryMarkdownView(
                          text: q.question,
                          textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white, height: 1.4),
                        ),
                        const SizedBox(height: 12),

                        // Action Buttons: AI Blueprint & Reveal Model Answer
                        Row(
                          children: [
                            InkWell(
                              onTap: () => _showAiStrategyDialog(q, origIndex + 1),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.brandPrimary.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.brandBright.withValues(alpha: 0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.psychology_rounded, size: 15, color: AppColors.brandBright),
                                    SizedBox(width: 5),
                                    Text('AI Blueprint', style: TextStyle(color: AppColors.brandBright, fontSize: 11.5, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isRevealed ? AppColors.statusSuccess : AppColors.brandBright,
                                  side: BorderSide(color: isRevealed ? AppColors.statusSuccess : AppColors.borderHighlight),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () => _toggleReveal(origIndex, isRevealed),
                                icon: Icon(isRevealed ? Icons.visibility_off : Icons.visibility, size: 15),
                                label: Text(isRevealed ? 'Hide Answer' : 'Model Answer & Rubric', style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),

                        // Answer and Rubric
                        if (isRevealed) ...[
                          const Divider(color: AppColors.borderSubtle, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('MODEL ACADEMIC ANSWER', style: TextStyle(color: AppColors.statusSuccess, fontSize: 11, fontWeight: FontWeight.w800)),
                              if (q.difficulty.isNotEmpty)
                                Text(q.difficulty, style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ChemistryMarkdownView(
                            text: q.modelAnswer,
                            textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.45),
                          ),
                          const SizedBox(height: 14),

                          // Interactive Marking Rubric Checklist
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('EXAMINATION MARKING RUBRIC (Check to score)', style: TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.w800)),
                              Text('${checkedSet.length}/${q.markingRubric.length} checked', style: const TextStyle(color: AppColors.accentGold, fontSize: 10.5, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...List.generate(q.markingRubric.length, (rIdx) {
                            final isChecked = checkedSet.contains(rIdx);
                            final rubricText = q.markingRubric[rIdx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: InkWell(
                                onTap: () => _toggleRubricCheck(origIndex, rIdx, q),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isChecked ? AppColors.accentGold.withValues(alpha: 0.12) : AppColors.bg2,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isChecked ? AppColors.accentGold.withValues(alpha: 0.4) : AppColors.borderSubtle,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                        size: 16,
                                        color: isChecked ? AppColors.accentGold : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ChemistryMarkdownView(
                                          text: rubricText,
                                          textStyle: TextStyle(
                                            color: isChecked ? Colors.white : AppColors.textSecondary,
                                            fontSize: 12,
                                            fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 12),

                          // Self-grading Bar
                          Row(
                            children: [
                              Text('Assessed: $score/${q.marks} Marks', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                              const Spacer(),
                              ...List.generate(q.marks + 1, (m) {
                                final isSelected = score == m;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: InkWell(
                                    onTap: () => _setAwardedMark(origIndex, m),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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
                                          fontSize: 11,
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

