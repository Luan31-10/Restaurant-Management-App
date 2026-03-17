part of 'clock_in_bloc.dart';

abstract class ClockInEvent extends Equatable {
  const ClockInEvent();
  @override
  List<Object> get props => [];
}

class CheckClockInStatus extends ClockInEvent {}
class ClockInRequested extends ClockInEvent {}
class ClockOutRequested extends ClockInEvent {}