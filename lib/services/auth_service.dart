import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'auth_dtos.dart';

/// Auth Service - Handles all authentication API calls
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // ==================== REGISTER ====================
  Future<ApiResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final dto = RegisterDto(
        fName: firstName,
        lName: lastName,
        email: email,
        password: password,
        conPassword: confirmPassword,
      );

      print('🔵 Registering user: $email');

      final response = await http.post(
        Uri.parse(ApiConstants.registerUrl),
        headers: ApiConstants.headers,
        body: jsonEncode(dto.toJson()),
      );

      print('📥 Register Response: ${response.statusCode}');
      print('📥 Register Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ Register Error: $e');
      return _handleError(e);
    }
  }

  // ==================== CONFIRM EMAIL ====================
  Future<ApiResponse> confirmEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final dto = ConfirmEmailDto(
        email: email,
        otp: otp,
      );

      print('🔵 Confirming email: $email with OTP: $otp');

      final response = await http.post(
        Uri.parse(ApiConstants.confirmEmailUrl),
        headers: ApiConstants.headers,
        body: jsonEncode(dto.toJson()),
      );

      print('📥 Confirm Email Response: ${response.statusCode}');
      print('📥 Confirm Email Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ Confirm Email Error: $e');
      return _handleError(e);
    }
  }

  // ==================== LOGIN ====================
  Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final dto = LoginDto(
        email: email,
        password: password,
      );

      print('🔵 Logging in user: $email');
      print('🔵 Login URL: ${ApiConstants.loginUrl}');

      final response = await http.post(
        Uri.parse(ApiConstants.loginUrl),
        headers: ApiConstants.headers,
        body: jsonEncode(dto.toJson()),
      );

      print('📥 Login Response Status: ${response.statusCode}');
      print('📥 Login Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ Login Error: $e');
      return _handleError(e);
    }
  }

  // ==================== FORGOT PASSWORD ====================
  /// Request password reset - sends OTP to email
  Future<ApiResponse> forgotPassword({
    required String email,
  }) async {
    try {
      final dto = ForgotPasswordDto(email: email);

      print('🔵 Forgot password for: $email');

      final response = await http.post(
        Uri.parse(ApiConstants.forgotPasswordUrl),
        headers: ApiConstants.headers,
        body: jsonEncode(dto.toJson()),
      );

      print('📥 Forgot Password Response: ${response.statusCode}');
      print('📥 Forgot Password Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ Forgot Password Error: $e');
      return _handleError(e);
    }
  }

  // ==================== VERIFY RESET OTP (NEW) ====================
  /// Verify OTP for password reset
  /// Endpoint: POST /api/Auth/verify-reset-otp
  /// Body: { "email": "...", "otp": "..." }
  Future<ApiResponse> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final dto = VerifyResetOtpDto(
        email: email,
        otp: otp,
      );

      print('🔵 Verifying reset OTP for: $email');
      print('🔵 OTP: $otp');

      final response = await http.post(
        Uri.parse(ApiConstants.verifyResetOtpUrl),
        headers: ApiConstants.headers,
        body: jsonEncode(dto.toJson()),
      );

      print('📥 Verify Reset OTP Response: ${response.statusCode}');
      print('📥 Verify Reset OTP Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ Verify Reset OTP Error: $e');
      return _handleError(e);
    }
  }

  // ==================== SET NEW PASSWORD (NEW) ====================
  /// Set new password after OTP verification
  /// Endpoint: POST /api/Auth/set-new-password
  /// Body: { "email": "...", "newPassword": "...", "conPassword": "..." }
  Future<ApiResponse> setNewPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final dto = SetNewPasswordDto(
        email: email,
        newPassword: newPassword,
        conPassword: confirmPassword,
      );

      print('🔵 Setting new password for: $email');

      final response = await http.post(
        Uri.parse(ApiConstants.setNewPasswordUrl),
        headers: ApiConstants.headers,
        body: jsonEncode(dto.toJson()),
      );

      print('📥 Set New Password Response: ${response.statusCode}');
      print('📥 Set New Password Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ Set New Password Error: $e');
      return _handleError(e);
    }
  }

  // ==================== RESEND EMAIL OTP ====================
  Future<ApiResponse> resendEmailOtp({
    required String email,
  }) async {
    try {
      final dto = ResendEmailDto(email: email);

      print('🔵 Resending email OTP for: $email');

      final response = await http.post(
        Uri.parse(ApiConstants.resendEmailOtpUrl),
        headers: ApiConstants.headers,
        body: jsonEncode(dto.toJson()),
      );

      print('📥 Resend Email OTP Response: ${response.statusCode}');
      print('📥 Resend Email OTP Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ Resend Email OTP Error: $e');
      return _handleError(e);
    }
  }

  // ==================== RESEND PASSWORD RESET OTP ====================
  Future<ApiResponse> resendPasswordResetOtp({
    required String email,
  }) async {
    try {
      final dto = ResendEmailDto(email: email);

      print('🔵 Resending password reset OTP for: $email');

      final response = await http.post(
        Uri.parse(ApiConstants.resendPasswordResetOtpUrl),
        headers: ApiConstants.headers,
        body: jsonEncode(dto.toJson()),
      );

      print('📥 Resend Password Reset OTP Response: ${response.statusCode}');
      print('📥 Resend Password Reset OTP Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ Resend Password Reset OTP Error: $e');
      return _handleError(e);
    }
  }

  // ==================== RESPONSE HANDLERS ====================

  ApiResponse _handleResponse(http.Response response) {
    print('🔍 Handling response - Status: ${response.statusCode}');

    try {
      final body = jsonDecode(response.body);
      print('✅ Successfully parsed JSON response');
      print('📦 Parsed body: $body');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: true,
          message: _extractMessage(body) ?? 'Success',
          data: _extractData(body),
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractMessage(body) ?? 'An error occurred',
          data: null,
        );
      }
    } catch (e) {
      print('⚠️ JSON parsing error: $e');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: true,
          message: response.body.isNotEmpty ? response.body : 'Success',
          data: response.body.isNotEmpty ? response.body : null,
        );
      }

      return ApiResponse(
        success: false,
        message: 'Failed to parse response: ${response.body}',
        data: null,
      );
    }
  }

  String? _extractMessage(dynamic body) {
    if (body is Map) {
      return body['message'] ??
          body['Message'] ??
          body['msg'] ??
          body['error'] ??
          body['Error'];
    }
    return null;
  }

  dynamic _extractData(dynamic body) {
    if (body is Map) {
      if (body.containsKey('data')) return body['data'];
      if (body.containsKey('Data')) return body['Data'];
      if (body.containsKey('result')) return body['result'];
      if (body.containsKey('Result')) return body['Result'];
      return body;
    }
    return body;
  }

  ApiResponse _handleError(dynamic error) {
    String message = 'An unexpected error occurred';

    if (error is http.ClientException) {
      message = 'Network error. Please check your internet connection.';
    } else if (error.toString().contains('SocketException')) {
      message = 'Cannot connect to server. Please check your internet.';
    } else if (error.toString().contains('TimeoutException')) {
      message = 'Request timeout. Please try again.';
    } else if (error.toString().contains('FormatException')) {
      message = 'Invalid response format from server.';
    }

    print('❌ Error handled: $message');

    return ApiResponse(
      success: false,
      message: message,
      data: null,
    );
  }
}