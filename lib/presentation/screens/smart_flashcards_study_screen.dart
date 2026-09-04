import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../core/widgets/flip_card_3d.dart';
import '../../core/widgets/glow_card.dart';

import '../../data/models/flashcard_evaluation.dart';
import '../../data/models/smart_flashcard.dart';
import '../../data/services/flashcard_evaluation_service.dart';
import '../providers/app_providers.dart';
import '../widgets/flashcard_evaluation_modal.dart';

class SmartFlashcardsStudyScreen extends ConsumerStatefulWidget {
  const SmartFlashcardsStudyScreen({
    super.key,
    required this.setId,
    this.review = ReviewMode.all,
  });

  final String setId;
  final ReviewMode review;

  @override
  ConsumerState<SmartFlashcardsStudyScreen> createState() => _SmartFlashcardsStudyScreenState();
}

class _SmartFlashcardsStudyScreenState extends ConsumerState<SmartFlashcardsStudyScreen> {
  final answer = TextEditingController();
  final _evalService = FlashcardEvaluationService();
  late List<SmartFlashcard> deck;
  late String sessionId;
  int index = 0;
  FlashcardUiState phase = FlashcardUiState.unanswered;
  bool _savingRating = false;
  bool _evaluatingWithAi = false;
  FlashcardAiEvaluation? _currentEvaluation;

  // Session Statistics
  int _againCount = 0;
  int _hardCount = 0;
  int _goodCount = 0;
  int _easyCount = 0;
  int _initialDeckSize = 0;

  @override
  void initState() {
    super.initState();
    final service = ref.read(flashcardServiceProvider);
    List<SmartFlashcard> cards;

    if (widget.review == ReviewMode.due) {
      cards = service.getDueCards(widget.setId.isNotEmpty ? widget.setId : null);
    } else if (widget.review == ReviewMode.newCards) {
      cards = service.getNewCards(widget.setId.isNotEmpty ? widget.setId : null);
    } else if (widget.review == ReviewMode.spacedRepetition) {
      cards = service.getSpacedRepetitionQueue(setId: widget.setId.isNotEmpty ? widget.setId : null);
    } else if (widget.review == ReviewMode.difficult) {
      final all = widget.setId.isNotEmpty ? service.cardsFor(widget.setId) : service.allCards();
      cards = all.where((c) => c.status == FlashcardUiState.difficult || c.srState == FlashcardSrState.lapse).toList();
    } else {
      cards = widget.setId.isNotEmpty ? service.cardsFor(widget.setId) : service.allCards();
    }

    deck = List<SmartFlashcard>.from(cards);
    _initialDeckSize = deck.length;
    sessionId = const Uuid().v4();

    service.saveSession(
      StudySession(
        id: sessionId,
        userId: service.remote.userId,
        flashcardSetId: widget.setId,
        currentPosition: 0,
        completed: false,
        startedAt: DateTime.now(),
        reviewMode: widget.review.name,
      ),
    );
    service.syncPending();
  }

  @override
  void dispose() {
    answer.dispose();
    super.dispose();
  }

  SmartFlashcard? get current => index < deck.length ? deck[index] : null;

