import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/ai_tutor_repository.dart';
import '../data/models/explanation_session_model.dart';
import '../data/models/youtube_video_model.dart';

abstract class AiTutorState {}
class AiTutorInitial extends AiTutorState {}
class AiTutorLoading extends AiTutorState {}
class AiTutorExplained extends AiTutorState {
  final ExplanationSessionModel session;
  final List<YoutubeVideoModel> videos;
  final bool isLoadingVideos;

  AiTutorExplained({
    required this.session,
    this.videos = const [],
    this.isLoadingVideos = false,
  });
}
class AiTutorError extends AiTutorState {
  final String message;
  AiTutorError(this.message);
}

class AiTutorCubit extends Cubit<AiTutorState> {
  final AiTutorRepository _repository;

  AiTutorCubit(this._repository) : super(AiTutorInitial());

  Future<void> explain({
    required String libraryId,
    File? file,
    String? userText,
    String preferredLanguage = 'ar',
  }) async {
    emit(AiTutorLoading());
    try {
      final session = await _repository.explainContent(
        libraryId: libraryId,
        file: file,
        userText: userText,
        preferredLanguage: preferredLanguage,
      );
      emit(AiTutorExplained(session: session));
    } catch (e) {
      emit(AiTutorError('حدث خطأ أثناء الشرح: $e'));
    }
  }

  /// استدعاء أفضل 3 فيديوهات يوتيوب عند ضغط الطالب على "لم أفهم"
  Future<void> getYoutubeSuggestions(String libraryId) async {
    final currentState = state;
    if (currentState is AiTutorExplained) {
      emit(AiTutorExplained(
        session: currentState.session,
        videos: currentState.videos,
        isLoadingVideos: true,
      ));
      try {
        final videos = await _repository.fetchSuggestedVideos(
          libraryId: libraryId,
          sessionId: currentState.session.id,
          keywords: currentState.session.keywords,
          languageCode: currentState.session.language,
        );
        emit(AiTutorExplained(
          session: currentState.session,
          videos: videos,
          isLoadingVideos: false,
        ));
      } catch (e) {
        emit(AiTutorExplained(
          session: currentState.session,
          isLoadingVideos: false,
        ));
      }
    }
  }
}