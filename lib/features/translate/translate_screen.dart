// ── lib/screens/translate/translate_screen.dart ───────────────────────────────
// Updated: Sign Language mode now records video and calls the sign API

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';   // ADD to pubspec.yaml

import '../../services/voice_service.dart';
import '../../services/voice_models.dart';
import '../../services/sign_service.dart';          // NEW
import '../../services/sign_models.dart';           // NEW
import '../../shared/strings.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  static const Color green = Color(0xFF44B65E);
  static const Color navy  = Color(0xFF1F2F6B);

  // Mode toggle
  bool isSignLanguage = true;

  // ── Voice state (unchanged) ────────────────────────────────────────────────
  final _audioRecorder    = AudioRecorder();
  bool  _isRecording      = false;
  bool  _isProcessing     = false;
  String? _audioPath;
  VoiceTranscription? _voiceResult;
  String _selectedLanguage = 'ar';
  final _voiceService      = VoiceService();

  // ── Sign state (NEW) ───────────────────────────────────────────────────────
  final _signService          = SignService();
  final _imagePicker          = ImagePicker();
  bool  _isSignProcessing     = false;
  SignTranscription? _signResult;

  // ── Shared ─────────────────────────────────────────────────────────────────
  final _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _tts.stop();
    super.dispose();
  }

  void _initTts() {
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.5);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SIGN LANGUAGE — Video picker + API call
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _pickAndProcessSignVideo() async {
    // Ask user: record now, or pick from gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                S.t(context, 'Choose video source', 'اختر مصدر الفيديو'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.videocam, color: green),
                title: Text(S.t(context, 'Record new video', 'تسجيل فيديو جديد')),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: green),
                title: Text(S.t(context, 'Choose from gallery', 'اختيار من المعرض')),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    // Request camera permission if recording
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showSnackBar(
          S.t(context, 'Camera permission denied', 'تم رفض إذن الكاميرا'),
          isError: true,
        );
        return;
      }
    }

    // Pick video
    final picked = await _imagePicker.pickVideo(
      source       : source,
      maxDuration  : const Duration(minutes: 2),  // limit to 2 min
    );

    if (picked == null) return;

    final videoFile = File(picked.path);
    await _processSignVideo(videoFile);
  }

  Future<void> _processSignVideo(File videoFile) async {
    setState(() {
      _isSignProcessing = true;
      _signResult       = null;
    });

    try {
      print('Sending sign video to backend: ${videoFile.path}');
      final response = await _signService.processSignVideo(videoFile);

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _signResult       = response.data;
          _isSignProcessing = false;
        });
        _showSnackBar(S.t(context, 'Sign recognised!', 'تم التعرف على الإشارة!'));
      } else {
        setState(() => _isSignProcessing = false);
        _showSnackBar(
          response.message ?? S.t(context, 'Recognition failed', 'فشل التعرف'),
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSignProcessing = false);
      _showSnackBar(S.t(context, 'An error occurred', 'حدث خطأ'), isError: true);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  VOICE (unchanged logic)
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
          isError: true,
        );
        return;
      }
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 44100, bitRate: 128000),
          path: path,
        );
        setState(() { _isRecording = true; _audioPath = path; _voiceResult = null; });
      }
    } catch (e) {
      _showSnackBar(S.t(context, 'Failed to start recording', 'فشل بدء التسجيل'), isError: true);
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
      final response = await _voiceService.transcribeAudio(audioFile: audioFile, language: _selectedLanguage);
      if (!mounted) return;
      if (response.success && response.data != null) {
        setState(() { _voiceResult = response.data; _isProcessing = false; });
        _showSnackBar(S.t(context, 'Transcription completed!', 'تم النسخ بنجاح!'));
      } else {
        setState(() => _isProcessing = false);
        _showSnackBar(response.message ?? S.t(context, 'Transcription failed', 'فشل النسخ'), isError: true);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnackBar(S.t(context, 'An error occurred', 'حدث خطأ'), isError: true);
    } finally {
      try { if (await audioFile.exists()) await audioFile.delete(); } catch (_) {}
    }
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Future<void> _speakText(String text, String lang) async {
    try {
      await _tts.setLanguage(lang == 'ar' ? 'ar-SA' : 'en-US');
      await _tts.speak(text);
    } catch (e) {
      _showSnackBar(S.t(context, 'Text-to-speech failed', 'فشل النطق'), isError: true);
    }
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar(S.t(context, 'Text copied!', 'تم النسخ!'));
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(message),
      backgroundColor: isError ? const Color(0xFFE24C4B) : green,
      duration       : const Duration(seconds: 2),
    ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title          : Text(S.t(context, 'Translate', 'ترجمة')),
        backgroundColor: Colors.transparent,
        elevation      : 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildModeToggle(),
              const SizedBox(height: 32),
              Expanded(
                child: isSignLanguage
                    ? _buildSignLanguageMode(isDark)
                    : _buildNormalLanguageMode(isDark),
              ),
              const SizedBox(height: 24),
              _buildMainButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mode toggle ────────────────────────────────────────────────────────────

  Widget _buildModeToggle() {
    return Container(
      padding    : const EdgeInsets.all(4),
      decoration : BoxDecoration(color: const Color(0xFFE6E6E6), borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          Expanded(child: _toggleButton(text: S.t(context, 'Sign Language', 'لغة الإشارة'), isSelected: isSignLanguage, onTap: () => setState(() => isSignLanguage = true))),
          Expanded(child: _toggleButton(text: S.t(context, 'Normal Language', 'اللغة العادية'), isSelected: !isSignLanguage, onTap: () => setState(() => isSignLanguage = false))),
        ],
      ),
    );
  }

  Widget _toggleButton({required String text, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap  : onTap,
      child  : Container(
        padding   : const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: isSelected ? green : Colors.transparent, borderRadius: BorderRadius.circular(26)),
        child     : Text(text, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }

  // ── Sign language mode ─────────────────────────────────────────────────────

  Widget _buildSignLanguageMode(bool isDark) {
    return Column(
      children: [
        _buildSignResultBox(isDark),
        const SizedBox(height: 16),
        if (_signResult != null) _buildSignActionButtons(),
      ],
    );
  }

  Widget _buildSignResultBox(bool isDark) {
    String displayText;

    if (_isSignProcessing) {
      displayText = S.t(context, 'Processing sign video...\nThis may take a few seconds', 'جاري معالجة فيديو الإشارة...\nقد يستغرق هذا بضع ثوان');
    } else if (_signResult != null) {
      displayText =
      '${S.t(context, 'English:', 'الإنجليزية:')}\n'
          '${_signResult!.transcriptedTextEn}\n\n'
          '${S.t(context, 'Arabic:', 'العربية:')}\n'
          '${_signResult!.transcriptedTextAr}';
    } else {
      displayText = S.t(
        context,
        'Press the camera button below to record your sign language video.\n\nYou can perform multiple signs — they will be combined into a sentence.',
        'اضغط على زر الكاميرا أدناه لتسجيل فيديو لغة الإشارة.\n\nيمكنك أداء إشارات متعددة — سيتم دمجها في جملة.',
      );
    }

    return Expanded(
      child: Container(
        width      : double.infinity,
        padding    : const EdgeInsets.all(20),
        decoration : BoxDecoration(
          color        : isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE6E6E6),
          borderRadius : BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: _isSignProcessing
              ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: green),
              SizedBox(height: 16),
              Text('Processing...', style: TextStyle(color: Colors.grey)),
            ],
          ))
              : Text(displayText, style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black87, height: 1.5)),
        ),
      ),
    );
  }

  Widget _buildSignActionButtons() {
    return Wrap(
      alignment : WrapAlignment.center,
      spacing   : 16,
      runSpacing: 12,
      children  : [
        _actionButton(icon: Icons.copy, label: S.t(context, 'Copy EN', 'نسخ EN'), onTap: () => _copyText(_signResult!.transcriptedTextEn)),
        _actionButton(icon: Icons.copy, label: S.t(context, 'Copy AR', 'نسخ AR'), onTap: () => _copyText(_signResult!.transcriptedTextAr)),
        _actionButton(icon: Icons.volume_up, label: S.t(context, 'Speak EN', 'نطق EN'), onTap: () => _speakText(_signResult!.transcriptedTextEn, 'en')),
        _actionButton(icon: Icons.volume_up, label: S.t(context, 'Speak AR', 'نطق AR'), onTap: () => _speakText(_signResult!.transcriptedTextAr, 'ar')),
      ],
    );
  }

  // ── Voice mode (unchanged) ─────────────────────────────────────────────────

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
      padding   : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFE6E6E6), borderRadius: BorderRadius.circular(12)),
      child     : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(S.t(context, 'Detect language:', 'لغة الكشف:'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value   : _selectedLanguage,
            underline: const SizedBox(),
            items   : [
              DropdownMenuItem(value: 'ar', child: Text(S.t(context, 'Arabic', 'العربية'))),
              DropdownMenuItem(value: 'en', child: Text(S.t(context, 'English', 'الإنجليزية'))),
            ],
            onChanged: (v) { if (v != null) setState(() => _selectedLanguage = v); },
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationBox(bool isDark) {
    String displayText = '';
    if (_isProcessing)        displayText = S.t(context, 'Transcribing audio...', 'جاري نسخ الصوت...');
    else if (_isRecording)    displayText = S.t(context, 'Recording...', 'جاري التسجيل...');
    else if (_voiceResult != null) {
      displayText = '${S.t(context, 'English:', 'الإنجليزية:')}\n${_voiceResult!.transcriptedTextEn}\n\n${S.t(context, 'Arabic:', 'العربية:')}\n${_voiceResult!.transcriptedTextAr}';
    } else {
      displayText = S.t(context, 'Press the microphone to start recording', 'اضغط على الميكروفون لبدء التسجيل');
    }
    return Expanded(
      child: Container(
        width     : double.infinity,
        padding   : const EdgeInsets.all(20),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE6E6E6), borderRadius: BorderRadius.circular(24)),
        child     : SingleChildScrollView(child: Text(displayText, style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black87, height: 1.5))),
      ),
    );
  }

  Widget _buildVoiceActionButtons() {
    return Wrap(
      alignment : WrapAlignment.center,
      spacing   : 16,
      runSpacing: 12,
      children  : [
        _actionButton(icon: Icons.copy, label: S.t(context, 'Copy EN', 'نسخ EN'), onTap: () => _copyText(_voiceResult!.transcriptedTextEn)),
        _actionButton(icon: Icons.copy, label: S.t(context, 'Copy AR', 'نسخ AR'), onTap: () => _copyText(_voiceResult!.transcriptedTextAr)),
      ],
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap        : onTap,
      borderRadius : BorderRadius.circular(12),
      child        : Container(
        padding   : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: green, width: 1)),
        child     : Column(
          children: [
            Icon(icon, color: green, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: green, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Main button ────────────────────────────────────────────────────────────

  Widget _buildMainButton() {
    if (isSignLanguage) {
      // Sign Language: open video picker
      return GestureDetector(
        onTap: _isSignProcessing ? null : _pickAndProcessSignVideo,
        child: Container(
          width     : 80,
          height    : 80,
          decoration: BoxDecoration(
            shape    : BoxShape.circle,
            color    : _isSignProcessing ? Colors.grey : navy,
            boxShadow: [BoxShadow(color: navy.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
          ),
          child: _isSignProcessing
              ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : const Icon(Icons.videocam, color: Colors.white, size: 40),
        ),
      );
    } else {
      // Voice: hold to record
      return GestureDetector(
        onTapDown  : (_) => _startRecording(),
        onTapUp    : (_) => _stopRecording(),
        onTapCancel: () => _stopRecording(),
        child      : Container(
          width     : 80,
          height    : 80,
          decoration: BoxDecoration(
            shape    : BoxShape.circle,
            color    : _isRecording ? const Color(0xFFE24C4B) : green,
            boxShadow: [BoxShadow(color: (_isRecording ? const Color(0xFFE24C4B) : green).withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
          ),
          child: _isProcessing
              ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 40),
        ),
      );
    }
  }
}
