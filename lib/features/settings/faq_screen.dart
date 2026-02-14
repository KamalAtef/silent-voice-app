import 'package:flutter/material.dart';
import '../../shared/strings.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const Color green = Color(0xFF44B65E);
  static const Color blue = Color(0xFF273D8B);

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final card = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = <_FaqItem>[
      _FaqItem(
        qEn: 'How does translation work?',
        qAr: 'كيف تعمل الترجمة؟',
        aEn:
        'Type or paste text and the app translates it instantly. Accuracy may vary by context.',
        aAr:
        'اكتب أو الصق النص وسيقوم التطبيق بترجمته فورًا. قد تختلف الدقة حسب السياق.',
      ),
      _FaqItem(
        qEn: 'Which languages are supported?',
        qAr: 'ما اللغات المدعومة؟',
        aEn: 'Arabic and English are supported currently.',
        aAr: 'يدعم التطبيق العربية والإنجليزية حاليًا.',
      ),
      _FaqItem(
        qEn: 'Is my data stored?',
        qAr: 'هل يتم حفظ بياناتي؟',
        aEn: 'Your history may be stored locally on your device for convenience.',
        aAr: 'قد يتم حفظ السجل محليًا على جهازك لتسهيل الاستخدام.',
      ),
      _FaqItem(
        qEn: 'Do you require internet connection?',
        qAr: 'هل التطبيق يحتاج إنترنت؟',
        aEn: 'Some translation features may require internet depending on the engine used.',
        aAr: 'قد تحتاج بعض ميزات الترجمة إلى الإنترنت حسب محرك الترجمة المستخدم.',
      ),
      _FaqItem(
        qEn: 'How do I clear translation history?',
        qAr: 'كيف أحذف سجل الترجمة؟',
        aEn: 'Go to History, then tap “Clear All”.',
        aAr: 'اذهب إلى السجل ثم اضغط “مسح الكل”.',
      ),
      _FaqItem(
        qEn: 'How do I contact support?',
        qAr: 'كيف أتواصل مع الدعم؟',
        aEn: 'Open Settings → Help and support to reach us via WhatsApp or Email.',
        aAr: 'افتح الإعدادات → المساعدة والدعم للتواصل عبر واتساب أو البريد.',
      ),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          S.t(context, 'FAQ', 'الأسئلة الشائعة'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color ?? (isDark ? Colors.white : blue),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final it = items[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Material(
                color: card,
                child: ExpansionTile(
                  collapsedIconColor: green,
                  iconColor: green,
                  title: Text(
                    S.t(context, it.qEn, it.qAr),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        S.t(context, it.aEn, it.aAr),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.85),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FaqItem {
  final String qEn, qAr;
  final String aEn, aAr;
  _FaqItem({required this.qEn, required this.qAr, required this.aEn, required this.aAr});
}
