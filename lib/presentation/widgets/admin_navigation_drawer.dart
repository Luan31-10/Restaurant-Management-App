import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qlnh_app/data/services/api_service.dart';
import 'package:qlnh_app/logic/blocs/end_of_day_report/end_of_day_report_bloc.dart';
import 'package:qlnh_app/logic/blocs/sales_report/sales_report_bloc.dart';
import 'package:qlnh_app/logic/blocs/statistics/statistics_bloc.dart';
import 'package:qlnh_app/logic/blocs/timekeeping_report/timekeeping_report_bloc.dart';
import 'package:qlnh_app/presentation/screens/admin/end_of_day_screen.dart';
import 'package:qlnh_app/presentation/screens/employee_management_screen.dart';
import 'package:qlnh_app/presentation/screens/menu_management_screen.dart';
import 'package:qlnh_app/presentation/screens/admin/revenue_statistics_screen.dart';
import 'package:qlnh_app/presentation/screens/admin/sales_report_screen.dart';
import 'package:qlnh_app/presentation/screens/admin/timekeeping_report_screen.dart';


class AdminNavigationDrawer extends StatelessWidget {
  const AdminNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer, // Dùng màu từ theme
            ),
            child: Text(
              'Admin Panel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer, // Màu chữ tương phản
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Tổng quan'),
            onTap: () {
              // Nếu màn hình hiện tại không phải là dashboard thì mới push
              // Hoặc đơn giản là pop drawer
              Navigator.pop(context);
              // Ví dụ: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminDashboardScreen()));
            },
          ),
          const Divider(), // Ngăn cách
          // --- MỤC QUẢN LÝ NHÂN VIÊN ---
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text('Quản lý Nhân viên'),
            onTap: () {
              Navigator.pop(context); // Đóng drawer trước
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeManagementScreen()));
            },
          ),
          // --- MỤC QUẢN LÝ THỰC ĐƠN ---
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Quản lý Thực đơn'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuManagementScreen()));
            },
          ),
          const Divider(),
          // --- MỤC THỐNG KÊ DOANH THU ---
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Thống kê Doanh thu'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BlocProvider(
                  // Cung cấp StatisticsBloc cho màn hình thống kê
                  create: (context) => StatisticsBloc(apiService: context.read<ApiService>()),
                  child: const RevenueStatisticsScreen(),
                ),
              ));
            },
          ),
          const Divider(), // Ngăn cách
          // --- CÁC MỤC BÁO CÁO ---
          ListTile(
            leading: const Icon(Icons.assessment_outlined),
            title: const Text('Báo cáo Bán hàng'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (context) => SalesReportBloc(apiService: context.read<ApiService>()),
                  child: const SalesReportScreen(),
                ),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time_filled_outlined), // Icon chấm công
            title: const Text('Báo cáo Chấm công'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (context) => TimekeepingReportBloc(apiService: context.read<ApiService>()),
                  child: const TimekeepingReportScreen(),
                ),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.nightlight_round_outlined), // Icon cuối ngày
            title: const Text('Báo cáo cuối ngày'),
            onTap: (){
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create:(context) => EndOfDayReportBloc(apiService: context.read<ApiService>()),
                  child: const EndOfDayScreen(),
                ),
              ));
            },
          ),
          // Có thể thêm Divider và nút Đăng xuất ở cuối
          // const Divider(),
          // ListTile(
          //   leading: const Icon(Icons.logout),
          //   title: const Text('Đăng xuất'),
          //   onTap: () {
          //     // Gọi event Logout của AuthBloc
          //     context.read<AuthBloc>().add(LogoutRequested());
          //     Navigator.pop(context); // Đóng drawer
          //     // AppController sẽ tự chuyển về LoginScreen
          //   },
          // ),
        ],
      ),
    );
  }
}