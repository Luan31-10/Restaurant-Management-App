import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qlnh_app/logic/blocs/sales_report/sales_report_bloc.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  late DateTimeRange _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Mặc định chọn ngày hôm nay
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
      end: DateTime.now().copyWith(hour: 23, minute: 59, second: 59),
    );
    _fetchReport();
  }

  void _fetchReport() {
    context.read<SalesReportBloc>().add(FetchSalesReport(
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
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo Bán hàng'),
      ),
      body: Column(
        children: [
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
          Expanded(
            child: BlocBuilder<SalesReportBloc, SalesReportState>(
              builder: (context, state) {
                if (state is SalesReportLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SalesReportError) {
                  return Center(child: Text('Lỗi: ${state.message}'));
                }
                if (state is SalesReportLoaded) {
                  final summary = state.report.summary;
                  final orders = state.report.orders;
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildSummaryCard(
                        'Tổng doanh thu',
                        currencyFormatter.format(summary.totalRevenue),
                        Icons.monetization_on,
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryCard(
                        'Tổng số đơn',
                        summary.totalOrders.toString(),
                        Icons.receipt_long,
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryCard(
                        'Trung bình/đơn',
                        currencyFormatter.format(summary.averageOrderValue),
                        Icons.trending_up,
                        Colors.orange,
                      ),
                      const SizedBox(height: 24),
                      Text('Chi tiết Hóa đơn', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('Mã HĐ')),
                            DataColumn(label: Text('Nhân viên')),
                            DataColumn(label: Text('Tổng tiền'), numeric: true),
                          ],
                          rows: orders.map((order) => DataRow(
                            cells: [
                              DataCell(Text('#${order.id}')),
                              DataCell(Text(order.employeeName ?? 'N/A')),
                              DataCell(Text(currencyFormatter.format(order.totalAmount))),
                            ],
                          )).toList(),
                        ),
                      ),
                    ],
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

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
                Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}