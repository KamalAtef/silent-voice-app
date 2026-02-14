/// Data Transfer Objects (DTOs) for API requests and responses

// ==================== REGISTER ====================
class RegisterDto {
  final String fName;
  final String lName;
  final String email;
  final String password;
  final String conPassword;

  RegisterDto({
    required this.fName,
    required this.lName,
    required this.email,
    required this.password,
    required this.conPassword,
  });

  Map<String, dynamic> toJson() => {
    'fName': fName,
    'lName': lName,
    'email': email,
    'password': password,
    'conPassword': conPassword,
  };
}

// ==================== CONFIRM EMAIL ====================
class ConfirmEmailDto {
  final String email;
  final String otp;

  ConfirmEmailDto({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'otp': otp,
  };
}

// ==================== LOGIN ====================
class LoginDto {
  final String email;
  final String password;

  LoginDto({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

// ==================== FORGOT PASSWORD ====================
class ForgotPasswordDto {
  final String email;

  ForgotPasswordDto({
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
  };
}

// ==================== VERIFY RESET OTP (NEW) ====================
class VerifyResetOtpDto {
  final String email;
  final String otp;

  VerifyResetOtpDto({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'otp': otp,
  };
}

// ==================== SET NEW PASSWORD (NEW) ====================
class SetNewPasswordDto {
  final String email;
  final String newPassword;
  final String conPassword;

  SetNewPasswordDto({
    required this.email,
    required this.newPassword,
    required this.conPassword,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'newPassword': newPassword,
    'conPassword': conPassword,
  };
}

// ==================== RESEND EMAIL ====================
class ResendEmailDto {
  final String email;

  ResendEmailDto({
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
  };
}

// ==================== API RESPONSE ====================
class ApiResponse {
  final bool success;
  final String? message;
  final dynamic data;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
    );
  }
}

// ==================== LOGIN RESPONSE ====================
class LoginResponse {
  final String? token;
  final String? refreshToken;
  final UserData? user;

  LoginResponse({
    this.token,
    this.refreshToken,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      refreshToken: json['refreshToken'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
    );
  }
}

// ==================== USER DATA ====================
class UserData {
  final String? id;
  final String? email;
  final String? firstName;
  final String? lastName;

  UserData({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'] ?? json['fName'],
      lastName: json['lastName'] ?? json['lName'],
    );
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}