import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_preferences.dart';
import '../providers/preferences_provider.dart';
import '../providers/history_provider.dart';
import 'package:drift/drift.dart' hide Column;
import '../providers/app_database.dart';
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _aiNameController;

  static const _primary = Color(0xFF1D4E89);
  static const _dark = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  static const _avatars = [
    '🤖', '🧠', '⚡', '🔥', '🌟', '💡', '🎯', '🚀',
    '🦾', '👾', '🐉', '🦋', '🌈', '🎭', '🔮', '🌙',
  ];

  static const _languages = [
    'English', 'Urdu', 'Arabic', 'Hindi', 'Spanish', 'French'
  ];

  static const _styles = [
    ('Professional', '💼', 'Formal and structured responses'),
    ('Friendly', '😊', 'Warm and conversational tone'),
    ('Short', '⚡', 'Brief and to the point'),
    ('Detailed', '📚', 'Thorough and comprehensive answers'),
  ];

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesProvider);
    _aiNameController = TextEditingController(text: prefs.aiName);
  }

  @override
  void dispose() {
    _aiNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      backgroundColor: prefs.isDarkTheme
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor:
            prefs.isDarkTheme ? const Color(0xFF1E2E43) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: prefs.isDarkTheme ? Colors.white : _dark, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Personalization',
          style: TextStyle(
            color: prefs.isDarkTheme ? Colors.white : _dark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar picker
          _section(
            prefs,
            title: 'Choose Avatar',
            child: Column(
              children: [
                // Selected avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: _primary, width: 2),
                  ),
                  child: Center(
                    child: Text(prefs.avatar,
                        style: const TextStyle(fontSize: 38)),
                  ),
                ),
                const SizedBox(height: 16),
                // Avatar grid
                GridView.count(
                  crossAxisCount: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: _avatars.map((emoji) {
                    final selected = prefs.avatar == emoji;
                    return GestureDetector(
                      onTap: () => notifier.updateAvatar(emoji),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: selected
                              ? _primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? _primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // AI Name
          _section(
            prefs,
            title: 'AI Name',
            child: TextField(
              controller: _aiNameController,
              style: TextStyle(
                  color: prefs.isDarkTheme ? Colors.white : _dark,
                  fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g. Aria, Max, Nova...',
                hintStyle: TextStyle(color: _muted),
                filled: true,
                fillColor: prefs.isDarkTheme
                    ? const Color(0xFF2A3D5A)
                    : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF1D4E89)),
                  onPressed: () {
                    notifier.updateAiName(_aiNameController.text);
                    FocusScope.of(context).unfocus();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('AI name updated!'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              onSubmitted: (val) => notifier.updateAiName(val),
            ),
          ),

          const SizedBox(height: 16),

          // Response Style
          _section(
            prefs,
            title: 'Response Style',
            child: Column(
              children: _styles.map((style) {
                final selected = prefs.responseStyle == style.$1;
                return GestureDetector(
                  onTap: () => notifier.updateResponseStyle(style.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? _primary.withValues(alpha: 0.1)
                          : (prefs.isDarkTheme
                              ? const Color(0xFF2A3D5A)
                              : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(style.$2,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.$1,
                                style: TextStyle(
                                  color: prefs.isDarkTheme
                                      ? Colors.white
                                      : _dark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                style.$3,
                                style: TextStyle(
                                    color: _muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF1D4E89), size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Language
          _section(
            prefs,
            title: 'Preferred Language',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languages.map((lang) {
                final selected = prefs.language == lang;
                return GestureDetector(
                  onTap: () => notifier.updateLanguage(lang),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? _primary
                          : (prefs.isDarkTheme
                              ? const Color(0xFF2A3D5A)
                              : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      lang,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : (prefs.isDarkTheme ? Colors.white70 : _muted),
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Dark/Light Theme toggle
          _section(
            prefs,
            title: 'Theme',
            child: Row(
              children: [
                Icon(
                  prefs.isDarkTheme
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: _primary,
                ),
                const SizedBox(width: 12),
                Text(
                  prefs.isDarkTheme ? 'Dark Theme' : 'Light Theme',
                  style: TextStyle(
                    color: prefs.isDarkTheme ? Colors.white : _dark,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Switch.adaptive(
                  value: prefs.isDarkTheme,
                  activeThumbColor: _primary,
                  onChanged: (_) => notifier.toggleTheme(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          ElevatedButton(
  onPressed: () async {
    final database = ref.read(appDatabaseProvider);

    await database.saveSettings(
      UserSettingsCompanion(
        id: const Value(1),
        aiTone: Value(prefs.responseStyle),
        language: Value(prefs.language),
        customInstruction: Value(_aiNameController.text),
        darkMode: Value(prefs.isDarkTheme),
      ),
    );
    



    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Settings saved successfully"),
        ),
      );
    }
  },
  child: const Text("Save"),
),
        ],
      ),
    );
  }

  Widget _section(UserPreferences prefs,
      {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: prefs.isDarkTheme ? const Color(0xFF1E2E43) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: prefs.isDarkTheme ? Colors.white70 : _muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}