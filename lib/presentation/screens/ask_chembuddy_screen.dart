import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/models/models.dart';
import '../providers/app_providers.dart';
import '../providers/rag_providers.dart';
import 'smart_flashcards_generate_screen.dart';

class AskChemBuddyScreen extends ConsumerStatefulWidget {
  const AskChemBuddyScreen({super.key});

  @override
  ConsumerState<AskChemBuddyScreen> createState() => _AskChemBuddyScreenState();
}

class _AskChemBuddyScreenState extends ConsumerState<AskChemBuddyScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    ref.read(chatControllerProvider.notifier).sendMessage(text);
    _controller.clear();
    
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

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);

    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.science, color: AppColors.purple),
              SizedBox(width: 8),
              Text('Ask ChemBuddy'),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => ref.read(chatControllerProvider.notifier).clearChat(),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: chatState.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.biotech, size: 64, color: AppColors.purple.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'Ask me anything about your chemistry courses!',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        final isUser = msg.role == 'user';
                        
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: GlowCard(
                              borderColor: isUser ? AppColors.purple : AppColors.border,
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isUser)
                                    Text(
                                      msg.content,
                                      style: const TextStyle(color: AppColors.textPrimary),
                                    )
                                  else
                                    MarkdownBody(
                                      data: msg.content,
                                      styleSheet: MarkdownStyleSheet(
                                        p: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                        h1: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
                                        h2: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                                        h3: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                                        listBullet: const TextStyle(color: AppColors.purple),
                                        tableHead: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                                        tableBorder: TableBorder.all(color: AppColors.border, width: 0.5),
                                        blockquoteDecoration: BoxDecoration(
                                          color: AppColors.surfaceElevated,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                                        ),
                                        code: const TextStyle(color: AppColors.purpleBright, backgroundColor: AppColors.surfaceElevated),
                                        codeblockDecoration: BoxDecoration(
                                          color: AppColors.surfaceElevated,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      selectable: true,
                                    ),
                                  if (msg.sources.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: msg.sources.map((s) => Chip(
                                        label: Text(s.fileName ?? s.documentTitle ?? 'Source', style: const TextStyle(fontSize: 10)),
                                        backgroundColor: AppColors.surface,
                                        padding: EdgeInsets.zero,
                                      )).toList(),
                                    ),
                                  ],
                                  if (!isUser) ...[
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
                                                    prefilledText: msg.content,
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
                                                    prefilledTopic: 'Chat Topic',
                                                    prefilledText: msg.content,
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
                                                'Explain this more simply: ${msg.content.substring(0, min(500, msg.content.length))}',
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          _ActionChip(
                                            icon: Icons.bookmark_add,
                                            label: 'Save Note',
                                            onTap: () {
                                              final title = msg.content.split('\n').firstWhere(
                                                (line) => line.trim().isNotEmpty,
                                                orElse: () => 'Chat Note',
                                              ).replaceAll(RegExp(r'^[#*\s]+'), '');
                                              
                                              final note = NoteItem(
                                                id: const Uuid().v4(),
                                                title: title.isEmpty ? 'Chat Note' : (title.length > 50 ? title.substring(0, 50) : title),
                                                body: msg.content,
                                                updatedAt: DateTime.now(),
                                              );
                                              ref.read(appControllerProvider.notifier).saveNote(note);
                                              
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Note saved successfully!')),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]
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
                padding: const EdgeInsets.all(16),
                child: GlowCard(
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.purple,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('ChemBuddy is thinking...', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
            if (chatState.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: GlowCard(
                  borderColor: AppColors.danger,
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(child: Text(chatState.error!, style: const TextStyle(color: AppColors.danger))),
                    ],
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
              color: AppColors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Type your question...',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.purple,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
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
              Icon(icon, size: 14, color: AppColors.purple),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
