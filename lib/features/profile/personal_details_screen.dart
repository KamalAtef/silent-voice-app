import 'package:flutter/material.dart';
import '../../shared/user_session.dart';
import '../../shared/strings.dart';

class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        title: Text(S.t(context, 'Personal details', 'البيانات الشخصية')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          children: [
            _sectionTitle(context, S.t(context, 'Account', 'الحساب')),
            const SizedBox(height: 10),

            // ✅ Full name (READ ONLY)
            ValueListenableBuilder<String>(
              valueListenable: UserSession.instance.fullName,
              builder: (_, name, __) {
                return _infoRow(
                  context,
                  title: S.t(context, 'Full name', 'الاسم بالكامل'),
                  value: name.trim().isEmpty ? '-' : name,
                  onTap: null, // ✅ no edit
                );
              },
            ),

            // ✅ Email (READ ONLY)
            ValueListenableBuilder<String>(
              valueListenable: UserSession.instance.email,
              builder: (_, email, __) {
                return _infoRow(
                  context,
                  title: S.t(context, 'Email', 'البريد الإلكتروني'),
                  value: email.trim().isEmpty ? '-' : email,
                  onTap: null, // ✅ no edit
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _infoRow(
      BuildContext context, {
        required String title,
        required String value,
        VoidCallback? onTap,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.70),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ Remove arrow when not clickable
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: cs.outline,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
