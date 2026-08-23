import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/rag_models.dart';
import '../../data/remote/supabase_service.dart';
import 'admin_providers.dart';

class ChatState {
  final List<AiMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<AiMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatController extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();
  
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
      error: null,
    );

    try {
      final response = await ragService.ask(
        question: question,
        subject: subject,
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
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  void clearChat() => state = const ChatState();
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(ChatController.new);
