import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qlnh_app/data/services/api_service.dart';
import 'package:qlnh_app/logic/blocs/auth/auth_bloc.dart';
import 'package:qlnh_app/logic/blocs/sales_report/sales_report_bloc.dart';
import 'package:qlnh_app/logic/blocs/statistics/statistics_bloc.dart';
import 'package:qlnh_app/logic/blocs/timekeeping_report/timekeeping_report_bloc.dart';
import 'package:qlnh_app/presentation/screens/employee_management_screen.dart';
import 'package:qlnh_app/presentation/screens/menu_management_screen.dart';
import 'package:qlnh_app/presentation/screens/admin/revenue_statistics_screen.dart';
import 'package:qlnh_app/presentation/screens/admin/sales_report_screen.dart';
import 'package:qlnh_app/presentation/screens/admin/timekeeping_report_screen.dart';

// THÊM CÁC IMPORT MỚI
import 'package:qlnh_app/logic/blocs/end_of_day_report/end_of_day_report_bloc.dart';
import 'package:qlnh_app/presentation/screens/admin/end_of_day_screen.dart';


final GlobalKey<EmployeeManagementScreenState> _employeeScreenKey = GlobalKey<EmployeeManagementScreenState>();
final GlobalKey<MenuManagementScreenState> _menuScreenKey = GlobalKey<MenuManagementScreenState>();

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _adminScreens = <Widget>[
    EmployeeManagementScreen(key: _employeeScreenKey),
    MenuManagementScreen(key: _menuScreenKey),
    BlocProvider(
      create: (context) => StatisticsBloc(apiService: context.read<ApiService>()),
      child: const RevenueStatisticsScreen(),
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onFabPressed() {
    if (_selectedIndex == 0) {
      _employeeScreenKey.currentState?.showUserFormSheet();
    } else if (_selectedIndex == 1) {
      _menuScreenKey.currentState?.showItemFormSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);

    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý - ${user?.name ?? ''}'),
        automaticallyImplyLeading: false,
        actions: [
          // --- NÚT CHỐT CA & BÁO CÁO CUỐI NGÀY ---
          IconButton(
            tooltip: 'Báo cáo cuối ngày',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (context) => EndOfDayReportBloc(apiService: context.read<ApiService>()),
                  child: const EndOfDayScreen(),
                ),
              ));
            },
          ),
          // --- NÚT BÁO CÁO BÁN HÀNG ---
          IconButton(
            tooltip: 'Báo cáo bán hàng',
            icon: const Icon(Icons.assessment_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (context) => SalesReportBloc(apiService: context.read<ApiService>()),
                  child: const SalesReportScreen(),
                ),
              ));
            },
          ),
          // --- NÚT BÁO CÁO CHẤM CÔNG ---
          IconButton(
            tooltip: 'Báo cáo chấm công',
            icon: const Icon(Icons.timer_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (context) => TimekeepingReportBloc(apiService: context.read<ApiService>()),
                  child: const TimekeepingReportScreen(),
                ),
              ));
            },
          ),
          // --- NÚT ĐĂNG XUẤT ---
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _adminScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'Nhân viên'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Thực đơn'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Thống kê'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex < 2
          ? FloatingActionButton(
        onPressed: _onFabPressed,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}