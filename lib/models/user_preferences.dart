class UserPreferences {
  final String aiName;
  final String language;
  final String responseStyle;
  final String avatar;
  final bool isDarkTheme;

  const UserPreferences({
    this.aiName = 'AI Assistant',
    this.language = 'English',
    this.responseStyle = 'Friendly',
    this.avatar = '🤖',
    this.isDarkTheme = false,
  });

  UserPreferences copyWith({
    String? aiName,
    String? language,
    String? responseStyle,
    String? avatar,
    bool? isDarkTheme,
  }) =>
      UserPreferences(
        aiName: aiName ?? this.aiName,
        language: language ?? this.language,
        responseStyle: responseStyle ?? this.responseStyle,
        avatar: avatar ?? this.avatar,
        isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      );

  Map<String, dynamic> toJson() => {
        'aiName': aiName,
        'language': language,
        'responseStyle': responseStyle,
        'avatar': avatar,
        'isDarkTheme': isDarkTheme,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        aiName: json['aiName'] ?? 'AI Assistant',
        language: json['language'] ?? 'English',
        responseStyle: json['responseStyle'] ?? 'Friendly',
        avatar: json['avatar'] ?? '🤖',
        isDarkTheme: json['isDarkTheme'] ?? false,
      );
}