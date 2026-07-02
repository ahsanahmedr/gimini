import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';
import 'history_provider.dart';

const _uuid = Uuid();

final geminiServiceProvider =
    Provider.family<GeminiService, String>((ref, sessionId) {
  return GeminiService();
});

class ChatState {
  final String sessionId;
  final List<ChatMessage> messages;
  final bool isTyping;

  ChatState({
    required this.sessionId,
    required this.messages,
    this.isTyping = false,
  });

  ChatState copyWith({
    String? sessionId,
    List<ChatMessage>? messages,
    bool? isTyping,
  }) =>
      ChatState(
        sessionId: sessionId ?? this.sessionId,
        messages: messages ?? this.messages,
        isTyping: isTyping ?? this.isTyping,
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final GeminiService _gemini;

  ChatNotifier(this._ref, this._gemini, String sessionId)
      : super(ChatState(sessionId: sessionId, messages: [])) {
    if (sessionId.isEmpty) return;

    final history = _ref
            .read(historyProvider.notifier)
            .getSession(sessionId)
            ?.messages
            .where((m) => m.text.trim().isNotEmpty)
            .toList() ??
        [];

    if (history.isNotEmpty) {
      state = state.copyWith(messages: history);
      _gemini.loadHistory(history);
    }
  }

  Future<void> sendMessage(String text) async {
    // ✅ Session nahi hai to pehle banao
    String sessionId = state.sessionId;
    if (sessionId.isEmpty) {
      final session = _ref.read(historyProvider.notifier).createSession();
      sessionId = session.id;
      state = ChatState(sessionId: sessionId, messages: []);
    }

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
    );

    _ref.read(historyProvider.notifier).addMessage(sessionId, userMsg);

    final botMsgId = _uuid.v4();
    final botMsgTimestamp = DateTime.now();

    String fullResponse = '';
    bool firstChunk = true;

    await for (final chunk in _gemini.sendMessage(text)) {
      fullResponse += chunk;

      if (firstChunk) {
        firstChunk = false;
        state = state.copyWith(
          isTyping: false,
          messages: [
            ...state.messages,
            ChatMessage(
              id: botMsgId,
              text: fullResponse,
              isUser: false,
              timestamp: botMsgTimestamp,
            ),
          ],
        );
      } else {
        final updatedMessages = [...state.messages];
        updatedMessages[updatedMessages.length - 1] = ChatMessage(
          id: botMsgId,
          text: fullResponse,
          isUser: false,
          timestamp: botMsgTimestamp,
        );
        state = state.copyWith(messages: updatedMessages);
      }
    }

    // ✅ Final response history mein save karo
    _ref.read(historyProvider.notifier).addMessage(
          state.sessionId,
          ChatMessage(
            id: botMsgId,
            text: fullResponse,
            isUser: false,
            timestamp: botMsgTimestamp,
          ),
        );
  }
}

final chatProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>(
        (ref, sessionId) {
  final gemini = ref.read(geminiServiceProvider(sessionId));
  return ChatNotifier(ref, gemini, sessionId);
});