import '../../data/services/chemistry_knowledge_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/rag_models.dart';
import '../../data/remote/supabase_service.dart';
import 'admin_providers.dart';

class ChatState {
  final List<AiMessage> messages;
  final bool isLoading;
  final String? error;
  final String? activeDocumentName;
  final String? activeDocumentText;
  final String? activeDocumentPath;
  final int? activeDocumentSize;
  final int? activeDocumentPages;
  final String? lastQuestion;
  final String? lastSubject;
  final String? lastModelPrompt;
  final String? lastMode;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.activeDocumentName,
    this.activeDocumentText,
    this.activeDocumentPath,
    this.activeDocumentSize,
    this.activeDocumentPages,
    this.lastQuestion,
    this.lastSubject,
    this.lastModelPrompt,
    this.lastMode,
  });

  bool get hasActiveDocument => activeDocumentText != null && activeDocumentText!.isNotEmpty;

  ChatState copyWith({
    List<AiMessage>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? activeDocumentName,
    String? activeDocumentText,
    String? activeDocumentPath,
    int? activeDocumentSize,
    int? activeDocumentPages,
    bool clearDocument = false,
    String? lastQuestion,
    String? lastSubject,
    String? lastModelPrompt,
    String? lastMode,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeDocumentName: clearDocument ? null : (activeDocumentName ?? this.activeDocumentName),
      activeDocumentText: clearDocument ? null : (activeDocumentText ?? this.activeDocumentText),
      activeDocumentPath: clearDocument ? null : (activeDocumentPath ?? this.activeDocumentPath),
      activeDocumentSize: clearDocument ? null : (activeDocumentSize ?? this.activeDocumentSize),
      activeDocumentPages: clearDocument ? null : (activeDocumentPages ?? this.activeDocumentPages),
      lastQuestion: lastQuestion ?? this.lastQuestion,
      lastSubject: lastSubject ?? this.lastSubject,
      lastModelPrompt: lastModelPrompt ?? this.lastModelPrompt,
      lastMode: lastMode ?? this.lastMode,
    );
  }
}

class ChatController extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();
  
  void attachDocument({
    required String name,
    required String text,
    required String path,
    int? size,
    int? pages,
  }) {
    final summaryContent = ChemistryKnowledgeEngine.generateDocumentSummary(text, name);
    final summaryMessage = AiMessage(
      id: const Uuid().v4(),
      conversationId: 'temp_conv',
      userId: SupabaseService.instance.userId ?? 'anonymous',
      role: 'assistant',
      content: summaryContent,
      sources: [
        RagSource(
          documentTitle: name,
          fileName: name,
          pageNumber: 1,
          subject: 'Attached Study Material',
          topic: 'Document Executive Summary',
          similarity: 1.0,
        ),
      ],
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      activeDocumentName: name,
      activeDocumentText: text,
      activeDocumentPath: path,
      activeDocumentSize: size,
      activeDocumentPages: pages,
      messages: [...state.messages, summaryMessage],
      clearError: true,
    );
  }

  void detachDocument() {
    state = state.copyWith(clearDocument: true);
  }

  Future<void> sendMessage(String question, {String? subject, String? modelPrompt, String? mode}) async {
    // Prevent duplicate requests while an answer is currently being computed
    if (state.isLoading) return;

    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    final ragService = ref.read(ragServiceProvider);
    final userId = SupabaseService.instance.userId ?? 'anonymous';
    final tempId = const Uuid().v4();
    final prior = List<AiMessage>.from(state.messages);

    final userMessage = AiMessage(
      id: tempId,
      conversationId: 'temp_conv',
      userId: userId,
      role: 'user',
      content: trimmed,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...prior, userMessage],
      isLoading: true,
      clearError: true,
      lastQuestion: trimmed,
      lastSubject: subject,
      lastModelPrompt: modelPrompt,
      lastMode: mode,
    );

    try {
      final history = prior.length > 4 ? prior.sublist(prior.length - 4) : prior;
      final response = await ragService.ask(
        question: modelPrompt ?? trimmed,
        subject: subject,
        documentText: state.activeDocumentText,
        documentName: state.activeDocumentName,
        history: history,
        mode: mode,
      );

      final assistantMessage = AiMessage(
        id: const Uuid().v4(),
        conversationId: 'temp_conv',
        userId: userId,
        role: 'assistant',
        content: response.answer,
        sources: response.sources,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      String cleanMsg = "Chem Buddy AI couldn't complete that request. Please try again.";
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('socket') || errStr.contains('network') || errStr.contains('offline')) {
        cleanMsg = 'Network connection issue. Please check your internet and retry.';
      } else if (errStr.contains('timeout')) {
        cleanMsg = 'The request timed out. Please tap retry to try again.';
      }

      state = state.copyWith(
        isLoading: false,
        error: cleanMsg,
      );
    }
  }

  Future<void> retryLastMessage() async {
    if (state.lastQuestion != null && state.lastQuestion!.isNotEmpty) {
      // Remove last failed user message if needed or just re-dispatch
      await sendMessage(
        state.lastQuestion!,
        subject: state.lastSubject,
        modelPrompt: state.lastModelPrompt,
        mode: state.lastMode,
      );
    }
  }
  
  void clearChat() => state = state.copyWith(messages: const [], clearError: true, clearDocument: false);
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(ChatController.new);
