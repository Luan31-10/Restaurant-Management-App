part of 'sales_report_bloc.dart';

abstract class SalesReportEvent extends Equatable {
  const SalesReportEvent();
  @override
  List<Object> get props => [];
}

class FetchSalesReport extends SalesReportEvent {
  final DateTime startDate;
  final DateTime endDate;

  const FetchSalesReport({required this.startDate, required this.endDate});

  @override
  List<Object> get props => [startDate, endDate];
}