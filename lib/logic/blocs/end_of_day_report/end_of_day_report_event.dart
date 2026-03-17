part of 'end_of_day_report_bloc.dart';

abstract class EndOfDayReportEvent extends Equatable {
  const EndOfDayReportEvent();
  @override
  List<Object> get props => [];
}

// Event để tạo báo cáo mới
class GenerateReport extends EndOfDayReportEvent {}

// Event để lấy danh sách các báo cáo cũ
class FetchPastReports extends EndOfDayReportEvent {}