import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/branding/chembuddy_mascot.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/library_models.dart';
import '../../data/models/models.dart';
import '../../data/services/pdf_ai_study_service.dart';
import '../../data/services/pdf_library_service.dart';
import '../../data/services/pdf_text_extraction_service.dart';
import '../providers/app_providers.dart';
import 'pdf_reader_screen.dart';
import 'pdf_study_hub_screen.dart';

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
          MascotEmptyState(
            title: 'Your Study Library is Empty',
            description: 'Import MSc Chemistry syllabus PDFs, lecture slides, or exam notes into your subject folders to start studying.',
            buttonLabel: 'Import First PDF',
            onAction: () => _import(state),
          ),
        ...docs.map((d) {
          String subjectName = 'Other';
          for (final s in state.subjects) {
            if (s.id == d.subjectId) subjectName = s.name;
          }

          final store = ref.watch(localStoreProvider);
          final docQuizzes = store.all(store.quizResults).where((j) => j['pdfDocId'] == d.id).length;
          final docFlashcards = store.all(store.smartSets).where((j) => j['sourceDocId'] == d.id).length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlowCard(
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PdfStudyHubScreen(doc: d))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(d.favorite ? Icons.star : Icons.picture_as_pdf_outlined, color: AppColors.purpleBright, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.white)),
                            Text(
                              '$subjectName · ${DateFormat('d MMM yyyy').format(d.dateAdded)}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) => _menu(d, v, state),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'study', child: Text('Study with AI')),
                          PopupMenuItem(value: 'read', child: Text('Read PDF')),
                          PopupMenuItem(value: 'rename', child: Text('Rename')),
                          PopupMenuItem(value: 'move', child: Text('Move subject')),
                          PopupMenuItem(value: 'fav', child: Text('Toggle favorite')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Study Metrics Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '📝 $docQuizzes Quiz${docQuizzes == 1 ? "" : "zes"}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🃏 $docFlashcards Deck${docFlashcards == 1 ? "" : "s"}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      if (d.lastOpened != null)
                        Text(
                          'Last studied ${DateFormat('d MMM').format(d.lastOpened!)}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 5 Quick Action Shortcuts
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildQuickActionBtn(
                        label: 'Chat',
                        icon: Icons.chat_bubble_outline,
                        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PdfStudyHubScreen(doc: d))),
                      ),
                      _buildQuickActionBtn(
                        label: 'Quiz',
                        icon: Icons.quiz_outlined,
                        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PdfStudyHubScreen(doc: d))),
                      ),
                      _buildQuickActionBtn(
                        label: 'Flashcards',
                        icon: Icons.style_outlined,
                        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PdfStudyHubScreen(doc: d))),
                      ),
                      _buildQuickActionBtn(
                        label: 'Summary',
                        icon: Icons.auto_stories_outlined,
                        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PdfStudyHubScreen(doc: d))),
                      ),
                      _buildQuickActionBtn(
                        label: 'Read',
                        icon: Icons.visibility_outlined,
                        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PdfReaderScreen(doc: d))),
                      ),
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
      if (doc != null) {
        await ref.read(appControllerProvider.notifier).savePdf(doc);

        // Content-based subject classification validation
        try {
          final sampleText = await PdfTextExtractionService.instance.extractFromPath(doc.localPath);
          final classification = classifyDocumentSubject(
            sampleText.substring(0, min(sampleText.length, 3000)),
            doc.displayName,
          );
          final currentSubject = state.subjects.firstWhere((s) => s.id == sid, orElse: () => state.subjects.first);

          final currentLower = currentSubject.name.toLowerCase();
          final detectedLower = classification.detectedSubject.toLowerCase();
          final mismatch = !currentLower.contains(detectedLower.split(' ').first) &&
              !detectedLower.contains(currentLower.split(' ').first) &&
              classification.confidence >= 0.5;

          if (mismatch && mounted) {
            final matchingSubject = state.subjects.cast<Subject?>().firstWhere(
              (s) => s?.name.toLowerCase().contains(classification.detectedSubject.toLowerCase().split(' ').first) ?? false,
              orElse: () => null,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.surfaceElevated,
                duration: const Duration(seconds: 7),
                content: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.accentGold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This looks like ${classification.detectedSubject} content — update tag?',
                        style: const TextStyle(fontSize: 12.5, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                action: SnackBarAction(
                  label: matchingSubject != null ? 'Update to ${matchingSubject.name}' : 'Change Tag',
                  textColor: AppColors.purpleBright,
                  onPressed: () async {
                    if (matchingSubject != null) {
                      await ref.read(appControllerProvider.notifier).savePdf(doc.copyWith(subjectId: matchingSubject.id));
                    } else {
                      _menu(doc, 'move', state);
                    }
                  },
                ),
              ),
            );
          }
        } catch (_) {}
      }
    } catch (e) {
      setState(() => error = 'Could not import that file. Choose a valid PDF.');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _menu(PdfDoc doc, String action, AppState state) async {
    final controller = ref.read(appControllerProvider.notifier);
    if (action == 'study') {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PdfStudyHubScreen(doc: doc)));
    } else if (action == 'read') {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PdfReaderScreen(doc: doc)));
    } else if (action == 'fav') {
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

  Widget _buildQuickActionBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.purpleBright),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
