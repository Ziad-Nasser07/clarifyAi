import 'package:flutter_bloc/flutter_bloc.dart';
import '../../ai_tutor/data/models/explanation_session_model.dart';
import '../data/research_repository.dart';

abstract class ResearchState {}
class ResearchInitial extends ResearchState {}
class ResearchLoading extends ResearchState {}
class ResearchSuccess extends ResearchState {
  final ExplanationSessionModel result;
  ResearchSuccess(this.result);
}
class ResearchError extends ResearchState {
  final String message;
  ResearchError(this.message);
}

class ResearchCubit extends Cubit<ResearchState> {
  final ResearchRepository _repository;

  ResearchCubit(this._repository) : super(ResearchInitial());

  Future<void> searchTopic({
    required String libraryId,
    required String topic,
  }) async {
    if (state is ResearchLoading) return;
    emit(ResearchLoading());
    try {
      final result = await _repository.performResearch(
        libraryId: libraryId,
        topic: topic,
      );
      emit(ResearchSuccess(result));
    } catch (e) {
      emit(ResearchError('تعذر إتمام البحث: $e'));
    }
  }
}