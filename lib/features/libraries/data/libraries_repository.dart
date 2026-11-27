import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/api_constants.dart';
import '../../ai_tutor/data/models/explanation_session_model.dart';
import 'models/subject_library_model.dart';

class LibrariesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createLibrary({
    required String subjectName,
    required int colorValue,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to create a library.');
    }

    final now = DateTime.now();
    final library = SubjectLibraryModel(
      id: '',
      subjectName: subjectName,
      colorValue: colorValue,
      createdAt: now,
    );

    final map = library.toMap();
    map['createdAt'] = Timestamp.fromDate(now);

    await _firestore
        .collection(ApiConstants.usersCollection)
        .doc(user.uid)
        .collection(ApiConstants.librariesCollection)
        .add(map);
  }

  Future<void> deleteLibrary(String libraryId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to delete a library.');
    }

    final libraryRef = _firestore
        .collection(ApiConstants.usersCollection)
        .doc(user.uid)
        .collection(ApiConstants.librariesCollection)
        .doc(libraryId);

    final sessionsSnapshot = await libraryRef
        .collection(ApiConstants.sessionsCollection)
        .get();

    final batch = _firestore.batch();
    for (final doc in sessionsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(libraryRef);

    await batch.commit();
  }

  Stream<List<SubjectLibraryModel>> getUserLibraries() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(<SubjectLibraryModel>[]);
    }

    return _firestore
        .collection(ApiConstants.usersCollection)
        .doc(user.uid)
        .collection(ApiConstants.librariesCollection)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => SubjectLibraryModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<ExplanationSessionModel>> getLibrarySessions(String libraryId) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(<ExplanationSessionModel>[]);
    }

    return _firestore
        .collection(ApiConstants.usersCollection)
        .doc(user.uid)
        .collection(ApiConstants.librariesCollection)
        .doc(libraryId)
        .collection(ApiConstants.sessionsCollection)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ExplanationSessionModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}