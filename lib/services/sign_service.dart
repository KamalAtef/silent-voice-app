// ── lib/services/sign_service.dart ─────────────────────────────────────────
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:silentvoice/services/secure_storage_service.dart';
import 'sign_models.dart';

class SignService {
  // ── Your .NET backend ──────────────────────────────────────────────────────
  static const String _baseUrl = 'http://silentvoice.runasp.net';

  // ── Your deployed FastAPI on Render ───────────────────────────────────────
  // After deploying to Render, paste your URL here:
  static const String _fastApiUrl = 'https://fastapi-example-i0u4.onrender.com';

  final _storage = SecureStorageService();

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
  };

  // ══════════════════════════════════════════════════════════════════════════
  //  NEW — Send landmarks to FastAPI, get back a sign label
  //  Called every 300ms from the live camera loop
  // ══════════════════════════════════════════════════════════════════════════
  Future<SignPrediction?> predictLandmarks(
      List<List<double>> landmarks) async {
    try {
      final response = await http
          .post(
        Uri.parse('$_fastApiUrl/predict/landmarks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'landmarks': landmarks}),
      )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final signs = json['signs'] as List;
        return SignPrediction(
          sign: json['sentence'] as String,
          confidence: signs.isNotEmpty
              ? (signs[0]['confidence'] as num).toDouble()
              : 0.0,
        );
      }
      // 422 = confidence too low — not an error, just no sign yet
      return null;
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  NEW — Save completed sentence to .NET backend
  //  Called once when user taps "Stop Camera"
  // ══════════════════════════════════════════════════════════════════════════
  Future<SignApiResponse<SignTranscription>> saveSignSentence(
      String sentenceEn) async {
    try {
      final token = await _storage.getToken();
      if (token == null) {
        return SignApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http
          .post(
        Uri.parse('$_baseUrl/api/Sign/save'),
        headers: {
          ..._authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'SentenceEn': sentenceEn}),
      )
          .timeout(const Duration(seconds: 30));

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
          message: json['message'] ?? 'Save failed',
        );
      }
    } on SocketException {
      return SignApiResponse(
          success: false, message: 'No internet connection');
    } catch (e) {
      return SignApiResponse(success: false, message: 'Error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  EXISTING — kept exactly as-is
  // ══════════════════════════════════════════════════════════════════════════

  Future<SignApiResponse<SignTranscription>> processSignVideo(
      File videoFile) async {
    try {
      final token = await _storage.getToken();
      if (token == null) {
        return SignApiResponse(success: false, message: 'Not authenticated');
      }
      final uri = Uri.parse('$_baseUrl/api/sign/process');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_authHeaders(token));
      final extension = videoFile.path.split('.').last.toLowerCase();
      request.files.add(await http.MultipartFile.fromPath(
        'videoFile',
        videoFile.path,
        contentType: http.MediaType('video', extension),
      ));
      final streamedResponse =
      await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return SignApiResponse(
            success: true, data: SignTranscription.fromJson(json));
      } else {
        final json = jsonDecode(response.body);
        return SignApiResponse(
            success: false,
            message: json['message'] ?? 'Processing failed');
      }
    } catch (e) {
      return SignApiResponse(success: false, message: 'Error: $e');
    }
  }

  Future<SignApiResponse<List<SignTranscription>>> getSignHistory() async {
    try {
      final token = await _storage.getToken();
      if (token == null) {
        return SignApiResponse(success: false, message: 'Not authenticated');
      }
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sign/history'),
        headers: {..._authHeaders(token), 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final items =
        jsonList.map((j) => SignTranscription.fromJson(j)).toList();
        return SignApiResponse(success: true, data: items);
      } else {
        final json = jsonDecode(response.body);
        return SignApiResponse(
            success: false,
            message: json['message'] ?? 'Failed to load history');
      }
    } on SocketException {
      return SignApiResponse(
          success: false, message: 'No internet connection');
    } catch (e) {
      return SignApiResponse(success: false, message: 'Error: $e');
    }
  }

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
      return false;
    }
  }
}