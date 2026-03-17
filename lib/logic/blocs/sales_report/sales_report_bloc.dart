import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qlnh_app/data/services/api_service.dart';

part 'sales_report_event.dart';
part 'sales_report_state.dart';

class SalesReportBloc extends Bloc<SalesReportEvent, SalesReportState> {
  final ApiService apiService;

  SalesReportBloc({required this.apiService}) : super(SalesReportInitial()) {
    on<FetchSalesReport>((event, emit) async {
      emit(SalesReportLoading());
      try {
        final report = await apiService.getSalesReport(event.startDate, event.endDate);
        emit(SalesReportLoaded(report));
      } catch (e) {
        emit(SalesReportError(e.toString()));
      }
    });
  }
}