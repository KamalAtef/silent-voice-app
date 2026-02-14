import 'package:flutter/material.dart';
import '../../app/routes.dart';

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
            title: 'Translate',
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.translate);
            },
          ),
          const SizedBox(height: 16),
          _bigActionButton(title: 'Learn', onTap: () {}),
          const SizedBox(height: 16),
          _bigActionButton(title: 'Awareness', onTap: () {}),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _bigActionButton({
    required String title,
    required VoidCallback onTap,
  }) {
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
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
