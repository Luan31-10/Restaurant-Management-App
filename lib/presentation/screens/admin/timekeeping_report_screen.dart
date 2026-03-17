import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qlnh_app/logic/blocs/timekeeping_report/timekeeping_report_bloc.dart';
import 'package:collection/collection.dart';

class TimekeepingReportScreen extends StatefulWidget {
  const TimekeepingReportScreen({super.key});

  @override
  State<TimekeepingReportScreen> createState() => _TimekeepingReportScreenState();
}

class _TimekeepingReportScreenState extends State<TimekeepingReportScreen> {
  late DateTimeRange _selectedDateRange;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 6)),
      end: now,
    );
    _fetchReport();

    // Bắt đầu bộ đếm thời gian để tự động làm mới sau mỗi 30 giây
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        // Dòng print này sẽ xuất hiện trong console mỗi 30 giây nếu Timer hoạt động
        print('[TIMER] Auto-refreshing timekeeping report...');
        _fetchReport();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _fetchReport() {
    // Dòng print này xác nhận sự kiện đã được gửi đến BLoC
    print('[BLOC] Dispatching FetchTimekeepingReport event.');
    context.read<TimekeepingReportBloc>().add(FetchTimekeepingReport(
      startDate: _selectedDateRange.start,
      endDate: _selectedDateRange.end,
    ));
  }

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      _fetchReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Chấm công'),
      ),
      body: Column(
        children: [
          // --- THÊM LẠI PHẦN GIAO DIỆN CHỌN NGÀY THÁNG ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateFormat('dd/MM/yyyy').format(_selectedDateRange.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange.end)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month_outlined),
                  onPressed: _selectDateRange,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // ---------------------------------------------------
          Expanded(
            child: BlocBuilder<TimekeepingReportBloc, TimekeepingReportState>(
              builder: (context, state) {
                if (state is TimekeepingReportLoading && state is! TimekeepingReportLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TimekeepingReportError) {
                  return Center(child: Text('Lỗi: ${state.message}'));
                }
                if (state is TimekeepingReportLoaded) {
                  if (state.entries.isEmpty) {
                    return const Center(child: Text('Không có dữ liệu.'));
                  }

                  final groupedByEmployee = groupBy(state.entries, (entry) => entry.userName);
                  final employees = groupedByEmployee.keys.toList();

                  return RefreshIndicator(
                    onRefresh: () async => _fetchReport(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80), // Thêm khoảng trống dưới
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final employeeName = employees[index];
                        final entries = groupedByEmployee[employeeName]!;
                        final totalHours = entries.fold<double>(0, (sum, item) => sum + item.totalHours);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              child: Text(employeeName.isNotEmpty ? employeeName[0] : '?'),
                            ),
                            title: Text(employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Tổng: ${totalHours.toStringAsFixed(2)} giờ'),
                            children: entries.map((entry) {
                              // Xử lý an toàn cho clockOutTime
                              final clockOutText = entry.clockOutTime != null
                                  ? DateFormat.Hm().format(entry.clockOutTime!)
                                  : 'Chưa checkout';

                              return ListTile(
                                tileColor: Colors.white,
                                title: Text(
                                  DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(entry.clockInTime),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  'Ca làm: ${DateFormat.Hm().format(entry.clockInTime)} - $clockOutText',
                                ),
                                trailing: Text(
                                  '${entry.totalHours.toStringAsFixed(2)} giờ',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}