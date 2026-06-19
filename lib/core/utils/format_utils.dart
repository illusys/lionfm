class FormatUtils {
  FormatUtils._();

  static String formatListeners(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  static String formatCurrency(int kobo) {
    final naira = kobo / 100;
    return '₦${naira.toStringAsFixed(2)}';
  }

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }

  static String initials(String name) {
    return name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
  }
}
