import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/api_constants.dart';
import '../../ai_tutor/data/models/explanation_session_model.dart';
import 'models/subject_library_model.dart';

class LibrariesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  Future<void> createLibrary({
    required String subjectName,
    required int colorValue,
  }) async {
    final library = SubjectLibraryModel(
      id: '',
      subjectName: subjectName,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(_userId)
        .collection(ApiConstants.librariesCollection)
        .add(library.toMap());
  }

  Stream<List<SubjectLibraryModel>> getUserLibraries() {
    return _firestore
        .collection(ApiConstants.usersCollection)
        .doc(_userId)
        .collection(ApiConstants.librariesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SubjectLibraryModel.fromFirestore(doc))
        .toList());
  }

  Stream<List<ExplanationSessionModel>> getLibrarySessions(String libraryId) {
    return _firestore
        .collection(ApiConstants.usersCollection)
        .doc(_userId)
        .collection(ApiConstants.librariesCollection)
        .doc(libraryId)
        .collection(ApiConstants.sessionsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ExplanationSessionModel.fromFirestore(doc))
        .toList());
  }
}