import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_helper.dart';
import 'models/explanation_session_model.dart';
import 'models/youtube_video_model.dart';

class AiTutorRepository {
  final Dio _dio;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<String> _geminiModels = [
    'gemini-3.8-flash',
  ];

  AiTutorRepository(this._dio);

  String _serverError(DioException error) {
    final data = error.response?.data;
    if (data is ResponseBody) return 'تعذر قراءة تفاصيل رد الخادم';
    if (data is Map) {
      final errorObject = data['error'];
      if (errorObject is Map) {
        return errorObject['message']?.toString() ?? error.message ?? 'خطأ غير معروف';
      }
    }
    if (data is String && data.isNotEmpty) return data;
    return error.message ?? 'تعذر الاتصال بالخادم';
  }

  String _sanitizeMathText(String text) {
    return text
        .replaceAll(r'$$', '')
        .replaceAll(r'$', '')
        .replaceAllMapped(RegExp(r'\\text\{([^}]*)\}'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'\\overline\{([^}]*)\}'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'\\sqrt\{([^}]*)\}'), (m) => '√(${m.group(1) ?? ''})')
        .replaceAllMapped(RegExp(r'\\frac\{([^}]*)\}\{([^}]*)\}'), (m) => '(${m.group(1)} ÷ ${m.group(2)})')
        .replaceAll(r'\triangle', '△')
        .replaceAll(r'\angle', '∠')
        .replaceAll(r'^\circ', '°')
        .replaceAll(r'\circ', '°')
        .replaceAll(r'\times', '×')
        .replaceAll(r'\div', '÷')
        .replaceAll(r'\approx', '≈')
        .replaceAll(r'\neq', '≠')
        .replaceAll(r'\leq', '≤')
        .replaceAll(r'\geq', '≥');
  }

