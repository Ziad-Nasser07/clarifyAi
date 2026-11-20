import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/api_constants.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<User?> login({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  Future<User?> register({
    required String name,
    required String email,
    required String password,
    String preferredLanguage = 'ar',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(name.trim());
      await _firestore.collection(ApiConstants.usersCollection).doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'preferredLanguage': preferredLanguage,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}