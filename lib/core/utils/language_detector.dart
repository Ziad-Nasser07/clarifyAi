class LanguageDetector {
  /// يحدد ما إذا كان النص يغلب عليه اللغة العربية أم الإنجليزية
  static String detectLanguage(String text) {
    if (text.trim().isEmpty) return 'en';
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    final arabicMatches = arabicRegex.allMatches(text).length;
    return arabicMatches > (text.length * 0.2) ? 'ar' : 'en';
  }
}