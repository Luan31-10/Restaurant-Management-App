part of 'timekeeping_report_bloc.dart';

class DetailedTimeClockEntry extends Equatable {
  final int userId;
  final String userName;
  final DateTime clockInTime;
  final DateTime? clockOutTime;
  final double totalHours;

  const DetailedTimeClockEntry({
    required this.userId,
    required this.userName,
    required this.clockInTime,
    this.clockOutTime,
    required this.totalHours,
  });

  factory DetailedTimeClockEntry.fromJson(Map<String, dynamic> json) {
    return DetailedTimeClockEntry(
      // SỬA LẠI: Dùng int.tryParse để an toàn hơn, phòng trường hợp userId bị null
      userId: int.tryParse(json['userId'].toString()) ?? 0,
      // SỬA LẠI: Dùng toán tử `?` và `??` để xử lý null an toàn
      userName: json['User']?['name'] ?? 'Không rõ',
      clockInTime: DateTime.parse(json['clockInTime']),
      clockOutTime: json['clockOutTime'] != null ? DateTime.parse(json['clockOutTime']) : null,
      totalHours: double.parse(json['totalHours'].toString()),
    );
  }

  @override
  List<Object?> get props => [userId, userName, clockInTime, clockOutTime, totalHours];
}


abstract class TimekeepingReportState extends Equatable {
  const TimekeepingReportState();

  @override
  List<Object> get props => [];
}

class TimekeepingReportInitial extends TimekeepingReportState {}
class TimekeepingReportLoading extends TimekeepingReportState {}

class TimekeepingReportLoaded extends TimekeepingReportState {
  final List<DetailedTimeClockEntry> entries;
  const TimekeepingReportLoaded(this.entries);
  @override
  List<Object> get props => [entries];
}

class TimekeepingReportError extends TimekeepingReportState {
  final String message;
  const TimekeepingReportError(this.message);
  @override
  List<Object> get props => [message];
}