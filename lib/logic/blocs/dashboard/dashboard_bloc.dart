import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qlnh_app/data/services/api_service.dart';
part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ApiService apiService;
  DashboardBloc({required this.apiService}) : super(DashboardInitial()) {
    on<FetchDashboardData>((event, emit) async {
      emit(DashboardLoading());
      try {
        final data = await apiService.getDashboardData(); // Sẽ tạo hàm này ở bước sau
        emit(DashboardLoaded(data));
      } catch (e) {
        emit(DashboardError(e.toString()));
      }
    });
  }
}