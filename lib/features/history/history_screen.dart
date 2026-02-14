import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static const Color green = Color(0xFF44B65E);
  static const Color blue = Color(0xFF273D8B);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<String> _items = [
    "Hello, How are you",
    "What's your name?",
    "Are you hungry?",
    "my",
    "1 2 3 4 5 6 7 8 9",
    "A B C D E F G",
    "Hello, How are you",
    "What's your name?",
    "Are you hungry?",
    "my",
    "1 2 3 4 5 6 7 8 9",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ألوان مرنة حسب الثيم
    final titleMuted = isDark ? Colors.white70 : const Color(0xFF9AA3AD);
    final clearDisabled = isDark ? Colors.white30 : const Color(0xFFB9C0C9);
    final clearEnabled = isDark ? Colors.white : HistoryScreen.blue;

    final cardColor = theme.cardColor;
    final shadowColor = Colors.black.withOpacity(isDark ? 0.22 : 0.06);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            const SizedBox(height: 18),

            // Header row (زي ما هو)
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: titleMuted),
                const SizedBox(width: 6),
                Text(
                  "Translate History",
                  style: TextStyle(
                    fontSize: 12,
                    color: titleMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _items.isEmpty ? null : () => setState(() => _items.clear()),
                  child: Text(
                    "Clear All",
                    style: TextStyle(
                      fontSize: 12,
                      color: _items.isEmpty ? clearDisabled : clearEnabled,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ✅ Card بنفس شكل settings
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _items.isEmpty
                    ? Center(
                  child: Text(
                    "No history yet",
                    style: TextStyle(
                      color: titleMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => _divider(context),
                  itemBuilder: (context, index) {
                    return _historyTile(
                      context: context,
                      text: _items[index],
                      onRemove: () => setState(() => _items.removeAt(index)),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static Widget _divider(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    color: Theme.of(context).dividerColor.withOpacity(0.35),
  );

  Widget _historyTile({
    required BuildContext context,
    required String text,
    required VoidCallback onRemove,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : HistoryScreen.blue);
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF8B95A1);

    return InkWell(
      onTap: () {}, // مفيش أكشن دلوقتي (UI بس)
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            // ✅ أيقونة زي settings
            const Icon(Icons.translate_rounded, color: HistoryScreen.green, size: 22),
            const SizedBox(width: 14),

            // ✅ Text block
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  color: titleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),


            const SizedBox(width: 10),

            // ✅ زر حذف بنفس روح الـ trailing في settings
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFEAF6EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: HistoryScreen.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
