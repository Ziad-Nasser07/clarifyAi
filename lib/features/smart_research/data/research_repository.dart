import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/language_detector.dart';
import '../../ai_tutor/data/models/explanation_session_model.dart';

class ResearchRepository {
  final Dio _dio;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ResearchRepository(this._dio);

  Future<ExplanationSessionModel> performResearch({
    required String libraryId,
    required String topic,
  }) async {
    final tavilyKey = dotenv.env['TAVILY_API_KEY'] ?? '';
    final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final languageCode = LanguageDetector.detectLanguage(topic);

    final searchResponse = await _dio.post(
      ApiConstants.tavilySearchEndpoint,
      data: {
        'api_key': tavilyKey,
        'query': topic,
        'search_depth': 'basic',
        'max_results': 5,
      },
    );

    final results = searchResponse.data['results'] as List? ?? [];
    final sourcesList = [];
    final sourcesContext = StringBuffer();

    for (int i = 0; i < results.length; i++) {
    final item = results[i];
    final title = item['title']?.toString() ?? 'مصدر ${i + 1}';
    final url = item['url']?.toString() ?? '';
    final content = item['content']?.toString() ?? '';

    sourcesList.add({'title': title, 'url': url});
    sourcesContext.writeln('[${i + 1}] $title ($url): $content');
    }

    final prompt = AppStrings.buildResearchPrompt(
    topic,
    languageCode,
    sourcesContext.toString(),
    );

    final aiResponse = await _dio.post(
    ApiConstants.geminiVertexUrl,
    queryParameters: {'key': geminiKey},
    data: {
    'contents': [
    {
    'role': 'user',
    'parts': [
    {'text': prompt}
    ],
    }
    ],
    },
    );

    final candidates = aiResponse.data['candidates'] as List? ?? [];
    final researchText = candidates.isNotEmpty
    ? (candidates[0]['content']['parts'][0]['text']?.toString() ?? '')
        : '';

    final session = ExplanationSessionModel(
    id: '',
    type: 'research',
    title: topic,
    inputText: topic,
    aiResponse: researchText,
    language: languageCode,
    sources: sourcesList,
    createdAt: DateTime.now(),
    );

    final userId = _auth.currentUser!.uid;
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
    aiResponse: session.aiResponse,
    language: session.language,
    sources: session.sources,
    createdAt: session.createdAt,
    );
  }
}