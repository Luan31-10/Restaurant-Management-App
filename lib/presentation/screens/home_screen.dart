import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qlnh_app/logic/blocs/auth/auth_bloc.dart';
import 'package:qlnh_app/logic/blocs/quick_sale/quick_sale_bloc.dart';
import 'package:qlnh_app/presentation/screens/menu_screen.dart';
import 'package:qlnh_app/presentation/screens/reservation_screen.dart';
import 'package:qlnh_app/presentation/screens/table_screen.dart';
import 'package:qlnh_app/presentation/screens/cart_summary_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:qlnh_app/logic/blocs/clock_in/clock_in_bloc.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    // YÊU CẦU KIỂM TRA TRẠNG THÁI CHẤM CÔNG KHI MÀN HÌNH KHỞI TẠO
    context.read<ClockInBloc>().add(CheckClockInStatus());
    _connectToSocket();
  }

  void _connectToSocket() {
    final user = context.read<AuthBloc>().state.user;
    socket = IO.io('http://192.168.2.5:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.connect();

    socket.onConnect((_) {
      print('✅ HomeScreen: Đã kết nối đến WebSocket Server');
      if (user != null) {
        socket.emit('join_role_room', user.role);
      }
    });

    socket.on('order_ready', (data) {
      if (mounted) {
        // Dùng lại Fluttertoast và key 'message' như cũ
        Fluttertoast.showToast(
            msg: data['message'],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0
        );
      }
    });

    socket.onDisconnect((_) => print('❌ HomeScreen: Đã ngắt kết nối WebSocket'));
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  static const List<Widget> _screens = [
    TableScreen(),
    MenuScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);

    return Scaffold(
        appBar: AppBar(
          title: Text('Xin chào, ${user?.name ?? ''}'),
          actions: [
            // --- THÊM WIDGET CHẤM CÔNG VÀO ĐÂY ---
            BlocConsumer<ClockInBloc, ClockInState>(
              listener: (context, state) {
                if (state.message.isNotEmpty && state.status != ClockInStatus.loading) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state.status == ClockInStatus.loading) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  );
                }
                if (state.status == ClockInStatus.clockedIn) {
                  return IconButton(
                    tooltip: 'Check-out',
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: () => context.read<ClockInBloc>().add(ClockOutRequested()),
                  );
                }
                return IconButton(
                  tooltip: 'Check-in',
                  icon: const Icon(Icons.login, color: Colors.lightGreenAccent),
                  onPressed: () => context.read<ClockInBloc>().add(ClockInRequested()),
                );
              },
            ),
            IconButton(
              tooltip: 'Quản lý Đặt bàn',
              icon: const Icon(Icons.bookmark_add_outlined),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationScreen()));
              },
            ),
            IconButton(
              tooltip: 'Đăng xuất',
              // Đổi icon để tránh nhầm lẫn
              icon: const Icon(Icons.power_settings_new),
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequested());
              },
            )
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.table_restaurant_outlined),
              label: 'Bàn ăn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              label: 'Thực đơn',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
        floatingActionButton: BlocBuilder<QuickSaleBloc, QuickSaleState>(
            builder: (context, state) {
              if (state.cartItems.isEmpty) {
                return const SizedBox.shrink();
              }
              return FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CartSummaryScreen()));
                },
                label: Text('${state.cartItems.length} món'),
                icon: const Icon(Icons.shopping_cart_outlined),
              );
            }
        )
    );
  }
}