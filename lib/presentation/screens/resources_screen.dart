import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/models.dart';
import '../providers/app_providers.dart';
import 'flashcard_editor_screen.dart';
import 'pdf_library_screen.dart';
import 'smart_flashcards_hub.dart';

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
        const Text('Resources', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(
          children: [
            _TabChip(label: 'Tests', selected: tab == 0, onTap: () => setState(() => tab = 0)),
            const SizedBox(width: 8),
            _TabChip(label: 'Notes', selected: tab == 1, onTap: () => setState(() => tab = 1)),
            const SizedBox(width: 8),
            _TabChip(label: 'PDFs', selected: tab == 2, onTap: () => setState(() => tab = 2)),
            const SizedBox(width: 8),
            _TabChip(label: 'Cards', selected: tab == 3, onTap: () => setState(() => tab = 3)),
          ],
        ),
        const SizedBox(height: 16),
        if (tab == 0) _EventsTab(state: state),
        if (tab == 1) _NotesTab(state: state),
        if (tab == 2) const PdfLibraryScreen(embedded: true),
        if (tab == 3) const SmartFlashcardsHub(),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.purple : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
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
          const GlowCard(child: Text('No deadlines yet. Add a test, assignment, or seminar.', style: TextStyle(color: AppColors.textSecondary))),
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
      children: [
        PrimaryButton(label: 'New note', onPressed: () => _editNote(context, ref)),
        const SizedBox(height: 16),
        if (state.notes.isEmpty)
          const GlowCard(child: Text('Day-to-day notes will show up here.', style: TextStyle(color: AppColors.textSecondary))),
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
                            builder: (_) => FlashcardEditorScreen(
                              subjectId: n.subjectId,
                              sourceHint: n.title,
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
