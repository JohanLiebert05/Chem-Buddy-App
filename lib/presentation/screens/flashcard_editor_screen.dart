import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/library_models.dart';
import '../../data/services/anki_service.dart';
import '../providers/app_providers.dart';

class FlashcardEditorScreen extends ConsumerStatefulWidget {
  const FlashcardEditorScreen({super.key, this.existing, this.subjectId, this.sourceHint});
  final FlashcardDraft? existing;
  final String? subjectId;
  final String? sourceHint;

  @override
  ConsumerState<FlashcardEditorScreen> createState() => _FlashcardEditorScreenState();
}

class _FlashcardEditorScreenState extends ConsumerState<FlashcardEditorScreen> {
  late final TextEditingController question;
  late final TextEditingController answer;
  late final TextEditingController deck;
  late final TextEditingController tags;
  late final TextEditingController equation;
  String? subjectId;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    question = TextEditingController(text: e?.question ?? '');
    answer = TextEditingController(text: e?.answer ?? '');
    deck = TextEditingController(text: e?.deck ?? 'Chem Buddy');
    tags = TextEditingController(text: e?.tags.join(', ') ?? 'organic, exam');
    equation = TextEditingController(text: e?.equation ?? '');
    subjectId = e?.subjectId ?? widget.subjectId;
  }

  @override
  void dispose() {
    question.dispose();
    answer.dispose();
    deck.dispose();
    tags.dispose();
    equation.dispose();
    super.dispose();
  }

  FlashcardDraft _draft() {
    return FlashcardDraft(
      id: widget.existing?.id ?? const Uuid().v4(),
      question: question.text.trim(),
      answer: answer.text.trim(),
      updatedAt: DateTime.now(),
      subjectId: subjectId,
      deck: deck.text.trim().isEmpty ? 'Chem Buddy' : deck.text.trim(),
      tags: tags.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
      equation: equation.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(appControllerProvider).subjects;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, title: const Text('Create flashcard')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          if (widget.sourceHint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('From ${widget.sourceHint}', style: const TextStyle(color: AppColors.textMuted)),
            ),
          TextField(controller: question, maxLines: 3, decoration: const InputDecoration(labelText: 'Question / Front')),
          const SizedBox(height: 8),
          TextField(controller: answer, maxLines: 5, decoration: const InputDecoration(labelText: 'Answer / Back')),
          const SizedBox(height: 8),
          TextField(controller: equation, decoration: const InputDecoration(labelText: 'Chemical equation (optional)')),
          const SizedBox(height: 8),
          TextField(controller: deck, decoration: const InputDecoration(labelText: 'Deck')),
          const SizedBox(height: 8),
          TextField(controller: tags, decoration: const InputDecoration(labelText: 'Tags (comma separated)')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: subjectId,
            items: [
              const DropdownMenuItem(value: null, child: Text('No subject')),
              ...subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
            ],
            onChanged: (v) => setState(() => subjectId = v),
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Save draft',
            onPressed: () async {
              final card = _draft();
              if (card.question.isEmpty || card.answer.isEmpty) return;
              await ref.read(appControllerProvider.notifier).saveFlashcard(card);
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Add to AnkiDroid',
            loading: sending,
            onPressed: sending
                ? null
                : () async {
                    final card = _draft();
                    if (card.question.isEmpty || card.answer.isEmpty) return;
                    setState(() => sending = true);
                    await ref.read(appControllerProvider.notifier).saveFlashcard(card);
                    final result = await AnkiService.instance.sendCard(card);
                    if (!context.mounted) return;
                    setState(() => sending = false);
                    if (result.needsInstall) {
                      await _missingAnki(context, card);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
                    }
                  },
          ),
        ],
      ),
    );
  }

  Future<void> _missingAnki(BuildContext context, FlashcardDraft card) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AnkiDroid is not installed.'),
        content: const Text('Install AnkiDroid, or share an import file you can open later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AnkiService.instance.shareImportFile(card);
            },
            child: const Text('Share file'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              AnkiService.instance.openInstallPage();
            },
            child: const Text('Install AnkiDroid'),
          ),
        ],
      ),
    );
  }
}

class FlashcardsTab extends ConsumerWidget {
  const FlashcardsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return Column(
      children: [
        PrimaryButton(
          label: 'Create card',
          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const FlashcardEditorScreen())),
        ),
        const SizedBox(height: 12),
        if (state.flashcards.isEmpty)
          const GlowCard(child: Text('Draft chemistry flashcards here, then send them to AnkiDroid.', style: TextStyle(color: AppColors.textSecondary))),
        ...state.flashcards.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => FlashcardEditorScreen(existing: c))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.question, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(c.answer, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
                  Text(c.tags.join(' · '), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
