import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/language_detector.dart';
import '../../ai_tutor/data/models/explanation_session_model.dart';

class ResearchRepository {
  final Dio _dio;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<String> _geminiModels = [
    'gemini-3.8-flash',
    'gemini-3.5-flash-lite',
  ];

  ResearchRepository(this._dio);

  String _errorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      return (data['error'] as Map)['message']?.toString() ?? error.message ?? 'خطأ غير معروف';
    }
    if (data is String && data.isNotEmpty) return data;
    return error.message ?? 'تعذر الاتصال بالخادم';
  }

  Future<String> _generateTextWithFallback(String prompt) async {
    final geminiKey = (dotenv.env['GEMINI_API_KEY'] ?? '').trim();
    Object? lastError;

    if (geminiKey.isNotEmpty) {
      for (final model in _geminiModels) {
        try {
          debugPrint('Research trying Gemini: $model');
          final response = await _dio.post(
            '${ApiConstants.geminiBaseUrl}/$model:generateContent',
            options: Options(
              sendTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 90),
              headers: {
                'x-goog-api-key': geminiKey,
                'Content-Type': 'application/json',
              },
            ),
            data: {
              'contents': [
                {'role': 'user', 'parts': [{'text': prompt}]},
              ],
              'generationConfig': {
                'thinkingConfig': {'thinkingLevel': 'LOW'},
              },
            },
          );
          final data = response.data;
          if (data is! Map) throw Exception('صيغة رد Gemini غير صحيحة.');
          final candidates = data['candidates'] as List? ?? const [];
          final content = candidates.isNotEmpty && candidates.first is Map
              ? candidates.first['content']
              : null;
          final parts = content is Map ? content['parts'] as List? ?? const [] : const [];
          final generated = parts
              .whereType<Map>()
              .map((part) => part['text']?.toString() ?? '')
              .join()
              .trim();
          if (generated.isNotEmpty) return generated;
          throw Exception('لم يرجع Gemini نصًا للبحث.');
        } catch (error) {
          lastError = error;
          debugPrint('Research Gemini $model failed: $error');
        }
      }
    } else {
      lastError = Exception('مفتاح Gemini غير مضبوط.');
    }

    final groqKey = (dotenv.env['GROQ_API_KEY'] ?? '').trim();
    if (groqKey.isEmpty) {
      throw Exception('تعذر إنشاء البحث عبر Gemini، ومفتاح Groq غير مضبوط. التفاصيل: $lastError');
    }
    try {
      final response = await _dio.post(
        ApiConstants.groqChatUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
          headers: {
            'Authorization': 'Bearer $groqKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': ApiConstants.groqTextModel,
          'messages': [{'role': 'user', 'content': prompt}],
          'stream': false,
        },
      );
      final data = response.data;
      final choices = data is Map ? data['choices'] as List? ?? const [] : const [];
      final message = choices.isNotEmpty && choices.first is Map ? choices.first['message'] : null;
      final generated = message is Map ? message['content']?.toString().trim() ?? '' : '';
      if (generated.isEmpty) throw Exception('لم يرجع Groq نصًا للبحث.');
      return generated;
    } on DioException catch (error) {
      throw Exception('فشل Groq (${error.response?.statusCode ?? 'اتصال'}): ${_errorMessage(error)}');
    }
  }

  Future<ExplanationSessionModel> performResearch({
    required String libraryId,
    required String topic,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('يرجى تسجيل الدخول أولاً لحفظ البحث.');
    final normalizedTopic = topic.trim();
    if (normalizedTopic.isEmpty) throw Exception('اكتب موضوع البحث أولاً.');

    final tavilyKey = (dotenv.env['TAVILY_API_KEY'] ?? '').trim();
    if (tavilyKey.isEmpty) throw Exception('مفتاح Tavily غير مضبوط في assets/app.env');

    final language = LanguageDetector.detectLanguage(normalizedTopic);
    try {
      final searchResponse = await _dio.post(
        ApiConstants.tavilySearchEndpoint,
        options: Options(
          sendTimeout: const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'Authorization': 'Bearer $tavilyKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'query': normalizedTopic,
          'search_depth': 'advanced',
          'max_results': 5,
          'include_answer': false,
        },
      );

      final responseData = searchResponse.data;
      if (responseData is! Map) throw Exception('استجابة Tavily غير مفهومة.');
      final results = responseData['results'] as List? ?? const [];
      final List<Map<String, String>> sources = [];
      final context = StringBuffer();

      for (final raw in results) {
        if (raw is! Map) continue;
        final title = raw['title']?.toString().trim() ?? '';
        final url = raw['url']?.toString().trim() ?? '';
        final content = raw['content']?.toString().trim() ?? '';
        final parsedUri = Uri.tryParse(url);
        if (title.isEmpty || parsedUri == null || !parsedUri.hasScheme ||
            (parsedUri.scheme != 'https' && parsedUri.scheme != 'http')) {
          continue;
        }
        sources.add({'title': title, 'url': url});
        context.writeln('[${sources.length}] $title ($url): $content');
      }

      if (sources.isEmpty) {
        throw Exception('لم يعثر Tavily على مصادر صالحة. جرّب صياغة موضوع البحث بشكل مختلف.');
      }

      final prompt = AppStrings.buildResearchPrompt(
        normalizedTopic,
        language,
        context.toString(),
      );
      final researchText = await _generateTextWithFallback(prompt);

      final session = ExplanationSessionModel(
        id: '',
        type: 'research',
        title: normalizedTopic,
        inputText: normalizedTopic,
        aiResponse: researchText,
        language: language,
        sources: sources,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(ApiConstants.usersCollection)
          .doc(user.uid)
          .collection(ApiConstants.librariesCollection)
          .doc(libraryId)
          .collection(ApiConstants.sessionsCollection)
          .add(session.toMap());

      return ExplanationSessionModel(
        id: docRef.id,
        type: session.type,
        title: session.title,
        inputText: session.inputText,
        aiResponse: session.aiResponse,
        language: session.language,
        sources: session.sources,
        createdAt: session.createdAt,
      );
    } on DioException catch (error) {
      debugPrint('Research API error (${error.response?.statusCode}): ${_errorMessage(error)}');
      throw Exception('فشل البحث (${error.response?.statusCode ?? 'اتصال'}): ${_errorMessage(error)}');
    }
  }
}
