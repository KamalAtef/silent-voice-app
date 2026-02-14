import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../shared/strings.dart';

class PasswordSuccessScreen extends StatefulWidget {
  const PasswordSuccessScreen({super.key});

  static const Color green = Color(0xFF44B65E);
  static const Color blue = Color(0xFF273D8B);

  @override
  State<PasswordSuccessScreen> createState() =>
      _PasswordSuccessScreenState();
}

class _PasswordSuccessScreenState extends State<PasswordSuccessScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
            (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final backgroundColor = theme.scaffoldBackgroundColor;

    final titleColor = theme.brightness == Brightness.dark
        ? cs.onSurface
        : PasswordSuccessScreen.blue;

    return Scaffold(
      backgroundColor: backgroundColor, // ✅ بدل الأبيض الثابت
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: cs.outline.withOpacity(0.25),
                ),
              ),
              child: const Icon(
                Icons.check_circle,
                color: PasswordSuccessScreen.green,
                size: 46,
              ),
            ),

            const SizedBox(height: 22),

            Text(
              S.t(
                context,
                'Password Changed Successfully',
                'تم تغيير كلمة المرور بنجاح',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                color: titleColor,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              S.t(
                context,
                'You will be redirected to login',
                'سيتم تحويلك إلى تسجيل الدخول',
              ),
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withOpacity(0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
