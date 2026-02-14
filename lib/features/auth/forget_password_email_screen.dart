import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../shared/strings.dart';
import '../../services/auth_service.dart';

class ForgetPasswordEmailScreen extends StatefulWidget {
  const ForgetPasswordEmailScreen({super.key});

  static const Color green = Color(0xFF44B65E);
  static const Color blue = Color(0xFF273D8B);

  @override
  State<ForgetPasswordEmailScreen> createState() =>
      _ForgetPasswordEmailScreenState();
}

class _ForgetPasswordEmailScreenState extends State<ForgetPasswordEmailScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();

  String? _emailError;
  bool _touched = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isEmailValid(String email) {
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[A-Za-z]{2,}$');
    return regex.hasMatch(email);
  }

  bool get _canSubmit => _isEmailValid(_emailController.text.trim()) && !_isLoading;

  void _validate({bool showError = false}) {
    final email = _emailController.text.trim();

    String? err;
    if (email.isEmpty) {
      err = showError
          ? S.t(context, "Please enter your email", "من فضلك اكتب البريد الإلكتروني")
          : null;
    } else if (!_isEmailValid(email)) {
      err = showError
          ? S.t(context, "Please enter a valid email", "من فضلك اكتب بريد إلكتروني صحيح")
          : null;
    }

    setState(() => _emailError = err);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFE24C4B) : ForgetPasswordEmailScreen.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ✅ API Forgot Password Integration
  // Endpoint: POST /api/Auth/forgot-password
  Future<void> _onSubmit() async {
    setState(() => _touched = true);
    _validate(showError: true);

    if (!_canSubmit) return;

    setState(() => _isLoading = true);

    try {
      final response = await _authService.forgotPassword(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      if (response.success) {
        // ✅ Navigate to Reset Password OTP verification screen
        Navigator.pushNamed(
          context,
          AppRoutes.verifyResetPasswordOtp, // New route for password reset OTP
          arguments: _emailController.text.trim(),
        );
      } else {
        _showSnackBar(
          response.message ?? S.t(context, 'Failed to send reset code', 'فشل إرسال كود التحقق'),
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          S.t(context, 'An error occurred. Please try again.', 'حدث خطأ. حاول مرة أخرى.'),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasError = _emailError != null;

    final backgroundColor = theme.scaffoldBackgroundColor;

    final titleColor = theme.brightness == Brightness.dark
        ? cs.onSurface
        : ForgetPasswordEmailScreen.blue;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.outline.withOpacity(0.25),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.fingerprint,
                    color: ForgetPasswordEmailScreen.green,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                S.t(
                  context,
                  'Forget your Password\nand Continue',
                  'نسيت كلمة المرور\nوتابع معنا',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  height: 1.15,
                  color: titleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface,
                ),
                onChanged: (_) {
                  if (!_touched) _touched = true;

                  if (_touched) {
                    _validate(showError: true);
                  } else {
                    _validate(showError: false);
                  }

                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText:
                  S.t(context, 'Enter Your Email', 'اكتب بريدك الإلكتروني'),
                  hintStyle: TextStyle(
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark
                      ? cs.surface
                      : const Color(0xFFF6F8FB),
                  prefixIcon: Icon(
                    Icons.mail_outline,
                    color: cs.outline,
                    size: 20,
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  errorText: _emailError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(34),
                    borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(34),
                    borderSide: BorderSide(
                      color: hasError
                          ? const Color(0xFFE24C4B)
                          : cs.outline.withOpacity(0.3),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(34),
                    borderSide: BorderSide(
                      color: hasError
                          ? const Color(0xFFE24C4B)
                          : ForgetPasswordEmailScreen.blue,
                      width: 1.4,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(34),
                    borderSide: const BorderSide(
                        color: Color(0xFFE24C4B), width: 1.4),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(34),
                    borderSide: const BorderSide(
                        color: Color(0xFFE24C4B), width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _onSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ForgetPasswordEmailScreen.green,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
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
                    S.t(context, 'Submit Now', 'إرسال'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new,
                      size: 14,
                      color: titleColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      S.t(context, 'Back to login', 'العودة لتسجيل الدخول'),
                      style: TextStyle(
                        fontSize: 13,
                        color: titleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}