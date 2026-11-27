import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  final bool isStreaming;
  final String? videoError;

  AiTutorExplained({
    required this.session,
    this.videos = const [],
    this.isLoadingVideos = false,
    this.isStreaming = false,
    this.videoError,
  });
}
class AiTutorError extends AiTutorState {
  final String message;
  AiTutorError(this.message);
}

class AiTutorCubit extends Cubit<AiTutorState> {
  final AiTutorRepository _repository;
  StreamSubscription? _streamSubscription;

  AiTutorCubit(this._repository) : super(AiTutorInitial());

  Future<void> explain({
    required String libraryId,
    File? file,
    String? userText,
    String preferredLanguage = 'ar',
  }) async {
    if (state is AiTutorLoading) return;
    await _streamSubscription?.cancel();
    emit(AiTutorLoading());

    ExplanationSessionModel? finalSavedSession;
    DateTime lastEmitTime = DateTime.fromMillisecondsSinceEpoch(0);
    String latestText = '';

    final stream = _repository.explainContentStream(
      libraryId: libraryId,
      file: file,
      userText: userText,
      preferredLanguage: preferredLanguage,
      onCompleted: (savedSession) {
        finalSavedSession = savedSession;
      },
    );

    _streamSubscription = stream.listen(
          (partialText) {
        latestText = partialText.toString();
        final now = DateTime.now();

        if (now.difference(lastEmitTime).inMilliseconds < 100) return;
        lastEmitTime = now;

        final liveSession = ExplanationSessionModel(
          id: finalSavedSession?.id ?? '',
          type: 'explanation',
          title: 'جاري الشرح...',
          inputText: userText ?? 'محتوى مرفق (صورة / PDF)',
          attachmentUrl: null,
          aiResponse: latestText,
          language: preferredLanguage == 'ar' ? 'ar' : 'en',
          keywords: finalSavedSession?.keywords ?? [],
          createdAt: DateTime.now(),
        );

        emit(AiTutorExplained(
          session: liveSession,
          isStreaming: true,
        ));
      },
      onDone: () {
        if (finalSavedSession != null) {
          emit(AiTutorExplained(
            session: finalSavedSession!,
            isStreaming: false,
          ));
        } else if (state is AiTutorExplained) {
          final current = state as AiTutorExplained;
          final completedSession = ExplanationSessionModel(
            id: current.session.id,
            type: current.session.type,
            title: current.session.title,
            inputText: current.session.inputText,
            attachmentUrl: current.session.attachmentUrl,
            aiResponse: latestText.isNotEmpty ? latestText : current.session.aiResponse,
            language: current.session.language,
            keywords: current.session.keywords,
            createdAt: current.session.createdAt,
          );
          emit(AiTutorExplained(
            session: completedSession,
            isStreaming: false,
          ));
        }
      },
      onError: (e) {
        emit(AiTutorError('حدث خطأ أثناء الشرح: $e'));
      },
    );
  }

  Future<void> getYoutubeSuggestions(String libraryId) async {
    final currentState = state;
    if (currentState is AiTutorExplained &&
        !currentState.isStreaming &&
        !currentState.isLoadingVideos) {
      if (currentState.videos.isNotEmpty) return;

      emit(AiTutorExplained(
        session: currentState.session,
        videos: currentState.videos,
        isLoadingVideos: true,
      ));

      try {
        final effectiveKeywords = currentState.session.keywords.isNotEmpty
            ? currentState.session.keywords
            : [
          currentState.session.inputText.trim().isNotEmpty &&
              currentState.session.inputText != 'محتوى مرفق (صورة / PDF)'
              ? currentState.session.inputText.trim().split('\n').first
              : currentState.session.aiResponse
              .replaceAll(RegExp(r'[#*`>-]'), '')
              .trim()
              .split('\n')
              .first
        ];

        final videos = await _repository.fetchSuggestedVideos(
          libraryId: libraryId,
          sessionId: currentState.session.id,
          keywords: effectiveKeywords,
          languageCode: currentState.session.language,
        );

        emit(AiTutorExplained(
          session: currentState.session,
          videos: List<YoutubeVideoModel>.from(videos),
          isLoadingVideos: false,
        ));
      } catch (e) {
        debugPrint('YouTube fetch failed in cubit: $e');
        emit(AiTutorExplained(
          session: currentState.session,
          isLoadingVideos: false,
          videoError: e.toString(),
        ));
      }
    }
  }

  @override
  Future<void> close() async {
    await _streamSubscription?.cancel();
    return super.close();
  }
}