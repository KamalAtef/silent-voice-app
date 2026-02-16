import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../shared/strings.dart';
import '../../services/auth_service.dart';

/// Screen for verifying OTP when resetting password
class VerifyResetPasswordOtpScreen extends StatefulWidget {
  const VerifyResetPasswordOtpScreen({super.key});

  static const Color green = Color(0xFF44B65E);
  static const Color blue = Color(0xFF273D8B);

  @override
  State<VerifyResetPasswordOtpScreen> createState() =>
      _VerifyResetPasswordOtpScreenState();
}

class _VerifyResetPasswordOtpScreenState
    extends State<VerifyResetPasswordOtpScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _authService = AuthService();

  String? _email;
  bool _isLoading = false;
  bool _isResending = false;

  // ✅ Timer (10 minutes)
  static const int _otpSeconds = 10 * 60;
  int _secondsLeft = _otpSeconds;
  Timer? _timer;

  bool get _canContinue =>
      _controllers.every((c) => RegExp(r'^\d$').hasMatch(c.text.trim())) &&
          !_isLoading;

  bool get _canResend => _secondsLeft == 0 && !_isResending;

  String get _code => _controllers.map((c) => c.text.trim()).join();

  @override
  void initState() {
    super.initState();
    _startTimer(reset: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      final e = args['email'];
      if (e is String && e.trim().isNotEmpty) _email = e.trim();
    } else if (args is String && args.trim().isNotEmpty) {
      _email = args.trim();
    }

    print('🔍 VerifyResetPasswordOtp - Email: $_email');
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer({bool reset = false}) {
    _timer?.cancel();
    if (reset) _secondsLeft = _otpSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 0) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  String _formatMMSS(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      final last = value.substring(value.length - 1);
      _controllers[index].text = last;
      _controllers[index].selection =
          TextSelection.collapsed(offset: _controllers[index].text.length);
    }

    final v = _controllers[index].text.trim();

    if (v.isNotEmpty) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
      }
    } else {
      if (index > 0) {
        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
      }
    }

    setState(() {});
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFE24C4B)
            : VerifyResetPasswordOtpScreen.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ✅ Verify OTP using the new API endpoint
  // Endpoint: POST /api/Auth/verify-reset-otp
  Future<void> _onContinue() async {
    if (!_canContinue || _email == null) return;

    setState(() => _isLoading = true);

    try {
      print('🔵 Verifying OTP: $_code for email: $_email');

      final response = await _authService.verifyResetOtp(
        email: _email!,
        otp: _code,
      );

      if (!mounted) return;

      if (response.success) {
        _showSnackBar(
          S.t(context, 'OTP verified successfully!', 'تم التحقق من الكود بنجاح!'),
        );

        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        Navigator.pushNamed(
          context,
          AppRoutes.resetPassword,
          arguments: _email,
        );
      } else {
        _showSnackBar(
          response.message ??
              S.t(context, 'Invalid or expired code', 'الكود غير صحيح أو منتهي'),
          isError: true,
        );
      }
    } catch (e) {
      print('❌ Verify OTP Error: $e');
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

  // ✅ Resend Password Reset OTP
  // Endpoint: POST /api/Auth/resend-password-reset-otp
  Future<void> _onResendCode() async {
    if (_email == null || _isResending || !_canResend) return;

    setState(() => _isResending = true);

    try {
      final response =
      await _authService.resendPasswordResetOtp(email: _email!);

      if (!mounted) return;

      if (response.success) {
        _showSnackBar(
          S.t(context, 'Code sent successfully!', 'تم إرسال الكود بنجاح!'),
        );

        for (var controller in _controllers) {
          controller.clear();
        }
        FocusScope.of(context).requestFocus(_focusNodes[0]);

        // ✅ restart 10 min timer after resend
        _startTimer(reset: true);
      } else {
        _showSnackBar(
          response.message ??
              S.t(context, 'Failed to resend code', 'فشل إعادة إرسال الكود'),
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          S.t(context, 'An error occurred. Please try again.',
              'حدث خطأ. حاول مرة أخرى.'),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bg = theme.scaffoldBackgroundColor;

    final titleColor = theme.brightness == Brightness.dark
        ? cs.onSurface
        : VerifyResetPasswordOtpScreen.blue;

    final subtitleColor = cs.onSurface.withOpacity(0.45);

    return Scaffold(
      backgroundColor: bg,
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
                  border: Border.all(color: cs.outline.withOpacity(0.25)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_reset,
                    color: VerifyResetPasswordOtpScreen.green,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                S.t(context, 'Verify Reset Code', 'تأكيد كود إعادة التعيين'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  height: 1.15,
                  color: titleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.t(
                  context,
                  'Enter the 6-digit code sent to your email',
                  'أدخل الكود المكون من 6 أرقام المرسل لبريدك',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: subtitleColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 22),

              // ✅ keep OTP row LTR even in Arabic
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) => _codeBox(context, i)),
                ),
              ),

              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: _canContinue ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VerifyResetPasswordOtpScreen.green,
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
                    S.t(context, 'Verify Code', 'تأكيد الكود'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ✅ keep resend area LTR (timer like 10:00)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      S.t(context, "Didn't you receive any code? ",
                          "لم يصلك الرمز؟ "),
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                    InkWell(
                      onTap: _canResend ? _onResendCode : null,
                      child: _isResending
                          ? const SizedBox(
                        width: 14,
                        height: 14,
                        child:
                        CircularProgressIndicator(strokeWidth: 2),
                      )
                          : (_secondsLeft > 0)
                          ? Text(
                        _formatMMSS(_secondsLeft),
                        style: TextStyle(
                          fontSize: 12,
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                          : Text(
                        S.t(context, "Resend Code", "إعادة إرسال"),
                        style: TextStyle(
                          fontSize: 12,
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _codeBox(BuildContext context, int index) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final fill = theme.brightness == Brightness.dark
        ? cs.surface
        : const Color(0xFFF6F8FB);
    final border = cs.outline.withOpacity(0.30);

    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        autofocus: index == 0,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr, // ✅ keep digits LTR
        maxLength: 1,
        onChanged: (v) => _onChanged(index, v),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: fill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: VerifyResetPasswordOtpScreen.blue),
          ),
        ),
      ),
    );
  }
}
