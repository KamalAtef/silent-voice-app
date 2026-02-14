import 'package:flutter/material.dart';
import '../../shared/strings.dart';
import 'email_login_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const Color _darkBlue = Color(0xFF1F2F6B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/login_bg.png',
            fit: BoxFit.cover,
          ),

          // Gradient overlay (Splash style - 30%)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2F5D8A).withOpacity(0.30),
                  const Color(0xFF3FA66B).withOpacity(0.30),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Spacer(),

                  // Google login
                  _googleLoginButton(
                    context: context,
                    onTap: () {
                      // TODO: Google auth later
                    },
                  ),

                  const SizedBox(height: 14),

                  // Email login
                  _emailLoginButton(
                    context: context,
                    onTap: () {
                      _openOverlay(
                        context,
                        const EmailLoginScreen(),
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // Register row
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        S.t(
                          context,
                          "You don't have an account? ",
                          "ليس لديك حساب؟ ",
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _openOverlay(
                            context,
                            const RegisterScreen(),
                          );
                        },
                        child: Text(
                          S.t(context, 'Register now', 'سجّل الآن'),
                          style: const TextStyle(
                            color: _darkBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: _darkBlue,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Overlay Navigation (Blur + Fade) =====
  static void _openOverlay(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: anim,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  // ===== Google Button =====
  static Widget _googleLoginButton({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          height: 58,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/google_icon.png',
                height: 22,
              ),
              const SizedBox(width: 12),
              Text(
                S.t(context, 'Login with Google', 'تسجيل الدخول عبر Google'),
                style: const TextStyle(
                  color: _darkBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Email Button =====
  static Widget _emailLoginButton({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _darkBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/email_icon.png',
                height: 22,
              ),
              const SizedBox(width: 12),
              Text(
                S.t(context, 'Login by e-mail', 'تسجيل الدخول بالبريد'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
