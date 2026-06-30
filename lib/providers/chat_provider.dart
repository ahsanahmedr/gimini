import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';
import 'history_provider.dart';

const _uuid = Uuid();

// ✅ GeminiService — sessionId se bind, sirf ek baar banega
final geminiServiceProvider = Provider.family<GeminiService, String>((ref, sessionId) {
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
    List<ChatMessage>? messages,
    bool? isTyping,
  }) =>
      ChatState(
        sessionId: sessionId,
        messages: messages ?? this.messages,
        isTyping: isTyping ?? this.isTyping,
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final GeminiService _gemini;

  ChatNotifier(this._ref, this._gemini, String sessionId)
      : super(ChatState(sessionId: sessionId, messages: [])) {
    // ✅ History sirf ek baar constructor mein lo
    final history = _ref
            .read(historyProvider.notifier)
            .getSession(sessionId)
            ?.messages
            .where((m) => m.text.trim().isNotEmpty)
            .toList() ?? [];

    if (history.isNotEmpty) {
      state = state.copyWith(messages: history);
      _gemini.loadHistory(history);
    }
  }

  Future<void> sendMessage(String text) async {
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

    _ref.read(historyProvider.notifier).addMessage(state.sessionId, userMsg);

    final botMsgId = _uuid.v4();
    final botMsgTimestamp = DateTime.now();



  
        String fullResponse = '';
    bool firstChunk = true;
    await for (final chunk in _gemini.sendMessage(text)) {
      fullResponse += chunk;

      if (firstChunk) {
        // ✅ Pehla chunk aaya — typing band, naya bubble banao
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
        // ✅ Baaki chunks — sirf last message update karo
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

    _ref.read(historyProvider.notifier).addMessage(
          state.sessionId,
          ChatMessage(
            id: botMsgId,
            text: fullResponse,
            isUser: false,
            timestamp: botMsgTimestamp,
          ),
        );
}}

// ✅ Ab sirf String (sessionId) — koi history nahi
final chatProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>(
        (ref, sessionId) {
  final gemini = ref.read(geminiServiceProvider(sessionId));
  return ChatNotifier(ref, gemini, sessionId);
});