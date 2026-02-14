import 'package:flutter/foundation.dart';

class UserSession {
  // Singleton
  UserSession._();
  static final instance = UserSession._();

  /// full name that updates the whole app when changed
  final ValueNotifier<String> fullName = ValueNotifier<String>('User');

  void setFullName(String name) {
    fullName.value = name.trim().isEmpty ? 'User' : name.trim();
  }

  void clear() {
    fullName.value = 'User';
  }
}
