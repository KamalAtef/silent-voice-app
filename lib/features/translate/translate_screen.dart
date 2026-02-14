import 'package:flutter/material.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  // ===== COLORS =====
  static const Color green = Color(0xFF44B65E);
  static const Color navy = Color(0xFF1F2F6B);

  // ===== STATES =====
  bool flashOn = false;
  bool useFrontCamera = false;
  bool isSignLanguage = true;

  String translatedText =
      'Detected: Hello 👋\nThis is a longer example sentence to test auto height.\nAnd one more line...';

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Directionality(
      textDirection: TextDirection.ltr, // ✅ تثبيت الاتجاه للشاشة دي
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ================= CAMERA (FULL SCREEN UI) =================
            Container(
              color: const Color(0xFFF3F4F6),
              alignment: Alignment.center,
              child: Text(
                'Camera Preview (UI فقط)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey.shade500,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // ================= TOP BAR =================
            _cameraTopBar(context),

            // ================= FLOATING BOTTOM UI =================
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomSafe + 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ===== Translation Box (AUTO HEIGHT) =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6E6E6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              translatedText,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.grey.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _miniCircleIcon(Icons.volume_up_rounded, onTap: () {}),
                          const SizedBox(width: 10),
                          _miniCircleIcon(Icons.copy_rounded, onTap: () {}),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== MAIN ACTION BUTTON (CENTER ONLY) =====
                  Center(
                    child: isSignLanguage
                        ? _mainCameraButton(
                      onTap: () {
                        setState(() {
                          translatedText =
                          'Detected: Welcome to Silent Voice 🤍';
                        });
                      },
                    )
                        : _mainMicButton(
                      onTap: () {
                        setState(() {
                          translatedText = 'Listening... 🎤';
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ===== MODE TOGGLE =====
                  _modeToggle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TOP BAR =================
  Widget _cameraTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.45),
              Colors.black.withOpacity(0.25),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              _topIcon(Icons.arrow_back_ios_new_rounded,
                      () => Navigator.pop(context)),
              const SizedBox(width: 10),
              _topIcon(
                flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    () => setState(() => flashOn = !flashOn),
              ),
              const Spacer(),
              Image.asset(
                'assets/images/logo.png',
                height: 26,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              _topIcon(
                Icons.cameraswitch_rounded,
                    () => setState(() => useFrontCamera = !useFrontCamera),
              ),
              const SizedBox(width: 10),
              _topIcon(Icons.more_vert_rounded, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22, color: Colors.white),
      ),
    );
  }

  // ================= BUTTONS =================
  Widget _mainCameraButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400, width: 5),
        ),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFEFEFEF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt_rounded, size: 26),
          ),
        ),
      ),
    );
  }

  Widget _mainMicButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400, width: 5),
        ),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFEFEFEF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded, size: 26),
          ),
        ),
      ),
    );
  }

  Widget _miniCircleIcon(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }

  // ================= MODE TOGGLE =================
  Widget _modeToggle() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFE6E6E6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Expanded(
                child: _toggleChip(
                  selected: isSignLanguage,
                  title: 'Sign Language',
                  icon: Icons.back_hand_rounded,
                  onTap: () => setState(() => isSignLanguage = true),
                ),
              ),
              Expanded(
                child: _toggleChip(
                  selected: !isSignLanguage,
                  title: 'Normal Language',
                  icon: Icons.person_rounded,
                  onTap: () => setState(() => isSignLanguage = false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleChip({
    required bool selected,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final color = selected ? green : navy;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Icon(
                icon,
                key: ValueKey('$title-$selected'),
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
