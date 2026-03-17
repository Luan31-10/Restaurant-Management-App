part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  final String pin;
  const LoginRequested(this.pin);
  @override List<Object> get props => [pin];
}

class VerifyAdminRequested extends AuthEvent {
  final int userId;
  final String masterPin;

  const VerifyAdminRequested({required this.userId, required this.masterPin});
  @override List<Object> get props => [userId, masterPin];
}

// <-- THÊM EVENT NÀY -->
class AdminVerifiedWithBiometrics extends AuthEvent {}

class LogoutRequested extends AuthEvent {}