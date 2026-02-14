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

            ValueListenableBuilder<String>(
              valueListenable: UserSession.instance.fullName,
              builder: (_, name, __) {
                return _infoRow(
                  context,
                  title: S.t(context, 'Full name', 'الاسم بالكامل'),
                  value: name.trim().isEmpty ? '-' : name,
                  onTap: () => _editTextBottomSheet(
                    context,
                    title: S.t(context, 'Full name', 'الاسم بالكامل'),
                    initialValue: name,
                    onSave: (v) => UserSession.instance.setFullName(v),
                  ),
                );
              },
            ),

            _infoRow(
              context,
              title: S.t(context, 'Email', 'البريد الإلكتروني'),
              value: S.t(context, 'Coming soon', 'قريبًا'),
              onTap: null,
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
            Icon(
              Icons.chevron_right_rounded,
              color: onTap == null ? cs.outline.withOpacity(0.35) : cs.outline,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _editTextBottomSheet(
      BuildContext context, {
        required String title,
        required String initialValue,
        required ValueChanged<String> onSave,
      }) async {
    final controller = TextEditingController(text: initialValue);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: title,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(S.t(context, 'Cancel', 'إلغاء')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        onSave(controller.text);
                        Navigator.pop(context);
                      },
                      child: Text(S.t(context, 'Save', 'حفظ')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
