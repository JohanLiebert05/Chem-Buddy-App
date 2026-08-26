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
    final sets = ref.watch(flashcardServiceProvider).sets();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          label: 'Create from PDF',
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SmartFlashcardsGenerateScreen()));
            if (mounted) setState(() {});
          },
        ),
        const SizedBox(height: 16),
        const Text('Saved sets', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        if (sets.isEmpty)
          GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.style, size: 48, color: AppColors.purpleBright),
                const SizedBox(height: 12),
                const Text('No flashcards yet. Create some from your notes or ask ChemBuddy!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                PrimaryButton(label: 'Create Flashcards', onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SmartFlashcardsGenerateScreen()));
                  if (mounted) setState(() {});
                }),
              ],
            ),
          ),
        ...sets.map(
          (s) {
            final dueCount = ref.read(flashcardServiceProvider).countDueCards(s.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlowCard(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => SmartFlashcardsStudyScreen(setId: s.id)));
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
                        if (dueCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$dueCount cards due',
                              style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${s.cardCount} cards • ${cleanStudyMaterialTitle(s.sourceFileName)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMM yyyy').format(s.createdAt),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    if (dueCount > 0) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => SmartFlashcardsStudyScreen(setId: s.id, review: ReviewMode.due)));
                          if (mounted) setState(() {});
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Review Due Cards'),
                      ),
                    ]
                  ],
                ),
              ),
            );
          }
        ),
      ],
    );
  }
}
