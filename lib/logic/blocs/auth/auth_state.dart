part of 'auth_bloc.dart';

enum AuthStatus {
  unknown,
  inProgress,
  authenticated,
  unauthenticated,
  adminVerificationRequired, // Trạng thái chờ Master PIN (giữ nguyên)
  adminBiometricRequired  // <-- THÊM TRẠNG THÁI NÀY
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String errorMessage;

  const AuthState({
    this.status = AuthStatus.unauthenticated, // Bắt đầu ở unauthenticated
    this.user,
    this.errorMessage = '',
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    // Xóa user và lỗi cũ khi logout
    if (status == AuthStatus.unauthenticated) {
      return AuthState(status: status ?? this.status);
    }
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override List<Object?> get props => [status, user, errorMessage];
}