import 'package:flutter/material.dart';
import '../../shared/strings.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const Color green = Color(0xFF44B65E);
  static const Color blue = Color(0xFF273D8B);

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final card = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sections = <_PrivacySection>[
      _PrivacySection(
        titleEn: 'Privacy Policy',
        titleAr: 'سياسة الخصوصية',
        bodyEn:
        'Your privacy matters to us. This policy explains what data we collect and how we use it.',
        bodyAr:
        'خصوصيتك مهمة لنا. توضح هذه السياسة ما البيانات التي نجمعها وكيف نستخدمها.',
      ),
      _PrivacySection(
        titleEn: 'Data We Collect',
        titleAr: 'البيانات التي نجمعها',
        bodyEn:
        '• Your translation input (text)\n'
            '• App usage data to improve the experience\n'
            '• Translation history may be saved locally on your device (if enabled).',
        bodyAr:
        '• نص الترجمة الذي تدخله\n'
            '• بيانات استخدام التطبيق لتحسين التجربة\n'
            '• قد يتم حفظ سجل الترجمة محليًا على جهازك (إذا كان مفعّلًا).',
      ),
      _PrivacySection(
        titleEn: 'How We Use Your Data',
        titleAr: 'كيف نستخدم بياناتك',
        bodyEn:
        'We use your data to provide translation features, improve performance, and enhance the user experience.',
        bodyAr:
        'نستخدم بياناتك لتقديم ميزات الترجمة، وتحسين الأداء، وتطوير تجربة المستخدم.',
      ),
      _PrivacySection(
        titleEn: 'Data Storage',
        titleAr: 'تخزين البيانات',
        bodyEn:
        'Your translation history is stored locally on your device. We do not sell your data.',
        bodyAr:
        'يتم حفظ سجل الترجمة محليًا على جهازك. نحن لا نقوم ببيع بياناتك.',
      ),
      _PrivacySection(
        titleEn: 'Third-Party Services',
        titleAr: 'خدمات الطرف الثالث',
        bodyEn:
        'Some features may rely on third-party services (e.g., translation engines). Their policies may apply.',
        bodyAr:
        'قد تعتمد بعض الميزات على خدمات طرف ثالث (مثل محركات الترجمة). وقد تنطبق سياساتهم.',
      ),
      _PrivacySection(
        titleEn: 'Contact Us',
        titleAr: 'تواصل معنا',
        bodyEn:
        'If you have questions about this policy, contact us from Settings → Help and support.',
        bodyAr:
        'إذا كان لديك أي استفسار حول هذه السياسة، تواصل معنا من الإعدادات → المساعدة والدعم.',
      ),
      _PrivacySection(
        titleEn: 'Last Updated',
        titleAr: 'آخر تحديث',
        bodyEn: 'Feb 2026',
        bodyAr: 'فبراير 2026',
      ),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          S.t(context, 'Privacy Policy', 'سياسة الخصوصية'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color ??
                (isDark ? Colors.white : blue),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: ListView.separated(
          itemCount: sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final s = sections[index];

            return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Material(
                color: card,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              S.t(context, s.titleEn, s.titleAr),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        S.t(context, s.bodyEn, s.bodyAr),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.85),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PrivacySection {
  final String titleEn, titleAr;
  final String bodyEn, bodyAr;

  _PrivacySection({
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
  });
}
