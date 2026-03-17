import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qlnh_app/data/services/api_service.dart';
part 'end_of_day_report_event.dart';
part 'end_of_day_report_state.dart';

class EndOfDayReportBloc extends Bloc<EndOfDayReportEvent, EndOfDayReportState> {
  final ApiService apiService;

  EndOfDayReportBloc({required this.apiService}) : super(EndOfDayReportInitial()) {
    on<FetchPastReports>(_onFetchPastReports);
    on<GenerateReport>(_onGenerateReport);
  }

  Future<void> _onFetchPastReports(FetchPastReports event, Emitter<EndOfDayReportState> emit) async {
    emit(EndOfDayReportLoading());
    try {
      final reports = await apiService.getPastReports();
      emit(EndOfDayReportListLoaded(reports));
    } catch (e) {
      emit(EndOfDayReportError(e.toString()));
    }
  }

  Future<void> _onGenerateReport(GenerateReport event, Emitter<EndOfDayReportState> emit) async {
    // Không emit Loading để không làm gián đoạn UI
    try {
      final newReport = await apiService.generateEndOfDayReport();
      emit(EndOfDayReportGenerated(newReport));
    } catch (e) {
      emit(EndOfDayReportError(e.toString()));
    }
  }
}