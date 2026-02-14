import 'package:flutter/material.dart';
import '../../shared/strings.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const Color green = Color(0xFF44B65E);
  static const Color blue = Color(0xFF273D8B);

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final card = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sections = <_TermsSection>[
      _TermsSection(
        titleEn: 'Terms & Conditions',
        titleAr: 'الشروط والأحكام',
        bodyEn:
        'By using the app, you agree to these Terms. If you do not agree, please stop using the app.',
        bodyAr:
        'باستخدام التطبيق، فإنك توافق على هذه الشروط. إذا لم توافق، يُرجى التوقف عن استخدام التطبيق.',
      ),
      _TermsSection(
        titleEn: 'Using the App',
        titleAr: 'استخدام التطبيق',
        bodyEn:
        '• Use the app for lawful purposes only\n'
            '• Do not abuse, harm, or disrupt the service\n'
            '• Do not attempt to reverse engineer or bypass security.',
        bodyAr:
        '• استخدم التطبيق للأغراض القانونية فقط\n'
            '• لا تُسيء الاستخدام أو تُسبب ضررًا أو تُعطل الخدمة\n'
            '• لا تحاول فك الحماية أو تجاوز الأمان أو الهندسة العكسية.',
      ),
      _TermsSection(
        titleEn: 'Accounts & Security',
        titleAr: 'الحساب والأمان',
        bodyEn:
        'You are responsible for keeping your account information secure and for all activities that occur under your account.',
        bodyAr:
        'أنت مسؤول عن الحفاظ على أمان بيانات حسابك وعن أي استخدام يتم عبر حسابك.',
      ),
      _TermsSection(
        titleEn: 'Translations & Results',
        titleAr: 'نتائج الترجمة',
        bodyEn:
        'Translation results may not be 100% accurate. Please verify important information before relying on it.',
        bodyAr:
        'قد لا تكون نتائج الترجمة دقيقة بنسبة 100%. يُرجى التحقق من المعلومات المهمة قبل الاعتماد عليها.',
      ),
      _TermsSection(
        titleEn: 'Content & History',
        titleAr: 'المحتوى وسجل الترجمة',
        bodyEn:
        'Your translation input is used to provide the translation feature. Translation history may be stored locally on your device (if enabled).',
        bodyAr:
        'يتم استخدام نصوصك لتقديم ميزة الترجمة. قد يتم حفظ سجل الترجمة محليًا على جهازك (إذا كان مفعّلًا).',
      ),
      _TermsSection(
        titleEn: 'Third-Party Services',
        titleAr: 'خدمات الطرف الثالث',
        bodyEn:
        'Some features may rely on third-party services (e.g., translation engines). Their terms and policies may apply.',
        bodyAr:
        'قد تعتمد بعض الميزات على خدمات طرف ثالث (مثل محركات الترجمة). وقد تنطبق شروطهم وسياساتهم.',
      ),
      _TermsSection(
        titleEn: 'Limitation of Liability',
        titleAr: 'تحديد المسؤولية',
        bodyEn:
        'We are not liable for any indirect or consequential damages arising from the use of the app.',
        bodyAr:
        'لسنا مسؤولين عن أي أضرار غير مباشرة أو تبعية ناتجة عن استخدام التطبيق.',
      ),
      _TermsSection(
        titleEn: 'Changes to Terms',
        titleAr: 'تعديل الشروط',
        bodyEn:
        'We may update these Terms from time to time. Continued use of the app means you accept the updated Terms.',
        bodyAr:
        'قد نقوم بتحديث هذه الشروط من وقت لآخر. استمرار استخدامك للتطبيق يعني موافقتك على الشروط المحدّثة.',
      ),
      _TermsSection(
        titleEn: 'Contact Us',
        titleAr: 'تواصل معنا',
        bodyEn:
        'If you have questions about these Terms, contact us from Settings → Help and support.',
        bodyAr:
        'إذا كان لديك أي استفسار حول هذه الشروط، تواصل معنا من الإعدادات → المساعدة والدعم.',
      ),
      _TermsSection(
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
          S.t(context, 'Terms & Conditions', 'الشروط والأحكام'),
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

class _TermsSection {
  final String titleEn, titleAr;
  final String bodyEn, bodyAr;

  _TermsSection({
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
  });
}
