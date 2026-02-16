import 'package:flutter/foundation.dart';

class UserSession {
  UserSession._();
  static final instance = UserSession._();

  final ValueNotifier<String> fullName = ValueNotifier<String>('User');
  final ValueNotifier<String> email = ValueNotifier<String>(''); // ✅ NEW

  void setFullName(String name, {String? fallback}) {
    final v = name.trim();
    fullName.value = v.isEmpty ? (fallback ?? 'User') : v;
  }

  void setEmail(String v, {String fallback = ''}) { // ✅ NEW
    final s = v.trim();
    email.value = s.isEmpty ? fallback : s;
  }

  void clear({String fallback = 'User'}) {
    fullName.value = fallback;
    email.value = ''; // ✅ NEW
  }
}
