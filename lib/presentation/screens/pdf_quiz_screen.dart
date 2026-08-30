import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/chemistry_text_formatter.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../providers/app_providers.dart';
import '../../data/models/pdf_study_models.dart';
import 'smart_flashcards_generate_screen.dart';

class PdfQuizScreen extends ConsumerStatefulWidget {
  const PdfQuizScreen({super.key, required this.quiz, this.docName});
  final ChemistryQuiz quiz;
  final String? docName;

  @override
  ConsumerState<PdfQuizScreen> createState() => _PdfQuizScreenState();
}

class _PdfQuizScreenState extends ConsumerState<PdfQuizScreen> {
  int _currentIndex = 0;
  final Map<int, int> _userAnswers = {};
  bool _submittedCurrent = false;
  bool _finished = false;
  QuizResult? _result;

  void _selectOption(int optionIndex) {
    if (_submittedCurrent) return;
    setState(() {
      _userAnswers[_currentIndex] = optionIndex;
      _submittedCurrent = true;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentIndex += 1;
        _submittedCurrent = _userAnswers.containsKey(_currentIndex);
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    var score = 0;
    final weakTopics = <String>{};

    for (var i = 0; i < widget.quiz.questions.length; i++) {
      final q = widget.quiz.questions[i];
      final userAns = _userAnswers[i];
      if (userAns == q.correctIndex) {
        score += 1;
      } else {
        weakTopics.add(q.topic);
      }
    }

    final total = widget.quiz.questions.length;
    final accuracy = total > 0 ? (score / total) * 100 : 0.0;

    final recommended = <String>[];
    if (weakTopics.isNotEmpty) {
      recommended.add('Review weak topics: ${weakTopics.take(3).join(", ")}');
      recommended.add('Generate a targeted 10-card Flashcard deck on these concepts');
    } else {
      recommended.add('Excellent mastery! Move on to the next chapter or try 30 questions');
    }

    final res = QuizResult(
      id: const Uuid().v4(),
      quizId: widget.quiz.id,
      quizTitle: widget.quiz.title,
      score: score,
      totalQuestions: total,
      accuracy: accuracy,
      weakTopics: weakTopics.toList(),
      recommendedRevision: recommended,
      userAnswers: _userAnswers,
      completedAt: DateTime.now(),
    );

    await ref.read(appControllerProvider.notifier).saveQuizResult(res);

    setState(() {
      _result = res;
      _finished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_finished && _result != null) {
      return _buildResultScreen(_result!);
    }

    if (widget.quiz.questions.isEmpty) {
      return HexBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              widget.quiz.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.quiz_outlined, size: 48, color: AppColors.warning),
                  const SizedBox(height: 16),
                  const Text('No Questions Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text(
                    'Could not generate quiz questions from this document. Try re-generating or analyzing a different document.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final total = widget.quiz.questions.length;
    final safeIndex = _currentIndex.clamp(0, total - 1);
    final q = widget.quiz.questions[safeIndex];
    final progress = (safeIndex + 1) / total;
    final selectedOption = _userAnswers[safeIndex];

    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.quiz.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // Progress Bar
            Row(
              children: [
                Text(
                  'QUESTION ${_currentIndex + 1} OF $total',
                  style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.1),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    q.type.name.toUpperCase(),
                    style: const TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purpleBright),
              ),
            ),
            const SizedBox(height: 16),

            // Question Card
            GlowCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.purple.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (q.topic.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        q.topic,
                        style: const TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  Text(
                    ChemistryTextFormatter.format(q.question),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.35, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Options List
            ...List.generate(q.options.length, (optIdx) {
              final optText = q.options[optIdx];
              final isChosen = selectedOption == optIdx;
              final isCorrect = q.correctIndex == optIdx;

              Color borderColor = AppColors.border;
              Color textColor = Colors.white;

              if (_submittedCurrent) {
                if (isCorrect) {
                  borderColor = AppColors.success;
                  textColor = AppColors.success;
                } else if (isChosen && !isCorrect) {
                  borderColor = AppColors.danger;
                  textColor = AppColors.danger;
                }
              } else if (isChosen) {
                borderColor = AppColors.purpleBright;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlowCard(
                  borderColor: borderColor,
                  padding: const EdgeInsets.all(14),
                  onTap: () => _selectOption(optIdx),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _submittedCurrent && isCorrect
                              ? AppColors.success
                              : (_submittedCurrent && isChosen
                                  ? AppColors.danger
                                  : AppColors.surfaceElevated),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          String.fromCharCode(65 + optIdx), // A, B, C, D
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _submittedCurrent && (isCorrect || isChosen) ? Colors.black : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ChemistryTextFormatter.format(optText),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isChosen ? FontWeight.w700 : FontWeight.w500,
                            color: textColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Explanation Card (Visible after answering)
            if (_submittedCurrent) ...[
              const SizedBox(height: 10),
              GlowCard(
                borderColor: (selectedOption == q.correctIndex ? AppColors.success : AppColors.warning).withValues(alpha: 0.5),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          selectedOption == q.correctIndex ? Icons.check_circle : Icons.info_outline,
                          color: selectedOption == q.correctIndex ? AppColors.success : AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedOption == q.correctIndex ? 'Correct Explanation' : 'Academic Explanation',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: selectedOption == q.correctIndex ? AppColors.success : AppColors.warning,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ChemistryTextFormatter.format(q.explanation),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
                    ),
                    if (q.numerical != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Formula: ${q.numerical!.formula}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
                            Text('Calculation: ${q.numerical!.calculation} = ${q.numerical!.answer} ${q.numerical!.unit}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _currentIndex == total - 1 ? 'View Quiz Results 📊' : 'Next Question →',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Final Results Screen
  Widget _buildResultScreen(QuizResult result) {
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Quiz Results', style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // Score Card
            GlowCard(
              padding: const EdgeInsets.all(20),
              borderColor: result.accuracy >= 70 ? AppColors.success : AppColors.warning,
              child: Column(
                children: [
                  Text(
                    result.accuracy >= 70 ? '🎉 Great Job!' : '📚 Study Review Needed',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${result.score}',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: result.accuracy >= 70 ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      Text(
                        ' / ${result.totalQuestions}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: (result.accuracy >= 70 ? AppColors.success : AppColors.warning).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${result.accuracy.toStringAsFixed(1)}% Accuracy',
                      style: TextStyle(
                        color: result.accuracy >= 70 ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Weak Areas Breakdown
            if (result.weakTopics.isNotEmpty) ...[
              const Text('Areas for Improvement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 8),
              GlowCard(
                borderColor: AppColors.warning.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('You encountered difficulty with these topics:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    const SizedBox(height: 8),
                    ...result.weakTopics.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 16, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Recommended Next Step
            const Text('Recommended Next Step', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            GlowCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...result.recommendedRevision.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('👉 ', style: TextStyle(fontSize: 14)),
                          Expanded(child: Text(r, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3))),
                        ],
                      ),
                    ),
                  ),
                  if (result.weakTopics.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.purple.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => SmartFlashcardsGenerateScreen(
                                prefilledTopic: result.weakTopics.join(', '),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.style_outlined, color: AppColors.purpleBright, size: 18),
                        label: const Text('Create Flashcards on Weak Topics', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0;
                        _userAnswers.clear();
                        _submittedCurrent = false;
                        _finished = false;
                        _result = null;
                      });
                    },
                    child: const Text('Retake Quiz', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
