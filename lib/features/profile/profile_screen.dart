import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../shared/user_session.dart';
import '../../shared/strings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _green = Color(0xFF3FA66B);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      // ✅ بدل الأبيض الثابت
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 6),

              // Close (X) top right
              Align(
                alignment: AlignmentDirectional.topEnd, // ✅ RTL friendly
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 24),
                  color: cs.onSurface,
                  splashRadius: 20,
                ),
              ),

              const SizedBox(height: 40),

              // Avatar
              Container(
                width: 86,
                height: 86,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.person, color: Colors.white, size: 44),
                ),
              ),

              const SizedBox(height: 10),

              // Name (Live from UserSession)
              ValueListenableBuilder<String>(
                valueListenable: UserSession.instance.fullName,
                builder: (context, name, _) {
                  return Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  );
                },
              ),

              const SizedBox(height: 70),

              // Sections
              _sectionTitle(context, S.t(context, 'General', 'عام')),
              const SizedBox(height: 10),
              _rowItem(
                context,
                title: S.t(context, 'Personal details', 'البيانات الشخصية'),
                onTap: () => Navigator.pushNamed(context, AppRoutes.personalDetails),

              ),

              const SizedBox(height: 34),

              _sectionTitle(context, S.t(context, 'Other', 'أخرى')),
              const SizedBox(height: 10),
              _rowItem(
                context,
                title: S.t(context, 'Sign Out', 'تسجيل الخروج'),
                onTap: () {
                  UserSession.instance.clear();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                        (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Align(
      alignment: AlignmentDirectional.centerStart, // ✅ RTL friendly
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _rowItem(
      BuildContext context, {
        required String title,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: cs.outline, // ✅ بدل الرمادي الثابت
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
