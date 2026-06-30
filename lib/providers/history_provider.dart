import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';
const _storageKey = 'chat_sessions';
const _uuid = Uuid();

// All saved chat sessions provider
class HistoryNotifier extends StateNotifier<List<ChatSession>> {
  HistoryNotifier() : super([]) {
    _loadFromStorage(); // Load saved sessions on start
  }

  // Load sessions from SharedPreferences
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;

    final List decoded = jsonDecode(raw);
    state = decoded.map((e) => ChatSession.fromJson(e)).toList();
  }

  // Save all sessions to SharedPreferences
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  // Create a brand new chat session
  ChatSession createSession() {
    final session = ChatSession(
      id: _uuid.v4(),
      title: 'New Chat',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = [session, ...state]; // Add to top of list
    _saveToStorage();
    return session;
  }

  // Add a message to existing session
  void addMessage(String sessionId, ChatMessage message) {
    state = state.map((session) {
      if (session.id != sessionId) return session;

      final updatedMessages = [...session.messages, message];

      // Auto set title from first user message
      final title = session.title == 'New Chat' && message.isUser
          ? (message.text.length > 40
              ? '${message.text.substring(0, 40)}...'
              : message.text)
          : session.title;

      return session.copyWith(
        messages: updatedMessages,
        title: title,
        updatedAt: DateTime.now(),
      );
    }).toList();

    _saveToStorage();
  }

  // Update bot's streaming message (append chunks)
  void updateLastBotMessage(String sessionId, String fullText) {
    state = state.map((session) {
      if (session.id != sessionId) return session;

      final messages = [...session.messages];
      if (messages.isNotEmpty && !messages.last.isUser) {
        // Replace last bot message with updated text
        messages[messages.length - 1] = ChatMessage(
          id: messages.last.id,
          text: fullText,
          isUser: false,
          timestamp: messages.last.timestamp,
        );
      }
      return session.copyWith(messages: messages, updatedAt: DateTime.now());
    }).toList();
    _saveToStorage();
  }

  // Delete a session
  void deleteSession(String sessionId) {
    state = state.where((s) => s.id != sessionId).toList();
    _saveToStorage();
  }

  // Get single session by id
  ChatSession? getSession(String sessionId) {
    try {
      return state.firstWhere((s) => s.id == sessionId);
    } catch (_) {
      return null;
    }
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<ChatSession>>((ref) {
  return HistoryNotifier();
});