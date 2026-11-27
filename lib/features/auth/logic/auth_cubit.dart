import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';

abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {}
class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      emit(AuthFailure('Please enter both your email address and password.'));
      return;
    }
    emit(AuthLoading());
    try {
      await _authRepository.login(email: email, password: password);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(_mapAuthError(e)));
    }
  }

  Future<void> register(String name, String email, String password) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      emit(AuthFailure('Please fill in your full name, email, and password.'));
      return;
    }
    emit(AuthLoading());
    try {
      await _authRepository.register(name: name, email: email, password: password);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(_mapAuthError(e)));
    }
  }

  Future<void> loginWithGoogle() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        emit(AuthSuccess());
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthFailure(_mapAuthError(e)));
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(AuthInitial());
  }

  String _mapAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          return 'Incorrect email or password. Please check your credentials and try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email address. Try signing in instead.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Your password is too weak. Please use at least 6 characters.';
        case 'network-request-failed':
          return 'No internet connection. Please check your network and try again.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please wait a moment and try again.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email using a different sign-in method.';
        default:
          return 'Authentication failed. Please try again.';
      }
    }
    return 'Something went wrong. Please check your connection and try again.';
  }
}