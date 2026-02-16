import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../services/voice_service.dart';
import '../../services/voice_models.dart';
import '../../shared/strings.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color green = Color(0xFF44B65E);
  static const Color navy = Color(0xFF1F2F6B);

  final _voiceService = VoiceService();
  final _tts = FlutterTts();

  List<VoiceTranscription> _items = [];
  bool _isLoading = false;
  bool _showArabic = true; // Toggle between Arabic and English
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadHistory();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _initTts() {
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.5);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  // ==================== LOAD HISTORY ====================
  Future<void> _loadHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔵 Loading history...');

      final response = await _voiceService.getHistory();

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _items = response.data;
          _isLoading = false;
        });

        print('✅ Loaded ${_items.length} items');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message ??
              S.t(context, 'Failed to load history', 'فشل تحميل السجل');
        });
      }
    } catch (e) {
      print('❌ History Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = S.t(
            context,
            'An error occurred while loading history',
            'حدث خطأ أثناء تحميل السجل',
          );
        });
      }
    }
  }

  // ==================== DELETE ITEM ====================
  Future<void> _deleteItem(int index) async {
    final item = _items[index];

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.t(context, 'Delete Item', 'حذف العنصر')),
        content: Text(
          S.t(
            context,
            'Are you sure you want to delete this item?',
            'هل أنت متأكد من حذف هذا العنصر؟',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.t(context, 'Cancel', 'إلغاء')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              S.t(context, 'Delete', 'حذف'),
              style: const TextStyle(color: Color(0xFFE24C4B)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Optimistically remove from UI
    setState(() {
      _items.removeAt(index);
    });

    // Try to delete from backend
    final success = await _voiceService.deleteTranscription(item.voiceId);

    if (!success) {
      // Revert if failed
      setState(() {
        _items.insert(index, item);
      });

      _showSnackBar(
        S.t(context, 'Failed to delete item', 'فشل حذف العنصر'),
        isError: true,
      );
    } else {
      _showSnackBar(
        S.t(context, 'Item deleted', 'تم حذف العنصر'),
      );
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
        title: Text(S.t(context, 'History', 'السجل')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Language Toggle Button
          IconButton(
            onPressed: () {
              setState(() {
                _showArabic = !_showArabic;
              });
            },
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: green, width: 1.5),
              ),
              child: Text(
                _showArabic ? 'AR' : 'EN',
                style: TextStyle(
                  color: green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            tooltip: S.t(
              context,
              'Toggle Language',
              'تبديل اللغة',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading && _items.isEmpty) {
      // Initial loading
      return const Center(
        child: CircularProgressIndicator(color: green),
      );
    }

    if (_errorMessage != null && _items.isEmpty) {
      // Error state
      return _buildErrorState();
    }

    if (_items.isEmpty) {
      // Empty state
      return _buildEmptyState();
    }

    // List with pull-to-refresh
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: green,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _historyTile(_items[index], index, isDark);
        },
      ),
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            S.t(context, 'No history yet', 'لا يوجد سجل بعد'),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.t(
              context,
              'Start recording to see your transcriptions here',
              'ابدأ التسجيل لرؤية النصوص هنا',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ERROR STATE ====================
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: const Color(0xFFE24C4B),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage ?? S.t(context, 'An error occurred', 'حدث خطأ'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              S.t(context, 'Retry', 'إعادة المحاولة'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HISTORY TILE ====================
  Widget _historyTile(VoiceTranscription item, int index, bool isDark) {
    final text = _showArabic ? item.transcriptedTextAr : item.transcriptedTextEn;
    final lang = _showArabic ? 'ar' : 'en';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Date & Delete)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.getFormattedDate(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                onPressed: () => _deleteItem(index),
                icon: const Icon(Icons.delete_outline, size: 20),
                color: const Color(0xFFE24C4B),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Text Content
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _miniButton(
                icon: Icons.copy,
                onTap: () => _copyText(text),
              ),
              const SizedBox(width: 8),
              _miniButton(
                icon: Icons.volume_up,
                onTap: () => _speakText(text, lang),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: green, width: 1),
        ),
        child: Icon(icon, color: green, size: 16),
      ),
    );
  }
}