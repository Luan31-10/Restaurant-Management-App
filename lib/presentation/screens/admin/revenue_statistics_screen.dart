import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:qlnh_app/logic/blocs/statistics/statistics_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart'; // <<< 1. THÊM IMPORT

class RevenueStatisticsScreen extends StatefulWidget {
  const RevenueStatisticsScreen({super.key});

  @override
  State<RevenueStatisticsScreen> createState() =>
      _RevenueStatisticsScreenState();
}

class _RevenueStatisticsScreenState extends State<RevenueStatisticsScreen> {
  @override
  void initState() {
    super.initState();
    // Tải dữ liệu theo tháng làm mặc định
    context.read<StatisticsBloc>().add(const FetchStatistics(period: 'month'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê doanh thu'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final currentState = context.read<StatisticsBloc>().state;
          if (currentState is StatisticsLoaded) {
            context.read<StatisticsBloc>().add(FetchStatistics(period: currentState.selectedPeriod));
          }
        },
        child: BlocBuilder<StatisticsBloc, StatisticsState>(
          builder: (context, state) {
            if (state is StatisticsError) {
              return Center(child: Text('Lỗi: ${state.message}'));
            }
            if (state is StatisticsLoaded) {
              return _buildStatisticsView(context, state);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildStatisticsView(BuildContext context, StatisticsLoaded state) {
    final selectedPeriod = state.selectedPeriod;
    final summaryData = state.summaryData;
    final detailedData = state.detailedData;

    final totalRevenue = summaryData.fold<double>(0, (sum, item) => sum + item.revenue);
    final totalOrders = summaryData.fold<int>(0, (sum, item) => sum + item.orderCount);
    final averageRevenue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

    // Tạo list các widget để thêm hiệu ứng
    final List<Widget> widgetsToAnimate = [
      Center(
        child: SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment(value: 'week', label: Text('Theo Tuần'), icon: Icon(Icons.calendar_view_week)),
            ButtonSegment(value: 'month', label: Text('Theo Tháng'), icon: Icon(Icons.calendar_month)),
          ],
          selected: {selectedPeriod},
          onSelectionChanged: (Set<String> newSelection) {
            context.read<StatisticsBloc>().add(FetchStatistics(period: newSelection.first));
          },
        ),
      ),
      const SizedBox(height: 24),
      // === 2. THÊM CỜ isPrimary VÀO THẺ TỔNG DOANH THU ===
      _buildInfoCard(
        context,
        icon: Icons.monetization_on,
        iconColor: Colors.green, // Màu này sẽ bị ghi đè
        title: 'Tổng doanh thu',
        value: NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(totalRevenue), // Dùng 'đ'
        isPrimary: true, // <<< Đánh dấu thẻ này là chính
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildInfoCard(context, icon: Icons.receipt_long, iconColor: Colors.blue, title: 'Số đơn hàng', value: totalOrders.toString()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCard(context, icon: Icons.trending_up, iconColor: Colors.orange, title: 'Trung bình/đơn', value: NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(averageRevenue)), // Dùng 'đ'
          ),
        ],
      ),
      const SizedBox(height: 24),
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Doanh thu theo ngày', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (detailedData.isNotEmpty)
                SizedBox(
                  height: 250,
                  child: LineChart(_createLineChartData(detailedData, context)),
                )
              else
                const SizedBox(
                  height: 250,
                  child: Center(child: Text('Không có dữ liệu để vẽ biểu đồ.')),
                ),
            ],
          ),
        ),
      ),
    ];


    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: widgetsToAnimate.length,
      itemBuilder: (context, index) {
        // === 3. THÊM HIỆU ỨNG VÀO TẤT CẢ WIDGET ===
        return widgetsToAnimate[index].animate()
            .fadeIn(duration: 500.ms, delay: (100 * index).ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
      },
    );
  }

  // === CẬP NHẬT WIDGET NÀY ĐỂ NHẬN cờ isPrimary ===
  Widget _buildInfoCard(BuildContext context, {required IconData icon, required Color iconColor, required String title, required String value, bool isPrimary = false}) {
    final theme = Theme.of(context);
    // Xác định màu sắc dựa trên isPrimary
    final Color backgroundColor = isPrimary ? theme.colorScheme.primary : theme.cardTheme.color ?? Colors.white;
    final Color effectiveIconColor = isPrimary ? Colors.white.withOpacity(0.9) : iconColor;
    final Color titleColor = isPrimary ? Colors.white.withOpacity(0.8) : Colors.grey.shade600;
    final Color valueColor = isPrimary ? Colors.white : theme.colorScheme.onSurface;

    return Card(
      color: backgroundColor, // <<< Dùng màu nền động
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: effectiveIconColor), // <<< Dùng màu icon động
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: titleColor)), // <<< Dùng màu chữ động
            const SizedBox(height: 4),
            Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor // <<< Dùng màu chữ động
                )
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _createLineChartData(List<RevenueDataPoint> data, BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return LineChartData(

      lineTouchData: LineTouchData(
        handleBuiltInTouches: true, // Bật tính năng chạm
        touchTooltipData: LineTouchTooltipData(


          getTooltipColor: (LineBarSpot touchedSpot) {
            return Colors.black.withOpacity(0.8);
          },


          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final spotIndex = barSpot.spotIndex;

              if (spotIndex < 0 || spotIndex >= data.length) {
                return null;
              }
              final date = data[spotIndex].date;
              final revenue = barSpot.y;

              return LineTooltipItem(
                '${DateFormat('d/M/yyyy').format(date)}\n',
                TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
                children: [
                  const TextSpan(
                    text: 'Doanh thu:\n',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  TextSpan(
                    text: currencyFormatter.format(revenue),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ],
                textAlign: TextAlign.left,
              );
            }).whereType<LineTooltipItem>().toList();
          },
        ),
      ),

      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(color: theme.dividerColor, strokeWidth: 1, dashArray: [4, 4]),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (value, meta) => Text('${(value / 1000000).toStringAsFixed(0)}tr '))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: data.length > 7 ? 5 : 1, getTitlesWidget: (value, meta) {
          if (value.toInt() >= 0 && value.toInt() < data.length) {
            return Text(DateFormat('d/M').format(data[value.toInt()].date), style: const TextStyle(fontSize: 12));
          }
          return const Text('');
        })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: data.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.revenue)).toList(),
          isCurved: true,
          color: theme.colorScheme.primary,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
      ],
    );
  }
}