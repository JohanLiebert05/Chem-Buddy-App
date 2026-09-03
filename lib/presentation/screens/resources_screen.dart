import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/models.dart';
import '../../data/models/pdf_study_models.dart';
import '../providers/app_providers.dart';
import '../widgets/reaction_mechanisms_card.dart';
import 'pdf_library_screen.dart';
import 'smart_flashcards_generate_screen.dart';
import 'smart_flashcards_hub.dart';
import 'spectroscopy_hub_screen.dart';
import 'pericyclic_hub_screen.dart';
import 'exam_pattern_quiz_screen.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        const Text('Library & MSc Tools', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _TabChip(label: 'PDFs', selected: tab == 0, onTap: () => setState(() => tab = 0)),
              const SizedBox(width: 8),
              _TabChip(label: '⚗️ Reactions', selected: tab == 1, onTap: () => setState(() => tab = 1)),
              const SizedBox(width: 8),
              _TabChip(label: 'Cards', selected: tab == 2, onTap: () => setState(() => tab = 2)),
              const SizedBox(width: 8),
              _TabChip(label: 'Quizzes', selected: tab == 3, onTap: () => setState(() => tab = 3)),
              const SizedBox(width: 8),
              _TabChip(label: 'Notes', selected: tab == 4, onTap: () => setState(() => tab = 4)),
              const SizedBox(width: 8),
              _TabChip(label: '🧲 Spectroscopy', selected: tab == 5, onTap: () => setState(() => tab = 5)),
              const SizedBox(width: 8),
              _TabChip(label: '🌀 Pericyclics', selected: tab == 6, onTap: () => setState(() => tab = 6)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (tab == 0) const PdfLibraryScreen(embedded: true),
        if (tab == 1) const _ReactionsTab(),
        if (tab == 2) const SmartFlashcardsHub(),
        if (tab == 3) const _QuizzesAndMasteryTab(),
        if (tab == 4) _NotesTab(state: state),
        if (tab == 5) const SizedBox(height: 650, child: SpectroscopyHubScreen()),
        if (tab == 6) const SizedBox(height: 650, child: PericyclicHubScreen()),
      ],
    );
  }
}


class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.purple : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.purpleBright : AppColors.border),
        ),
        child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
      ),
    );
  }
}