  @override
  Widget build(BuildContext context) {
    if (deck.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, title: const Text('Smart Flashcards')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: GlowCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                const SizedBox(height: 12),
                const Text('All caught up! 🎉', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
                const SizedBox(height: 8),
                const Text(
                  'No flashcards currently due for review in this queue. Great job staying consistent!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Back to Library',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final card = current;
    if (card == null) return _complete();

    final progress = _initialDeckSize > 0 ? (index / _initialDeckSize).clamp(0.0, 1.0) : 1.0;
    final preview = ref.read(flashcardServiceProvider).scheduler.calculateSchedulePreview(card);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Flashcard Review'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${index + 1} / ${deck.length}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.purpleBright, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${index + 1} of ${deck.length}',
                style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
              _buildStateBadge(card),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              color: AppColors.purpleBright,
              backgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(height: 16),

          // 3D Perspective Flashcard (Question on Front, Answer on Back)
          FlipCard3D(
            isFlipped: phase != FlashcardUiState.unanswered,
            onFlip: (isBack) {
              if (isBack && phase == FlashcardUiState.unanswered) {
                _reveal();
              }
            },
            front: GlowCard(
              borderColor: AppColors.purple.withValues(alpha: 0.40),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (card.topic.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            card.topic.toUpperCase(),
                            style: const TextStyle(color: AppColors.purpleBright, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  ChemistryMarkdownView(
                    text: card.question,
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.4, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tap card to flip in 3D ↻',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: (card.srState == FlashcardSrState.lapse ? AppColors.statusDanger : AppColors.brandPrimary).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          card.srState.name.toUpperCase(),
                          style: TextStyle(
                            color: card.srState == FlashcardSrState.lapse ? AppColors.statusDanger : AppColors.brandBright,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),
            back: GlowCard(
              borderColor: AppColors.blue.withValues(alpha: 0.45),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'OFFICIAL ANSWER',
                          style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Tap to flip back ↻',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ChemistryMarkdownView(
                    text: card.answer,
                    textStyle: const TextStyle(fontSize: 15.5, height: 1.45, color: Colors.white),
                  ),
                  if (card.keyTerms.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: card.keyTerms.map((term) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.purpleBright.withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Text(
                          '✨ $term',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      )).toList(),
                    ),
                  ],
                  if (card.sourceBacklink.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => _showBacklinkSheet(context, card.sourceBacklink),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.brandBright.withValues(alpha: 0.35)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link_rounded, size: 14, color: AppColors.brandBright),
                            SizedBox(width: 6),
                            Text(
                              'View Original AI Source Explanation',
                              style: TextStyle(color: AppColors.brandBright, fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),



          // Action Phase: Type Answer & Show Answer or Rate Recall
          if (phase == FlashcardUiState.unanswered) ...[
            GlowCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.purple.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR ANSWER (ACTIVE RECALL)',
                    style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: answer,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 14.5),
                    decoration: InputDecoration(
                      hintText: 'Type your answer here before revealing...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.purpleBright),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Submit / Show Answer',
                    onPressed: _reveal,
                  ),
                ],
              ),
            ),
          ],

          if (phase == FlashcardUiState.revealed || phase == FlashcardUiState.submitted) ...[
            if (answer.text.trim().isNotEmpty) ...[
              const Text(
                'YOUR ANSWER',
                style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w800, fontSize: 11.5, letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              GlowCard(
                borderColor: AppColors.purple.withValues(alpha: 0.4),
                padding: const EdgeInsets.all(14),
                child: Text(
                  answer.text.trim(),
                  style: const TextStyle(fontSize: 14.5, height: 1.4, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),

              // Evaluate My Answer with AI Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.purpleBright,
                    side: BorderSide(
                      color: _currentEvaluation != null ? AppColors.success : AppColors.purpleBright,
                      width: 1.2,
                    ),
                    backgroundColor: AppColors.purple.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _evaluatingWithAi ? null : () => _evaluateWithAi(card, preview),
                  icon: _evaluatingWithAi
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purpleBright),
                        )
                      : Icon(
                          _currentEvaluation != null ? Icons.check_circle_outline : Icons.auto_awesome,
                          size: 18,
                          color: _currentEvaluation != null ? AppColors.success : AppColors.purpleBright,
                        ),
                  label: Text(
                    _evaluatingWithAi
                        ? 'Evaluating with AI...'
                        : (_currentEvaluation != null
                            ? 'AI Match: ${_currentEvaluation!.matchPercentage}% (${_currentEvaluation!.recommendedLabel}) • View Analysis'
                            : 'Evaluate My Answer with AI ✨'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: _currentEvaluation != null ? AppColors.success : AppColors.purpleBright,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            const Text(
              'CORRECT ANSWER',
              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 11.5, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            GlowCard(
              borderColor: AppColors.blue.withValues(alpha: 0.35),
              padding: const EdgeInsets.all(18),
              child: ChemistryMarkdownView(
                text: card.answer,
                textStyle: const TextStyle(fontSize: 15.5, height: 1.45, color: Colors.white),
              ),
            ),
            if (card.keyTerms.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'MANDATORY KEY TERMS',
                style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.8),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: card.keyTerms.map((term) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.purpleBright.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Text(
                    '✨ $term',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                )).toList(),
              ),
            ],
            const SizedBox(height: 20),

            // Anki Recall Rating Prompt
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'How well did you remember?',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                if (_currentEvaluation != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.purpleBright.withValues(alpha: 0.5), width: 0.8),
                    ),
                    child: Text(
                      'AI Pick: ${_currentEvaluation!.recommendedLabel}',
                      style: const TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // 4 Anki-style choices with dynamic intervals
            Row(
              children: [
                Expanded(
                  child: _buildAnkiRatingButton(
                    label: 'Again',
                    interval: preview.againLabel,
                    color: AppColors.danger,
                    rating: FlashcardRating.again,
                    isRecommended: _currentEvaluation?.recommendedAction == FlashcardRating.again,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildAnkiRatingButton(
                    label: 'Hard',
                    interval: preview.hardLabel,
                    color: AppColors.warning,
                    rating: FlashcardRating.hard,
                    isRecommended: _currentEvaluation?.recommendedAction == FlashcardRating.hard,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildAnkiRatingButton(
                    label: 'Good',
                    interval: preview.goodLabel,
                    color: AppColors.success,
                    rating: FlashcardRating.good,
                    isRecommended: _currentEvaluation?.recommendedAction == FlashcardRating.good,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildAnkiRatingButton(
                    label: 'Easy',
                    interval: preview.easyLabel,
                    color: AppColors.blue,
                    rating: FlashcardRating.easy,
                    isRecommended: _currentEvaluation?.recommendedAction == FlashcardRating.easy,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStateBadge(SmartFlashcard card) {
    String label = 'Review';
    Color color = AppColors.purpleBright;

    if (card.isNew) {
      label = '🆕 New';
      color = AppColors.blue;
    } else if (card.isLearning) {
      label = '🟡 Learning';
      color = AppColors.warning;
    } else if (card.isMature) {
      label = '🟢 Mature';
      color = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildAnkiRatingButton({
    required String label,
    required String interval,
    required Color color,
    required FlashcardRating rating,
    bool isRecommended = false,
  }) {
    return InkWell(
      onTap: _savingRating ? null : () => _markWithRating(rating),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isRecommended ? color.withValues(alpha: 0.24) : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRecommended ? color : color.withValues(alpha: 0.5),
            width: isRecommended ? 2.0 : 1.0,
          ),
          boxShadow: isRecommended
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              interval,
              style: TextStyle(color: isRecommended ? Colors.white : color, fontSize: 11, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              isRecommended ? '$label ★' : label,
              style: TextStyle(
                color: isRecommended ? Colors.white : Colors.white70,
                fontSize: 12.5,
                fontWeight: isRecommended ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reveal() async {
    AppHaptics.tap();
    setState(() => phase = FlashcardUiState.revealed);
  }

  Future<void> _evaluateWithAi(SmartFlashcard card, ReviewSchedulePreview preview) async {
    final clean = answer.text.trim();
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type your answer in the box first to evaluate with AI.')),
      );
      return;
    }

    setState(() => _evaluatingWithAi = true);
    AppHaptics.tap();

    try {
      final eval = await _evalService.evaluate(
        userAnswer: clean,
        officialAnswer: card.answer,
        keyTerms: card.keyTerms,
        topic: card.topic,
      );

      if (!mounted) return;
      setState(() {
        _evaluatingWithAi = false;
        _currentEvaluation = eval;
      });

      await FlashcardEvaluationModal.show(
        context: context,
        evaluation: eval,
        preview: preview,
        onApplyRating: (rating) => _markWithRating(rating),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _evaluatingWithAi = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Evaluation error: $e')),
      );
    }
  }

  Future<void> _markWithRating(FlashcardRating rating) async {
    if (_savingRating) return;
    _savingRating = true;
    AppHaptics.confirm();

    final card = current;
    if (card == null) {
      _savingRating = false;
      return;
    }

    // Track session stats
    switch (rating) {
      case FlashcardRating.again:
        _againCount++;
        break;
      case FlashcardRating.hard:
        _hardCount++;
        break;
      case FlashcardRating.good:
        _goodCount++;
        break;
      case FlashcardRating.easy:
        _easyCount++;
        break;
    }

    try {
      final service = ref.read(flashcardServiceProvider);
      final updated = await service.applyRating(card.id, rating);
      deck[index] = updated;

      // If user failed to recall (Again), re-queue card to the end of this session
      if (rating == FlashcardRating.again) {
        deck.add(updated);
      }

      await service.saveAttempt(
        FlashcardAttempt(
          id: const Uuid().v4(),
          flashcardId: card.id,
          userId: service.remote.userId,
          userAnswer: answer.text.trim(),
          selfRating: rating.name,
          createdAt: DateTime.now(),
        ),
      );

      if (index + 1 >= deck.length) {
        await service.saveSession(
          StudySession(
            id: sessionId,
            userId: service.remote.userId,
            flashcardSetId: widget.setId,
            currentPosition: index,
            completed: true,
            startedAt: DateTime.now(),
            completedAt: DateTime.now(),
            reviewMode: widget.review.name,
          ),
        );
        setState(() => index = deck.length);
        _savingRating = false;
        return;
      }

      setState(() {
        index += 1;
        phase = FlashcardUiState.unanswered;
        answer.clear();
        _currentEvaluation = null;
        _evaluatingWithAi = false;
      });

      await service.saveSession(
        StudySession(
          id: sessionId,
          userId: service.remote.userId,
          flashcardSetId: widget.setId,
          currentPosition: index,
          completed: false,
          startedAt: DateTime.now(),
          reviewMode: widget.review.name,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t save this review to cloud. Saved locally.')),
        );
      }
    } finally {
      _savingRating = false;
    }
  }

  Widget _complete() {
    final totalReviewed = _goodCount + _hardCount + _easyCount + _againCount;
    final totalSuccess = _goodCount + _easyCount;
    final retention = totalReviewed > 0 ? ((totalSuccess / totalReviewed) * 100).round() : 100;
    final dueTomorrow = ref.read(flashcardServiceProvider).getDueCards().length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, title: const Text('Review Complete')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          GlowCard(
            borderColor: AppColors.success.withValues(alpha: 0.4),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.military_tech_rounded, color: AppColors.purpleBright, size: 28),
                    SizedBox(width: 10),
                    Text('🎉 Review Complete!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('$totalReviewed cards reviewed in this session', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildStatPill('Good', _goodCount, AppColors.success),
                    const SizedBox(width: 8),
                    _buildStatPill('Hard', _hardCount, AppColors.warning),
                    const SizedBox(width: 8),
                    _buildStatPill('Easy', _easyCount, AppColors.blue),
                    const SizedBox(width: 8),
                    _buildStatPill('Again', _againCount, AppColors.danger),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recall Accuracy:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                    Text('$retention%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.success)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Next Review:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                    Text('$dueTomorrow cards due tomorrow', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.purpleBright)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Review Due Cards',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SmartFlashcardsStudyScreen(setId: widget.setId, review: ReviewMode.due),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Flashcards', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color)),
            Text(label, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showBacklinkSheet(BuildContext context, String backlink) {
    AppHaptics.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.borderHighlight),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scroll,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: AppColors.brandBright, size: 20),
                  const SizedBox(width: 8),
                  const Text('Source AI Derivation & Notes', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderSubtle, height: 20),
              ChemistryMarkdownView(
                text: backlink,
                textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

