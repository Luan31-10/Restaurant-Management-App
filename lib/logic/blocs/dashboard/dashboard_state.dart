part of 'dashboard_bloc.dart';

// Models
class TodaySummary {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  TodaySummary({required this.totalRevenue, required this.totalOrders, required this.averageOrderValue});
}

class TopMenuItem {
  final String name;
  final int totalQuantity;
  TopMenuItem({required this.name, required this.totalQuantity});
}

class RevenueByHour {
  final int hour;
  final double revenue;
  RevenueByHour({required this.hour, required this.revenue});
}

class DashboardModel {
  final TodaySummary todaySummary;
  final List<TopMenuItem> topMenuItems;
  final List<RevenueByHour> revenueByHour;
  DashboardModel({required this.todaySummary, required this.topMenuItems, required this.revenueByHour});
}

// States
abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  final DashboardModel data;
  const DashboardLoaded(this.data);
  @override
  List<Object> get props => [data];
}
class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object> get props => [message];
}