  String _extractCleanTitle(String explanation, String? userNote, String language) {
    final lines = explanation
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'^[#*>\-\s]+'), '').replaceAll('**', '').trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final greetingPattern = RegExp(
      r'^(أهلاً|مرحباً|بصفتي|سأقوم|بالطبع|hello|hi\b|welcome|sure|here is)',
      caseSensitive: false,
    );

    String candidate = '';
    for (final line in lines) {
      if (!greetingPattern.hasMatch(line) && line.length >= 3) {
        candidate = line;
        break;
      }
    }

    if (candidate.isEmpty && userNote != null && userNote.trim().isNotEmpty) {
      candidate = userNote.trim().split('\n').first.trim();
    }

    if (candidate.isEmpty) {
      return language == 'ar' ? 'شرح وحل محتوى علمي' : 'Academic Explanation & Solution';
    }

    return candidate.length > 55 ? '${candidate.substring(0, 55)}…' : candidate;
  }

  Stream<String> _readGroqStream({
    required String prompt,
    File? imageFile,
    String? imageMimeType,
    String? imageBase64,
  }) async* {
    final key = (dotenv.env['GROQ_API_KEY'] ?? '').trim();
    if (key.isEmpty) throw Exception('مفتاح Groq غير مضبوط في assets/app.env');

    final isVision = imageFile != null;
    if (isVision && (imageMimeType == null || imageBase64 == null)) {
      throw Exception('تعذر تجهيز الصورة لإرسالها إلى نموذج الرؤية.');
    }

    final messageContent = isVision
        ? [
      {'type': 'text', 'text': prompt},
      {
        'type': 'image_url',
        'image_url': {'url': 'data:$imageMimeType;base64,$imageBase64'},
      },
    ]
        : prompt;

    final model = isVision ? ApiConstants.groqVisionModel : ApiConstants.groqTextModel;
    debugPrint('ClarifyAI fallback provider: Groq ($model)');

    try {
      final response = await _dio.post(
        ApiConstants.groqChatUrl,
        options: Options(
          responseType: ResponseType.stream,
          connectTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 90),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': model,
          'stream': true,
          'temperature': 0.3,
          'messages': [
            {'role': 'user', 'content': messageContent},
          ],
        },
      );

      final stream = (response.data as ResponseBody).stream;
      final lines = stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      final buffer = StringBuffer();
      await for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        final payload = trimmed.substring(5).trim();
        if (payload.isEmpty || payload == '[DONE]') continue;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is! Map<String, dynamic>) continue;
          final choices = decoded['choices'] as List? ?? const [];
          if (choices.isEmpty) continue;
          final choice = choices.first;
          if (choice is! Map) continue;
          final delta = choice['delta'];
          final content = delta is Map ? delta['content'] : null;
          if (content is String && content.isNotEmpty) {
            buffer.write(content);
            yield buffer.toString();
          }
        } on FormatException catch (error) {
          debugPrint('Skipping incomplete Groq SSE event: $error');
        }
      }
      if (buffer.isEmpty) throw Exception('أعاد Groq استجابة فارغة.');
    } on DioException catch (error) {
      debugPrint('Groq request failed (${error.response?.statusCode}): ${_serverError(error)}');
      throw Exception('فشل Groq (${error.response?.statusCode ?? 'اتصال'}): ${_serverError(error)}');
    }
  }

  Stream<String> explainContentStream({
    required String libraryId,
    File? file,
    String? userText,
    String preferredLanguage = 'ar',
    required void Function(ExplanationSessionModel savedSession) onCompleted,
  }) async* {
    final user = _auth.currentUser;
    if (user == null) throw Exception('يرجى تسجيل الدخول أولاً لحفظ الجلسة.');
    if ((userText == null || userText.trim().isEmpty) && file == null) {
      throw Exception('أدخل نصًا أو اختر صورة أو ملف PDF أولاً.');
    }

    final language = preferredLanguage == 'ar' ? 'ar' : 'en';
    final note = userText?.trim();
    final prompt = AppStrings.buildExplainPrompt(language, note);

    String? mimeType;
    String? base64Data;
    if (file != null) {
      mimeType = FileHelper.getMimeType(file.path);
      final isPdf = mimeType == 'application/pdf';
      if (!isPdf && !mimeType.startsWith('image/')) {
        throw Exception('نوع الملف غير مدعوم. استخدم صورة أو ملف PDF.');
      }
      final bytes = await FileHelper.fileToBytes(file);
      if (bytes.isEmpty) throw Exception('الملف المحدد فارغ.');
      if (bytes.length > 18 * 1024 * 1024) {
        throw Exception('حجم الملف أكبر من 18 MB. قلّل حجمه ثم حاول مرة أخرى.');
      }
      base64Data = base64Encode(bytes);
    }

    final geminiKey = (dotenv.env['GEMINI_API_KEY'] ?? '').trim();
    final buffer = StringBuffer();
    Object? geminiFailure;

    if (geminiKey.isNotEmpty) {
      for (final model in _geminiModels) {
        try {
          debugPrint('ClarifyAI trying Gemini model: $model');
          final List parts = [
    {'text': prompt},
    ];
    if (base64Data != null && mimeType != null) {
    parts.add({
    'inlineData': {'mimeType': mimeType, 'data': base64Data},
    });
    }

    final body = <String, dynamic>{
    'contents': [
    {'role': 'user', 'parts': parts},
    ],
    'generationConfig': {
    'temperature': 0.3,
    if (model.startsWith('gemini-3'))
    'thinkingConfig': {'thinkingLevel': 'LOW'},
    },
    };

    final response = await _dio.post(
    '${ApiConstants.geminiBaseUrl}/$model:streamGenerateContent?alt=sse',
    options: Options(
    responseType: ResponseType.stream,
    connectTimeout: const Duration(seconds: 6),
    sendTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 45),
    headers: {
    'x-goog-api-key': geminiKey,
    'Content-Type': 'application/json',
    },
    ),
    data: body,
    );

    final stream = (response.data as ResponseBody).stream;
    final lines = stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('data:')) continue;
    final payload = trimmed.substring(5).trim();
    if (payload.isEmpty || payload == '[DONE]') continue;
    try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) continue;
    final candidates = decoded['candidates'] as List? ?? const [];
    if (candidates.isEmpty || candidates.first is! Map) continue;
    final content = candidates.first['content'];
    final responseParts = content is Map ? content['parts'] as List? ?? const [] : const [];
    for (final part in responseParts) {
    if (part is Map && part['text'] is String) {
    buffer.write(part['text'] as String);
    }
    }
    if (buffer.isNotEmpty) {
    final fullText = buffer.toString();
    final keywordIndex = fullText.lastIndexOf('KEYWORDS:');
    final visibleText = keywordIndex >= 0
    ? fullText.substring(0, keywordIndex).trim()
        : fullText;
    yield _sanitizeMathText(visibleText);
    }
    } on FormatException catch (error) {
    debugPrint('Skipping incomplete Gemini SSE event: $error');
    }
    }
    if (buffer.isNotEmpty) break;
    geminiFailure = Exception('أعاد Gemini استجابة فارغة.');
    } catch (error) {
    geminiFailure = error;
    buffer.clear();
    debugPrint('Gemini model $model failed quickly: $error');
    }
    }
    } else {
    geminiFailure = Exception('مفتاح Gemini غير مضبوط.');
    }

    if (buffer.isEmpty) {
    final isImage = mimeType != null && mimeType.startsWith('image/');
    if (mimeType == 'application/pdf') {
    throw Exception('تعذرت معالجة ملف PDF عبر Gemini، ولا يدعم مسار Groq الاحتياطي ملفات PDF مباشرة. التفاصيل: $geminiFailure');
    }
    await for (final groqText in _readGroqStream(
    prompt: prompt,
    imageFile: isImage ? file : null,
    imageMimeType: isImage ? mimeType : null,
    imageBase64: isImage ? base64Data : null,
    )) {
    buffer
    ..clear()
    ..write(groqText);
    final keywordIndex = groqText.lastIndexOf('KEYWORDS:');
    final visibleText = keywordIndex >= 0
    ? groqText.substring(0, keywordIndex).trim()
        : groqText;
    yield _sanitizeMathText(visibleText);
    }
    }

    final rawText = buffer.toString().trim();
    if (rawText.isEmpty) throw Exception('لم يصل رد من Gemini أو Groq. تحقق من المفاتيح والاتصال ثم أعد المحاولة.');

    var explanation = rawText;
    final keywords = <String>[];
    final keywordIndex = rawText.lastIndexOf('KEYWORDS:');
    if (keywordIndex >= 0) {
    explanation = rawText.substring(0, keywordIndex).trim();
    keywords.addAll(
    rawText.substring(keywordIndex + 'KEYWORDS:'.length)
        .split(RegExp(r'[,،\n]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .take(5),
    );
    }

    explanation = _sanitizeMathText(explanation);
    final title = _extractCleanTitle(explanation, note, language);
    final session = ExplanationSessionModel(
    id: '',
    type: 'explanation',
    title: title,
    inputText: note?.isNotEmpty == true ? note! : (file == null ? '' : 'محتوى مرفق (صورة / PDF)'),
    attachmentUrl: null,
    aiResponse: explanation,
    language: language,
    keywords: keywords,
    createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(user.uid)
        .collection(ApiConstants.librariesCollection)
        .doc(libraryId)
        .collection(ApiConstants.sessionsCollection)
        .add(session.toMap());

    onCompleted(ExplanationSessionModel(
    id: docRef.id,
    type: session.type,
    title: session.title,
    inputText: session.inputText,
    attachmentUrl: session.attachmentUrl,
    aiResponse: session.aiResponse,
    language: session.language,
    keywords: session.keywords,
    createdAt: session.createdAt,
    ));
  }

  Future<List<YoutubeVideoModel>> fetchSuggestedVideos({
    required String libraryId,
    required String sessionId,
    required List<String> keywords,
    required String languageCode,
  }) async {
    final key = (dotenv.env['YOUTUBE_API_KEY'] ?? '').trim();
    if (key.isEmpty) throw Exception('مفتاح YouTube API غير مضبوط في assets/app.env');
    if (_auth.currentUser == null) throw Exception('انتهت جلسة الدخول. سجّل الدخول مجددًا.');

    final lang = languageCode == 'ar' ? 'ar' : 'en';
    final terms = keywords.map((item) => item.trim()).where((item) => item.isNotEmpty).take(5).join(' ');
    final query = terms.isEmpty ? (lang == 'ar' ? 'شرح علمي مبسط' : 'simple academic explanation') : '$terms ${lang == 'ar' ? 'شرح' : 'explained'}';

    try {
      final response = await _dio.get(
        ApiConstants.youtubeSearchEndpoint,
        queryParameters: {
          'part': 'snippet',
          'q': query,
          'type': 'video',
          'maxResults': 3,
          'relevanceLanguage': lang,
          'order': 'relevance',
          'safeSearch': 'moderate',
          'key': key,
        },
      );
      final data = response.data;
      if (data is! Map) throw Exception('استجابة YouTube غير مفهومة.');
      final items = data['items'] as List? ?? const [];
      final videos = items
          .whereType()
          .map((item) => YoutubeVideoModel.fromYoutubeApi(Map<String, dynamic>.from(item)))
          .where((video) => video.videoId.isNotEmpty)
          .take(3)
          .toList();

      if (sessionId.isNotEmpty && videos.isNotEmpty) {
        final userId = _auth.currentUser!.uid;
        await _firestore
            .collection(ApiConstants.usersCollection)
            .doc(userId)
            .collection(ApiConstants.librariesCollection)
            .doc(libraryId)
            .collection(ApiConstants.sessionsCollection)
            .doc(sessionId)
            .update({'youtubeVideos': videos.map((video) => video.toMap()).toList()});
      }
      if (videos.isEmpty) throw Exception('لم يعثر YouTube على فيديوهات مناسبة لهذه الكلمات.');
      return videos;
    } on DioException catch (error) {
      final message = _serverError(error);
      debugPrint('YouTube API error (${error.response?.statusCode}): $message');
      throw Exception('فشل YouTube (${error.response?.statusCode ?? 'اتصال'}): $message');
    }
  }
}