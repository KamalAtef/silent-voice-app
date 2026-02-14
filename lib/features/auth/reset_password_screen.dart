import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../shared/strings.dart';
import '../../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  static const Color green = Color(0xFF44B65E);
  static const Color blue = Color(0xFF273D8B);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _pass1 = TextEditingController();
  final _pass2 = TextEditingController();
  final _authService = AuthService();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _touched1 = false;
  bool _touched2 = false;
  bool _isLoading = false;

  String? _err1;
  String? _err2;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    print('🔍 Reset Password Screen - Received arguments: $args');
    print('🔍 Arguments type: ${args.runtimeType}');

    // ✅ Now we only expect email (String), OTP was already verified
    if (args is String && args.isNotEmpty) {
      _email = args;
      print('✅ Extracted email: $_email');
    } else if (args is Map) {
      // Fallback if someone passes a Map
      _email = args['email'] as String?;
      print('✅ Extracted email from Map: $_email');
    } else {
      print('❌ Invalid arguments type!');
    }

    if (_email == null || _email!.isEmpty) {
      print('⚠️ WARNING: Email is null or empty!');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSnackBar(
            S.t(context, 'Session expired. Please try again.', 'انتهت الجلسة. حاول مرة أخرى.'),
            isError: true,
          );

          // Navigate back to forgot password
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.forgetPasswordEmail,
                    (route) => false,
              );
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _pass1.dispose();
    _pass2.dispose();
    super.dispose();
  }

  bool _isStrongEnough(String p) => p.trim().length >= 6;

  bool get _canContinue {
    final p1 = _pass1.text.trim();
    final p2 = _pass2.text.trim();
    return p1.isNotEmpty &&
        p2.isNotEmpty &&
        p1 == p2 &&
        _isStrongEnough(p1) &&
        !_isLoading &&
        _email != null &&
        _email!.isNotEmpty;
  }

  void _validate({bool showError1 = false, bool showError2 = false}) {
    final p1 = _pass1.text.trim();
    final p2 = _pass2.text.trim();

    String? e1;
    String? e2;

    if (p1.isEmpty) {
      e1 = showError1
          ? S.t(context, 'Please enter a password', 'من فضلك اكتب كلمة المرور')
          : null;
    } else if (!_isStrongEnough(p1)) {
      e1 = showError1
          ? S.t(context, 'Password must be at least 6 characters', 'كلمة المرور يجب أن تكون 6 أحرف على الأقل')
          : null;
    }

    if (p2.isEmpty) {
      e2 = showError2
          ? S.t(context, 'Please confirm your password', 'من فضلك أكد كلمة المرور')
          : null;
    } else if (p1.isNotEmpty && p1 != p2) {
      e2 = showError2
          ? S.t(context, 'Passwords do not match', 'كلمتا المرور غير متطابقتين')
          : null;
    }

    setState(() {
      _err1 = e1;
      _err2 = e2;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFE24C4B) : ResetPasswordScreen.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ✅ NEW: Use set-new-password endpoint (no OTP needed, it was already verified)
  // Endpoint: POST /api/Auth/set-new-password
  // Body: { "email": "...", "newPassword": "...", "conPassword": "..." }
  Future<void> _onContinue() async {
    setState(() {
      _touched1 = true;
      _touched2 = true;
    });

    _validate(showError1: true, showError2: true);

    if (_email == null || _email!.isEmpty) {
      _showSnackBar(
        S.t(context, 'Session expired. Please try again.', 'انتهت الجلسة. حاول مرة أخرى.'),
        isError: true,
      );
      return;
    }

    if (!_canContinue) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔵 Setting new password...');
      print('   Email: $_email');
      print('   New Password Length: ${_pass1.text.trim().length}');

      // ✅ Call the new set-new-password endpoint
      final response = await _authService.setNewPassword(
        email: _email!,
        newPassword: _pass1.text.trim(),
        confirmPassword: _pass2.text.trim(),
      );

      print('📥 Set New Password Response Success: ${response.success}');
      print('📥 Set New Password Response Message: ${response.message}');

      if (!mounted) return;

      if (response.success) {
        // Navigate to success screen
        Navigator.pushNamed(context, AppRoutes.passwordSuccess);
      } else {
        _showSnackBar(
          response.message ??
              S.t(context, 'Failed to reset password', 'فشل إعادة تعيين كلمة المرور'),
          isError: true,
        );
      }
    } catch (e) {
      print('❌ Set New Password Error: $e');
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

  void _onCancel() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
          (route) => false,
    );
  }

  InputDecoration _decoration({
    required BuildContext context,
    required String hint,
    required bool hasError,
    required VoidCallback onToggle,
    required bool obscure,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final fill = theme.brightness == Brightness.dark
        ? cs.surface
        : const Color(0xFFF6F8FB);

    final hintColor = cs.onSurface.withOpacity(0.40);
    final iconColor = cs.outline;
    final normalBorder = cs.outline.withOpacity(0.30);

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor),
      filled: true,
      fillColor: fill,
      prefixIcon: Icon(Icons.lock_outline, color: iconColor, size: 20),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          color: cs.onSurface.withOpacity(0.45),
          size: 20,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(34),
        borderSide: BorderSide(color: normalBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(34),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFE24C4B) : normalBorder,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(34),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFE24C4B) : ResetPasswordScreen.blue,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(34),
        borderSide: const BorderSide(color: Color(0xFFE24C4B), width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(34),
        borderSide: const BorderSide(color: Color(0xFFE24C4B), width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasErr1 = _err1 != null;
    final hasErr2 = _err2 != null;

    final titleColor = theme.brightness == Brightness.dark
        ? cs.onSurface
        : ResetPasswordScreen.blue;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    color: ResetPasswordScreen.green,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                S.t(context, 'Set New Password', 'تعيين كلمة مرور جديدة'),
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
                controller: _pass1,
                obscureText: _obscure1,
                style: TextStyle(fontSize: 14, color: cs.onSurface),
                onChanged: (_) {
                  if (!_touched1) _touched1 = true;
                  _validate(showError1: _touched1, showError2: _touched2);
                  setState(() {});
                },
                decoration: _decoration(
                  context: context,
                  hint: S.t(context, 'Enter your new password', 'اكتب كلمة المرور الجديدة'),
                  hasError: hasErr1,
                  obscure: _obscure1,
                  onToggle: () => setState(() => _obscure1 = !_obscure1),
                ),
              ),
              if (_err1 != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    _err1!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE24C4B),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _pass2,
                obscureText: _obscure2,
                style: TextStyle(fontSize: 14, color: cs.onSurface),
                onChanged: (_) {
                  if (!_touched2) _touched2 = true;
                  _validate(showError1: _touched1, showError2: _touched2);
                  setState(() {});
                },
                decoration: _decoration(
                  context: context,
                  hint: S.t(context, 'Confirm your password', 'أكد كلمة المرور'),
                  hasError: hasErr2,
                  obscure: _obscure2,
                  onToggle: () => setState(() => _obscure2 = !_obscure2),
                ),
              ),
              if (_err2 != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    _err2!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE24C4B),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: _canContinue ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ResetPasswordScreen.green,
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
                    S.t(context, 'Reset Password', 'إعادة تعيين كلمة المرور'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: _onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.brightness == Brightness.dark
                        ? cs.surface
                        : const Color(0xFFE2E2E2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    S.t(context, 'Cancel', 'إلغاء'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}