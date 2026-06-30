import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import '../providers/app_database.dart' as db;
import '../models/chat_session.dart';
import '../models/chat_message.dart';

const _uuid = Uuid();

// Single shared database instance for the whole app
final appDatabaseProvider = Provider<db.AppDatabase>((ref) {
  final database = db.AppDatabase();
  ref.onDispose(database.close);
  return database;
});

// All saved chat sessions provider (same shape as before: List<ChatSession>)
class HistoryNotifier extends StateNotifier<List<ChatSession>> {
  final db.AppDatabase _database;

  HistoryNotifier(this._database) : super([]) {
    _loadFromStorage(); // Load saved sessions on start
  }

  // Load sessions + their messages from Drift
  Future<void> _loadFromStorage() async {
    final sessionRows = await _database.getAllSessions();

    final sessions = <ChatSession>[];
    for (final row in sessionRows) {
      final messageRows = await _database.getMessagesForSession(row.id);
      sessions.add(
        ChatSession(
          id: row.id,
          title: row.title,
          messages: messageRows
              .map((m) => ChatMessage(
                    id: m.id,
                    text: m.content,
                    isUser: m.isUser,
                    timestamp: m.timestamp,
                  ))
              .toList(),
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        ),
      );
    }
    state = sessions;
  }

  // Create a brand new chat session
  ChatSession createSession() {
    final now = DateTime.now();
    final session = ChatSession(
      id: _uuid.v4(),
      title: 'New Chat',
      messages: [],
      createdAt: now,
      updatedAt: now,
    );

    state = [session, ...state]; // Add to top of list

    _database.insertSession(db.ChatSessionsCompanion.insert(
      id: session.id,
      title: const Value('New Chat'),
      createdAt: now,
      updatedAt: now,
    ));

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

    final updatedSession = getSession(sessionId);
    if (updatedSession == null) return;

    _database.insertMessage(db.ChatMessagesCompanion.insert(
      id: message.id,
      sessionId: sessionId,
      content: message.text,
      isUser: message.isUser,
      timestamp: message.timestamp,
    ));

    _database.updateSession(db.ChatSessionsCompanion(
      id: Value(sessionId),
      title: Value(updatedSession.title),
      updatedAt: Value(updatedSession.updatedAt),
    ));
  }

  // Update bot's streaming message (append chunks)
  void updateLastBotMessage(String sessionId, String fullText) {
    String? lastMessageId;

    state = state.map((session) {
      if (session.id != sessionId) return session;

      final messages = [...session.messages];
      if (messages.isNotEmpty && !messages.last.isUser) {
        lastMessageId = messages.last.id;
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

    if (lastMessageId == null) return;

    // Persist only the changed message text, avoid rewriting everything
    _database.updateMessage(db.ChatMessagesCompanion(
      id: Value(lastMessageId!),
      content: Value(fullText),
    ));

    _database.updateSession(db.ChatSessionsCompanion(
      id: Value(sessionId),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // Delete a session
  void deleteSession(String sessionId) {
    state = state.where((s) => s.id != sessionId).toList();
    _database.deleteSession(sessionId); // messages cascade-delete in DB
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
  final database = ref.watch(appDatabaseProvider);
  return HistoryNotifier(database);
});