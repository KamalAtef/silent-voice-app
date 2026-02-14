import 'package:flutter/material.dart';

class S {
  static bool isAr(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar';

  static String t(BuildContext context, String en, String ar) {
    return isAr(context) ? ar : en;
  }
}
