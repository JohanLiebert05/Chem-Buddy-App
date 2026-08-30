import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/library_models.dart';
import '../../data/services/pdf_library_service.dart';
import '../providers/app_providers.dart';
import 'pdf_study_hub_screen.dart';

class PdfReaderScreen extends ConsumerStatefulWidget {
  const PdfReaderScreen({super.key, required this.doc});
  final PdfDoc doc;

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  late PdfDoc _doc;
  int _page = 0;
  int _total = 0;
  PDFViewController? _controller;
  bool _night = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _doc = widget.doc;
    _page = widget.doc.lastPage;
    if (!PdfLibraryService.instance.exists(_doc.localPath)) {
      _error = 'This PDF is missing from storage. It may have been moved or deleted.';
    }
  }

  Future<void> _persistPage(int page) async {
    _doc = _doc.copyWith(lastPage: page, lastOpened: DateTime.now());
    await ref.read(appControllerProvider.notifier).savePdf(_doc);
  }

  void _openStudyHub([int initialTab = 0]) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PdfStudyHubScreen(doc: _doc, initialTab: initialTab),
      ),
    );
  }

  void _showStudyOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.purpleBright, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_doc.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        const Text('What would you like to do?', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _StudyOptionRow(
                icon: Icons.local_fire_department_outlined,
                color: AppColors.warning,
                title: 'Find Important Topics',
                subtitle: 'Ranked priorities based on document coverage & exams',
                onTap: () {
                  Navigator.pop(ctx);
                  _openStudyHub(0);
                },
              ),
              _StudyOptionRow(
                icon: Icons.summarize_outlined,
                color: AppColors.purpleBright,
                title: 'Summarize Document',
                subtitle: 'Overview, core definitions, and reaction equations',
                onTap: () {
                  Navigator.pop(ctx);
                  _openStudyHub(1);
                },
              ),
              _StudyOptionRow(
                icon: Icons.quiz_outlined,
                color: AppColors.blue,
                title: 'Create Practice Quiz',
                subtitle: '10, 20, or 30 questions with weak area analysis',
                onTap: () {
                  Navigator.pop(ctx);
                  _openStudyHub(2);
                },
              ),
              _StudyOptionRow(
                icon: Icons.style_outlined,
                color: AppColors.success,
                title: 'Generate Flashcards',
                subtitle: 'Turn concepts into spaced repetition cards',
                onTap: () {
                  Navigator.pop(ctx);
                  _openStudyHub(3);
                },
              ),
              _StudyOptionRow(
                icon: Icons.chat_bubble_outline_rounded,
                color: AppColors.purpleBright,
                title: 'Ask ChemBuddy',
                subtitle: 'Ask questions grounded directly in this PDF',
                onTap: () {
                  Navigator.pop(ctx);
                  _openStudyHub(4);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _night ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(_doc.displayName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Favorite',
            onPressed: () async {
              _doc = _doc.copyWith(favorite: !_doc.favorite);
              await ref.read(appControllerProvider.notifier).savePdf(_doc);
              setState(() {});
            },
            icon: Icon(_doc.favorite ? Icons.star : Icons.star_border, color: AppColors.purpleBright),
          ),
          IconButton(
            tooltip: 'Share',
            onPressed: () => Share.shareXFiles([XFile(_doc.localPath)]),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
              ),
            )
          : Column(
              children: [
                // Top Page Counter & Study Header
                Container(
                  color: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _total == 0 ? 'Loading…' : 'Page ${_page + 1} / $_total',
                        style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: _showStudyOptions,
                        child: const Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 14, color: AppColors.purpleBright),
                            SizedBox(width: 4),
                            Text('Study Options', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // PDF Viewer
                Expanded(
                  child: PDFView(
                    filePath: _doc.localPath,
                    defaultPage: _doc.lastPage,
                    swipeHorizontal: false,
                    nightMode: _night,
                    autoSpacing: true,
                    pageFling: true,
                    onRender: (pages) => setState(() => _total = pages ?? 0),
                    onViewCreated: (c) => _controller = c,
                    onPageChanged: (page, total) {
                      setState(() {
                        _page = page ?? 0;
                        _total = total ?? _total;
                      });
                      _persistPage(_page);
                    },
                    onError: (e) => setState(() => _error = 'This PDF could not be opened. It may be corrupted.'),
                    onPageError: (p, e) => setState(() => _error = 'Could not read page ${(p ?? 0) + 1}.'),
                  ),
                ),

                // Unified Primary Study Action Bar & Navigation
                ColoredBox(
                  color: AppColors.background,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Primary Study Card / Button
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.purple,
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => _openStudyHub(0),
                              icon: const Icon(Icons.auto_awesome, size: 18),
                              label: const Text('Study with ChemBuddy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Reader Controls
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _controller?.setPage((_page - 1).clamp(0, _total)),
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Expanded(
                                child: Text('${_page + 1} / $_total', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ),
                              IconButton(
                                onPressed: () => _controller?.setPage((_page + 1).clamp(0, (_total - 1).clamp(0, 9999))),
                                icon: const Icon(Icons.chevron_right),
                              ),
                              IconButton(
                                tooltip: 'Night mode',
                                onPressed: () => setState(() => _night = !_night),
                                icon: Icon(_night ? Icons.dark_mode : Icons.light_mode, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StudyOptionRow extends StatelessWidget {
  const _StudyOptionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlowCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Colors.white)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
