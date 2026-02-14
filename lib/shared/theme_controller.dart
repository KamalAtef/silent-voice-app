import 'package:flutter/material.dart';

enum AppThemeMode { light, dark }

class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(ThemeMode.light);

  void setLight() => mode.value = ThemeMode.light;
  void setDark() => mode.value = ThemeMode.dark;

  // لو حبيت زرار toggle
  void toggle() {
    mode.value = mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}
