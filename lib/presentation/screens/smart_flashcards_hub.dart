import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/title_cleaner.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/smart_flashcard.dart';
import '../providers/app_providers.dart';
import 'smart_flashcards_generate_screen.dart';
import 'smart_flashcards_study_screen.dart';

class SmartFlashcardsPage extends StatelessWidget {
  const SmartFlashcardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, title: const Text('Smart Flashcards')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: const [SmartFlashcardsHub()],
      ),
    );
  }
}

class SmartFlashcardsHub extends ConsumerStatefulWidget {
  const SmartFlashcardsHub({super.key});

  @override
  ConsumerState<SmartFlashcardsHub> createState() => _SmartFlashcardsHubState();
}

class _SmartFlashcardsHubState extends ConsumerState<SmartFlashcardsHub> {
  @override
  void initState() {
    super.initState();
    ref.read(flashcardServiceProvider).syncPending();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(flashcardServiceProvider);
    final sets = service.sets();
    final overallStats = service.getOverallStats();
    final hasDueOrNew = overallStats.dueToday > 0 || overallStats.learningToday > 0 || overallStats.newToday > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Spaced Repetition Daily Review Queue Card
        GlowCard(
          borderColor: hasDueOrNew ? AppColors.purpleBright.withValues(alpha: 0.5) : AppColors.border,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology_outlined, color: AppColors.purpleBright, size: 24),
                      SizedBox(width: 8),
                      Text('Review Today', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                    ],
                  ),
                  if (overallStats.reviewedToday > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${overallStats.reviewedToday} done today ✓',
                        style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Status metrics (Due, Learning, New, Mature)
              Row(
                children: [
                  _buildQueuePill('Due', overallStats.dueToday, AppColors.danger),
                  const SizedBox(width: 8),
                  _buildQueuePill('Learning', overallStats.learningToday, AppColors.warning),
                  const SizedBox(width: 8),
                  _buildQueuePill('New', overallStats.newToday, AppColors.blue),
                  const SizedBox(width: 8),
                  _buildQueuePill('Mature', overallStats.matureCount, AppColors.success),
                ],
              ),
              const SizedBox(height: 16),

              if (hasDueOrNew)
                PrimaryButton(
                  label: 'Start Daily Review (${overallStats.dueToday + overallStats.learningToday + (overallStats.newToday > 10 ? 10 : overallStats.newToday)} cards)',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SmartFlashcardsStudyScreen(
                          setId: '',
                          review: ReviewMode.spacedRepetition,
                        ),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'All cards reviewed for today! 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Action: Create Flashcards from PDF
        PrimaryButton(
          label: 'Create Flashcards from PDF',
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SmartFlashcardsGenerateScreen()));
            if (mounted) setState(() {});
          },
        ),
        const SizedBox(height: 20),

        // 3. Saved Flashcard Decks
        const Text('Your Decks & Topics', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
        const SizedBox(height: 10),

        if (sets.isEmpty)
          GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.style, size: 48, color: AppColors.purpleBright),
                const SizedBox(height: 12),
                const Text('No flashcards yet. Create some from your chemistry notes or Ask ChemBuddy!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Generate Flashcards',
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SmartFlashcardsGenerateScreen()));
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),

        ...sets.map((s) {
          final deckStats = service.getDeckStats(s.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => SmartFlashcardsStudyScreen(setId: s.id, review: ReviewMode.all)),
                );
                if (mounted) setState(() {});
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          cleanStudyMaterialTitle(s.title),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      if (deckStats.due > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '${deckStats.due} Due',
                            style: const TextStyle(color: AppColors.danger, fontSize: 10.5, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${s.cardCount} cards (${deckStats.newCount} new, ${deckStats.mature} mature) • ${cleanStudyMaterialTitle(s.sourceFileName)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMM yyyy').format(s.createdAt),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  if (deckStats.due > 0) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => SmartFlashcardsStudyScreen(setId: s.id, review: ReviewMode.due)),
                        );
                        if (mounted) setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        minimumSize: const Size.fromHeight(38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Review ${deckStats.due} Due Cards', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQueuePill(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
