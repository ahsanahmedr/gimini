import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_database.dart' as db;
import '../models/chat_session.dart';
import '../models/chat_message.dart';

const _uuid = Uuid();

final appDatabaseProvider = Provider<db.AppDatabase>((ref) {
  final database = db.AppDatabase();
  ref.onDispose(database.close);
  return database;
});

class HistoryNotifier extends StateNotifier<List<ChatSession>> {
  final db.AppDatabase _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Set<String> _driftSavedSessions = {};

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  HistoryNotifier(this._database) : super([]) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final sessionRows = await _database.getAllSessions();
    final sessions = <ChatSession>[];
    for (final row in sessionRows) {
      _driftSavedSessions.add(row.id);
      final messageRows = await _database.getMessagesForSession(row.id);
      sessions.add(ChatSession(
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
      ));
    }
    state = sessions;
  }

  Future<void> _saveSessionToFirestore(ChatSession session) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('sessions')
          .doc(session.id)
          .set({
        'id': session.id,
        'title': session.title,
        'createdAt': session.createdAt.toIso8601String(),
        'updatedAt': session.updatedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Firestore session save error: $e');
    }
  }

  Future<void> _saveMessageToFirestore(
      String sessionId, ChatMessage message) async {
    if (_uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('sessions')
          .doc(sessionId)
          .collection('messages')
          .doc(message.id)
          .set({
        'id': message.id,
        'text': message.text,
        'isUser': message.isUser,
        'timestamp': message.timestamp.toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Firestore message save error: $e');
    }
  }

  // ✅ Sirf local state mein banao — Firestore/Drift mein NAHI
  // Jab pehla message aayega tab save hoga
// ✅ Sirf local state — Drift/Firestore mein BILKUL nahi
ChatSession createSession() {
  final now = DateTime.now();
  final session = ChatSession(
    id: _uuid.v4(),
    title: 'New Chat',
    messages: [],
    createdAt: now,
    updatedAt: now,
  );
  state = [session, ...state]; // sirf memory mein
  return session;
}

  void addMessage(String sessionId, ChatMessage message) {
  final sessionExists = state.any((s) => s.id == sessionId);
  if (!sessionExists) return;

  // Pehle check karo ke session abhi Drift mein hai ya nahi
  final existsInDrift = _driftSavedSessions.contains(sessionId); // ← set rakhenge

  state = state.map((session) {
    if (session.id != sessionId) return session;
    final updatedMessages = [...session.messages, message];
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

  if (!existsInDrift && message.isUser) {
    // ✅ Pehli baar — Drift mein session banao
    _driftSavedSessions.add(sessionId);
    _database.insertSession(db.ChatSessionsCompanion.insert(
      id: updatedSession.id,
      title: Value(updatedSession.title),
      createdAt: updatedSession.createdAt,
      updatedAt: updatedSession.updatedAt,
    ));
    _saveSessionToFirestore(updatedSession);
  } else if (existsInDrift) {
    // ✅ Already saved — sirf update karo
    _database.updateSession(db.ChatSessionsCompanion(
      id: Value(sessionId),
      title: Value(updatedSession.title),
      updatedAt: Value(updatedSession.updatedAt),
    ));
    _saveSessionToFirestore(updatedSession);
  }

  // Message save karo (sirf agar session Drift mein ho)
  if (_driftSavedSessions.contains(sessionId)) {
    _database.insertMessage(db.ChatMessagesCompanion.insert(
      id: message.id,
      sessionId: sessionId,
      content: message.text,
      isUser: message.isUser,
      timestamp: message.timestamp,
    ));
    _saveMessageToFirestore(sessionId, message);
  }
}

  void updateLastBotMessage(String sessionId, String fullText) {
    String? lastMessageId;

    state = state.map((session) {
      if (session.id != sessionId) return session;
      final messages = [...session.messages];
      if (messages.isNotEmpty && !messages.last.isUser) {
        lastMessageId = messages.last.id;
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

    _database.updateMessage(db.ChatMessagesCompanion(
      id: Value(lastMessageId!),
      content: Value(fullText),
    ));

    _database.updateSession(db.ChatSessionsCompanion(
      id: Value(sessionId),
      updatedAt: Value(DateTime.now()),
    ));

    if (_uid != null) {
      _firestore
          .collection('users')
          .doc(_uid)
          .collection('sessions')
          .doc(sessionId)
          .collection('messages')
          .doc(lastMessageId!)
          .update({'text': fullText}).catchError(
              (e) => debugPrint('Firestore message update error: $e'));
    }
  }

  void deleteSession(String sessionId) {
    state = state.where((s) => s.id != sessionId).toList();

    _database.deleteSession(sessionId);

    if (_uid != null) {
      _firestore
          .collection('users')
          .doc(_uid)
          .collection('sessions')
          .doc(sessionId)
          .delete()
          .catchError((e) => debugPrint('Firestore delete error: $e'));
    }
  }

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