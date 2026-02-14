/// API Constants - Silent Voice Backend
class ApiConstants {
  // ✅ Base URL - Silent Voice API
  static const String baseUrl = 'http://silentvoice.runasp.net';

  // Auth Endpoints
  static const String register = '/api/Auth/register';
  static const String confirmEmail = '/api/Auth/confirm-email';
  static const String login = '/api/Auth/login';

  // ✅ NEW: Reset Password Flow (3 separate endpoints)
  static const String forgotPassword = '/api/Auth/forgot-password';
  static const String verifyResetOtp = '/api/Auth/verify-reset-otp'; // NEW
  static const String setNewPassword = '/api/Auth/set-new-password'; // NEW
  static const String resendPasswordResetOtp = '/api/Auth/resend-password-reset-otp';

  static const String resendEmailOtp = '/api/Auth/resend-email-otp';

  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Full endpoint URLs
  static String get registerUrl => baseUrl + register;
  static String get confirmEmailUrl => baseUrl + confirmEmail;
  static String get loginUrl => baseUrl + login;
  static String get forgotPasswordUrl => baseUrl + forgotPassword;
  static String get verifyResetOtpUrl => baseUrl + verifyResetOtp; // NEW
  static String get setNewPasswordUrl => baseUrl + setNewPassword; // NEW
  static String get resendEmailOtpUrl => baseUrl + resendEmailOtp;
  static String get resendPasswordResetOtpUrl => baseUrl + resendPasswordResetOtp;
}