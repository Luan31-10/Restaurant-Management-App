import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qlnh_app/data/models/user_model.dart';
import 'package:qlnh_app/data/services/api_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;

  AuthBloc({required this.apiService}) : super(const AuthState()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<VerifyAdminRequested>(_onVerifyAdminRequested);
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    log('[AuthBloc] Event: LoginRequested');
    emit(state.copyWith(status: AuthStatus.inProgress, errorMessage: ''));
    try {
      final user = await apiService.login(event.pin);

      // SỬA LOGIC Ở ĐÂY
      if (user.role == 'admin') {
        // Nếu là admin, yêu cầu quét vân tay thay vì vào thẳng
        log('[AuthBloc] State: AdminBiometricRequired for user: ${user.name}');
        emit(state.copyWith(
          status: AuthStatus.adminBiometricRequired,
          user: user, // Lưu user lại
        ));
      } else {
        // Nhân viên thường thì đăng nhập thành công
        log('[AuthBloc] State: Authenticated for user: ${user.name}');
        emit(state.copyWith(status: AuthStatus.authenticated, user: user));
      }
    } catch (e) {
      log('[AuthBloc] State: Unauthenticated. Error: $e');
      emit(state.copyWith(status: AuthStatus.unauthenticated, errorMessage: e.toString()));
    }
  }

  // Handler cho Master PIN giữ nguyên
  Future<void> _onVerifyAdminRequested(VerifyAdminRequested event, Emitter<AuthState> emit) async {
    log('[AuthBloc] Event: VerifyAdminRequested');
    emit(state.copyWith(status: AuthStatus.inProgress, errorMessage: ''));
    try {
      final user = await apiService.verifyAdmin(event.userId, event.masterPin);
      log('[AuthBloc] State: Authenticated for admin: ${user.name}');
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch(e) {
      log('[AuthBloc] State: AdminVerificationRequired. Error: $e');
      // Giữ lại user khi Master PIN sai để hiển thị lại dialog
      emit(state.copyWith(status: AuthStatus.adminVerificationRequired, errorMessage: e.toString()));
    }
  }

  void _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) {
    log('[AuthBloc] Event: LogoutRequested');
    // Reset hoàn toàn về trạng thái ban đầu
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}