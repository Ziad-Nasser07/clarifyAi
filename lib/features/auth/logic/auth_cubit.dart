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
    emit(AuthLoading());
    try {
      await _authRepository.login(email: email, password: password);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> register(String name, String email, String password) async {
    emit(AuthLoading());
    try {
      await _authRepository.register(name: name, email: email, password: password);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(AuthInitial());
  }
}