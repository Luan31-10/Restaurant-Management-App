part of 'statistics_bloc.dart';

abstract class StatisticsEvent extends Equatable {
  const StatisticsEvent();
  @override
  List<Object> get props => [];
}

class FetchStatistics extends StatisticsEvent {
  final String period; // 'week' or 'month'
  const FetchStatistics({required this.period});
  @override
  List<Object> get props => [period];
}