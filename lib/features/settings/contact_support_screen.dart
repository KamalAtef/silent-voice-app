import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/strings.dart';


class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  static const Color green = Color(0xFF44B65E);

  Future<void> _openWhatsApp(BuildContext context) async {
    const phoneNumber = '201143909706';
    final msg = Uri.encodeComponent('Hello, I need help with Silent Voice.');
    final uri = Uri.parse('https://wa.me/$phoneNumber?text=$msg');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t(context, 'Could not open WhatsApp', 'تعذر فتح واتساب'))),
      );
    }
  }

  Future<void> _openEmail(BuildContext context) async {
    final subject = Uri.encodeComponent('Silent Voice Support');
    final body = Uri.encodeComponent('Hello, I need help with Silent Voice.');
    final uri = Uri.parse('mailto:kamalatef2018@gmail.com?subject=$subject&body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t(context, 'Could not open Email app', 'تعذر فتح تطبيق البريد'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final card = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(S.t(context, 'Contact support', 'تواصل مع الدعم')),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          children: [
            _actionTile(
              context,
              icon: Icons.chat_rounded,
              title: S.t(context, 'WhatsApp', 'واتساب'),
              subtitle: S.t(context, 'Chat with us on WhatsApp', 'راسلنا عبر واتساب'),
              onTap: () => _openWhatsApp(context),
              cardColor: card,
            ),
            const SizedBox(height: 12),
            _actionTile(
              context,
              icon: Icons.email_rounded,
              title: S.t(context, 'Email', 'البريد الإلكتروني'),
              subtitle: S.t(context, 'Send us an email', 'راسلنا عبر البريد'),
              onTap: () => _openEmail(context),
              cardColor: card,
            ),
            const SizedBox(height: 12),
            _actionTile(
              context,
              icon: Icons.edit_rounded,
              title: S.t(context, 'Send message', 'إرسال رسالة'),
              subtitle: S.t(context, 'Write a message inside the app', 'اكتب رسالتك داخل التطبيق'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SendMessageScreen()),
                );
              },
              cardColor: card,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        required Color cardColor,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6EAF0)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Color(0xFFEAF6EF), shape: BoxShape.circle),
              child: Icon(icon, color: green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: green),
          ],
        ),
      ),
    );
  }
}

class SendMessageScreen extends StatefulWidget {
  const SendMessageScreen({super.key});

  @override
  State<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final card = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(S.t(context, 'Send message', 'إرسال رسالة')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE6EAF0)),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 6,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: S.t(context, 'Write your message...', 'اكتب رسالتك هنا...'),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.t(context, 'Message saved (demo)', 'تم حفظ الرسالة (تجربة)'))),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF44B65E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(S.t(context, 'Send', 'إرسال')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
