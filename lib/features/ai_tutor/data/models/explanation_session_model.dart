import 'package:cloud_firestore/cloud_firestore.dart';
import 'youtube_video_model.dart';

class ExplanationSessionModel {
  final String id;
  final String type;
  final String title;
  final String inputText;
  final String? attachmentUrl;
  final String aiResponse;
  final String language;
  final List<String> keywords;
  final List<YoutubeVideoModel> youtubeVideos;
  final List sources;
  final DateTime createdAt;

  ExplanationSessionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.inputText,
    this.attachmentUrl,
    required this.aiResponse,
    required this.language,
    this.keywords = const [],
    this.youtubeVideos = const [],
    this.sources = const [],
    required this.createdAt,
  });

  factory ExplanationSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExplanationSessionModel(
      id: doc.id,
      type: data['type'] ?? 'explanation',
      title: data['title'] ?? 'شرح جديد',
      inputText: data['inputText'] ?? '',
      attachmentUrl: data['attachmentUrl'],
      aiResponse: data['aiResponse'] ?? '',
      language: data['language'] ?? 'ar',
      keywords: List<String>.from(data['keywords'] ?? []),
      youtubeVideos: (data['youtubeVideos'] as List? ?? [])
          .map((v) => YoutubeVideoModel.fromMap(Map<String, dynamic>.from(v)))
          .toList(),
      sources: (data['sources'] as List? ?? [])
          .map((s) => Map<String, String>.from(s))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'inputText': inputText,
      'attachmentUrl': attachmentUrl,
      'aiResponse': aiResponse,
      'language': language,
      'keywords': keywords,
      'youtubeVideos': youtubeVideos.map((v) => v.toMap()).toList(),
      'sources': sources,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}