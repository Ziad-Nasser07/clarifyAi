class AppStrings {
  static const String appName = 'ClarifyAI';

  // أمر الشرح والتبسيط لـ Gemini
  static String buildExplainPrompt(String languageCode, String? userNote) {
    final isArabic = languageCode == 'ar';
    if (isArabic) {
      return '''
أنت مساعد تعليمي ذكي ومبسط للطلاب الجامعيين.
قم بتحليل المحتوى المرفق (صورة أو ملف أو نص) واشرحه باللغة العربية بأسلوب واضح، منظم، وبسيط جداً.
- قسم الشرح إلى عناوين رئيسية ونقاط واضحة.
- إذا كان هناك معادلات رياضية أو منطقية، اشرح خطوات حلها بالتفصيل.
- أعطِ مثالاً عملياً مبسطاً لتقريب الفكرة.
- في نهاية ردك تماماً، اكتب سطراً يبدأ بـ "KEYWORDS:" متبوعاً بأهم 3 كلمات مفتاحية علمية تصف موضوع الدرس بدقة (بنفس لغة المحتوى) لاستخدامها في البحث عن فيديوهات يوتيوب.
${userNote != null && userNote.isNotEmpty ? 'ملاحظة أو سؤال إضافي من الطالب: $userNote' : ''}
''';
    } else {
      return '''
You are an expert, student-friendly AI academic tutor.
Analyze the attached content (image, document, or text) and explain it in clear, structured, and simplified English.
- Break down complex concepts into clear headings and bullet points.
- If there are equations or logic problems, explain the solution step-by-step.
- Provide a simple real-world example to clarify the concept.
- At the very end of your response, add a single line starting with "KEYWORDS:" followed by the top 3 precise academic search keywords describing this topic (in English) to be used for YouTube video search.
${userNote != null && userNote.isNotEmpty ? 'Additional student question/note: $userNote' : ''}
''';
    }
  }

  // أمر صياغة البحث العلمي الموثق بالمصادر
  static String buildResearchPrompt(String topic, String languageCode, String sourcesContext) {
    final isArabic = languageCode == 'ar';
    if (isArabic) {
      return '''
اكتب بحثاً أكاديمياً مختصراً، دقيقاً، ومنظماً حول الموضوع التالي: "$topic".
اعتمد في معلوماتك على المصادر المرفقة أدناه فقط لضمان الدقة العلمية وعدم الاختلاق:
$sourcesContext

شروط التنسيق:
- اكتب البحث باللغة العربية الفصحى الواضحة بصيغة Markdown.
- قسم البحث إلى: مقدمة، المحاور الأساسية، وخاتمة.
- أشر إلى رقم المصدر [1]، [2]، إلخ داخل الفقرات عند ذكر معلومة منه.
''';
    } else {
      return '''
Write a concise, accurate, and well-structured academic research summary on the topic: "$topic".
Base your content strictly on the verified sources provided below to avoid hallucinations:
$sourcesContext

Formatting rules:
- Write in clear academic English using Markdown.
- Structure into: Introduction, Key Findings/Sections, and Conclusion.
- Cite sources inline using [1], [2], etc. where information is referenced.
''';
    }
  }
}