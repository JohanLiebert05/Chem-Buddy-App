import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/smart_flashcard.dart';
import '../providers/app_providers.dart';

class SmartFlashcardsStudyScreen extends ConsumerStatefulWidget {
  const SmartFlashcardsStudyScreen({super.key, required this.setId, this.review = ReviewMode.all});
  final String setId;
  final ReviewMode review;

  @override
  ConsumerState<SmartFlashcardsStudyScreen> createState() => _SmartFlashcardsStudyScreenState();
}

class _SmartFlashcardsStudyScreenState extends ConsumerState<SmartFlashcardsStudyScreen> {
  final answer = TextEditingController();
  late List<SmartFlashcard> deck;
  late String sessionId;
  int index = 0;
  FlashcardUiState phase = FlashcardUiState.unanswered;

  @override
  void initState() {
    super.initState();
    final service = ref.read(flashcardServiceProvider);
    var cards = service.cardsFor(widget.setId);
    if (widget.review == ReviewMode.difficult) {
      cards = cards.where((c) => c.status == FlashcardUiState.difficult).toList();
    } else if (widget.review == ReviewMode.skipped) {
      cards = cards.where((c) => c.status == FlashcardUiState.skipped).toList();
    } else if (widget.review == ReviewMode.due) {
      cards = service.getDueCards(widget.setId);
    }
    deck = cards;
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
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: GlowCard(child: Text('No cards in this review queue.')),
        ),
      );
    }
    final card = current;
    if (card == null) return _complete();
    final progress = (index + 1) / deck.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, title: const Text('Smart Flashcards')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text('Question ${index + 1} of ${deck.length}', style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              color: AppColors.purpleBright,
              backgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(height: 16),
          GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (card.topic.isNotEmpty)
                  Text(card.topic.toUpperCase(), style: const TextStyle(color: AppColors.purpleBright, fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(card.question, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (phase == FlashcardUiState.unanswered || phase == FlashcardUiState.answering) ...[
            TextField(
              controller: answer,
              minLines: 4,
              maxLines: 8,
              onChanged: (_) => setState(() => phase = FlashcardUiState.answering),
              decoration: const InputDecoration(hintText: 'Write your answer here…'),
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Submit Answer', onPressed: _submit),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _reveal,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.purpleBright, side: const BorderSide(color: AppColors.border), minimumSize: const Size.fromHeight(48)),
              child: const Text('Show Answer'),
            ),
          ],
          if (phase == FlashcardUiState.submitted || phase == FlashcardUiState.revealed) ...[
            if (phase == FlashcardUiState.submitted) ...[
              const Text('YOUR ANSWER', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 12)),
              const SizedBox(height: 6),
              GlowCard(child: Text(answer.text.trim().isEmpty ? '(blank)' : answer.text.trim())),
              const SizedBox(height: 12),
            ],
            const Text('REFERENCE ANSWER', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 6),
            GlowCard(child: Text(card.answer)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _rate('Easy', AppColors.success, FlashcardUiState.easy)),
                const SizedBox(width: 8),
                Expanded(child: _rate('Difficult', AppColors.warning, FlashcardUiState.difficult)),
                const SizedBox(width: 8),
                Expanded(child: _rate('Skip', AppColors.blue, FlashcardUiState.skipped)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _rate(String label, Color color, FlashcardUiState rating) {
    return ElevatedButton(
      onPressed: () => _mark(rating),
      style: ElevatedButton.styleFrom(backgroundColor: color.withValues(alpha: 0.2), foregroundColor: color, minimumSize: const Size.fromHeight(48)),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }

  Future<void> _submit() async {
    final card = current;
    if (card == null) return;
    if (answer.text.trim().isEmpty) return;
    setState(() => phase = FlashcardUiState.submitted);
    await _persist(card.copyWith(lastUserAnswer: answer.text.trim(), status: FlashcardUiState.submitted));
  }

  Future<void> _reveal() async {
    final card = current;
    if (card == null) return;
    setState(() => phase = FlashcardUiState.revealed);
    await _persist(card.copyWith(status: FlashcardUiState.revealed));
  }

  Future<void> _mark(FlashcardUiState rating) async {
    final card = current;
    if (card == null) return;
    final updated = card.copyWith(status: rating, lastUserAnswer: answer.text.trim());
    deck[index] = updated;
    await _persist(updated);
    final service = ref.read(flashcardServiceProvider);
    
    String srRating = 'skipped';
    if (rating == FlashcardUiState.easy) srRating = 'easy';
    if (rating == FlashcardUiState.difficult) srRating = 'difficult';
    await service.updateSpacedRepetition(card.id, srRating);

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
      return;
    }
    setState(() {
      index += 1;
      phase = FlashcardUiState.unanswered;
      answer.clear();
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
  }

  Future<void> _persist(SmartFlashcard card) {
    return ref.read(flashcardServiceProvider).updateCard(card);
  }

  Widget _complete() {
    final easy = deck.where((c) => c.status == FlashcardUiState.easy).length;
    final difficult = deck.where((c) => c.status == FlashcardUiState.difficult).length;
    final skipped = deck.where((c) => c.status == FlashcardUiState.skipped).length;
    final accuracy = (easy + difficult) > 0 ? (easy / (easy + difficult)) * 100 : 0.0;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, title: const Text('Session Complete')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎉 Study Session Complete!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 16),
                Text('${deck.length} cards reviewed', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Easy: $easy', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                Text('Difficult: $difficult', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700)),
                Text('Skipped: $skipped', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Accuracy: ${accuracy.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (difficult > 0)
            PrimaryButton(
              label: 'Review Difficult Cards',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(builder: (_) => SmartFlashcardsStudyScreen(setId: widget.setId, review: ReviewMode.difficult)),
              ),
            ),
          if (difficult > 0) const SizedBox(height: 10),
          PrimaryButton(
            label: 'Done',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
