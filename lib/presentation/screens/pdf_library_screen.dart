import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/library_models.dart';
import '../../data/services/pdf_library_service.dart';
import '../providers/app_providers.dart';
import 'pdf_reader_screen.dart';

class PdfLibraryScreen extends ConsumerStatefulWidget {
  const PdfLibraryScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  ConsumerState<PdfLibraryScreen> createState() => _PdfLibraryScreenState();
}

class _PdfLibraryScreenState extends ConsumerState<PdfLibraryScreen> {
  int filter = 0;
  String? subjectId;
  String sort = 'recent';
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    var docs = List<PdfDoc>.from(state.pdfs);
    if (filter == 1 && subjectId != null) {
      docs = docs.where((d) => d.subjectId == subjectId).toList();
    }
    if (filter == 2) docs = docs.where((d) => d.favorite).toList();
    if (filter == 3) {
      docs.sort((a, b) => (b.lastOpened ?? b.dateAdded).compareTo(a.lastOpened ?? a.dateAdded));
    } else if (sort == 'name') {
      docs.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    } else if (sort == 'size') {
      docs.sort((a, b) => b.fileSize.compareTo(a.fileSize));
    }

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embedded) const Text('PDF library', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        if (!widget.embedded) const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in ['All', 'Subjects', 'Favorites', 'Recent'].asMap().entries)
              ChoiceChip(
                label: Text(item.value),
                selected: filter == item.key,
                onSelected: (_) => setState(() => filter = item.key),
              ),
          ],
        ),
        if (filter == 1) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: subjectId ?? (state.subjects.isEmpty ? null : state.subjects.first.id),
            items: state.subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
            onChanged: (v) => setState(() => subjectId = v),
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: sort,
                items: const [
                  DropdownMenuItem(value: 'recent', child: Text('Newest')),
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'size', child: Text('Size')),
                ],
                onChanged: (v) => setState(() => sort = v ?? 'recent'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: loading ? null : () => _import(state),
              icon: const Icon(Icons.add),
              label: const Text('Add PDF'),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 12),
        if (loading) const Center(child: CircularProgressIndicator(color: AppColors.purpleBright)),
        if (!loading && docs.isEmpty)
          const GlowCard(child: Text('No PDFs yet. Import notes into your subject folders.', style: TextStyle(color: AppColors.textSecondary))),
        ...docs.map((d) {
          String subjectName = 'Other';
          for (final s in state.subjects) {
            if (s.id == d.subjectId) subjectName = s.name;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PdfReaderScreen(doc: d))),
              child: Row(
                children: [
                  Icon(d.favorite ? Icons.star : Icons.picture_as_pdf_outlined, color: AppColors.purpleBright),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(
                          '$subjectName · ${DateFormat('d MMM').format(d.dateAdded)}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) => _menu(d, v, state),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'move', child: Text('Move subject')),
                      PopupMenuItem(value: 'fav', child: Text('Toggle favorite')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, title: const Text('PDF library')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: [body]),
    );
  }

  Future<void> _import(AppState state) async {
    if (state.subjects.isEmpty) {
      setState(() => error = 'Add a subject first, then import PDFs into it.');
      return;
    }
    final sid = subjectId ?? state.subjects.first.id;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final doc = await PdfLibraryService.instance.importPdf(subjectId: sid);
      if (doc != null) await ref.read(appControllerProvider.notifier).savePdf(doc);
    } catch (e) {
      setState(() => error = 'Could not import that file. Choose a valid PDF.');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _menu(PdfDoc doc, String action, AppState state) async {
    final controller = ref.read(appControllerProvider.notifier);
    if (action == 'fav') {
      await controller.savePdf(doc.copyWith(favorite: !doc.favorite));
    } else if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete PDF?'),
          content: Text(doc.displayName),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
          ],
        ),
      );
      if (ok == true) await controller.deletePdf(doc.id);
    } else if (action == 'rename') {
      final name = TextEditingController(text: doc.displayName);
      final next = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rename'),
          content: TextField(controller: name),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, name.text.trim()), child: const Text('Save')),
          ],
        ),
      );
      if (next != null && next.isNotEmpty) await controller.savePdf(doc.copyWith(displayName: next));
    } else if (action == 'move') {
      final next = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Move to subject'),
          children: [
            for (final s in state.subjects)
              SimpleDialogOption(onPressed: () => Navigator.pop(ctx, s.id), child: Text(s.name)),
          ],
        ),
      );
      if (next != null) await controller.savePdf(doc.copyWith(subjectId: next));
    }
  }
}
