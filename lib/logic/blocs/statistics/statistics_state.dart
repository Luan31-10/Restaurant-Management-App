part of 'statistics_bloc.dart';

// Model cho dữ liệu tóm tắt (giữ nguyên)
class RevenueData {
  final String label;
  final double revenue;
  final int orderCount;
  RevenueData({
    required this.label,
    required this.revenue,
    required this.orderCount,
  });
}

// MODEL MỚI: Dành cho các điểm dữ liệu trên biểu đồ đường
class RevenueDataPoint {
  final DateTime date;
  final double revenue;
  RevenueDataPoint({required this.date, required this.revenue});

  factory RevenueDataPoint.fromJson(Map<String, dynamic> json) {
    return RevenueDataPoint(
      date: DateTime.parse(json['date']),
      revenue: (num.tryParse(json['dailyRevenue'].toString()) ?? 0).toDouble(),
    );
  }
}

// --- STATE ---

abstract class StatisticsState extends Equatable {
  const StatisticsState();
  @override
  List<Object> get props => [];
}

class StatisticsInitial extends StatisticsState {}
class StatisticsLoading extends StatisticsState {}

// SỬA LẠI: State này giờ sẽ chứa cả 2 loại dữ liệu
class StatisticsLoaded extends StatisticsState {
  final List<RevenueData> summaryData; // Dữ liệu tóm tắt cho các thẻ KPI
  final List<RevenueDataPoint> detailedData; // Dữ liệu chi tiết cho biểu đồ
  final String selectedPeriod;

  const StatisticsLoaded(this.summaryData, this.detailedData, this.selectedPeriod);

  @override
  List<Object> get props => [summaryData, detailedData, selectedPeriod];
}

class StatisticsError extends StatisticsState {
  final String message;
  const StatisticsError(this.message);
  @override
  List<Object> get props => [message];
}