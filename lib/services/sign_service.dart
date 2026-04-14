// ── lib/services/sign_service.dart ────────────────────────────────────────────
// Handles all API calls to .NET backend sign endpoints

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silentvoice/services/secure_storage_service.dart';

import 'sign_models.dart';

class SignService {
  // ── IMPORTANT: change this to your .NET backend base URL ──────────────────
  static const String _baseUrl = 'http://silentvoice.runasp.net';
  // Example: 'https://abc123.ngrok-free.app' or 'http://192.168.1.X:5000'
  final _storage = SecureStorageService();
  // ── Get JWT token saved at login ──────────────────────────────────────────
  // Future<String?> _getToken() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getString('auth_token');
  // }

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
  };

  // ══════════════════════════════════════════════════════════════════════════
  //  POST /api/sign/process
  //  Send video file → get EN + AR transcription back
  // ══════════════════════════════════════════════════════════════════════════
  Future<SignApiResponse<SignTranscription>> processSignVideo(File videoFile) async {
    try {
      final token = await _storage.getToken();
      if (token == null) {
        return SignApiResponse(success: false, message: 'Not authenticated');
      }

      final uri = Uri.parse('$_baseUrl/api/sign/process');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll(_authHeaders(token));

      final extension = videoFile.path.split('.').last.toLowerCase();

      request.files.add(
        await http.MultipartFile.fromPath(
          'videoFile',
          videoFile.path,
          contentType: http.MediaType('video', extension),
        ),
      );

      final streamedResponse =
      await request.send().timeout(const Duration(seconds: 60));

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return SignApiResponse(
          success: true,
          data: SignTranscription.fromJson(json),
        );
      } else {
        final json = jsonDecode(response.body);
        return SignApiResponse(
          success: false,
          message: json['message'] ?? 'Processing failed',
        );
      }
    } catch (e) {
      return SignApiResponse(success: false, message: 'Error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  GET /api/sign/history
  //  Load all sign transcriptions for the current user
  // ══════════════════════════════════════════════════════════════════════════
  Future<SignApiResponse<List<SignTranscription>>> getSignHistory() async {
    try {
      final token = await _storage.getToken();
      if (token == null) {
        return SignApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/sign/history'),
        headers: {
          ..._authHeaders(token),
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final items = jsonList.map((j) => SignTranscription.fromJson(j)).toList();
        return SignApiResponse(success: true, data: items);
      } else {
        final json = jsonDecode(response.body);
        return SignApiResponse(
          success: false,
          message: json['message'] ?? 'Failed to load history',
        );
      }
    } on SocketException {
      return SignApiResponse(success: false, message: 'No internet connection');
    } catch (e) {
      return SignApiResponse(success: false, message: 'Error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DELETE /api/sign/{id}
  //  Delete a specific sign record
  // ══════════════════════════════════════════════════════════════════════════
  Future<bool> deleteSign(int signId) async {
    try {
      final token = await _storage.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/sign/$signId'),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      print('Delete sign error: $e');
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _getMimeType(String extension) {
    switch (extension) {
      case 'mp4':  return 'video/mp4';
      case 'mov':  return 'video/quicktime';
      case 'avi':  return 'video/x-msvideo';
      case 'webm': return 'video/webm';
      case 'mkv':  return 'video/x-matroska';
      default:     return 'video/mp4';
    }
  }

  // http.MediaType workaround since we can't import dart:mirrors
  dynamic _parseMediaType(String mimeType) {
    final parts = mimeType.split('/');
    return http_media_type(parts[0], parts[1]);
  }
}

// Simple MediaType helper (avoids needing http_parser dependency explicitly)
class http_media_type {
  final String type;
  final String subtype;
  const http_media_type(this.type, this.subtype);
  @override
  String toString() => '$type/$subtype';
}
