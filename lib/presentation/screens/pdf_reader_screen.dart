import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/library_models.dart';
import '../../data/services/pdf_library_service.dart';
import '../providers/app_providers.dart';
import 'flashcard_editor_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _night ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(_doc.displayName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Create flashcard',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => FlashcardEditorScreen(subjectId: _doc.subjectId, sourceHint: _doc.displayName),
              ),
            ),
            icon: const Icon(Icons.style_outlined),
          ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _total == 0 ? 'Loading…' : 'Page ${_page + 1} / $_total',
                    style: TextStyle(color: _night ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w700),
                  ),
                ),
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
                ColoredBox(
                  color: AppColors.background,
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _controller?.setPage((_page - 1).clamp(0, _total)),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text('${_page + 1}', textAlign: TextAlign.center),
                        ),
                        IconButton(
                          onPressed: () => _controller?.setPage((_page + 1).clamp(0, (_total - 1).clamp(0, 9999))),
                          icon: const Icon(Icons.chevron_right),
                        ),
                        IconButton(
                          tooltip: 'Night mode',
                          onPressed: () => setState(() => _night = !_night),
                          icon: Icon(_night ? Icons.dark_mode : Icons.light_mode),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
