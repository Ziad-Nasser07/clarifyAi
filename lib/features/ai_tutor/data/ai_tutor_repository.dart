import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_helper.dart';
import '../../../core/utils/language_detector.dart';
import 'models/explanation_session_model.dart';
import 'models/youtube_video_model.dart';

class AiTutorRepository {
  final Dio _dio;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AiTutorRepository(this._dio);

  Future<ExplanationSessionModel> explainContent({
    required String libraryId,
    File? file,
    String? userText,
    String preferredLanguage = 'ar',
  }) async {
    final userId = _auth.currentUser!.uid;
    final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    final detectedLang = (userText != null && userText.trim().isNotEmpty)
        ? LanguageDetector.detectLanguage(userText)
        : preferredLanguage;

    final prompt = AppStrings.buildExplainPrompt(detectedLang, userText);
    final dynamic parts = [
    {'text': prompt}
    ];
    String? uploadedFileUrl;

    if (file != null) {
    final bytes = await FileHelper.fileToBytes(file);
    final mimeType = FileHelper.getMimeType(file.path);
    final base64Data = base64Encode(bytes);

    parts.add({
    'inlineData': {
    'mimeType': mimeType,
    'data': base64Data,
    }
    });

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = _storage.ref().child('users/$userId/libraries/$libraryId/$fileName');
    await ref.putFile(file);
    uploadedFileUrl = await ref.getDownloadURL();
    }

    final response = await _dio.post(
    ApiConstants.geminiVertexUrl,
    queryParameters: {'key': geminiKey},
    data: {
    'contents': [
    {
    'role': 'user',
    'parts': parts,
    }
    ],
    },
    );

    final candidates = response.data['candidates'] as List? ?? [];
    final rawText = candidates.isNotEmpty
    ? (candidates[0]['content']['parts'][0]['text']?.toString() ?? '')
        : '';

    String cleanExplanation = rawText;
    var keywords = <String>[];

    if (rawText.contains('KEYWORDS:')) {
    final splitIndex = rawText.lastIndexOf('KEYWORDS:');
    cleanExplanation = rawText.substring(0, splitIndex).trim();
    final keywordsLine = rawText.substring(splitIndex + 9).trim();
    keywords = keywordsLine
        .split(RegExp(r'[,،]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    }

    final firstLine = cleanExplanation.split('\n').first.replaceAll('#', '').trim();
    final sessionTitle = firstLine.length > 45 ? '${firstLine.substring(0, 45)}...' : firstLine;

    final session = ExplanationSessionModel(
    id: '',
    type: 'explanation',
    title: sessionTitle.isEmpty ? 'شرح محتوى علمي' : sessionTitle,
    inputText: userText ?? 'محتوى مرفق (صورة / PDF)',
    attachmentUrl: uploadedFileUrl,
    aiResponse: cleanExplanation,
    language: detectedLang,
    keywords: keywords,
    createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.librariesCollection)
        .doc(libraryId)
        .collection(ApiConstants.sessionsCollection)
        .add(session.toMap());

    return ExplanationSessionModel(
    id: docRef.id,
    type: session.type,
    title: session.title,
    inputText: session.inputText,
    attachmentUrl: session.attachmentUrl,
    aiResponse: session.aiResponse,
    language: session.language,
    keywords: session.keywords,
    createdAt: session.createdAt,
    );
  }

  Future<List<YoutubeVideoModel>> fetchSuggestedVideos({
    required String libraryId,
    required String sessionId,
    required List<String> keywords,
    required String languageCode,
  }) async {
    final youtubeKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
    final searchQuery = keywords.isNotEmpty
        ? '${keywords.join(' ')} ${languageCode == 'ar' ? 'شرح' : 'explained'}'
        : 'scientific explanation';

    final response = await _dio.get(
      ApiConstants.youtubeSearchEndpoint,
      queryParameters: {
        'part': 'snippet',
        'q': searchQuery,
        'type': 'video',
        'maxResults': 3,
        'relevanceLanguage': languageCode,
        'order': 'relevance',
        'key': youtubeKey,
      },
    );

    final items = response.data['items'] as List? ?? [];
    final videos = items.map((item) => YoutubeVideoModel.fromYoutubeApi(item)).toList();

    final userId = _auth.currentUser!.uid;
    await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(userId)
        .collection(ApiConstants.librariesCollection)
        .doc(libraryId)
        .collection(ApiConstants.sessionsCollection)
        .doc(sessionId)
        .update({
      'youtubeVideos': videos.map((v) => v.toMap()).toList(),
    });

    return videos;
  }
}