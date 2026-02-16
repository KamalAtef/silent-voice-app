import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../services/voice_service.dart';
import '../../services/voice_models.dart';
import '../../shared/strings.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  static const Color green = Color(0xFF44B65E);
  static const Color navy = Color(0xFF1F2F6B);

  // Mode toggle
  bool isSignLanguage = true; // true = Sign Language, false = Normal Language (Voice)

  // Recording state
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _audioPath;

  // Transcription results
  VoiceTranscription? _transcription;
  String _selectedLanguage = 'ar'; // Default to Arabic

  // Services
  final _voiceService = VoiceService();
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

  // ==================== TTS INITIALIZATION ====================
  void _initTts() {
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.5);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  // ==================== PERMISSION HANDLING ====================
  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // ==================== RECORDING ====================
  Future<void> _startRecording() async {
    try {
      // Check permission
      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        _showSnackBar(
          S.t(context, 'Microphone permission denied', 'تم رفض إذن الميكروفون'),
          isError: true,
        );
        return;
      }

      // Check if can record
      if (await _audioRecorder.hasPermission()) {
        // Get temp directory
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';

        // Start recording
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav, // ✅ WAV format required by API
            sampleRate: 44100,
            bitRate: 128000,
          ),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _audioPath = path;
          _transcription = null; // Clear previous result
        });

        print('🎤 Recording started: $path');
      }
    } catch (e) {
      print('❌ Recording Error: $e');
      _showSnackBar(
        S.t(context, 'Failed to start recording', 'فشل بدء التسجيل'),
        isError: true,
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
      });

      print('🎤 Recording stopped: $path');

      if (path != null) {
        // Auto-send to API
        await _transcribeAudio(File(path));
      }
    } catch (e) {
      print('❌ Stop Recording Error: $e');
      setState(() => _isRecording = false);
    }
  }

  // ==================== TRANSCRIPTION ====================
  Future<void> _transcribeAudio(File audioFile) async {
    setState(() => _isProcessing = true);

    try {
      print('🔵 Transcribing audio file...');

      final response = await _voiceService.transcribeAudio(
        audioFile: audioFile,
        language: _selectedLanguage,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _transcription = response.data;
          _isProcessing = false;
        });

        _showSnackBar(
          S.t(context, 'Transcription completed!', 'تم النسخ بنجاح!'),
        );
      } else {
        setState(() => _isProcessing = false);
        _showSnackBar(
          response.message ??
              S.t(context, 'Transcription failed', 'فشل النسخ'),
          isError: true,
        );
      }
    } catch (e) {
      print('❌ Transcription Error: $e');
      setState(() => _isProcessing = false);
      _showSnackBar(
        S.t(context, 'An error occurred', 'حدث خطأ'),
        isError: true,
      );
    } finally {
      // Clean up temp file
      try {
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      } catch (e) {
        print('⚠️ Failed to delete temp file: $e');
      }
    }
  }

  // ==================== TEXT TO SPEECH ====================
  Future<void> _speakText(String text, String lang) async {
    try {
      await _tts.setLanguage(lang == 'ar' ? 'ar-SA' : 'en-US');
      await _tts.speak(text);
    } catch (e) {
      print('❌ TTS Error: $e');
      _showSnackBar(
        S.t(context, 'Text-to-speech failed', 'فشل النطق'),
        isError: true,
      );
    }
  }

  // ==================== COPY TEXT ====================
  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar(
      S.t(context, 'Text copied!', 'تم النسخ!'),
    );
  }

  // ==================== UI HELPERS ====================
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFE24C4B) : green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(S.t(context, 'Translate', 'ترجمة')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Mode Toggle (Sign Language / Normal Language)
              _buildModeToggle(),

              const SizedBox(height: 32),

              // Main content area
              Expanded(
                child: isSignLanguage
                    ? _buildSignLanguageMode()
                    : _buildNormalLanguageMode(isDark),
              ),

              const SizedBox(height: 24),

              // Main Action Button
              _buildMainButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== MODE TOGGLE ====================
  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleButton(
              text: S.t(context, 'Sign Language', 'لغة الإشارة'),
              isSelected: isSignLanguage,
              onTap: () => setState(() => isSignLanguage = true),
            ),
          ),
          Expanded(
            child: _toggleButton(
              text: S.t(context, 'Normal Language', 'اللغة العادية'),
              isSelected: !isSignLanguage,
              onTap: () => setState(() => isSignLanguage = false),
            ),
          ),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? green : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ==================== SIGN LANGUAGE MODE ====================
  Widget _buildSignLanguageMode() {
    return Center(
      child: Text(
        S.t(context, 'Sign Language mode\n(Camera coming soon)',
            'وضع لغة الإشارة\n(الكاميرا قريباً)'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  // ==================== NORMAL LANGUAGE MODE (VOICE) ====================
  Widget _buildNormalLanguageMode(bool isDark) {
    return Column(
      children: [
        // Language Selection
        _buildLanguageSelector(),

        const SizedBox(height: 24),

        // Translation Result Box
        _buildTranslationBox(isDark),

        const SizedBox(height: 16),

        // Action Buttons (Copy & Speak)
        if (_transcription != null) _buildActionButtons(),
      ],
    );
  }

  // Language Selector
  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            S.t(context, 'Detect language:', 'لغة الكشف:'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedLanguage,
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(
                value: 'ar',
                child: Text(S.t(context, 'Arabic', 'العربية')),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Text(S.t(context, 'English', 'الإنجليزية')),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedLanguage = value);
              }
            },
          ),
        ],
      ),
    );
  }

  // Translation Box
  Widget _buildTranslationBox(bool isDark) {
    String displayText = '';

    if (_isProcessing) {
      displayText = S.t(context, 'Transcribing audio...', 'جاري نسخ الصوت...');
    } else if (_isRecording) {
      displayText = S.t(context, '🎤 Recording...', '🎤 جاري التسجيل...');
    } else if (_transcription != null) {
      displayText = '${S.t(context, 'English:', 'الإنجليزية:')}\n'
          '${_transcription!.transcriptedTextEn}\n\n'
          '${S.t(context, 'Arabic:', 'العربية:')}\n'
          '${_transcription!.transcriptedTextAr}';
    } else {
      displayText = S.t(
        context,
        'Press the microphone to start recording',
        'اضغط على الميكروفون لبدء التسجيل',
      );
    }

    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // Action Buttons (Copy & Speak)
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Copy English
        _actionButton(
          icon: Icons.copy,
          label: S.t(context, 'Copy EN', 'نسخ EN'),
          onTap: () => _copyText(_transcription!.transcriptedTextEn),
        ),
        const SizedBox(width: 16),
        // Speak English
        _actionButton(
          icon: Icons.volume_up,
          label: S.t(context, 'Speak EN', 'نطق EN'),
          onTap: () => _speakText(_transcription!.transcriptedTextEn, 'en'),
        ),
        const SizedBox(width: 16),
        // Copy Arabic
        _actionButton(
          icon: Icons.copy,
          label: S.t(context, 'Copy AR', 'نسخ AR'),
          onTap: () => _copyText(_transcription!.transcriptedTextAr),
        ),
        const SizedBox(width: 16),
        // Speak Arabic
        _actionButton(
          icon: Icons.volume_up,
          label: S.t(context, 'Speak AR', 'نطق AR'),
          onTap: () => _speakText(_transcription!.transcriptedTextAr, 'ar'),
        ),
      ],
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
          border: Border.all(color: green, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: green, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MAIN BUTTON ====================
  Widget _buildMainButton() {
    if (!isSignLanguage) {
      // Voice Recording Button
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
                color: (_isRecording ? const Color(0xFFE24C4B) : green)
                    .withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: _isProcessing
              ? const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          )
              : Icon(
            _isRecording ? Icons.stop : Icons.mic,
            color: Colors.white,
            size: 40,
          ),
        ),
      );
    } else {
      // Sign Language Camera Button (placeholder)
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: navy,
        ),
        child: const Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 40,
        ),
      );
    }
  }
}