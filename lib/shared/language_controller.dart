import 'package:flutter/material.dart';

class LanguageController {
  LanguageController._();
  static final LanguageController instance = LanguageController._();

  final ValueNotifier<Locale> locale =
  ValueNotifier<Locale>(const Locale('en'));

  void setEnglish() => locale.value = const Locale('en');
  void setArabic() => locale.value = const Locale('ar');
}
