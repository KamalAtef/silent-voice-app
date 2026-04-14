import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../shared/strings.dart';
import '../../services/auth_service.dart';

class VerifyEmailCodeScreen extends StatefulWidget {
  const VerifyEmailCodeScreen({super.key});

  static const Color green = Color(0xFF44B65E);
  static const Color blue = Color(0xFF273D8B);

  @override
  State<VerifyEmailCodeScreen> createState() => _VerifyEmailCodeScreenState();
}

class _VerifyEmailCodeScreenState extends State<VerifyEmailCodeScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _authService = AuthService();

  String? _email;
  String _flow = 'register'; // register | forget
  bool _isLoading = false;
  bool _isResending = false;

  bool get _canContinue =>
      _controllers.every((c) => RegExp(r'^\d$').hasMatch(c.text.trim())) &&
          !_isLoading;

  String get _code => _controllers.map((c) => c.text.trim()).join();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      final e = args['email'];
      final f = args['flow'];

      if (e is String && e.trim().isNotEmpty) _email = e.trim();
      if (f is String && f.trim().isNotEmpty) _flow = f.trim();
    } else if (args is String && args.trim().isNotEmpty) {
      _email = args.trim();
      _flow = 'register';
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
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
        backgroundColor:
        isError ? const Color(0xFFE24C4B) : VerifyEmailCodeScreen.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ✅ NEW: API Confirm Email Integration
  Future<void> _onContinue() async {
    if (!_canContinue || _email == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await _authService.confirmEmail(
        email: _email!,
        otp: _code,
      );

      if (!mounted) return;

      if (response.success) {
        if (_flow == 'forget') {
          // Navigate to Reset Password
          Navigator.pushNamed(
            context,
            AppRoutes.resetPassword,
            arguments: {"email": _email, "code": _code},
          );
        } else {
          // Navigate to Login after successful registration
          _showSnackBar(
            S.t(context, 'Email verified successfully!',
                'تم تأكيد البريد الإلكتروني بنجاح!'),
          );

          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                    (route) => false,
              );
            }
          });
        }
      } else {
        _showSnackBar(
          response.message ?? S.t(context, 'Invalid code', 'الكود غير صحيح'),
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ NEW: Resend OTP
  Future<void> _onResendCode() async {
    if (_email == null || _isResending) return;

    setState(() => _isResending = true);

    try {
      final response = _flow == 'forget'
          ? await _authService.resendPasswordResetOtp(email: _email!)
          : await _authService.resendEmailOtp(email: _email!);

      if (!mounted) return;

      if (response.success) {
        _showSnackBar(
          S.t(context, 'Code sent successfully!', 'تم إرسال الكود بنجاح!'),
        );
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
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bg = theme.scaffoldBackgroundColor;

    final titleColor =
    theme.brightness == Brightness.dark ? cs.onSurface : VerifyEmailCodeScreen.blue;

    final subtitleColor = cs.onSurface.withOpacity(0.45);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom; // ✅ keyboard height

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true, // ✅ prevent overflow with keyboard
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 16), // ✅ push up above keyboard
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                          Icons.mail_outline,
                          color: VerifyEmailCodeScreen.green,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      S.t(context, 'Verify Your Email', 'تأكيد البريد الإلكتروني'),
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
                      S.t(context, 'Enter the 6-digit verification code',
                          'أدخل رمز التحقق المكون من 6 أرقام'),
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) => _codeBox(context, i)),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 62,
                      child: ElevatedButton(
                        onPressed: _canContinue ? _onContinue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VerifyEmailCodeScreen.green,
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
                          S.t(context, 'Continue', 'متابعة'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
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
                          onTap: _isResending ? null : _onResendCode,
                          child: _isResending
                              ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _codeBox(BuildContext context, int index) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final fill =
    theme.brightness == Brightness.dark ? cs.surface : const Color(0xFFF6F8FB);
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
            borderSide: const BorderSide(color: VerifyEmailCodeScreen.blue),
          ),
        ),
      ),
    );
  }
}
