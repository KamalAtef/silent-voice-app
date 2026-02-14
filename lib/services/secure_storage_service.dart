import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'auth_dtos.dart';

/// Secure Storage Service - Handles secure storage of tokens and user data
class SecureStorageService {
  // Singleton pattern
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage();

  // Storage Keys
  static const String _keyToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserData = 'user_data';
  static const String _keyEmail = 'user_email';

  // ==================== TOKEN MANAGEMENT ====================

  /// Save authentication token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  /// Get authentication token
  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  // ==================== USER DATA MANAGEMENT ====================

  /// Save user data
  Future<void> saveUserData(UserData user) async {
    final jsonString = jsonEncode({
      'id': user.id,
      'email': user.email,
      'firstName': user.firstName,
      'lastName': user.lastName,
    });
    await _storage.write(key: _keyUserData, value: jsonString);
  }

  /// Get user data
  Future<UserData?> getUserData() async {
    final jsonString = await _storage.read(key: _keyUserData);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString);
      return UserData.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Save email (for convenience in flows)
  Future<void> saveEmail(String email) async {
    await _storage.write(key: _keyEmail, value: email);
  }

  /// Get saved email
  Future<String?> getEmail() async {
    return await _storage.read(key: _keyEmail);
  }

  // ==================== SESSION MANAGEMENT ====================

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all data (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Clear only auth tokens (keep user data)
  Future<void> clearTokens() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRefreshToken);
  }
}