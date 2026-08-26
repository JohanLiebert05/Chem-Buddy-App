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

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.activeDocumentName,
    this.activeDocumentText,
    this.activeDocumentPath,
    this.activeDocumentSize,
    this.activeDocumentPages,
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
    state = state.copyWith(
      activeDocumentName: name,
      activeDocumentText: text,
      activeDocumentPath: path,
      activeDocumentSize: size,
      activeDocumentPages: pages,
      clearError: true,
    );
  }

  void detachDocument() {
    state = state.copyWith(clearDocument: true);
  }

  Future<void> sendMessage(String question, {String? subject}) async {
    final ragService = ref.read(ragServiceProvider);
    final userId = SupabaseService.instance.userId ?? 'anonymous';
    final tempId = const Uuid().v4();

    final userMessage = AiMessage(
      id: tempId,
      conversationId: 'temp_conv',
      userId: userId,
      role: 'user',
      content: question,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
    );

    try {
      final response = await ragService.ask(
        question: question,
        subject: subject,
        documentText: state.activeDocumentText,
        documentName: state.activeDocumentName,
        history: state.messages,
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
      );
    } catch (e) {
      String cleanMsg = e.toString();
      if (cleanMsg.contains('Bad state:')) {
        cleanMsg = cleanMsg.replaceAll('Bad state:', '').trim();
      }
      if (cleanMsg.isEmpty) {
        cleanMsg = 'Could not get an answer. Please check your internet connection and try again.';
      }
      state = state.copyWith(
        isLoading: false,
        error: cleanMsg,
      );
    }
  }
  
  void clearChat() => state = state.copyWith(messages: const []);
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(ChatController.new);
