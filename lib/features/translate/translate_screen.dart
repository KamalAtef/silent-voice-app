// ── lib/screens/translate/translate_screen.dart ───────────────────────────
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../services/voice_service.dart';
import '../../services/voice_models.dart';
import '../../services/sign_service.dart';
import '../../services/sign_models.dart';
import '../../shared/strings.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen>
    with SingleTickerProviderStateMixin {
  static const Color green = Color(0xFF44B65E);
  static const Color navy  = Color(0xFF1F2F6B);

  static const _channel = MethodChannel('asl_landmark_channel');

  // Mode toggle
  bool isSignLanguage = true;

  // ── Voice state ───────────────────────────────────────────────────────────
  final _audioRecorder     = AudioRecorder();
  bool  _isRecording       = false;
  bool  _isProcessing      = false;
  String? _audioPath;
  VoiceTranscription? _voiceResult;
  String _selectedLanguage = 'ar';
  final _voiceService      = VoiceService();

  // ── Sign state ────────────────────────────────────────────────────────────
  final _signService       = SignService();
  bool  _cameraRunning     = false;
  bool  _isDetecting       = false;
  bool  _isSaving          = false;
  bool  _handVisible       = false;

  String _currentSign      = '';
  double _currentConf      = 0.0;

  final List<String> _words         = [];
  String             _lastSign      = '';
  int                _sameSignCount = 0;
  static const int   _holdFrames    = 3;

  SignTranscription? _savedResult;
  String _statusMessage = '';

  Timer? _pollingTimer;

  // ── Rotation animation controller ─────────────────────────────────────────
  late AnimationController _rotationAnimController;
  late Animation<double>   _rotationAnim;

  // ── Shared ─────────────────────────────────────────────────────────────────
  final _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();

    _rotationAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotationAnim = Tween<double>(begin: 0.0, end: -1.5708).animate(
      CurvedAnimation(
        parent: _rotationAnimController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _channel.invokeMethod('stopCamera');
    _audioRecorder.dispose();
    _tts.stop();
    _rotationAnimController.dispose();
    super.dispose();
  }

  void _initTts() {
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.5);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SIGN — Start live camera
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _startSignCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showSnackBar(
          S.t(context, 'Camera permission denied', 'تم رفض إذن الكاميرا'),
          isError: true);
      return;
    }

    try {
      await _channel.invokeMethod('startCamera');
    } catch (e) {
      _showSnackBar(
          S.t(context, 'Could not start camera', 'تعذر تشغيل الكاميرا'),
          isError: true);
      return;
    }

    setState(() {
      _cameraRunning  = true;
      _words.clear();
      _lastSign       = '';
      _sameSignCount  = 0;
      _currentSign    = '';
      _currentConf    = 0.0;
      _savedResult    = null;
      _handVisible    = false;
      _statusMessage  = S.t(
        context,
        'Show your hand and sign — words appear as you hold each sign',
        'أظهر يدك وقم بالإشارة — تظهر الكلمات عند ثبات كل إشارة',
      );
    });

    _pollingTimer = Timer.periodic(
      const Duration(milliseconds: 300),
          (_) => _pollAndPredict(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SIGN — Stop camera and save sentence
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _stopSignCamera() async {
    _pollingTimer?.cancel();
    await _channel.invokeMethod('stopCamera');

    setState(() {
      _cameraRunning = false;
      _handVisible   = false;
    });

    final sentence = _words.join(' ').trim();

    if (sentence.isEmpty) {
      _showSnackBar(S.t(context, 'No signs detected', 'لم يتم اكتشاف إشارات'));
      return;
    }

    setState(() => _isSaving = true);
    final response = await _signService.saveSignSentence(sentence);
    setState(() => _isSaving = false);

    if (response.success && response.data != null) {
      setState(() => _savedResult = response.data);
      _showSnackBar(S.t(context, 'Sentence saved!', 'تم حفظ الجملة!'));
    } else {
      _showSnackBar(
          response.message ??
              S.t(context, 'Failed to save sentence', 'فشل حفظ الجملة'),
          isError: true);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SIGN — Polling loop
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _pollAndPredict() async {
    if (_isDetecting || !_cameraRunning) return;
    _isDetecting = true;

    try {
      final dynamic raw = await _channel.invokeMethod('getLandmarks');

      if (raw == null) {
        if (mounted) {
          setState(() {
            _handVisible   = false;
            _currentSign   = '';
            _sameSignCount = 0;
          });
        }
        return;
      }

      final List<List<double>> landmarks = (raw as List)
          .map((pt) => (pt as List).map((v) => (v as num).toDouble()).toList())
          .toList();

      if (mounted) setState(() => _handVisible = true);

      final prediction = await _signService.predictLandmarks(landmarks);

      if (prediction == null) {
        if (mounted) setState(() => _sameSignCount = 0);
        return;
      }

      if (mounted) {
        setState(() {
          _currentSign = prediction.sign;
          _currentConf = prediction.confidence;
        });

        if (prediction.sign == _lastSign) {
          _sameSignCount++;
          if (_sameSignCount == _holdFrames) {
            if (_words.isEmpty || _words.last != prediction.sign) {
              setState(() => _words.add(prediction.sign));
            }
            _sameSignCount = 0;
          }
        } else {
          _lastSign      = prediction.sign;
          _sameSignCount = 1;
        }
      }
    } catch (_) {
      // Swallow errors silently in the polling loop
    } finally {
      _isDetecting = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  VOICE
  // ══════════════════════════════════════════════════════════════════════════

  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        _showSnackBar(
            S.t(context, 'Microphone permission denied', 'تم رفض إذن الميكروفون'),
            isError: true);
        return;
      }
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _audioRecorder.start(
          const RecordConfig(
              encoder: AudioEncoder.wav,
              sampleRate: 44100,
              bitRate: 128000),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _audioPath   = path;
          _voiceResult = null;
        });
      }
    } catch (e) {
      _showSnackBar(
          S.t(context, 'Failed to start recording', 'فشل بدء التسجيل'),
          isError: true);
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) await _transcribeAudio(File(path));
    } catch (e) {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _transcribeAudio(File audioFile) async {
    setState(() => _isProcessing = true);
    try {
      final response = await _voiceService.transcribeAudio(
          audioFile: audioFile, language: _selectedLanguage);
      if (!mounted) return;
      if (response.success && response.data != null) {
        setState(() {
          _voiceResult  = response.data;
          _isProcessing = false;
        });
        _showSnackBar(S.t(context, 'Transcription completed!', 'تم النسخ بنجاح!'));
      } else {
        setState(() => _isProcessing = false);
        _showSnackBar(
            response.message ??
                S.t(context, 'Transcription failed', 'فشل النسخ'),
            isError: true);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnackBar(S.t(context, 'An error occurred', 'حدث خطأ'), isError: true);
    } finally {
      try {
        if (await audioFile.exists()) await audioFile.delete();
      } catch (_) {}
    }
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Future<void> _speakText(String text, String lang) async {
    try {
      await _tts.setLanguage(lang == 'ar' ? 'ar-SA' : 'en-US');
      await _tts.speak(text);
    } catch (e) {
      _showSnackBar(
          S.t(context, 'Text-to-speech failed', 'فشل النطق'), isError: true);
    }
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar(S.t(context, 'Text copied!', 'تم النسخ!'));
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? const Color(0xFFE24C4B) : green,
      duration: const Duration(seconds: 2),
    ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final isDark     = theme.brightness == Brightness.dark;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isLandscape && isSignLanguage
          ? null  // hide appbar in landscape sign mode to maximise space
          : AppBar(
        title: Text(S.t(context, 'Translate', 'ترجمة')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: isSignLanguage && !isLandscape
        // ── Portrait + Sign mode → show rotate prompt overlay ────────────
            ? _buildRotatePrompt(isDark)
            : isSignLanguage && isLandscape
        // ── Landscape + Sign mode → full sign UI ─────────────────────
            ? _buildLandscapeSignUI(isDark)
        // ── Voice mode (portrait or landscape) ───────────────────────
            : _buildPortraitVoiceUI(isDark),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ROTATE PROMPT — shown when Sign mode is selected but phone is portrait
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildRotatePrompt(bool isDark) {
    return Column(
      children: [
        // Mode toggle still visible so user can switch to voice
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _buildModeToggle(),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Animated phone icon ──────────────────────────────────
                  AnimatedBuilder(
                    animation: _rotationAnim,
                    builder: (_, __) {
                      return Transform.rotate(
                        angle: _rotationAnim.value,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            border: Border.all(color: green, width: 3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.smartphone,
                            size: 40,
                            color: green,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  // Curved arrow hint
                  const Icon(Icons.rotate_left, size: 32, color: green),
                  const SizedBox(height: 24),
                  Text(
                    S.t(
                      context,
                      'Rotate your phone to landscape',
                      'أدر هاتفك إلى الوضع الأفقي',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    S.t(
                      context,
                      'The sign language model works best in landscape mode for higher accuracy.',
                      'نموذج لغة الإشارة يعمل بدقة أعلى في الوضع الأفقي.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black45,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LANDSCAPE SIGN UI
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLandscapeSignUI(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // ── Top bar: mode toggle + status ──────────────────────────────
          Row(
            children: [
              SizedBox(width: 200, child: _buildModeToggle()),
              const SizedBox(width: 12),
              if (_cameraRunning)
                Expanded(
                  child: _buildLiveSignIndicatorCompact(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Main area: sentence box + button side by side ───────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sentence / result box
                Expanded(
                  flex: 5,
                  child: _buildSignSentenceBox(isDark),
                ),
                const SizedBox(width: 12),
                // Right column: action buttons + start/stop button
                SizedBox(
                  width: 90,
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_savedResult != null) ...[
                            _buildSignActionButtonsVertical(),
                            const SizedBox(height: 12),
                          ],

                          const SizedBox(height: 10),

                          // keeps button visible + prevents bottom clipping
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildMainSignButton(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact one-line live sign indicator for landscape top bar
  Widget _buildLiveSignIndicatorCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _handVisible
            ? green.withOpacity(0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _handVisible ? green : Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _handVisible ? green : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _handVisible
                ? S.t(context, 'Hand detected', 'تم اكتشاف اليد')
                : S.t(context, 'No hand', 'لا توجد يد'),
            style: TextStyle(
              fontSize: 12,
              color: _handVisible ? green : Colors.grey.shade500,
            ),
          ),
          if (_currentSign.isNotEmpty) ...[
            const Spacer(),
            Text(
              _currentSign,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: green),
            ),
            const SizedBox(width: 6),
            Text(
              '${(_currentConf * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  /// Start / Stop button sized for landscape sidebar
  Widget _buildMainSignButton() {
    return GestureDetector(
      onTap: _isSaving
          ? null
          : (_cameraRunning ? _stopSignCamera : _startSignCamera),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isSaving
              ? Colors.grey
              : (_cameraRunning ? const Color(0xFFE24C4B) : navy),
          boxShadow: [
            BoxShadow(
              color: (_cameraRunning ? const Color(0xFFE24C4B) : navy)
                  .withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: 3,
            ),
          ],
        ),
        child: _isSaving
            ? const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5))
            : Icon(
          _cameraRunning ? Icons.stop : Icons.videocam,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  /// Vertical layout of action buttons for landscape sidebar
  Widget _buildSignActionButtonsVertical() {
    if (_savedResult == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _smallActionButton(Icons.copy, 'EN',
                () => _copyText(_savedResult!.transcriptedTextEn)),
        const SizedBox(height: 4),

        _smallActionButton(Icons.copy, 'AR',
                () => _copyText(_savedResult!.transcriptedTextAr)),
        const SizedBox(height: 4),

        _smallActionButton(Icons.volume_up, 'EN',
                () => _speakText(_savedResult!.transcriptedTextEn, 'en')),
        const SizedBox(height: 4),

        _smallActionButton(Icons.volume_up, 'AR',
                () => _speakText(_savedResult!.transcriptedTextAr, 'ar')),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PORTRAIT VOICE UI (unchanged layout, just extracted)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPortraitVoiceUI(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildModeToggle(),
          const SizedBox(height: 24),
          Expanded(child: _buildNormalLanguageMode(isDark)),
          const SizedBox(height: 16),
          _buildVoiceButton(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SHARED SIGN SENTENCE BOX (used in landscape)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSignSentenceBox(bool isDark) {
    Widget content;

    if (_isSaving) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: green),
            const SizedBox(height: 16),
            Text(S.t(context, 'Saving...', 'جاري الحفظ...'),
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    } else if (_savedResult != null) {
      content = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.t(context, 'English:', 'الإنجليزية:'),
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              _savedResult!.transcriptedTextEn,
              style: TextStyle(
                  fontSize: 17,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.5),
            ),
            const SizedBox(height: 14),
            Text(
              S.t(context, 'Arabic:', 'العربية:'),
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              _savedResult!.transcriptedTextAr,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                  fontSize: 17,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.5),
            ),
          ],
        ),
      );
    } else if (_cameraRunning) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_statusMessage,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 10),
          Expanded(
            child: _words.isEmpty
                ? Center(
              child: Text(
                S.t(context,
                    'Hold a sign to add a word…',
                    'ثبّت إشارة لإضافة كلمة…'),
                style: TextStyle(
                    fontSize: 15, color: Colors.grey.shade400),
              ),
            )
                : SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _words
                    .asMap()
                    .entries
                    .map((e) => _wordChip(e.value, e.key))
                    .toList(),
              ),
            ),
          ),
        ],
      );
    } else {
      content = Center(
        child: Text(
          S.t(
            context,
            'Press the button to start.\n\nHold each sign steady for ~1 second to add it to your sentence.',
            'اضغط الزر للبدء.\n\nثبّت كل إشارة لمدة ثانية تقريباً لإضافتها.',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black54,
              height: 1.6),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: content,
    );
  }

  Widget _wordChip(String word, int index) {
    return GestureDetector(
      onLongPress: () => setState(() => _words.removeAt(index)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Text(
          word,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MODE TOGGLE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          Expanded(
              child: _toggleButton(
                  text: S.t(context, 'Sign Language', 'لغة الإشارة'),
                  isSelected: isSignLanguage,
                  onTap: () => setState(() => isSignLanguage = true))),
          Expanded(
              child: _toggleButton(
                  text: S.t(context, 'Normal Language', 'اللغة العادية'),
                  isSelected: !isSignLanguage,
                  onTap: () => setState(() => isSignLanguage = false))),
        ],
      ),
    );
  }

  Widget _toggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: isSelected ? green : Colors.transparent,
            borderRadius: BorderRadius.circular(26)),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  VOICE UI
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildNormalLanguageMode(bool isDark) {
    return Column(
      children: [
        _buildLanguageSelector(),
        const SizedBox(height: 24),
        _buildTranslationBox(isDark),
        const SizedBox(height: 16),
        if (_voiceResult != null) _buildVoiceActionButtons(),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(S.t(context, 'Detect language:', 'لغة الكشف:'),
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedLanguage,
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(
                  value: 'ar',
                  child: Text(S.t(context, 'Arabic', 'العربية'))),
              DropdownMenuItem(
                  value: 'en',
                  child: Text(S.t(context, 'English', 'الإنجليزية'))),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _selectedLanguage = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationBox(bool isDark) {
    String displayText = '';
    if (_isProcessing)
      displayText =
          S.t(context, 'Transcribing audio...', 'جاري نسخ الصوت...');
    else if (_isRecording)
      displayText = S.t(context, 'Recording...', 'جاري التسجيل...');
    else if (_voiceResult != null) {
      displayText =
      '${S.t(context, 'English:', 'الإنجليزية:')}\n${_voiceResult!.transcriptedTextEn}\n\n'
          '${S.t(context, 'Arabic:', 'العربية:')}\n${_voiceResult!.transcriptedTextAr}';
    } else {
      displayText = S.t(
          context,
          'Press the microphone to start recording',
          'اضغط على الميكروفون لبدء التسجيل');
    }
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFE6E6E6),
            borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Text(displayText,
              style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.5)),
        ),
      ),
    );
  }

  Widget _buildVoiceActionButtons() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        _actionButton(
            icon: Icons.copy,
            label: S.t(context, 'Copy EN', 'نسخ EN'),
            onTap: () => _copyText(_voiceResult!.transcriptedTextEn)),
        _actionButton(
            icon: Icons.copy,
            label: S.t(context, 'Copy AR', 'نسخ AR'),
            onTap: () => _copyText(_voiceResult!.transcriptedTextAr)),
      ],
    );
  }

  Widget _buildVoiceButton() {
    return GestureDetector(
      onTapDown: (_) => _startRecording(),
      onTapUp: (_) => _stopRecording(),
      onTapCancel: () => _stopRecording(),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isRecording ? const Color(0xFFE24C4B) : green,
          boxShadow: [
            BoxShadow(
                color:
                (_isRecording ? const Color(0xFFE24C4B) : green)
                    .withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5)
          ],
        ),
        child: _isProcessing
            ? const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 3))
            : Icon(_isRecording ? Icons.stop : Icons.mic,
            color: Colors.white, size: 40),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: green, width: 1)),
        child: Column(
          children: [
            Icon(icon, color: green, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: green,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SIGN ACTION BUTTONS (horizontal, used in portrait — kept for reference)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSignActionButtons() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        _actionButton(
            icon: Icons.copy,
            label: S.t(context, 'Copy EN', 'نسخ EN'),
            onTap: () => _copyText(_savedResult!.transcriptedTextEn)),
        _actionButton(
            icon: Icons.copy,
            label: S.t(context, 'Copy AR', 'نسخ AR'),
            onTap: () => _copyText(_savedResult!.transcriptedTextAr)),
        _actionButton(
            icon: Icons.volume_up,
            label: S.t(context, 'Speak EN', 'نطق EN'),
            onTap: () =>
                _speakText(_savedResult!.transcriptedTextEn, 'en')),
        _actionButton(
            icon: Icons.volume_up,
            label: S.t(context, 'Speak AR', 'نطق AR'),
            onTap: () =>
                _speakText(_savedResult!.transcriptedTextAr, 'ar')),
      ],
    );
  }

  Widget _smallActionButton(
      IconData icon,
      String label,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 54,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: green, width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: green),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}