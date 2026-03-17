import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qlnh_app/data/services/api_service.dart';

part 'timekeeping_report_event.dart';
part 'timekeeping_report_state.dart';

class TimekeepingReportBloc extends Bloc<TimekeepingReportEvent, TimekeepingReportState> {
  final ApiService apiService;

  TimekeepingReportBloc({required this.apiService}) : super(TimekeepingReportInitial()) {
    on<FetchTimekeepingReport>((event, emit) async {
      emit(TimekeepingReportLoading());
      try {
        // Sửa lại: Gọi hàm lấy báo cáo chi tiết
        final reportEntries = await apiService.getDetailedTimekeepingReport(event.startDate, event.endDate);
        // Sửa lại: Emit state với dữ liệu chi tiết
        emit(TimekeepingReportLoaded(reportEntries));
      } catch (e) {
        emit(TimekeepingReportError(e.toString()));
      }
    });
  }
}