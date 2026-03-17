part of 'clock_in_bloc.dart';

enum ClockInStatus { unknown, loading, clockedIn, clockedOut, error }

class ClockInState extends Equatable {
  final ClockInStatus status;
  final String message;

  const ClockInState({
    this.status = ClockInStatus.unknown,
    this.message = '',
  });

  @override
  List<Object> get props => [status, message];
}