import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/claude_loading_text.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/library_models.dart';
import '../../data/models/pdf_study_models.dart';
import '../../data/services/pdf_ai_study_service.dart';
import '../../data/services/pdf_text_extraction_service.dart';
import '../providers/app_providers.dart';
import '../screens/pdf_quiz_screen.dart';

/// Modal dialog / bottom sheet that lets students configure and generate
/// a strictly document-grounded MSc Chemistry quiz.
class PdfQuizSetupDialog extends ConsumerStatefulWidget {
  const PdfQuizSetupDialog({
    super.key,
    required this.documentTitle,
    this.sourceText = '',
    this.docId = '',
    this.doc,
    this.initialConfig,
  });

  final String documentTitle;
  final String sourceText;
  final String docId;
  final PdfDoc? doc;
  final PdfQuizConfig? initialConfig;

  static Future<void> show(
    BuildContext context, {
    required String documentTitle,
    String sourceText = '',
    String docId = '',
    PdfDoc? doc,
    PdfQuizConfig? initialConfig,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PdfQuizSetupDialog(
        documentTitle: documentTitle,
        sourceText: sourceText,
        docId: docId,
        doc: doc,
        initialConfig: initialConfig,
      ),
    );
  }

  @override
  ConsumerState<PdfQuizSetupDialog> createState() => _PdfQuizSetupDialogState();
}

class _PdfQuizSetupDialogState extends ConsumerState<PdfQuizSetupDialog> {
  late QuizMode _selectedMode;
  late int _selectedCount;
  late QuizDifficulty _selectedDifficulty;
  late Set<QuizQuestionType> _selectedTypes;

