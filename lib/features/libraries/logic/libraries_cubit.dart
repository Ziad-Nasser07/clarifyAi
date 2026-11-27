import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/libraries_repository.dart';
import '../data/models/subject_library_model.dart';
import '../../ai_tutor/data/models/explanation_session_model.dart';

abstract class LibrariesState {}
class LibrariesInitial extends LibrariesState {}
class LibrariesLoading extends LibrariesState {}
class LibrariesError extends LibrariesState {
  final String message;
  LibrariesError(this.message);
}

class LibrariesCubit extends Cubit<LibrariesState> {
  final LibrariesRepository _repository;
  late final Stream<List<SubjectLibraryModel>> librariesStream;

  LibrariesCubit(this._repository) : super(LibrariesInitial()) {
    librariesStream = _repository.getUserLibraries();
  }

  Stream<List<ExplanationSessionModel>> sessionsStream(String libraryId) =>
      _repository.getLibrarySessions(libraryId);

  Future<void> addLibrary(String name, int colorValue) async {
    try {
      await _repository.createLibrary(
        subjectName: name,
        colorValue: colorValue,
      );
    } catch (e) {
      emit(LibrariesError(e.toString()));
      rethrow;
    }
  }
}