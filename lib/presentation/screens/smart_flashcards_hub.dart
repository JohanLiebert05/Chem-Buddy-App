import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../providers/app_providers.dart';
import 'flashcard_editor_screen.dart';
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
    final drafts = ref.watch(appControllerProvider).flashcards;
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
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const FlashcardEditorScreen())),
          child: const Text('Manual / AnkiDroid card'),
        ),
        const SizedBox(height: 16),
        const Text('Saved sets', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        if (sets.isEmpty)
          const GlowCard(child: Text('Generate flashcards from a PDF, then reopen them here anytime — even offline.', style: TextStyle(color: AppColors.textSecondary))),
        ...sets.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => SmartFlashcardsStudyScreen(setId: s.id)));
                if (mounted) setState(() {});
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${s.cardCount} cards · ${s.sourceFileName}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  Text(DateFormat('d MMM yyyy').format(s.createdAt), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        if (drafts.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Anki drafts', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          ...drafts.take(5).map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlowCard(
                    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => FlashcardEditorScreen(existing: c))),
                    child: Text(c.question, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
        ],
      ],
    );
  }
}
