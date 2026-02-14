import 'dart:ui';
import 'package:flutter/material.dart';

import '../../app/app_settings.dart'; // ✅ بدل ThemeController/LanguageController
import '../../shared/strings.dart';
import '../../app/routes.dart';

import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color green = Color(0xFF44B65E);
  static const Color blue = Color(0xFF273D8B);

  @override
  Widget build(BuildContext context) {
    // ✅ نخلي الخلفية والـ card ياخدوا ألوانهم من الثيم بدل الأبيض الثابت
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 90, bottom: 24),
            child: Column(
              children: [
                // Card Menu
                Container(
                  width: MediaQuery.of(context).size.width * 0.82,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _tile(
                        icon: Icons.nights_stay_rounded,
                        title: S.t(context, 'App Theme', 'مظهر التطبيق'),
                        onTap: () {
                          _showBlurDialog(
                            context: context,
                            title: S.t(context, 'App Theme', 'مظهر التطبيق'),
                            items: [
                              _BlurItem(
                                icon: Icons.wb_sunny_outlined,
                                title: S.t(context, 'Light', 'فاتح'),
                                onTap: () {
                                  // ✅ بدل ThemeController
                                  AppSettings.instance.setThemeMode(ThemeMode.light);
                                },
                              ),
                              _BlurItem(
                                icon: Icons.nightlight_round,
                                title: S.t(context, 'Dark', 'داكن'),
                                onTap: () {
                                  // ✅ بدل ThemeController
                                  AppSettings.instance.setThemeMode(ThemeMode.dark);
                                },
                              ),
                              _BlurItem(
                                icon: Icons.phone_iphone_rounded,
                                title: S.t(context, 'System', 'النظام'),
                                onTap: () {
                                  AppSettings.instance.setThemeMode(ThemeMode.system);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      _divider(context),
                      _tile(
                        icon: Icons.translate_rounded,
                        title: S.t(context, 'App Language', 'لغة التطبيق'),
                        onTap: () {
                          _showBlurDialog(
                            context: context,
                            title: S.t(context, 'App Language', 'لغة التطبيق'),
                            items: [
                              _BlurItem(
                                icon: Icons.language_rounded,
                                title: S.t(context, 'English', 'الإنجليزية'),
                                onTap: () {
                                  // ✅ بدل LanguageController
                                  AppSettings.instance.setLanguage('en');
                                },
                              ),
                              _BlurItem(
                                icon: Icons.language_rounded,
                                title: S.t(context, 'Arabic', 'العربية'),
                                onTap: () {
                                  // ✅ بدل LanguageController
                                  AppSettings.instance.setLanguage('ar');
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      _divider(context),
                      _tile(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: S.t(context, 'Help and support', 'المساعدة والدعم'),
                        onTap: () {
                          _showBlurDialog(
                            context: context,
                            title: S.t(context, 'Help and support', 'المساعدة والدعم'),
                            items: [
                              _BlurItem(
                                icon: Icons.chat_rounded,
                                title: S.t(context, 'Contact support', 'تواصل مع الدعم'),
                                onTap: () {
                                  Navigator.pushNamed(context, AppRoutes.contactSupport);
                                },
                              ),
                              _BlurItem(
                                icon: Icons.help_outline_rounded,
                                title: S.t(context, 'FAQ', 'الأسئلة الشائعة'),
                                onTap: () {
                                  Navigator.pushNamed(context, AppRoutes.faq);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      _divider(context),
                      _tile(
                        icon: Icons.verified_user_outlined,
                        title: S.t(context, 'Privacy Policy', 'سياسة الخصوصية'),
                        onTap: () {
                          _showBlurDialog(
                            context: context,
                            title: S.t(context, 'Privacy Policy', 'سياسة الخصوصية'),
                            items: [
                              _BlurItem(
                                icon: Icons.privacy_tip_outlined,
                                title: S.t(context, 'Open Privacy Policy', 'فتح سياسة الخصوصية'),
                                onTap: () {
                                  Navigator.pushNamed(context, AppRoutes.privacy);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      _divider(context),

                      // ✅ Terms & Conditions (بدل Share App) - نفس ستايل Privacy
                      _tile(
                        icon: Icons.description_outlined,
                        title: S.t(context, 'Terms & Conditions', 'الشروط والأحكام'),
                        onTap: () {
                          _showBlurDialog(
                            context: context,
                            title: S.t(context, 'Terms & Conditions', 'الشروط والأحكام'),
                            items: [
                              _BlurItem(
                                icon: Icons.description_outlined,
                                title: S.t(context, 'Open Terms & Conditions', 'فتح الشروط والأحكام'),
                                onTap: () {
                                  Navigator.pushNamed(context, AppRoutes.terms);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                Text(
                  S.t(context, 'Follow us to learn more', 'تابعنا لمعرفة المزيد'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B95A1),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 12),
                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () async {
                      final uri = Uri.parse('https://alfan.link/silent_voice');
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/alfan.png',
                          fit: BoxFit.cover,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  S.t(context, 'App Version V1.0', 'إصدار التطبيق V1.0'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B95A1),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= BLUR DIALOG (CENTER) =================
  static void _showBlurDialog({
    required BuildContext context,
    String? title,
    required List<_BlurItem> items,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'blur_dialog',
      barrierColor: Colors.black.withOpacity(0.20),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) {
        final cardColor = Theme.of(context).cardColor;

        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(color: Colors.transparent),
              ),
            ),
            Center(
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      color: cardColor,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (title != null && title.trim().isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).textTheme.titleMedium?.color ?? blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => Navigator.pop(context),
                                    borderRadius: BorderRadius.circular(999),
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            _divider(context),
                          ],
                          for (int i = 0; i < items.length; i++) ...[
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                items[i].onTap?.call();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                child: Row(
                                  children: [
                                    Icon(items[i].icon, color: green, size: 22),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        items[i].title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Theme.of(context).textTheme.bodyLarge?.color ?? blue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (i != items.length - 1) _divider(context),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  // ================= UI Helpers =================
  static Widget _divider(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    color: Theme.of(context).dividerColor.withOpacity(0.35),
  );

  static Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: green, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white : blue,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: green, size: 26),
          ],
        ),
      ),
    );
  }

  static Widget _socialCircle({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xFFEAF6EF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: green, size: 16),
      ),
    );
  }
}

// ================= Model =================
class _BlurItem {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  _BlurItem({
    required this.icon,
    required this.title,
    this.onTap,
  });
}
