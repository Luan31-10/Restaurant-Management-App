part of 'sales_report_bloc.dart';

// --- Models ---
class ReportSummary {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final Map<String, dynamic> revenueByPaymentMethod;

  ReportSummary({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.revenueByPaymentMethod,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalOrders: json['totalOrders'] as int,
      averageOrderValue: (json['averageOrderValue'] as num).toDouble(),
      revenueByPaymentMethod: json['revenueByPaymentMethod'] as Map<String, dynamic>,
    );
  }
}

class OrderDetail {
  final int id;
  final double totalAmount;
  final DateTime createdAt;
  final String? employeeName;

  OrderDetail({
    required this.id,
    required this.totalAmount,
    required this.createdAt,
    this.employeeName,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'] as int,
      totalAmount: double.parse(json['totalAmount'].toString()),
      createdAt: DateTime.parse(json['createdAt']),
      employeeName: json['User']?['name'],
    );
  }
}

class SalesReportModel {
  final ReportSummary summary;
  final List<OrderDetail> orders;

  SalesReportModel({required this.summary, required this.orders});

  factory SalesReportModel.fromJson(Map<String, dynamic> json) {
    var orderList = json['orders'] as List;
    List<OrderDetail> orders = orderList.map((i) => OrderDetail.fromJson(i)).toList();

    return SalesReportModel(
      summary: ReportSummary.fromJson(json['summary']),
      orders: orders,
    );
  }
}
// --- States ---

abstract class SalesReportState extends Equatable {
  const SalesReportState();
  @override
  List<Object> get props => [];
}

class SalesReportInitial extends SalesReportState {}
class SalesReportLoading extends SalesReportState {}

class SalesReportLoaded extends SalesReportState {
  final SalesReportModel report;
  const SalesReportLoaded(this.report);
  @override
  List<Object> get props => [report];
}

class SalesReportError extends SalesReportState {
  final String message;
  const SalesReportError(this.message);
  @override
  List<Object> get props => [message];
}