import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:flutter/foundation.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Đang khởi tạo phiên làm việc...'));

    try {
      final session = await _authRepository.restoreSession();
      if (session == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      emit(AuthAuthenticated(session));
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Mình đang đăng nhập nhẹ nhàng...'));

    try {
      final session = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      debugPrint(
        '✅ Login success response: email=${session.email}, '
        'displayName=${session.displayName}, hasToken=${session.token.isNotEmpty}',
      );
      emit(AuthAuthenticated(session));
    } on AuthFailure catch (failure) {
      emit(AuthError(failure.message));
    } catch (_) {
      emit(
        const AuthError('Kết nối hơi chậm một chút, mình thử lại ngay nhé 🌿'),
      );
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Đang tạo tài khoản cho bạn...'));

    try {
      final session = await _authRepository.register(
        name: event.name,
        email: event.email,
        password: event.password,
        confirmPassword: event.confirmPassword,
      );
      emit(AuthAuthenticated(session));
    } on AuthFailure catch (failure) {
      emit(AuthError(failure.message));
    } catch (_) {
      emit(
        const AuthError(
          'Mình chưa tạo được tài khoản lúc này, thử lại giúp mình nhé 🌱',
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Mình đang lưu lại phiên học của bạn...'));

    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (_) {
      emit(
        const AuthError(
          'Mình chưa đăng xuất được, bạn thử lại giúp mình nhé 🌿',
        ),
      );
    }
  }
}
