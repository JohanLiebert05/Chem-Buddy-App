import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/chemistry_text_formatter.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/models/models.dart';
import '../../data/models/library_models.dart';
import '../../data/services/pdf_text_extraction_service.dart';
import '../../data/services/pdf_text_utils.dart';
import '../providers/app_providers.dart';
import '../providers/rag_providers.dart';
import 'pdf_reader_screen.dart';
import 'smart_flashcards_generate_screen.dart';

class AskChemBuddyScreen extends ConsumerStatefulWidget {
  const AskChemBuddyScreen({super.key});

  @override
  ConsumerState<AskChemBuddyScreen> createState() => _AskChemBuddyScreenState();
}

class _AskChemBuddyScreenState extends ConsumerState<AskChemBuddyScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _extracting = false;
  String _extractingStatus = 'Reading document...';
  String? _lastSentQuestion;

  void _sendMessage([String? textOverride]) {
    final text = textOverride ?? _controller.text.trim();
    if (text.isEmpty) return;
    
    _lastSentQuestion = text;
    ref.read(chatControllerProvider.notifier).sendMessage(text);
    if (textOverride == null) _controller.clear();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) return;

      setState(() {
        _extracting = true;
        _extractingStatus = 'Reading document structure...';
      });

      final text = await PdfTextExtractionService.instance.extractFromPath(
        file.path!,
        onProgress: (status) {
          if (mounted) setState(() => _extractingStatus = status);
        },
      );
      final fileObj = File(file.path!);
      final size = await fileObj.length();

      ref.read(chatControllerProvider.notifier).attachDocument(
        name: file.name,
        text: text,
        path: file.path!,
        size: size,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Attached: ${file.name}\nChemBuddy is ready to answer questions from it.')),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(e is PdfExtractionException ? e.message : 'Could not read PDF text. Make sure it contains readable text.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);

    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            children: const [
              Icon(Icons.auto_awesome, color: AppColors.purpleBright, size: 22),
              SizedBox(width: 8),
              Text('Ask ChemBuddy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            TextButton.icon(
              onPressed: _extracting ? null : _pickPdf,
              icon: const Icon(Icons.note_add, size: 16, color: AppColors.purpleBright),
              label: const Text('+ Study Material', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
              tooltip: 'Clear Chat',
              onPressed: () => ref.read(chatControllerProvider.notifier).clearChat(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Extracting banner
            if (_extracting)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: GlowCard(
                  borderColor: AppColors.purpleBright.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purpleBright)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _extractingStatus,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Active Attached PDF Banner & Quick Actions
            if (chatState.hasActiveDocument && !_extracting)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: GlowCard(
                  borderColor: AppColors.purpleBright.withValues(alpha: 0.4),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.purpleBright, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chatState.activeDocumentName ?? 'Study Material',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                Row(
                                  children: [
                                    const Text('Ready 🟢', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                                    if (chatState.activeDocumentSize != null)
                                      Text(' · ${_formatSize(chatState.activeDocumentSize)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (chatState.activeDocumentPath != null)
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.blue),
                              tooltip: 'View PDF',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => PdfReaderScreen(
                                      doc: PdfDoc(
                                        id: const Uuid().v4(),
                                        filename: chatState.activeDocumentName ?? 'document.pdf',
                                        displayName: chatState.activeDocumentName ?? 'Study Material',
                                        subjectId: '',
                                        localPath: chatState.activeDocumentPath!,
                                        dateAdded: DateTime.now(),
                                        fileSize: chatState.activeDocumentSize ?? 0,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                            tooltip: 'Remove Attached PDF',
                            onPressed: () => ref.read(chatControllerProvider.notifier).detachDocument(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _ActionChip(
                              icon: Icons.summarize_outlined,
                              label: 'Summarize',
                              onTap: () => _sendMessage('Please give me a clear, structured summary of this study material with major topics and reaction mechanisms.'),
                            ),
                            const SizedBox(width: 8),
                            _ActionChip(
                              icon: Icons.style,
                              label: 'Flashcards',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => SmartFlashcardsGenerateScreen(
                                      prefilledTopic: chatState.activeDocumentName,
                                      prefilledText: chatState.activeDocumentText,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _ActionChip(
                              icon: Icons.lightbulb_outline,
                              label: 'Key Concepts',
                              onTap: () => _sendMessage('Extract and list all the key chemistry concepts, definitions, and equations from this PDF.'),
                            ),
                            const SizedBox(width: 8),
                            _ActionChip(
                              icon: Icons.quiz_outlined,
                              label: 'Practice Questions',
                              onTap: () => _sendMessage('Generate 5 MSc-level exam practice questions with model answers based on this study material.'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Messages
            Expanded(
              child: chatState.messages.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.science_outlined, size: 48, color: AppColors.purpleBright),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Ask ChemBuddy',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Ask chemistry questions or attach your course notes to study from them.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.purple.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onPressed: _pickPdf,
                              icon: const Icon(Icons.upload_file, color: AppColors.purpleBright, size: 18),
                              label: const Text('Attach PDF Study Material', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(height: 24),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Suggested Topics:', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 8),
                            _SuggestionTile(
                              text: 'Explain SN1 vs SN2 reaction mechanisms and stereochemistry.',
                              onTap: () => _sendMessage('Explain SN1 vs SN2 reaction mechanisms and stereochemistry.'),
                            ),
                            const SizedBox(height: 6),
                            _SuggestionTile(
                              text: 'How does Huckel\'s rule (4n+2) determine aromaticity?',
                              onTap: () => _sendMessage('How does Huckel\'s rule (4n+2) determine aromaticity?'),
                            ),
                            const SizedBox(height: 6),
                            _SuggestionTile(
                              text: 'Differentiate between thermodynamic and kinetic control.',
                              onTap: () => _sendMessage('Differentiate between thermodynamic and kinetic control.'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        final isUser = msg.role == 'user';
                        
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                            child: GlowCard(
                              borderColor: isUser ? AppColors.purple.withValues(alpha: 0.6) : AppColors.border,
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isUser)
                                    Text(
                                      msg.content,
                                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                                    )
                                  else ...[
                                    if (msg.sources.isNotEmpty) ...[
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.purple.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.menu_book, size: 13, color: AppColors.purpleBright),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'Answering from: ${msg.sources.first.fileName ?? msg.sources.first.documentTitle ?? "Study Notes"}',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: AppColors.purpleBright, fontSize: 11.5, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    MarkdownBody(
                                      data: ChemistryTextFormatter.format(msg.content),
                                      styleSheet: MarkdownStyleSheet(
                                        p: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.45),
                                        h1: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                                        h2: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                                        h3: const TextStyle(color: AppColors.purpleBright, fontSize: 15, fontWeight: FontWeight.w600),
                                        listBullet: const TextStyle(color: AppColors.purpleBright),
                                        tableHead: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                        tableBorder: TableBorder.all(color: AppColors.border, width: 0.6),
                                        blockquoteDecoration: BoxDecoration(
                                          color: AppColors.surfaceElevated,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                                        ),
                                        code: const TextStyle(color: AppColors.purpleBright, backgroundColor: AppColors.surfaceElevated, fontFamily: 'monospace'),
                                        codeblockDecoration: BoxDecoration(
                                          color: AppColors.surfaceElevated,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                      ),
                                      selectable: true,
                                    ),
                                    const SizedBox(height: 12),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _ActionChip(
                                            icon: Icons.style,
                                            label: 'Flashcards',
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute<void>(
                                                  builder: (_) => SmartFlashcardsGenerateScreen(
                                                    prefilledTopic: 'Chat Topic',
                                                    prefilledText: ChemistryTextFormatter.format(msg.content),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionChip(
                                            icon: Icons.quiz,
                                            label: 'Quiz',
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute<void>(
                                                  builder: (_) => SmartFlashcardsGenerateScreen(
                                                    prefilledTopic: 'Quiz Review',
                                                    prefilledText: ChemistryTextFormatter.format(msg.content),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionChip(
                                            icon: Icons.auto_awesome,
                                            label: 'Simpler',
                                            onTap: () {
                                              ref.read(chatControllerProvider.notifier).sendMessage(
                                                'Explain this more simply and concisely for an exam summary: ${msg.content.substring(0, min(400, msg.content.length))}',
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionChip(
                                            icon: Icons.bookmark_add,
                                            label: 'Save Note',
                                            onTap: () {
                                              final rawTitle = msg.content.split('\n').firstWhere(
                                                (line) => line.trim().isNotEmpty,
                                                orElse: () => 'Chemistry Note',
                                              ).replaceAll(RegExp(r'^[#*\s]+'), '');
                                              final title = ChemistryTextFormatter.format(rawTitle);
                                              
                                              final note = NoteItem(
                                                id: const Uuid().v4(),
                                                title: title.isEmpty ? 'Chemistry Note' : (title.length > 50 ? title.substring(0, 50) : title),
                                                body: ChemistryTextFormatter.format(msg.content),
                                                updatedAt: DateTime.now(),
                                              );
                                              ref.read(appControllerProvider.notifier).saveNote(note);
                                              
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Saved to your Notes library!')),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (chatState.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GlowCard(
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.purpleBright,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('ChemBuddy is thinking...', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic, fontSize: 13)),
                    ],
                  ),
                ),
              ),

            if (chatState.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GlowCard(
                  borderColor: AppColors.danger.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(chatState.error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                      ),
                      if (_lastSentQuestion != null)
                        TextButton(
                          onPressed: () => _sendMessage(_lastSentQuestion),
                          child: const Text('Retry', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
              ),

            // Input Bar with responsive spacing above bottom navigation bar
            Builder(
              builder: (context) {
                final insets = MediaQuery.viewInsetsOf(context).bottom;
                final safeBottom = MediaQuery.paddingOf(context).bottom;
                final bottomPadding = insets > 0 ? 8.0 : (62.0 + max(6.0, safeBottom));

                return Container(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
                  decoration: BoxDecoration(
                    color: const Color(0xE8141620),
                    border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.4))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: chatState.hasActiveDocument
                                ? 'Ask about ${chatState.activeDocumentName}...'
                                : 'Ask any chemistry question...',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.purple,
                        radius: 22,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 18),
                          onPressed: () => _sendMessage(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionTile({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.subdirectory_arrow_right, size: 16, color: AppColors.purpleBright),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.purpleBright),
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
