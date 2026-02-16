import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../services/auth_dtos.dart';
import '../../shared/strings.dart';
import '../../services/auth_service.dart';
import '../../services/secure_storage_service.dart';
import '../../shared/user_session.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  static const Color darkBlue = Color(0xFF273D8B);
  static const Color green = Color(0xFF44B65E);

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();
  final _storageService = SecureStorageService();

  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  // ✅ show/hide password
  bool _obscurePassword = true;

  bool get _isEmailValid => _validateEmail(_emailController.text.trim());
  bool get _isPasswordValid => _passwordController.text.trim().isNotEmpty;
  bool get _canLogin => _isEmailValid && _isPasswordValid && !_isLoading;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[A-Za-z]{2,}$');
    return regex.hasMatch(email);
  }

  void _validateFields({bool showErrors = false}) {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    String? emailErr;
    String? passErr;

    if (email.isEmpty) {
      emailErr = showErrors
          ? S.t(context, "Please enter your email", "من فضلك اكتب البريد الإلكتروني")
          : null;
    } else if (!_validateEmail(email)) {
      emailErr = showErrors
          ? S.t(context, "Please enter a valid email", "من فضلك اكتب بريد إلكتروني صحيح")
          : null;
    }

    if (pass.isEmpty) {
      passErr = showErrors
          ? S.t(context, "Please enter your password", "من فضلك اكتب كلمة المرور")
          : null;
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? const Color(0xFFE24C4B) : EmailLoginScreen.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _onLogin() async {
    _validateFields(showErrors: true);

    if (!_canLogin) {
      _showSnackBar(
        S.t(context, 'Please fill in the fields correctly',
            'من فضلك اكتب البيانات بشكل صحيح'),
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (response.success) {
        try {
          if (response.data != null) {
            final data = response.data;

            if (data is Map) {
              final token = data['token'] ?? data['Token'] ?? data['accessToken'];
              if (token != null && token.toString().isNotEmpty) {
                await _storageService.saveToken(token.toString());
              }

              // ✅ direct user fields
              try {
                final map = Map<String, dynamic>.from(data as Map);
                map['id'] = map['id'] ?? map['userID'] ?? map['userId'];

                final directUser = UserData.fromJson(map);
                await _storageService.saveUserData(directUser);
                UserSession.instance.setFullName(directUser.fullName);
              } catch (_) {}

              final refreshToken = data['refreshToken'] ?? data['RefreshToken'];
              if (refreshToken != null && refreshToken.toString().isNotEmpty) {
                await _storageService.saveRefreshToken(refreshToken.toString());
              }

              final userData = data['user'] ?? data['User'];
              if (userData != null && userData is Map) {
                try {
                  final user =
                  UserData.fromJson(userData as Map<String, dynamic>);
                  await _storageService.saveUserData(user);
                  UserSession.instance.setFullName(user.fullName);
                } catch (_) {}
              }
            } else if (data is String && data.isNotEmpty) {
              await _storageService.saveToken(data);
            }
          }

          // ✅ Save email + put in session
          final email = _emailController.text.trim();
          await _storageService.saveEmail(email);
          UserSession.instance.setEmail(email);

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
                  (route) => false,
            );
          }
        } catch (_) {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
                  (route) => false,
            );
          }
        }
      } else {
        _showSnackBar(
          response.message ?? S.t(context, 'Login failed', 'فشل تسجيل الدخول'),
          isError: true,
        );
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(
          S.t(context, 'An error occurred. Please try again.',
              'حدث خطأ. حاول مرة أخرى.'),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final cardColor =
    theme.brightness == Brightness.dark ? cs.surface : Colors.white;
    final titleColor = theme.brightness == Brightness.dark
        ? cs.onSurface
        : EmailLoginScreen.darkBlue;
    final labelColor = EmailLoginScreen.green;
    final hintColor = cs.onSurface.withOpacity(0.45);
    final inputTextColor = cs.onSurface;

    final overlayColor = theme.brightness == Brightness.dark
        ? Colors.black.withOpacity(0.35)
        : Colors.black.withOpacity(0.15);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true, // ✅ مهم لحركة الكيبورد
      body: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(color: overlayColor),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    top: 0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: IntrinsicHeight(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: AlignmentDirectional.topEnd,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Icon(Icons.close,
                                      size: 22, color: cs.onSurface),
                                ),
                              ),
                              const SizedBox(height: 10),

                              Text(
                                S.t(context, 'Login', 'تسجيل الدخول'),
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 24),

                              Text(
                                S.t(context, 'Email', 'البريد الإلكتروني'),
                                style: TextStyle(
                                  color: labelColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),

                              _inputField(
                                controller: _emailController,
                                hint: S.t(context, 'Enter Your Email',
                                    'اكتب بريدك الإلكتروني'),
                                obscure: false,
                                errorText: _emailError,
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (_) =>
                                    _validateFields(showErrors: false),
                                textColor: inputTextColor,
                                hintColor: hintColor,
                                borderColor: cs.outline.withOpacity(0.35),
                                focusedColor: EmailLoginScreen.darkBlue,
                              ),

                              const SizedBox(height: 16),

                              Text(
                                S.t(context, 'Password', 'كلمة المرور'),
                                style: TextStyle(
                                  color: labelColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),

                              _inputField(
                                controller: _passwordController,
                                hint: S.t(context, 'Enter Your Password',
                                    'اكتب كلمة المرور'),
                                obscure: _obscurePassword,
                                errorText: _passwordError,
                                keyboardType: TextInputType.text,
                                onChanged: (_) =>
                                    _validateFields(showErrors: false),
                                textColor: inputTextColor,
                                hintColor: hintColor,
                                borderColor: cs.outline.withOpacity(0.35),
                                focusedColor: EmailLoginScreen.darkBlue,
                                suffix: IconButton(
                                  onPressed: () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 20,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.forgetPasswordEmail,
                                    arguments: _emailController.text.trim(),
                                  );
                                },
                                child: Text(
                                  S.t(context, 'Forget Password?',
                                      'نسيت كلمة المرور؟'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: EmailLoginScreen.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _canLogin ? _onLogin : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _canLogin
                                        ? EmailLoginScreen.green
                                        : Colors.grey.shade400,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                      : Text(
                                    S.t(context, 'Login', 'تسجيل الدخول'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              Center(
                                child: Text(
                                  S.t(context, '© 2026 - All Rights reserved.',
                                      '© 2026 - جميع الحقوق محفوظة.'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withOpacity(0.45),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required ValueChanged<String> onChanged,
    required TextInputType keyboardType,
    String? errorText,
    required Color textColor,
    required Color hintColor,
    required Color borderColor,
    required Color focusedColor,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor),
        errorText: errorText,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: focusedColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE24C4B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE24C4B)),
        ),
      ),
    );
  }
}
