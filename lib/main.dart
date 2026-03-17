import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qlnh_app/data/models/user_model.dart';
import 'package:qlnh_app/data/services/api_service.dart';
import 'package:qlnh_app/logic/blocs/auth/auth_bloc.dart';
import 'package:qlnh_app/logic/blocs/kitchen/kitchen_bloc.dart';
import 'package:qlnh_app/logic/blocs/menu_items/menu_item_bloc.dart';
import 'package:qlnh_app/logic/blocs/quick_sale/quick_sale_bloc.dart';
import 'package:qlnh_app/logic/blocs/tables/table_bloc.dart';
import 'package:qlnh_app/presentation/screens/home_screen.dart';
import 'package:qlnh_app/presentation/screens/kitchen_screen.dart';
import 'package:qlnh_app/presentation/screens/login_screen.dart';
import 'package:qlnh_app/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:qlnh_app/logic/blocs/clock_in/clock_in_bloc.dart';
import 'package:qlnh_app/logic/blocs/dashboard/dashboard_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart'; // <<<--- 1. IMPORT GOOGLE FONTS

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', '');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => ApiService(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthBloc(apiService: context.read<ApiService>())),
          BlocProvider(create: (context) => QuickSaleBloc(apiService: context.read<ApiService>())),
          BlocProvider(create: (context) => KitchenBloc(apiService: context.read<ApiService>())),
          BlocProvider(create: (context) => TableBloc(apiService: context.read<ApiService>())..add(FetchTables())),
          BlocProvider(create: (context) => MenuItemBloc(apiService: context.read<ApiService>())..add(FetchMenuItems())),
        ],
        child: MaterialApp(
          title: 'Quản lý Nhà hàng',
          debugShowCheckedModeBanner: false,

          // === 2. ĐỊNH NGHĨA THEME MỚI ===
          // === 2. ĐỊNH NGHĨA THEME MỚI ===
          theme: ThemeData(
            // Sử dụng màu Cam làm màu gốc
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.orange,
              primary: Colors.orange.shade800, // Màu chính đậm hơn
              surfaceVariant: Colors.grey.shade100, // Màu nền nhẹ cho TextField, Card...
              background: const Color(0xFFF9F9F9), // Màu nền chính hơi xám
            ),
            useMaterial3: true, // Bật Material 3 UI

            // Áp dụng font Be Vietnam Pro
            textTheme: GoogleFonts.beVietnamProTextTheme(
              Theme.of(context).textTheme,
            ),

            // Định dạng chung cho Card
            // === SỬA TẠI ĐÂY: Thêm 'Data' ===
            cardTheme: const CardThemeData( // <--- SỬA LẠI THÀNH CardThemeData
              elevation: 2,
              color: Colors.white, // Nền Card luôn trắng
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              margin: EdgeInsets.zero, // Bỏ margin mặc định nếu cần
            ),

            // Định dạng AppBar (Tùy chọn)
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white, // Nền AppBar trắng
              foregroundColor: Colors.black87, // Chữ/icon đen
              elevation: 1,
              titleTextStyle: GoogleFonts.beVietnamPro( // Áp dụng font cho tiêu đề AppBar
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              centerTitle: true, // Canh giữa tiêu đề mặc định
            ),

            // Định dạng TabBar (Tùy chọn)
            // === SỬA TẠI ĐÂY: Thêm 'Data' ===
            tabBarTheme: TabBarThemeData( // <--- SỬA LẠI THÀNH TabBarThemeData
              labelColor: Colors.orange.shade800, // Màu chữ tab được chọn
              unselectedLabelColor: Colors.black54, // Màu chữ tab chưa chọn
              indicatorColor: Colors.orange.shade800, // Màu đường gạch dưới
              labelStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600), // Font cho tab
              unselectedLabelStyle: GoogleFonts.beVietnamPro(),
            ),

            // Định dạng Nút nổi (Tùy chọn)
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),

            // Định dạng TextField (Tùy chọn)
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey.shade100, // Màu nền mặc định cho TextField
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // Padding bên trong
            ),

          ),

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('vi', 'VN'), // Hỗ trợ Tiếng Việt
          ],
          // ---------------------------------------------

          home: const AppController(),
        ),
      ),
    );
  }
}

// === KHÔNG CẦN SỬA AppController ===
class AppController extends StatelessWidget {
  const AppController({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          final UserModel? user = state.user;
          switch (user?.role) {
            case 'admin':
              return BlocProvider(
                create: (context) => DashboardBloc(apiService: context.read<ApiService>()),
                child: const AdminDashboardScreen(), // Trỏ đến màn hình mới
              );
            case 'waitstaff':
              return BlocProvider(
                create: (context) => ClockInBloc(apiService: context.read<ApiService>()),
                child: const HomeScreen(),
              );
            case 'kitchen':
              return BlocProvider(
                create: (context) => ClockInBloc(apiService: context.read<ApiService>()),
                child: const KitchenScreen(),
              );
            default:
            // === THÊM CONST ===
              return const LoginScreen();
          }
        }
        // === THÊM CONST ===
        return const LoginScreen();
      },
    );
  }
}