import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
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
                                  Text(
                                    msg.content,
                                    style: const TextStyle(color: AppColors.textPrimary),
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
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.style, size: 14),
                                      label: const Text('Create Flashcards', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                        minimumSize: const Size(0, 32),
                                        side: const BorderSide(color: AppColors.purple),
                                      ),
                                      onPressed: () {
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
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('ChemBuddy is thinking...', style: TextStyle(color: AppColors.purple)),
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