  bool _loading = false;
  String _progressStatus = 'Analyzing document...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final cfg = widget.initialConfig ?? const PdfQuizConfig();
    _selectedMode = cfg.mode;
    _selectedCount = cfg.count;
    _selectedDifficulty = cfg.difficulty;
    _selectedTypes = Set.from(cfg.questionTypes);
  }

  void _onModeChanged(QuizMode mode) {
    AppHaptics.selection();
    setState(() {
      _selectedMode = mode;
      if (mode == QuizMode.smartQuiz) {
        _selectedCount = 20;
        _selectedDifficulty = QuizDifficulty.mixed;
        _selectedTypes = {
          QuizQuestionType.conceptual,
          QuizQuestionType.reaction,
          QuizQuestionType.mechanism,
          QuizQuestionType.spectroscopy,
          QuizQuestionType.numerical,
        };
      } else if (mode == QuizMode.importantTopics) {
        _selectedCount = 15;
        _selectedDifficulty = QuizDifficulty.hard;
        _selectedTypes = {
          QuizQuestionType.conceptual,
          QuizQuestionType.reaction,
          QuizQuestionType.mechanism,
        };
      }
    });
  }

  Future<void> _startQuizGeneration() async {
    AppHaptics.confirm();
    setState(() {
      _loading = true;
      _errorMessage = null;
      _progressStatus = 'Reading document structure & topics...';
    });

    try {
      String resolvedText = widget.sourceText;
      if (resolvedText.trim().isEmpty && widget.doc != null) {
        final store = ref.read(localStoreProvider);
        final bundle = store.getDocumentOcrBundle(widget.doc!.id);
        if (bundle != null && bundle.fullText.trim().isNotEmpty) {
          resolvedText = bundle.fullText;
        } else {
          setState(() => _progressStatus = 'Extracting text from PDF...');
          resolvedText = await PdfTextExtractionService.instance.extractFromPath(
            widget.doc!.localPath,
            onProgress: (status) {
              if (mounted) setState(() => _progressStatus = status);
            },
          );
        }
      }

      if (resolvedText.trim().isEmpty) {
        throw Exception('Could not extract readable text from this PDF.');
      }

      final service = ref.read(pdfAiStudyServiceProvider);
      final config = PdfQuizConfig(
        count: _selectedCount,
        difficulty: _selectedDifficulty,
        questionTypes: _selectedTypes,
        mode: _selectedMode,
      );

      final quiz = await service.generateQuiz(
        sourceText: resolvedText,
        documentTitle: widget.documentTitle,
        docId: widget.docId.isNotEmpty ? widget.docId : (widget.doc?.id ?? ''),
        config: config,
        onProgress: (status) {
          if (mounted) {
            setState(() => _progressStatus = status);
          }
        },
      );

      // Save quiz to repository for local persistence
      await ref.read(appControllerProvider.notifier).saveQuiz(quiz);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => PdfQuizScreen(
              quiz: quiz,
              docName: widget.documentTitle,
              doc: widget.doc,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString().contains('Exception:')
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Could not generate quiz. Check connection and ensure the PDF has readable text.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final classification = PdfAiStudyService.classifyDocumentSubject(
      widget.sourceText.isNotEmpty ? widget.sourceText : widget.documentTitle,
      widget.documentTitle,
    );

    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF131024),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.borderHighlight, width: 1.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.purpleBright.withValues(alpha: 0.4), width: 0.8),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.purpleBright, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.documentTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            classification.branchCategory,
                            style: const TextStyle(color: AppColors.brandBright, fontSize: 10.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('· Strict PDF Grounding 🔒', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: _loading ? null : () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mode Selector
          const Text('Quiz Generation Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildModeOption(
                mode: QuizMode.smartQuiz,
                title: '✨ Smart Quiz',
                subtitle: 'Auto-balanced',
              ),
              const SizedBox(width: 8),
              _buildModeOption(
                mode: QuizMode.importantTopics,
                title: '🔥 High Priority',
                subtitle: 'Exam Core',
              ),
              const SizedBox(width: 8),
              _buildModeOption(
                mode: QuizMode.custom,
                title: '⚙️ Custom',
                subtitle: 'Full Control',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question Count Selector
          Row(
            children: [
              const Text('Question Count', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              if (_selectedMode == QuizMode.smartQuiz)
                const Text('(Recommended: 20)', style: TextStyle(color: AppColors.brandBright, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [10, 20, 30, 40].map((c) {
              final isSel = _selectedCount == c;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Center(
                      child: Text(
                        '$c',
                        style: TextStyle(
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    selected: isSel,
                    selectedColor: AppColors.purple.withValues(alpha: 0.35),
                    backgroundColor: AppColors.surfaceElevated,
                    side: BorderSide(
                      color: isSel ? AppColors.purpleBright : AppColors.borderSubtle,
                      width: isSel ? 1.2 : 0.8,
                    ),
                    onSelected: (val) {
                      if (val) {
                        AppHaptics.selection();
                        setState(() => _selectedCount = c);
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Difficulty Selector
          const Text('Academic Difficulty', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: QuizDifficulty.values.map((d) {
              final isSel = _selectedDifficulty == d;
              return ChoiceChip(
                label: Text('${d.label} ${d == QuizDifficulty.mixed ? "(Recommended)" : ""}'),
                selected: isSel,
                selectedColor: AppColors.purple.withValues(alpha: 0.35),
                backgroundColor: AppColors.surfaceElevated,
                side: BorderSide(
                  color: isSel ? AppColors.purpleBright : AppColors.borderSubtle,
                  width: isSel ? 1.2 : 0.8,
                ),
                onSelected: (val) {
                  if (val) {
                    AppHaptics.selection();
                    setState(() => _selectedDifficulty = d);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Grounding Guarantee Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle, width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.verified_user_outlined, color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Single Source of Truth: All questions, answers, and explanations are verified against this document. Every question cites its exact page with direct snippet verification.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Error banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Loading Indicator or Primary CTA
          if (_loading) ...[
            GlowCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  ClaudeThinkingIndicator(
                    thoughts: [_progressStatus, ...ClaudeThinkingMicrocopy.quiz],
                    isCard: false,
                    showSparkle: true,
                    fontSize: 12.5,
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.purple.withValues(alpha: 0.5),
              ),
              onPressed: _startQuizGeneration,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Generate $_selectedCount Questions 🚀',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required QuizMode mode,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onModeChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandPrimary.withValues(alpha: 0.25) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.brandBright : AppColors.borderSubtle,
              width: isSelected ? 1.4 : 0.8,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12.5,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? AppColors.brandBright : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
