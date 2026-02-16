import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'voice_models.dart';
import '../services/secure_storage_service.dart';

/// Voice Service - Handles all Voice API calls
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  static const String baseUrl = 'http://silentvoice.runasp.net';
  final _storage = SecureStorageService();
  final _dio = Dio();

  // ==================== TRANSCRIBE AUDIO ====================
  /// Upload audio file and get transcription
  /// Endpoint: POST /api/Voice/transcribe
  /// Returns: VoiceApiResponse with transcription
  Future<VoiceApiResponse> transcribeAudio({
    required File audioFile,
    required String language, // 'en' or 'ar'
  }) async {
    try {
      // Get token
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) {
        return VoiceApiResponse(
          success: false,
          message: 'Authentication token not found. Please login again.',
        );
      }

      print('🔵 Transcribing audio...');
      print('   File: ${audioFile.path}');
      print('   Language: $language');
      print('   File size: ${await audioFile.length()} bytes');

      // Prepare multipart request
      final formData = FormData.fromMap({
        'audioFile': await MultipartFile.fromFile(
          audioFile.path,
          filename: 'audio.wav',
        ),
        'language': language,
      });

      // Make request
      final response = await _dio.post(
        '$baseUrl/api/Voice/transcribe',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      print('📥 Transcribe Response: ${response.statusCode}');
      print('📥 Response Data: ${response.data}');

      if (response.statusCode == 200) {
        return VoiceApiResponse.fromJson(response.data);
      } else if (response.statusCode == 401) {
        return VoiceApiResponse(
          success: false,
          message: 'Session expired. Please login again.',
        );
      } else {
        return VoiceApiResponse(
          success: false,
          message: response.data['message'] ?? 'Failed to transcribe audio',
        );
      }
    } on DioException catch (e) {
      print('❌ Transcribe Error: ${e.message}');
      return _handleDioError(e);
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return VoiceApiResponse(
        success: false,
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  // ==================== GET HISTORY ====================
  /// Get all voice transcription history
  /// Endpoint: GET /api/Voice/history
  /// Returns: VoiceHistoryResponse with list of transcriptions
  Future<VoiceHistoryResponse> getHistory() async {
    try {
      // Get token
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) {
        return VoiceHistoryResponse(
          success: false,
          message: 'Authentication token not found. Please login again.',
          data: [],
        );
      }

      print('🔵 Fetching voice history...');

      // Make request using http package (simpler for GET)
      final response = await http.get(
        Uri.parse('$baseUrl/api/Voice/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 History Response: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return VoiceHistoryResponse.fromJson(json);
      } else if (response.statusCode == 401) {
        return VoiceHistoryResponse(
          success: false,
          message: 'Session expired. Please login again.',
          data: [],
        );
      } else {
        return VoiceHistoryResponse(
          success: false,
          message: 'Failed to fetch history',
          data: [],
        );
      }
    } catch (e) {
      print('❌ History Error: $e');
      return VoiceHistoryResponse(
        success: false,
        message: 'An error occurred: $e',
        data: [],
      );
    }
  }

  // ==================== DELETE TRANSCRIPTION ====================
  /// Delete a voice transcription (if endpoint exists)
  /// Endpoint: DELETE /api/Voice/{id}
  Future<bool> deleteTranscription(int voiceId) async {
    try {
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) return false;

      print('🔵 Deleting transcription: $voiceId');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/Voice/$voiceId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Delete Response: ${response.statusCode}');

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('❌ Delete Error: $e');
      return false;
    }
  }

  // ==================== ERROR HANDLING ====================
  VoiceApiResponse _handleDioError(DioException e) {
    String message = 'An error occurred';

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout. Please try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection. Please check your network.';
    } else if (e.response != null) {
      if (e.response!.statusCode == 401) {
        message = 'Session expired. Please login again.';
      } else if (e.response!.data != null) {
        message = e.response!.data['message'] ?? 'Request failed';
      }
    }

    return VoiceApiResponse(success: false, message: message);
  }
}