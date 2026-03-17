import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qlnh_app/data/services/api_service.dart';

part 'clock_in_event.dart';
part 'clock_in_state.dart';

class ClockInBloc extends Bloc<ClockInEvent, ClockInState> {
  final ApiService apiService;

  ClockInBloc({required this.apiService}) : super(const ClockInState()) {
    on<CheckClockInStatus>(_onCheckStatus);
    on<ClockInRequested>(_onClockIn);
    on<ClockOutRequested>(_onClockOut);
  }

  Future<void> _onCheckStatus(CheckClockInStatus event, Emitter<ClockInState> emit) async {
    emit(const ClockInState(status: ClockInStatus.loading));
    try {
      final statusString = await apiService.getClockInStatus();
      final status = statusString == 'clocked_in' ? ClockInStatus.clockedIn : ClockInStatus.clockedOut;
      emit(ClockInState(status: status));
    } catch (e) {
      emit(ClockInState(status: ClockInStatus.error, message: e.toString()));
    }
  }

  Future<void> _onClockIn(ClockInRequested event, Emitter<ClockInState> emit) async {
    emit(const ClockInState(status: ClockInStatus.loading));
    try {
      await apiService.clockIn();
      emit(const ClockInState(status: ClockInStatus.clockedIn, message: 'Check-in thành công!'));
    } catch (e) {
      emit(ClockInState(status: ClockInStatus.clockedOut, message: e.toString()));
    }
  }

  Future<void> _onClockOut(ClockOutRequested event, Emitter<ClockInState> emit) async {
    emit(const ClockInState(status: ClockInStatus.loading));
    try {
      await apiService.clockOut();
      emit(const ClockInState(status: ClockInStatus.clockedOut, message: 'Check-out thành công!'));
    } catch (e) {
      emit(ClockInState(status: ClockInStatus.clockedIn, message: e.toString()));
    }
  }
}