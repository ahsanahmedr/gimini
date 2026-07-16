import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// One row per chat session (a "conversation")
class ChatSessions extends Table {
  TextColumn get id => text()(); // uuid, primary key
  TextColumn get title => text().withDefault(const Constant('New Chat'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// One row per message, linked to a session
class ChatMessages extends Table {
  TextColumn get id => text()(); // uuid, primary key
  TextColumn get sessionId =>
      text().references(ChatSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get content => text()();
  BoolColumn get isUser => boolean()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Simple key-value store, used for flags like 'onboarding_seen'
class Settings extends Table {
  TextColumn get key => text()(); // e.g. 'onboarding_seen'
  TextColumn get value => text()(); // stored as string, parsed by caller

  @override
  Set<Column> get primaryKey => {key};
}

class UserSettings extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get aiTone => text().withDefault(const Constant('Friendly'))();
  TextColumn get language => text().withDefault(const Constant('English'))();
  TextColumn get customInstruction =>
      text().withDefault(const Constant(''))();

  BoolColumn get darkMode =>
      boolean().withDefault(const Constant(false))();
}

@DriftDatabase(
  tables: [
    ChatSessions,
    ChatMessages,
    Settings,
    UserSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  
  AppDatabase() : super(_openConnection());


  // Bump this whenever you change a table's columns
  @override
  int get schemaVersion => 2;

  // ---------------- Session queries ----------------

  Future<List<ChatSession>> getAllSessions() {
    return (select(chatSessions)
          ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)]))
        .get();
  }
  

  Stream<List<ChatSession>> watchAllSessions() {
    return (select(chatSessions)
          ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)]))
        .watch();
  }

  Future<void> insertSession(ChatSessionsCompanion session) {
    return into(chatSessions).insert(session);
  }

  Future<void> updateSession(ChatSessionsCompanion session) {
    return (update(chatSessions)
          ..where((s) => s.id.equals(session.id.value)))
        .write(session);
  }

Future<UserSetting?> getSettings() {
  return select(userSettings).getSingleOrNull();
}

Future<void> saveSettings(UserSettingsCompanion data) async {
  await into(userSettings).insertOnConflictUpdate(data);
}

  Future<void> deleteSession(String sessionId) {
    return (delete(chatSessions)..where((s) => s.id.equals(sessionId))).go();
    // Messages are deleted automatically (onDelete: cascade)
  }

  // ---------------- Message queries ----------------

  Future<List<ChatMessage>> getMessagesForSession(String sessionId) {
    return (select(chatMessages)
          ..where((m) => m.sessionId.equals(sessionId))
          ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
        .get();
  }

  Future<void> insertMessage(ChatMessagesCompanion message) {
    return into(chatMessages).insert(message);
  }

  Future<void> updateMessage(ChatMessagesCompanion message) {
    return (update(chatMessages)
          ..where((m) => m.id.equals(message.id.value)))
        .write(message);
  }

  // ---------------- Settings (key-value) queries ----------------

  Future<String?> getSetting(String key) async {
    final row = await (select(settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await getSetting(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  Future<void> setBool(String key, bool value) {
    return into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(key: key, value: value.toString()),
    );
  }

  Future<void> setString(String key, String value) {
    return into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(key: key, value: value),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'chat_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}