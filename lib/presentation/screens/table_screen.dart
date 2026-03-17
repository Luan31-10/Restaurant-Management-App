// table_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:qlnh_app/logic/blocs/tables/table_bloc.dart';
import 'package:qlnh_app/data/models/table_model.dart';
import 'package:qlnh_app/data/services/api_service.dart';
import 'package:qlnh_app/logic/blocs/auth/auth_bloc.dart';
import 'package:qlnh_app/presentation/widgets/floor_plan_table_widget.dart';
import 'package:qlnh_app/logic/blocs/order_cart/order_cart_bloc.dart';
import 'package:qlnh_app/presentation/screens/edit_order_screen.dart';
import 'package:qlnh_app/presentation/screens/order_creation_screen.dart';
import 'package:qlnh_app/presentation/screens/payment_screen.dart';
import '../../data/models/cart_item_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TableScreen extends StatefulWidget {
  // === THÊM CONST ===
  const TableScreen({Key? key}) : super(key: key);

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _connectToSocket();
    final currentTableState = context.read<TableBloc>().state;
    if (currentTableState is TableInitial || currentTableState is TableError) {
      context.read<TableBloc>().add(FetchTables());
    }
  }

  void _connectToSocket() {
    if (!mounted) return;
    try {
      final user = context.read<AuthBloc>().state.user;
      final baseUrl = context.read<ApiService>().baseUrl.replaceAll('/api', '');

      socket = IO.io(baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionDelay': 1000,
        'reconnectionAttempts': 5,
        'forceNew': true,
      });

      socket.onConnect((_) {
        print('✅ TableScreen: Đã kết nối đến WebSocket Server');
        if (user != null) {
          socket.emit('join_role_room', user.role);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Đã kết nối real-time (Bàn)'),
                backgroundColor: Colors.green, // Giữ màu xanh lá cho SnackBar này
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      });

      socket.on('table_status_updated', (data) {
        print('⚡️ TableScreen: Nhận được table_status_updated từ WebSocket.');
        if (mounted && data is Map<String, dynamic>) {
          try {
            final updatedTable = TableModel.fromJson(data);
            print('   Parse thành công Bàn: ID ${updatedTable.id}, Trạng thái ${updatedTable.status}');
            context.read<TableBloc>().add(TableStatusReceived(updatedTable));
          } catch (e, stacktrace) {
            print('❌ TableScreen: Lỗi parse TableModel từ WebSocket: $e');
            print('   Dữ liệu nhận được: $data');
            print('   Stacktrace: $stacktrace');
          }
        } else if (!mounted) {
          print('   Widget không còn mounted, bỏ qua cập nhật WebSocket.');
        } else {
          print('   Dữ liệu nhận được không đúng định dạng: $data');
        }
      });

      socket.onConnectError((data) => print(' Lỗi kết nối Socket (TableScreen): $data'));
      socket.onError((data) => print(' Lỗi Socket (TableScreen): $data'));
      socket.onDisconnect((_) => print(' TableScreen: Đã ngắt kết nối WebSocket'));

    } catch (e) {
      print(" TableScreen: Lỗi khi khởi tạo hoặc kết nối socket: $e");
    }
  }

  @override
  void dispose() {
    print(' TableScreen: Hủy kết nối WebSocket.');
    socket.dispose();
    super.dispose();
  }

  void _navigateToCreateOrder(BuildContext context, TableModel table) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => OrderCartBloc(apiService: context.read<ApiService>()),
          child: OrderCreationScreen(table: table),
        ),
      ),
    );
  }

  void _navigateToEditOrder(BuildContext context, TableModel table) {
    if (table.activeOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        // === THÊM CONST ===
          SnackBar(content: Text('${table.number} chưa có order nào.'), backgroundColor: Colors.orange)
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => OrderCartBloc(apiService: context.read<ApiService>())
            ..add(InitializeCart(
                table.activeOrder!.orderItems.map((oi) =>
                    CartItemModel(menuItem: oi.menuItem, quantity: oi.quantity)
                ).toList()
            )),
          child: EditOrderScreen(table: table),
        ),
      ),
    );
  }

  void _navigateToPayment(BuildContext context, TableModel table) {
    context.read<TableBloc>().add(UpdateTableStatus(table.id, 'billing'));
    if (table.activeOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        // === THÊM CONST ===
          SnackBar(content: Text('Bàn ${table.number} không có order nào đang hoạt động.'), backgroundColor: Colors.orange)
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<TableBloc>(),
            child: PaymentScreen(table: table),
          )
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TableBloc, TableState>(
      listener: (context, state) {
        if (state is TableLoaded) {
          if (state.status == TableStatus.error && state.errorMessage.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if(mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${state.errorMessage}'), backgroundColor: Colors.red)
                );
              }
            });
          } else if (state.status == TableStatus.paymentSuccess) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if(mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  // === THÊM CONST ===
                    const SnackBar(content: Text('Thanh toán thành công!'), backgroundColor: Colors.green)
                );
              }
            });
          } else if (state.status == TableStatus.paymentFailure) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if(mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Thanh toán thất bại: ${state.errorMessage}'), backgroundColor: Colors.red)
                );
              }
            });
          }
        } else if (state is TableError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if(mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi tải bàn: ${state.message}'), backgroundColor: Colors.red)
              );
            }
          });
        }
      },
      builder: (context, state) {
        Widget content;

        if (state is TableInitial || state is TableLoading) {
          // === THÊM CONST ===
          content = const Center(child: CircularProgressIndicator());
        }
        else if (state is TableError) {
          content = Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // === THÊM CONST ===
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  // === THÊM CONST ===
                  const SizedBox(height: 10),
                  Text('Lỗi tải danh sách bàn:\n${state.message}', textAlign: TextAlign.center),
                  // === THÊM CONST ===
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    // === THÊM CONST ===
                    icon: const Icon(Icons.refresh),
                    // === THÊM CONST ===
                    label: const Text('Thử lại'),
                    onPressed: () => context.read<TableBloc>().add(FetchTables()),
                  )
                ],
              )
          );
        }
        else if (state is TableLoaded) {
          if (state.tables.isEmpty && state.status != TableStatus.loading) {
            content = Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // === THÊM CONST ===
                    const Text("Không có bàn nào được cấu hình."),
                    // === THÊM CONST ===
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: ()=> context.read<TableBloc>().add(FetchTables()), child: const Text("Tải lại"))
                  ],
                )
            );
          } else {
            content = SingleChildScrollView(
              // === THÊM CONST ===
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // === THÊM CONST ===
                  const double spacing = 16.0;
                  final double itemWidth = (constraints.maxWidth - spacing * 3) / 2;

                  return Padding(
                    // === THÊM CONST ===
                    padding: const EdgeInsets.all(spacing),
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      // === 2. THÊM HIỆU ỨNG ANIMATION VÀO ĐÂY ===
                      children: state.tables.map((table) {
                        return SizedBox(
                          width: itemWidth,
                          child: FloorPlanTableWidget(
                            key: ValueKey(table.id), // Key quan trọng cho animation và cập nhật
                            table: table,
                            onNewOrderTap: () => _navigateToCreateOrder(context, table),
                            onAddItemsTap: () => _navigateToEditOrder(context, table),
                            onEditOrderTap: () => _navigateToEditOrder(context, table),
                            onCleanedTap: () => context.read<TableBloc>().add(UpdateTableStatus(table.id, 'available')),
                            onPaymentTap: () => _navigateToPayment(context, table),
                          ),
                        )
                            .animate() // Thêm animate
                            .fadeIn(duration: 500.ms) // Hiệu ứng mờ dần
                            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCirc); // Hiệu ứng trượt lên
                      }).toList(),
                      // ===========================================
                    ),
                  );
                },
              ),
            );
          }
        }
        else {
          // === THÊM CONST ===
          content = const Center(child: Text('Trạng thái không xác định.'));
        }

        return Container(
          // === 3. SỬ DỤNG MÀU TỪ THEME ===
          // color: const Color(0xFFF0F0F8), // Bỏ màu cố định
          color: Theme.of(context).colorScheme.background, // Dùng màu nền từ theme
          // ==============================
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<TableBloc>().add(FetchTables());
              await context.read<TableBloc>().stream.firstWhere((s) => s is TableLoaded || s is TableError);
            },
            child: Stack(
              children: [
                content,
                if (state is TableLoaded && state.status == TableStatus.loading)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        // === THÊM CONST ===
                        child: const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}