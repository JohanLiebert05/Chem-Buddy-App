import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/flashcard_evaluation.dart';
import '../../data/models/smart_flashcard.dart';

/// Modal bottom sheet displaying the AI Active Recall Evaluation results.
class FlashcardEvaluationModal extends StatelessWidget {
  const FlashcardEvaluationModal({
    super.key,
    required this.evaluation,
    required this.onApplyRating,
    this.preview,
  });

  final FlashcardAiEvaluation evaluation;
  final ValueChanged<FlashcardRating> onApplyRating;
  final ReviewSchedulePreview? preview;

  static Future<void> show({
    required BuildContext context,
    required FlashcardAiEvaluation evaluation,
    required ValueChanged<FlashcardRating> onApplyRating,
    ReviewSchedulePreview? preview,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FlashcardEvaluationModal(
        evaluation: evaluation,
        onApplyRating: onApplyRating,
        preview: preview,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = evaluation.matchPercentage;
    Color scoreColor;
    String scoreGrade;
    if (score >= 85) {
      scoreColor = AppColors.success;
      scoreGrade = 'Excellent Recall';
    } else if (score >= 70) {
      scoreColor = AppColors.blue;
      scoreGrade = 'Solid Retention';
    } else if (score >= 40) {
      scoreColor = AppColors.warning;
      scoreGrade = 'Needs Polish';
    } else {
      scoreColor = AppColors.danger;
      scoreGrade = 'Review Required';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.purpleBright, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI Active Recall Evaluation',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Score Badge & Progress
          GlowCard(
            borderColor: scoreColor.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 5,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                    Text(
                      '$score%',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: scoreColor),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scoreGrade,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: scoreColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chemical Accuracy & Concept Alignment',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Covered & Missed Terms
          if (evaluation.coveredTerms.isNotEmpty || evaluation.missedTerms.isNotEmpty) ...[
            if (evaluation.coveredTerms.isNotEmpty) ...[
              Row(
                children: const [
                  Icon(Icons.check_circle, color: AppColors.success, size: 15),
                  SizedBox(width: 6),
                  Text(
                    'COVERED CONCEPTS',
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.8),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: evaluation.coveredTerms.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Text(
                    '✓ $t',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],

            if (evaluation.missedTerms.isNotEmpty) ...[
              Row(
                children: const [
                  Icon(Icons.cancel, color: AppColors.danger, size: 15),
                  SizedBox(width: 6),
                  Text(
                    'MISSED / INCOMPLETE TERMS',
                    style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.8),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: evaluation.missedTerms.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Text(
                    '✗ $t',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ],

          // Feedback Note
          if (evaluation.feedback.isNotEmpty) ...[
            const Text(
              'ACADEMIC FEEDBACK',
              style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.8),
            ),
            const SizedBox(height: 6),
            GlowCard(
              padding: const EdgeInsets.all(12),
              borderColor: AppColors.purple.withValues(alpha: 0.3),
              child: ChemistryMarkdownView(
                text: evaluation.feedback,
                textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.35),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Recommended Action Prompt
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.purpleBright.withValues(alpha: 0.4)),
              ),
              child: Text(
                '✨ AI Recommendation: ${evaluation.recommendedLabel}',
                style: const TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Rating Choice Buttons
          Row(
            children: [
              Expanded(
                child: _buildChoiceButton(
                  context: context,
                  label: 'Again',
                  interval: preview?.againLabel ?? '<10m',
                  color: AppColors.danger,
                  rating: FlashcardRating.again,
                  isRecommended: evaluation.recommendedAction == FlashcardRating.again,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildChoiceButton(
                  context: context,
                  label: 'Hard',
                  interval: preview?.hardLabel ?? '1.2d',
                  color: AppColors.warning,
                  rating: FlashcardRating.hard,
                  isRecommended: evaluation.recommendedAction == FlashcardRating.hard,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildChoiceButton(
                  context: context,
                  label: 'Good',
                  interval: preview?.goodLabel ?? '2.5d',
                  color: AppColors.success,
                  rating: FlashcardRating.good,
                  isRecommended: evaluation.recommendedAction == FlashcardRating.good,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildChoiceButton(
                  context: context,
                  label: 'Easy',
                  interval: preview?.easyLabel ?? '4.0d',
                  color: AppColors.blue,
                  rating: FlashcardRating.easy,
                  isRecommended: evaluation.recommendedAction == FlashcardRating.easy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton({
    required BuildContext context,
    required String label,
    required String interval,
    required Color color,
    required FlashcardRating rating,
    required bool isRecommended,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onApplyRating(rating);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isRecommended ? color.withValues(alpha: 0.22) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRecommended ? color : AppColors.border,
              width: isRecommended ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isRecommended ? Colors.white : color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                interval,
                style: TextStyle(
                  color: isRecommended ? Colors.white70 : AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