class _ReactionsTab extends StatelessWidget {
  const _ReactionsTab();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ReactionMechanismsCard(compact: false),
        SizedBox(height: 16),
        GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Why Verified Reaction SVGs?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.white)),
              SizedBox(height: 8),
              Text(
                'AI text generators often hallucinate chemical structures. ChemBuddy\'s upcoming Reaction Engine pairs curated, peer-reviewed reaction mechanisms rendered in vector SVG format with step-by-step electron arrow pushing for 100% academic precision.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuizzesAndMasteryTab extends ConsumerWidget {
  const _QuizzesAndMasteryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(chemRepositoryProvider);
    final allPdfs = ref.watch(appControllerProvider).pdfs;
    final allQuizzes = <ChemistryQuiz>[];
    for (final pdf in allPdfs) {
      allQuizzes.addAll(repo.getPdfQuizzes(pdf.id));
    }

    final examCard = Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlowCard(
        borderColor: AppColors.accentGold.withValues(alpha: 0.4),
        padding: const EdgeInsets.all(14),
        onTap: () {
          AppHaptics.confirm();
          Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ExamPatternQuizScreen()));
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_rounded, color: AppColors.accentGold, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('University Exam Pattern Paper 📝', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white)),
                  SizedBox(height: 2),
                  Text('Practice authentic 2M, 5M, and 10M questions with model marking schemes.', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.accentGold, size: 20),
          ],
        ),
      ),
    );

    if (allQuizzes.isEmpty) {
      return Column(
        children: [
          examCard,
          const GlowCard(
            child: Column(
              children: [
                Icon(Icons.quiz_outlined, size: 48, color: AppColors.purpleBright),
                SizedBox(height: 12),
                Text('No Quiz History Yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                SizedBox(height: 8),
                Text(
                  'Take a quiz from any uploaded PDF notes to track your Strong 🟢, Moderate 🟡, and Weak 🔴 chemistry topic mastery here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        examCard,
        const Text('Chemistry Topic Mastery 🧠', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),

        const SizedBox(height: 8),
        const Text(
          'Adaptive tracking based on your PDF quiz performance:',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...allQuizzes.take(5).map((q) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlowCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school, size: 18, color: AppColors.purpleBright),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            q.title,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${q.questionCount} Questions',
                            style: const TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Source: ${q.sourceFileName} · ${DateFormat("d MMM yyyy").format(q.createdAt)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _EventsTab extends ConsumerWidget {
  const _EventsTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = state.events;
    return Column(
      children: [
        PrimaryButton(
          label: 'Add test or assignment',
          onPressed: () => _editEvent(context, ref),
        ),
        const SizedBox(height: 16),
        if (events.isEmpty)
          const GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.event_note, size: 48, color: AppColors.purpleBright),
                SizedBox(height: 12),
                Text('No deadlines yet.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                SizedBox(height: 8),
                Text('Add a test, assignment, or seminar to track it here.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ...events.map((e) {
          String? subjectName;
          for (final s in state.subjects) {
            if (s.id == e.subjectId) subjectName = s.name;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              onTap: () => _editEvent(context, ref, existing: e),
              child: Row(
                children: [
                  Checkbox(
                    value: e.completed,
                    activeColor: AppColors.purple,
                    onChanged: (v) => ref.read(appControllerProvider.notifier).saveEvent(e.copyWith(completed: v ?? false)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: e.completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          '${e.type.name.toUpperCase()} · ${DateFormat('d MMM yyyy').format(e.dueDate)}${subjectName == null ? '' : ' · $subjectName'}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        if (!e.completed) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => SmartFlashcardsGenerateScreen(
                                  prefilledTopic: '${e.title}${subjectName != null ? ' ($subjectName)' : ''}',
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.school, size: 16, color: AppColors.purpleBright),
                            label: const Text('Study for this', style: TextStyle(color: AppColors.purpleBright, fontSize: 12)),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.read(appControllerProvider.notifier).deleteEvent(e.id),
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _editEvent(BuildContext context, WidgetRef ref, {AcademicEvent? existing}) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final desc = TextEditingController(text: existing?.description ?? '');
    var type = existing?.type ?? EventType.test;
    var due = existing?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    String? subjectId = existing?.subjectId;
    final subjects = ref.read(appControllerProvider).subjects;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(existing == null ? 'New deadline' : 'Edit deadline', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 12),
                    TextField(controller: title, decoration: const InputDecoration(hintText: 'Title')),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<EventType>(
                      initialValue: type,
                      items: EventType.values
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                          .toList(),
                      onChanged: (v) => setModal(() => type = v ?? type),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: subjectId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No subject')),
                        ...subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                      ],
                      onChanged: (v) => setModal(() => subjectId = v),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Due ${DateFormat('d MMM yyyy').format(due)}'),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: due,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setModal(() => due = picked);
                      },
                    ),
                    TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(hintText: 'Description')),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Save',
                      onPressed: () async {
                        if (title.text.trim().isEmpty) return;
                        final repo = ref.read(chemRepositoryProvider);
                        await ref.read(appControllerProvider.notifier).saveEvent(
                              AcademicEvent(
                                id: existing?.id ?? repo.newId(),
                                title: title.text.trim(),
                                type: type,
                                dueDate: due,
                                subjectId: subjectId,
                                description: desc.text.trim(),
                                completed: existing?.completed ?? false,
                              ),
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _NotesTab extends ConsumerWidget {
  const _NotesTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EventsTab(state: state),
        const SizedBox(height: 24),
        const Text('Daily Chemistry Notes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 10),
        PrimaryButton(label: 'New note', onPressed: () => _editNote(context, ref)),
        const SizedBox(height: 16),
        if (state.notes.isEmpty)
          const GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.notes, size: 48, color: AppColors.purpleBright),
                SizedBox(height: 12),
                Text('No notes yet.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                SizedBox(height: 8),
                Text('Day-to-day notes will show up here.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ...state.notes.map((n) {
          String? tag;
          for (final s in state.subjects) {
            if (s.id == n.subjectId) tag = s.code;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              onTap: () => _editNote(context, ref, existing: n),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800))),
                      IconButton(
                        tooltip: 'Flashcard',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => SmartFlashcardsGenerateScreen(
                              prefilledTopic: n.title,
                              prefilledText: n.body,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.style_outlined, color: AppColors.purpleBright),
                      ),
                      IconButton(
                        onPressed: () => ref.read(appControllerProvider.notifier).deleteNote(n.id),
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                      ),
                    ],
                  ),
                  Text(n.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text(
                    '${DateFormat('d MMM, h:mm a').format(n.updatedAt)}${tag == null ? '' : ' · $tag'}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _editNote(BuildContext context, WidgetRef ref, {NoteItem? existing}) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final body = TextEditingController(text: existing?.body ?? '');
    String? subjectId = existing?.subjectId;
    final subjects = ref.read(appControllerProvider).subjects;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(existing == null ? 'New note' : 'Edit note', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 12),
                    TextField(controller: title, decoration: const InputDecoration(hintText: 'Title')),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: subjectId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No subject tag')),
                        ...subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                      ],
                      onChanged: (v) => setModal(() => subjectId = v),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: body, maxLines: 6, decoration: const InputDecoration(hintText: 'Write your note…')),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Save',
                      onPressed: () async {
                        if (title.text.trim().isEmpty) return;
                        final repo = ref.read(chemRepositoryProvider);
                        await ref.read(appControllerProvider.notifier).saveNote(
                              NoteItem(
                                id: existing?.id ?? repo.newId(),
                                title: title.text.trim(),
                                body: body.text.trim(),
                                subjectId: subjectId,
                                updatedAt: DateTime.now(),
                              ),
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
