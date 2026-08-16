import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/services/global_search.dart';
import '../providers/app_providers.dart';
import 'pdf_reader_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final hits = GlobalSearch.query(state, _q.text);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _q,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Search PDFs, notes, classes, reminders…'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: hits.isEmpty
                  ? GlowCard(
                      child: Text(
                        _q.text.trim().isEmpty ? 'Type to search everything stored on this device.' : 'No matches.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      itemCount: hits.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final hit = hits[i];
                        return GlowCard(
                          onTap: () {
                            if (hit.kind == 'PDF' && hit.id != null) {
                              final doc = state.pdfs.where((p) => p.id == hit.id);
                              if (doc.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(builder: (_) => PdfReaderScreen(doc: doc.first)),
                                );
                              }
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(hit.kind.toUpperCase(), style: const TextStyle(color: AppColors.purpleBright, fontSize: 11, fontWeight: FontWeight.w800)),
                              Text(hit.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(hit.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
