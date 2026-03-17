part of 'timekeeping_report_bloc.dart';

abstract class TimekeepingReportEvent extends Equatable {
  const TimekeepingReportEvent();

  @override
  List<Object> get props => [];
}

class FetchTimekeepingReport extends TimekeepingReportEvent {
  final DateTime startDate;
  final DateTime endDate;

  const FetchTimekeepingReport({required this.startDate, required this.endDate});

  @override
  List<Object> get props => [startDate, endDate];
}