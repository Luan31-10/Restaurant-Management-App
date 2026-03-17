part of 'end_of_day_report_bloc.dart';

// --- Models ---

// Model cho danh sách tóm tắt các báo cáo cũ
class PastReportInfo extends Equatable {
  final int id;
  final DateTime reportDate;
  final String generatedBy;

  const PastReportInfo({required this.id, required this.reportDate, required this.generatedBy});

  factory PastReportInfo.fromJson(Map<String, dynamic> json) {
    return PastReportInfo(
      id: json['id'],
      reportDate: DateTime.parse(json['reportDate']),
      generatedBy: json['User']?['name'] ?? 'Không rõ',
    );
  }

  @override
  List<Object?> get props => [id, reportDate, generatedBy];
}

// Model cho báo cáo chi tiết
class EndOfDayReportModel extends Equatable {
  final DateTime reportTime;
  final double totalRevenue;
  final int totalOrders;
  final int cancelledOrders;
  final Map<String, dynamic> revenueByPaymentMethod;

  const EndOfDayReportModel({
    required this.reportTime,
    required this.totalRevenue,
    required this.totalOrders,
    required this.cancelledOrders,
    required this.revenueByPaymentMethod,
  });

  factory EndOfDayReportModel.fromJson(Map<String, dynamic> json) {
    return EndOfDayReportModel(
      reportTime: DateTime.parse(json['reportDate']),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalOrders: json['totalOrders'] as int,
      cancelledOrders: json['cancelledOrders'] as int,
      // Xử lý trường hợp revenueByPaymentMethod có thể là null
      revenueByPaymentMethod: json['revenueByPaymentMethod'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  List<Object?> get props => [reportTime, totalRevenue, totalOrders, cancelledOrders, revenueByPaymentMethod];
}

// --- States ---

abstract class EndOfDayReportState extends Equatable {
  const EndOfDayReportState();
  @override
  List<Object> get props => [];
}

class EndOfDayReportInitial extends EndOfDayReportState {}
class EndOfDayReportLoading extends EndOfDayReportState {}

class EndOfDayReportListLoaded extends EndOfDayReportState {
  final List<PastReportInfo> reports;
  const EndOfDayReportListLoaded(this.reports);
  @override
  List<Object> get props => [reports];
}

class EndOfDayReportGenerated extends EndOfDayReportState {
  final EndOfDayReportModel report;
  const EndOfDayReportGenerated(this.report);
  @override
  List<Object> get props => [report];
}

class EndOfDayReportError extends EndOfDayReportState {
  final String message;
  const EndOfDayReportError(this.message);
  @override
  List<Object> get props => [message];
}