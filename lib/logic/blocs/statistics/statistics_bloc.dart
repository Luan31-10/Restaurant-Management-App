import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qlnh_app/data/services/api_service.dart';

part 'statistics_event.dart';
part 'statistics_state.dart';

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final ApiService apiService;

  StatisticsBloc({required this.apiService}) : super(StatisticsInitial()) {
    on<FetchStatistics>((event, emit) async {
      emit(StatisticsLoading());
      try {
        // SỬA LẠI: Gọi song song cả 2 API để lấy dữ liệu
        final results = await Future.wait([
          apiService.fetchRevenue(event.period),
          apiService.fetchDetailedStatistics(event.period), // Hàm mới sẽ được thêm vào ApiService
        ]);

        // Gán kết quả vào các biến tương ứng
        final summaryData = results[0] as List<RevenueData>;
        final detailedData = results[1] as List<RevenueDataPoint>;

        // Emit state mới với đầy đủ dữ liệu
        emit(StatisticsLoaded(summaryData, detailedData, event.period));
      } catch (e) {
        emit(StatisticsError(e.toString()));
      }
    });
  }
}