import 'package:flutter/material.dart';

import '../features/splash/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';

import '../features/auth/forget_password_email_screen.dart';
import '../features/auth/verify_email_otp_screen.dart'; // ✅ NEW: Email verification OTP
import '../features/auth/verify_reset_password_otp_screen.dart'; // ✅ NEW: Reset password OTP
import '../features/auth/reset_password_screen.dart';
import '../features/auth/password_success_screen.dart';

import '../features/history/history_screen.dart';
import '../features/settings/settings_screen.dart';

import '../features/main/main_shell_screen.dart';
import '../features/profile/profile_screen.dart';

import '../features/translate/translate_screen.dart';

import '../features/settings/faq_screen.dart';
import '../features/settings/contact_support_screen.dart';

import '../features/settings/privacy_screen.dart';

import '../features/profile/personal_details_screen.dart';

import '../features/settings/terms_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';

  // ✅ خلي الهوم يفتح الـ MainShell عشان الـ BottomBar ثابت
  static const home = '/home';

  static const history = '/history';
  static const settings = '/settings';

  static const profile = '/profile';

  // 🔐 Email Verification (بعد التسجيل)
  static const verifyEmailOtp = '/verify-email-otp'; // ✅ NEW

  // 🔐 Forget password flow
  static const forgetPasswordEmail = '/forget-password-email';
  static const verifyResetPasswordOtp = '/verify-reset-password-otp'; // ✅ NEW
  static const resetPassword = '/reset-password';
  static const passwordSuccess = '/password-success';

  static const translate = '/translate';

  static const faq = '/faq';
  static const contactSupport = '/contact-support';

  static const privacy = '/privacy';

  static const personalDetails = '/personal-details';

  static const terms = '/terms';

  static Map<String, WidgetBuilder> get map => {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),

    // ✅ MainShell
    home: (_) => const MainShellScreen(),

    // 🔐 Email Verification (بعد التسجيل)
    verifyEmailOtp: (_) => const VerifyEmailOtpScreen(), // ✅ NEW

    // 🔐 Forget password screens
    forgetPasswordEmail: (_) => const ForgetPasswordEmailScreen(),
    verifyResetPasswordOtp: (_) =>
    const VerifyResetPasswordOtpScreen(), // ✅ NEW
    resetPassword: (_) => const ResetPasswordScreen(),
    passwordSuccess: (_) => const PasswordSuccessScreen(),

    history: (_) => const HistoryScreen(),
    settings: (_) => const SettingsScreen(),

    profile: (_) => const ProfileScreen(),

    translate: (_) => const TranslateScreen(),

    faq: (_) => const FaqScreen(),
    contactSupport: (_) => const ContactSupportScreen(),

    privacy: (_) => const PrivacyScreen(),

    personalDetails: (_) => const PersonalDetailsScreen(),

    terms: (_) => const TermsScreen(),
  };
}