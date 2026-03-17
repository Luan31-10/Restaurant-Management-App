import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qlnh_app/logic/blocs/auth/auth_bloc.dart';
import 'package:qlnh_app/logic/blocs/dashboard/dashboard_bloc.dart';
import 'package:qlnh_app/presentation/widgets/admin_navigation_drawer.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<DashboardBloc>().add(FetchDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Lấy theme

    return Scaffold(
      drawer: const AdminNavigationDrawer(),
      appBar: AppBar(
        title: const Text('Tổng quan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          )
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardError) {
            return Center(child: Text('Lỗi: ${state.message}'));
          }
          if (state is DashboardLoaded) {
            final data = state.data;
            final summary = data.todaySummary;
            final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      // Thẻ Doanh thu (Nổi bật)
                      _buildKpiCard(
                        context,
                        title: 'Doanh thu Hôm nay',
                        value: currencyFormatter.format(summary.totalRevenue),
                        icon: Icons.monetization_on,
                        color: theme.colorScheme.primary, // Dùng màu theme
                        isPrimary: true, // Đánh dấu thẻ chính
                      ),
                      _buildKpiCard(
                        context,
                        title: 'Số Hóa đơn',
                        value: summary.totalOrders.toString(),
                        icon: Icons.receipt_long,
                        color: theme.colorScheme.secondary, // Dùng màu theme
                      ),
                      _buildKpiCard(
                        context,
                        title: 'Trung bình/HĐ',
                        value: currencyFormatter.format(summary.averageOrderValue),
                        icon: Icons.trending_up,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildChartCard(context, data.revenueByHour),
                  const SizedBox(height: 24),
                  _buildTopItemsCard(context, data.topMenuItems), // <<< Hàm này đã được sửa
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// Widget Thẻ KPI (Đã cập nhật từ lần trước)
Widget _buildKpiCard(
    BuildContext context, {
      required String title,
      required String value,
      required IconData icon,
      required Color color,
      bool isPrimary = false,
    }) {
  final theme = Theme.of(context);
  final Color backgroundColor = isPrimary ? color : theme.cardTheme.color ?? Colors.white;
  final Color iconColor = isPrimary ? Colors.white.withOpacity(0.9) : color;
  final Color titleColor = isPrimary ? Colors.white.withOpacity(0.8) : Colors.grey.shade600;
  final Color valueColor = isPrimary ? Colors.white : theme.colorScheme.onSurface;

  return Card(
    color: backgroundColor,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 32, color: iconColor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: titleColor)),
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// Widget Biểu đồ (Đã cập nhật từ lần trước)
Widget _buildChartCard(BuildContext context, List<RevenueByHour> data) {
  final theme = Theme.of(context);

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Doanh thu theo giờ', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: data.map((d) => BarChartGroupData(x: d.hour, barRods: [
                  BarChartRodData(
                      toY: d.revenue / 1000,
                      width: 15,
                      color: theme.colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4))
                  )
                ])).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text('${value.toInt()}k'))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text(value.toInt().toString()))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.dividerColor.withOpacity(0.5),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// === HÀM BUILD CARD TOP 5 MÓN (ĐÃ CẬP NHẬT) ===
Widget _buildTopItemsCard(BuildContext context, List<TopMenuItem> items) {
  final theme = Theme.of(context);

  // 1. Tìm số lượng lớn nhất để làm mốc 100% cho thanh bar
  final double maxQuantity = items.fold(0, (max, item) => item.totalQuantity > max ? item.totalQuantity.toDouble() : max);
  // Tránh chia cho 0 nếu danh sách trống
  final double maxQtyForCalc = maxQuantity == 0 ? 1.0 : maxQuantity;

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top 5 Món bán chạy', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16), // Tăng khoảng cách

          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'Chưa có dữ liệu món bán chạy.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
          // 2. Dùng Column thay vì ...items.map
            Column(
              children: items.map((item) {
                // 3. Gọi hàm build row mới
                return _buildTopItemRow(context, item, maxQtyForCalc);
              }).toList(),
            ),
        ],
      ),
    ),
  );
}

// === WIDGET MỚI: HÀNG TOP MÓN ĂN VỚI THANH BAR ===
Widget _buildTopItemRow(BuildContext context, TopMenuItem item, double maxQuantity) {
  final theme = Theme.of(context);
  // Tính toán tỷ lệ chiều rộng của thanh bar (0.0 đến 1.0)
  final double barFraction = item.totalQuantity / maxQuantity;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0), // Tăng khoảng cách giữa các món
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hàng chứa Tên món và Số lượng
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible( // Dùng Flexible để tên món không bị tràn
              child: Text(
                item.name,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${item.totalQuantity} suất',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Thanh Bar
        LayoutBuilder( // Dùng LayoutBuilder để lấy chiều rộng tối đa
          builder: (context, constraints) {
            return Stack( // Dùng Stack để có thanh nền
              children: [
                // Thanh nền (màu xám mờ)
                Container(
                  height: 8,
                  width: constraints.maxWidth, // Rộng 100%
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant, // Màu nền xám từ theme
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Thanh dữ liệu (màu cam)
                AnimatedContainer( // Thêm hiệu ứng động
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  width: constraints.maxWidth * barFraction, // Chiều rộng tỷ lệ
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary, // Màu chính từ theme
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}