// ── lib/screens/history/history_screen.dart ───────────────────────────────────
// Updated: shows BOTH voice history and sign history in one unified list

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../services/voice_service.dart';
import '../../services/voice_models.dart';
import '../../services/sign_service.dart';
import '../../services/sign_models.dart';
import '../../shared/strings.dart';

// Unified item to hold either voice or sign transcription
class _HistoryItem {
  final bool   isSign;
  final int    id;
  final String textEn;
  final String textAr;
  final DateTime date;

  _HistoryItem({
    required this.isSign,
    required this.id,
    required this.textEn,
    required this.textAr,
    required this.date,
  });

  String getFormattedDate() =>
      '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color green = Color(0xFF44B65E);
  static const Color navy  = Color(0xFF1F2F6B);

  final _voiceService = VoiceService();
  final _signService  = SignService();
  final _tts          = FlutterTts();

  List<_HistoryItem> _items     = [];
  bool               _isLoading = false;
  bool               _showArabic = true;
  String?            _errorMessage;

  // Filter: 'all' | 'sign' | 'voice'
  String _filter = 'all';

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

  // ══════════════════════════════════════════════════════════════════════════
  //  Load both histories in parallel, merge and sort by date
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      // Load voice and sign history simultaneously
      final results = await Future.wait([
        _voiceService.getHistory(),
        _signService.getSignHistory(),
      ]);

      final voiceResponse = results[0] as dynamic;
      final signResponse  = results[1] as SignApiResponse<List<SignTranscription>>;

      final List<_HistoryItem> items = [];

      // Add voice items
      if (voiceResponse.success && voiceResponse.data != null) {
        for (final v in voiceResponse.data as List<VoiceTranscription>) {
          items.add(_HistoryItem(
            isSign : false,
            id     : v.voiceId,
            textEn : v.transcriptedTextEn,
            textAr : v.transcriptedTextAr,
            date   : v.date,
          ));
        }
      }

      // Add sign items
      if (signResponse.success && signResponse.data != null) {
        for (final s in signResponse.data!) {
          items.add(_HistoryItem(
            isSign : true,
            id     : s.signId,
            textEn : s.transcriptedTextEn,
            textAr : s.transcriptedTextAr,
            date   : s.date,
          ));
        }
      }

      // Sort newest first
      items.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() { _items = items; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading    = false;
        _errorMessage = S.t(context, 'An error occurred while loading history', 'حدث خطأ أثناء تحميل السجل');
      });
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> _deleteItem(int index) async {
    final item = _items[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title  : Text(S.t(context, 'Delete Item', 'حذف العنصر')),
        content: Text(S.t(context, 'Are you sure you want to delete this item?', 'هل أنت متأكد من حذف هذا العنصر؟')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(S.t(context, 'Cancel', 'إلغاء'))),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: Text(S.t(context, 'Delete', 'حذف'), style: const TextStyle(color: Color(0xFFE24C4B)))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _items.removeAt(index));

    // Call the correct delete endpoint based on item type
    final success = item.isSign
        ? await _signService.deleteSign(item.id)
        : await _voiceService.deleteTranscription(item.id);

    if (!success) {
      setState(() => _items.insert(index, item));
      _showSnackBar(S.t(context, 'Failed to delete item', 'فشل حذف العنصر'), isError: true);
    } else {
      _showSnackBar(S.t(context, 'Item deleted', 'تم حذف العنصر'));
    }
  }

  // ── TTS & copy ─────────────────────────────────────────────────────────────
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

  // ── Filtered items ─────────────────────────────────────────────────────────
  List<_HistoryItem> get _filteredItems {
    if (_filter == 'sign')  return _items.where((i) => i.isSign).toList();
    if (_filter == 'voice') return _items.where((i) => !i.isSign).toList();
    return _items;
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
        title          : Text(S.t(context, 'History', 'السجل')),
        backgroundColor: Colors.transparent,
        elevation      : 0,
        actions: [
          // Language toggle
          IconButton(
            onPressed: () => setState(() => _showArabic = !_showArabic),
            icon     : Container(
              padding   : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: green.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: green, width: 1.5)),
              child     : Text(_showArabic ? 'AR' : 'EN', style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),
          // Content
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  // ── Filter chips: All / Sign / Voice ──────────────────────────────────────
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip('all',   S.t(context, 'All', 'الكل')),
          const SizedBox(width: 8),
          _filterChip('sign',  S.t(context, 'Sign', 'إشارة')),
          const SizedBox(width: 8),
          _filterChip('voice', S.t(context, 'Voice', 'صوت')),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding   : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color       : selected ? green : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border      : Border.all(color: selected ? green : Colors.grey.shade400),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody(bool isDark) {
    if (_isLoading && _items.isEmpty) return const Center(child: CircularProgressIndicator(color: green));
    if (_errorMessage != null && _items.isEmpty) return _buildErrorState();
    if (_filteredItems.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color    : green,
      child    : ListView.separated(
        padding          : const EdgeInsets.all(16),
        itemCount        : _filteredItems.length,
        separatorBuilder : (_, __) => const SizedBox(height: 12),
        itemBuilder      : (context, index) => _historyTile(_filteredItems[index], index, isDark),
      ),
    );
  }

  // ── History tile ───────────────────────────────────────────────────────────
  Widget _historyTile(_HistoryItem item, int index, bool isDark) {
    final text = _showArabic ? item.textAr : item.textEn;
    final lang = _showArabic ? 'ar' : 'en';

    return Container(
      padding   : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color       : isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow   : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Type badge
              Container(
                padding   : const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color       : item.isSign ? Colors.orange.withOpacity(0.1) : green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border      : Border.all(color: item.isSign ? Colors.orange : green, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.isSign ? Icons.sign_language : Icons.mic, size: 12, color: item.isSign ? Colors.orange : green),
                    const SizedBox(width: 4),
                    Text(
                      item.isSign ? S.t(context, 'Sign', 'إشارة') : S.t(context, 'Voice', 'صوت'),
                      style: TextStyle(fontSize: 11, color: item.isSign ? Colors.orange : green, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              // Date + delete
              Row(
                children: [
                  Text(item.getFormattedDate(), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _deleteItem(_items.indexOf(item)),
                    child: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFE24C4B)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Text
          Text(text, style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black87, height: 1.5)),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _miniButton(icon: Icons.copy,      onTap: () => _copyText(text)),
              const SizedBox(width: 8),
              _miniButton(icon: Icons.volume_up, onTap: () => _speakText(text, lang)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap        : onTap,
      borderRadius : BorderRadius.circular(8),
      child        : Container(
        padding   : const EdgeInsets.all(8),
        decoration: BoxDecoration(color: green.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: green, width: 1)),
        child     : Icon(icon, color: green, size: 16),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(S.t(context, 'No history yet', 'لا يوجد سجل بعد'), style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(S.t(context, 'Start recording to see your transcriptions here', 'ابدأ التسجيل لرؤية النصوص هنا'), textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Color(0xFFE24C4B)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child  : Text(_errorMessage ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadHistory,
            style    : ElevatedButton.styleFrom(backgroundColor: green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
            child    : Text(S.t(context, 'Retry', 'إعادة المحاولة'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
