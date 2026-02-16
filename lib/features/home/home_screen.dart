import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../shared/strings.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _green = Color(0xFF3FA66B);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          const SizedBox(height: 30),

          // ✅ الصورة الجديدة
          Image.asset(
            'assets/images/hello.png',
            width: double.infinity,
            height: 180,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 30),

          // ===== Buttons =====
          _bigActionButton(
            title: S.t(context, 'Translate', 'ترجمــــــــــة'),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.translate);
            },
          ),
          const SizedBox(height: 16),
          _bigActionButton(
            title: S.t(context, 'Learn', 'تعلــــــــــّم'),
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _bigActionButton(
            title: S.t(context, 'Awareness', 'توعيــــــــــة'),
            onTap: () {},
          ),


          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _bigActionButton({
    required String title,
    required VoidCallback onTap,
  }) {
    final lang = Localizations.localeOf(context).languageCode; // 'ar' أو 'en'
    final isAr = lang == 'ar';

    // ✅ تحكم منفصل لكل لغة
    final double fontSizeEn = 20;
    final double fontSizeAr = 20;

    final FontWeight weightEn = FontWeight.w600;
    final FontWeight weightAr = FontWeight.w600;

    // لو عايز خط مختلف لكل لغة (اختياري)
    final String? fontEn = null; // مثال: 'Poppins'
    final String? fontAr = null; // مثال: 'Cairo' أو 'Tajawal'

    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: isAr ? fontSizeAr : fontSizeEn,
      fontWeight: isAr ? weightAr : weightEn,
      color: Colors.white,
      fontFamily: isAr ? fontAr : fontEn,
    );

    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
          ),
        ),
        child: Text(title, style: textStyle),
      ),
    );
  }
}


