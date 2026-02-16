import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../shared/app_colors.dart';
import '../../shared/strings.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();

  bool _acceptedTerms = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  bool _isEmailValid(String e) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(e.trim());

  bool _isStrongEnough(String p) => p.trim().length >= 6;

  bool get _canSignUp {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    return _acceptedTerms &&
        first.isNotEmpty &&
        last.isNotEmpty &&
        email.isNotEmpty &&
        _isEmailValid(email) &&
        pass.isNotEmpty &&
        confirm.isNotEmpty &&
        _isStrongEnough(pass) &&
        pass == confirm &&
        !_isLoading;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFE24C4B) : AppColors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ✅ NEW: API Register Integration
  Future<void> _onSignUp() async {
    if (!_canSignUp) return;

    setState(() => _isLoading = true);

    try {
      final response = await _authService.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        confirmPassword: _confirmPasswordController.text.trim(),
      );

      if (!mounted) return;

      if (response.success) {
        // ✅ Navigate to Email OTP verification (not reset password OTP)
        Navigator.pushNamed(
          context,
          AppRoutes.verifyEmailOtp, // Changed to specific email verification route
          arguments: _emailController.text.trim(),
        );
      } else {
        _showSnackBar(
          response.message ?? S.t(context, 'Registration failed', 'فشل إنشاء الحساب'),
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

    final cardColor =
    theme.brightness == Brightness.dark ? cs.surface : Colors.white;
    final overlayColor = theme.brightness == Brightness.dark
        ? Colors.black.withOpacity(0.35)
        : Colors.black.withOpacity(0.15);

    final softTextColor = cs.onSurface.withOpacity(0.55);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(color: overlayColor),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: SingleChildScrollView(
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
                          S.t(context, 'Register', 'إنشاء حساب'),
                          style: const TextStyle(
                            color: AppColors.darkBlue,
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                          ).copyWith(
                            color: theme.brightness == Brightness.dark
                                ? cs.onSurface
                                : AppColors.darkBlue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          S.t(context, 'Name', 'الاسم'),
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _inputField(
                                context: context,
                                controller: _firstNameController,
                                hint: S.t(context, 'First Name', 'الاسم الأول'),
                                obscure: false,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _inputField(
                                context: context,
                                controller: _lastNameController,
                                hint: S.t(context, 'Last Name', 'اسم العائلة'),
                                obscure: false,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          S.t(context, 'Email', 'البريد الإلكتروني'),
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _inputField(
                          context: context,
                          controller: _emailController,
                          hint: S.t(context, 'Enter Your Email', 'اكتب بريدك الإلكتروني'),
                          obscure: false,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          S.t(context, 'Password', 'كلمة المرور'),
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _inputField(
                          context: context,
                          controller: _passwordController,
                          hint: S.t(context, 'Enter Your Password', 'اكتب كلمة المرور'),
                          obscure: _obscurePass,
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                              color: cs.onSurface.withOpacity(0.55),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          S.t(context, 'Confirm Password', 'تأكيد كلمة المرور'),
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _inputField(
                          context: context,
                          controller: _confirmPasswordController,
                          hint: S.t(context, 'Confirm your password', 'أكد كلمة المرور'),
                          obscure: _obscureConfirm,
                          suffix: IconButton(
                            onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                              color: cs.onSurface.withOpacity(0.55),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -3),
                              child: Checkbox(
                                value: _acceptedTerms,
                                onChanged: (v) =>
                                    setState(() => _acceptedTerms = v ?? false),

                                activeColor: AppColors.green, // بدل darkBlue لو عايزها زي الصورة
                                checkColor: Colors.white,     // يخلي علامة الصح أوضح

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6), // كانت 4
                                ),

                                side: BorderSide( // ده المهم عشان الإطار يبقى أوضح
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
                                  width: 1.5,
                                ),
                              )

                            ),
                            Expanded(
                              child: Wrap(
                                children: [
                                  Text(
                                    S.t(context, 'Accept ', 'أوافق على '),
                                    style: TextStyle(
                                        fontSize: 12, color: softTextColor),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                        context, AppRoutes.terms),
                                    child: Text(
                                      S.t(context, 'Terms and Conditions', 'الشروط والأحكام'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.darkBlue,
                                        fontWeight: FontWeight.w600,
                                      ).copyWith(
                                        color: theme.brightness == Brightness.dark
                                            ? cs.onSurface
                                            : AppColors.darkBlue,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    S.t(context, ' And ', ' و '),
                                    style: TextStyle(
                                        fontSize: 12, color: softTextColor),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                        context, AppRoutes.privacy),
                                    child: Text(
                                      S.t(context, 'Privacy Polices', 'سياسة الخصوصية'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.darkBlue,
                                        fontWeight: FontWeight.w600,
                                      ).copyWith(
                                        color: theme.brightness == Brightness.dark
                                            ? cs.onSurface
                                            : AppColors.darkBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _canSignUp ? _onSignUp : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _canSignUp
                                  ? AppColors.green
                                  : AppColors.greyDisabled,
                              disabledBackgroundColor: AppColors.greyDisabled,
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
                              S.t(context, 'Sign up', 'إنشاء حساب'),
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
          ),
        ],
      ),
    );
  }

  static Widget _inputField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final textColor = cs.onSurface;
    final hintColor = cs.onSurface.withOpacity(0.45);

    final borderColor = theme.brightness == Brightness.dark
        ? cs.outline.withOpacity(0.35)
        : AppColors.border;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor),
        suffixIcon: suffix,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: AppColors.darkBlue),
        ),
      ),
    );
  }
}