
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_preferences.dart';
import '../providers/history_provider.dart';
import '../providers/app_database.dart';
import 'package:drift/drift.dart';

class PreferencesNotifier extends StateNotifier<UserPreferences> {
  final AppDatabase database;

  PreferencesNotifier(this.database)
      : super(const UserPreferences()) {
    _load();
  }

Future<void> _load() async {
  final data = await database.getSettings();

  if (data != null) {
    state = state.copyWith(
      aiName: data.customInstruction,
      language: data.language,
      responseStyle: data.aiTone,
      isDarkTheme: data.darkMode,
    );
  }
}

Future<void> _save() async {
  await database.saveSettings(
    UserSettingsCompanion(
      id: const Value(1),
      aiTone: Value(state.responseStyle),
      language: Value(state.language),
      customInstruction: Value(state.aiName),
      darkMode: Value(state.isDarkTheme),
    ),
  );
}

  void updateAiName(String name) {
    state = state.copyWith(aiName: name.trim().isEmpty ? 'AI Assistant' : name);
    _save();
  }

  void updateLanguage(String language) {
    state = state.copyWith(language: language);
    _save();
  }

  void updateResponseStyle(String style) {
    state = state.copyWith(responseStyle: style);
    _save();
  }

  void updateAvatar(String avatar) {
    state = state.copyWith(avatar: avatar);
    _save();
  }

  void toggleTheme() {
    state = state.copyWith(isDarkTheme: !state.isDarkTheme);
    _save();
  }
}

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, UserPreferences>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return PreferencesNotifier(database);
});