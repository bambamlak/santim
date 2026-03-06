import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final ThemeMode themeMode;
  final Color seedColor;
  final String languageCode;
  final String currencyCode;
  final bool isAmoled;

  AppSettings({
    required this.themeMode,
    required this.seedColor,
    this.languageCode = 'en',
    this.currencyCode = 'ETB',
    this.isAmoled = false,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    Color? seedColor,
    String? languageCode,
    String? currencyCode,
    bool? isAmoled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
      languageCode: languageCode ?? this.languageCode,
      currencyCode: currencyCode ?? this.currencyCode,
      isAmoled: isAmoled ?? this.isAmoled,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const String _themeModeKey = 'theme_mode';
  static const String _seedColorKey = 'seed_color';
  static const String _languageKey = 'language_code';
  static const String _currencyKey = 'currency_code';
  static const String _isAmoledKey = 'is_amoled';

  @override
  AppSettings build() {
    return AppSettings(
      themeMode: ThemeMode.light,
      seedColor: const Color(0xFFD97706),
    );
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.light.index;
    final colorValue =
        prefs.getInt(_seedColorKey) ?? const Color(0xFFD97706).toARGB32();
    final lang = prefs.getString(_languageKey) ?? 'en';
    final curr = prefs.getString(_currencyKey) ?? 'ETB';
    final amoled = prefs.getBool(_isAmoledKey) ?? false;

    state = AppSettings(
      themeMode: ThemeMode.values[themeIndex],
      seedColor: Color(colorValue),
      languageCode: lang,
      currencyCode: curr,
      isAmoled: amoled,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setSeedColor(Color color) async {
    state = state.copyWith(seedColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.toARGB32());
  }

  Future<void> setLanguageCode(String code) async {
    state = state.copyWith(languageCode: code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
  }

  Future<void> setCurrencyCode(String code) async {
    state = state.copyWith(currencyCode: code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code);
  }

  Future<void> setIsAmoled(bool val) async {
    state = state.copyWith(isAmoled: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAmoledKey, val);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
