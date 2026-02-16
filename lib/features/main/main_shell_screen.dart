import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/routes.dart';
import '../../shared/user_session.dart';
import '../../services/secure_storage_service.dart'; // ✅ NEW

import '../home/home_screen.dart';
import '../history/history_screen.dart';
import '../favorite/favorite_screen.dart';
import '../settings/settings_screen.dart';

import '../../shared/strings.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  static const Color green = Color(0xFF44B65E);
  static const Color blue = Color(0xFF273D8B);

  final _storageService = SecureStorageService(); // ✅ NEW

  int _index = 0;

  void _goToHistory() {
    setState(() => _index = 1);
  }

  void _openProfile() {
    Navigator.pushNamed(context, AppRoutes.profile);
  }

  // ✅ NEW: load name once from secure storage (so it persists after restart)
  @override
  void initState() {
    super.initState();
    _loadNameFromStorage();
  }

  Future<void> _loadNameFromStorage() async {
    final u = await _storageService.getUserData();
    if (u != null) {
      UserSession.instance.setFullName(u.fullName);
    } else {
      UserSession.instance.clear();
    }
  }

  // ✅ فتح واتساب
  // ✅ فتح واتساب (مضمون + fallback)
  Future<void> _openHelp() async {
    const phoneNumber = '201143909706'; // بدون +
    final message = Uri.encodeComponent('Hello, I need help with Silent Voice.');

    // 1) يفتح التطبيق مباشرة لو موجود
    final appUri = Uri.parse('whatsapp://send?phone=$phoneNumber&text=$message');

    // 2) fallback: wa.me
    final webUri = Uri.parse('https://wa.me/$phoneNumber?text=$message');

    // 3) fallback: api.whatsapp.com
    final apiUri =
    Uri.parse('https://api.whatsapp.com/send?phone=$phoneNumber&text=$message');

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
        return;
      }

      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }

      // آخر محاولة
      await launchUrl(apiUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onViewAll: _goToHistory),
      const HistoryScreen(),
      const FavoriteScreen(),
      const SettingsScreen(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // ✅ ألوان ديناميك للـ Light/Dark
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final appTextColor = Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black);
    final welcomeColor = isDark ? Colors.white70 : Colors.grey;
    final helpBg = isDark ? Colors.white12 : Colors.grey.shade100;
    final helpTextColor = isDark ? Colors.white : Colors.black87;

    // ✅ Bottom bar ديناميك
    final bottomBg = Theme.of(context).cardColor;
    final unselected = isDark ? Colors.white54 : Colors.grey;
    final shadowOpacity = isDark ? 0.35 : 0.08;

    // ===== Widgets (Header pieces) =====
    final profileBtn = GestureDetector(
      onTap: _openProfile,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: green,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.person, color: Colors.white, size: 24),
        ),
      ),
    );

    final helpBtn = GestureDetector(
      onTap: _openHelp,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: helpBg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          S.t(context, 'Get Help', 'الدعم'),
          style: TextStyle(
            fontSize: 12,
            color: helpTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );

    final nameBlock = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
      isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align( // ✅ ده المهم
          alignment:
          isRtl ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            '${S.t(context, 'Welcome', 'مرحبًا')} 👋',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: 12,
              color: welcomeColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        const SizedBox(height: 2),

        Align( // ✅ نفس المحاذاة للاسم
          alignment:
          isRtl ? Alignment.centerRight : Alignment.centerLeft,
          child: ValueListenableBuilder<String>(
            valueListenable: UserSession.instance.fullName,
            builder: (context, name, _) {
              final fallback = S.t(context, 'User', 'مستخدم');

              final displayName =
              (name.trim().isEmpty || name == 'User')
                  ? fallback
                  : name;

              return Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign:
                isRtl ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  fontSize: 14,
                  color: appTextColor,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: scaffoldBg,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                profileBtn,
                const SizedBox(width: 12),

                nameBlock,

                const Spacer(),

                helpBtn,
              ],
            ),
          ),
        ),
      ),

      body: IndexedStack(
        index: _index,
        children: pages,
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: bottomBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(34),
            topRight: Radius.circular(34),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(shadowOpacity),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(34),
            topRight: Radius.circular(34),
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: bottomBg,
            elevation: 0,
            selectedItemColor: green,
            unselectedItemColor: unselected,
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                  _index == 0 ? Icons.home_rounded : Icons.home_outlined,
                ),
                label: S.t(context, 'Home', 'الرئيسية'),
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _index == 1
                      ? Icons.history_rounded
                      : Icons.history_outlined,
                ),
                label: S.t(context, 'History', 'السجل'),
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _index == 2
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                label: S.t(context, 'Favorite', 'المفضلة'),
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _index == 3
                      ? Icons.settings_rounded
                      : Icons.settings_outlined,
                ),
                label: S.t(context, 'Setting', 'الإعدادات'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
