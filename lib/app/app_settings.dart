import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final theme = prefs.getString('theme_mode') ?? 'system';
    themeMode.value = switch (theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final lang = prefs.getString('lang') ?? 'en';
    locale.value = Locale(lang);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    final v = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString('theme_mode', v);
  }

  Future<void> setLanguage(String code) async {
    locale.value = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', code);
  }
}
