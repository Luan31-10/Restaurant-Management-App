import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:qlnh_app/data/models/active_order_model.dart'; // Model Order
import 'package:qlnh_app/data/models/menu_item_model.dart'; // Model MenuItem (cần cho OrderTicket)
import 'package:qlnh_app/logic/blocs/auth/auth_bloc.dart';
import 'package:qlnh_app/logic/blocs/kitchen/kitchen_bloc.dart'; // Bloc của màn hình này
import 'package:qlnh_app/logic/blocs/clock_in/clock_in_bloc.dart';
import 'package:qlnh_app/data/services/api_service.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  // === KHAI BÁO BIẾN SOCKET ===
  late IO.Socket socket;
  // ==========================

  @override
  void initState() {
    super.initState();
    // Kiểm tra trạng thái chấm công
    context.read<ClockInBloc>().add(CheckClockInStatus());
    // Gọi Fetch lần đầu để lấy dữ liệu ban đầu
    context.read<KitchenBloc>().add(FetchKitchenOrders());
    // === KẾT NỐI WEBSOCKET ===
    _connectToSocket();
    // ========================
  }

  // === HÀM KẾT NỐI SOCKET ===
  void _connectToSocket() {
    // Đảm bảo widget còn tồn tại trước khi dùng context
    if (!mounted) return;
    try {
      // Lấy thông tin user và baseUrl
      final user = context.read<AuthBloc>().state.user;
      final baseUrl = context.read<ApiService>().baseUrl.replaceAll('/api', '');

      // Khởi tạo socket
      socket = IO.io(baseUrl, <String, dynamic>{
        'transports': ['websocket'], // Chỉ dùng websocket
        'autoConnect': true, // Tự động kết nối
        'reconnection': true, // Tự động kết nối lại nếu mất mạng
        'reconnectionDelay': 1000, // Delay 1 giây
        'reconnectionAttempts': 5, // Thử kết nối lại 5 lần

        // === SỬA LỖI: Buộc tạo kết nối mới, không dùng cache ===
        'forceNew': true,
        // ====================================================
      });

      // Lắng nghe sự kiện 'connect'
      socket.onConnect((_) {
        print('✅ KitchenScreen: Đã kết nối đến WebSocket Server');
        // Bếp join phòng 'kitchen'
        if (user != null) {
          // Gửi đúng role 'kitchen'
          socket.emit('join_role_room', 'kitchen');
        }

        // === THÊM MỚI: HIỂN THỊ SNACKBAR KHI KẾT NỐI THÀNH CÔNG ===
        // Dùng addPostFrameCallback để đảm bảo context hợp lệ và Scaffold đã sẵn sàng
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) { // Kiểm tra xem widget còn tồn tại không
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✅ Đã kết nối real-time (Bếp)'),
                backgroundColor: Colors.green.shade600, // Màu xanh lá
                behavior: SnackBarBehavior.floating, // Cho SnackBar nổi lên
                duration: const Duration(seconds: 3), // Hiện trong 3 giây
              ),
            );
          }
        });
        // ========================================================
      });

      // === LẮNG NGHE CÁC SỰ KIỆN TỪ BACKEND ===
      // 1. Order mới được tạo
      socket.on('new_order', (data) {
        print('⚡️ KitchenScreen: Nhận được new_order');
        _handleOrderUpdate(data); // Dùng chung hàm xử lý
      });

      // 2. Order được cập nhật (trạng thái, món ăn, bếp/nhân viên cập nhật)
      socket.on('order_updated', (data) {
        print('⚡️ KitchenScreen: Nhận được order_updated');
        _handleOrderUpdate(data); // Dùng chung hàm xử lý
      });

      // 3. Order bị hủy (Backend cần emit event này, ví dụ 'order_cancelled')
      // Đảm bảo backend có emit event này khi order chuyển sang 'cancelled'
      socket.on('order_cancelled', (data) {
        print('🗑️ KitchenScreen: Nhận được order_cancelled');
        _handleOrderCancellation(data);
      });
      // =======================================

      // Các sự kiện lỗi và ngắt kết nối
      socket.onConnectError((data) =>
          print('❌ Lỗi kết nối Socket (KitchenScreen): $data'));
      socket.onError(
              (data) => print('❌ Lỗi Socket (KitchenScreen): $data'));
      socket.onDisconnect(
              (_) => print('🔌 KitchenScreen: Đã ngắt kết nối WebSocket'));

      // Bắt đầu kết nối nếu autoConnect là false
      // socket.connect();

    } catch (e) {
      print("❌ KitchenScreen: Lỗi khi khởi tạo hoặc kết nối socket: $e");
      // Hiển thị SnackBar báo lỗi kết nối real-time
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                Text('Lỗi kết nối real-time: $e. Vui lòng kiểm tra lại.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5)),
          );
        }
      });
    }
  }
  // =============================

  // === HÀM XỬ LÝ DỮ LIỆU ORDER TỪ WEBSOCKET ===
  void _handleOrderUpdate(dynamic data) {
    // Kiểm tra widget còn tồn tại và data là Map hợp lệ
    if (mounted && data is Map<String, dynamic>) {
      try {
        // Parse dữ liệu JSON thành ActiveOrderModel
        // Đảm bảo ActiveOrderModel.fromJson xử lý đúng cấu trúc JSON backend gửi
        final updatedOrder = ActiveOrderModel.fromJson(data);
        // Gửi event KitchenOrderReceived đến KitchenBloc
        context.read<KitchenBloc>().add(KitchenOrderReceived(updatedOrder));
      } catch (e, stacktrace) {
        // Log lỗi chi tiết nếu parse thất bại
        print('❌ KitchenScreen: Lỗi parse ActiveOrderModel từ WebSocket: $e');
        print('   Data nhận được: $data');
        print('   Stacktrace: $stacktrace');
        // Cân nhắc: Có thể gọi FetchKitchenOrders để đồng bộ lại toàn bộ nếu parse lỗi
        // context.read<KitchenBloc>().add(FetchKitchenOrders());
      }
    } else {
      print(
          '⚠️ KitchenScreen: Nhận được dữ liệu order update không hợp lệ hoặc màn hình đã dispose.');
    }
  }

  // === HÀM XỬ LÝ ORDER BỊ HỦY TỪ WEBSOCKET ===
  void _handleOrderCancellation(dynamic data) {
    // Kiểm tra widget còn tồn tại và data là Map hợp lệ
    if (mounted && data is Map<String, dynamic>) {
      try {
        // Parse dữ liệu JSON (chỉ cần ID là đủ, nhưng parse cả object cũng không sao)
        final cancelledOrder = ActiveOrderModel.fromJson(data);
        // Gửi event KitchenOrderCancelled đến KitchenBloc
        context.read<KitchenBloc>().add(KitchenOrderCancelled(cancelledOrder));
      } catch (e, stacktrace) {
        // Log lỗi chi tiết nếu parse thất bại
        print(
            '❌ KitchenScreen: Lỗi parse ActiveOrderModel (cancel) từ WebSocket: $e');
        print('   Data nhận được: $data');
        print('   Stacktrace: $stacktrace');
      }
    } else {
      print(
          '⚠️ KitchenScreen: Nhận được dữ liệu order cancel không hợp lệ hoặc màn hình đã dispose.');
    }
  }
  // ======================================

  @override
  void dispose() {
    // === HỦY KẾT NỐI SOCKET KHI MÀN HÌNH BỊ HỦY ===
    print('🔌 KitchenScreen: Hủy kết nối WebSocket.');
    socket.dispose();
    // ==========================================
    super.dispose();
  }

  // --- HÀM BUILD VÀ CÁC WIDGET CON ---
  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.user);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC), // Màu nền sáng
      appBar: AppBar(
        title: Text('Bếp - ${user?.name ?? ''}'),
        centerTitle: false, // Tiêu đề căn trái
        backgroundColor: Colors.white, // Nền AppBar trắng
        foregroundColor: Colors.black87, // Màu chữ/icon AppBar đen
        elevation: 1, // Đổ bóng nhẹ cho AppBar
        automaticallyImplyLeading: false, // Ẩn nút back tự động
        actions: [
          // Widget Chấm công (Giữ nguyên)
          BlocConsumer<ClockInBloc, ClockInState>(
            listener: (context, state) {
              if (state.message.isNotEmpty &&
                  state.status != ClockInStatus.loading) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              if (state.status == ClockInStatus.loading) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.black87, strokeWidth: 2)),
                );
              }
              if (state.status == ClockInStatus.clockedIn) {
                return IconButton(
                  tooltip: 'Check-out',
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  onPressed: () =>
                      context.read<ClockInBloc>().add(ClockOutRequested()),
                );
              }
              return IconButton(
                tooltip: 'Check-in',
                icon: const Icon(Icons.login, color: Colors.green),
                onPressed: () =>
                    context.read<ClockInBloc>().add(ClockInRequested()),
              );
            },
          ),
          // Nút Đăng xuất (Giữ nguyên)
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.power_settings_new),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
              // Navigator.of(context).pushReplacement(...); // Điều hướng về Login nếu cần
            },
          )
        ],
      ),
      // Dùng BlocConsumer để lắng nghe lỗi và rebuild UI
      body: BlocConsumer<KitchenBloc, KitchenState>(
        listener: (context, state) {
          // Hiển thị SnackBar nếu có lỗi ngầm (vd: lỗi gọi API update)
          if (state.status == KitchenStatus.error &&
              state.errorMessage.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Lỗi: ${state.errorMessage}'),
                      backgroundColor: Colors.red),
                );
                // Cân nhắc xóa lỗi sau khi hiển thị để không hiện lại
                // context.read<KitchenBloc>().add(ClearKitchenError());
              }
            });
          }
        },
        builder: (context, state) {
          // --- Xử lý trạng thái Loading và Error ban đầu ---
          // Chỉ hiện loading toàn màn hình khi chưa có data và đang load
          if ((state.status == KitchenStatus.initial ||
              state.status == KitchenStatus.loading) &&
              state.pendingOrders.isEmpty &&
              state.preparingOrders.isEmpty &&
              state.readyOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          // Hiện lỗi nếu là trạng thái error và không có data cũ để hiển thị
          if (state.status == KitchenStatus.error &&
              state.pendingOrders.isEmpty &&
              state.preparingOrders.isEmpty &&
              state.readyOrders.isEmpty) {
            return Center(
                child: Padding(
                  // Thêm Padding cho đẹp
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: Colors.red.shade700, size: 60),
                      const SizedBox(height: 16),
                      Text('Lỗi tải dữ liệu bếp:\n${state.errorMessage}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Thử lại'),
                        onPressed: () =>
                            context.read<KitchenBloc>().add(FetchKitchenOrders()),
                      )
                    ],
                  ),
                ));
          }
          // --- Giao diện chính với các cột ---
          // Luôn hiển thị giao diện cột nếu đã có data (kể cả khi đang loading ngầm hoặc có lỗi ngầm)
          return ListView(
            scrollDirection: Axis.horizontal, // Cuộn ngang
            padding: const EdgeInsets.all(8.0), // Padding bao ngoài các cột
            children: [
              // Cột 'Mới'
              _buildOrderColumn('Mới', 'pending', state.pendingOrders, context,
                  Icons.new_releases_rounded, Colors.blue.shade700),
              // Cột 'Đang làm'
              _buildOrderColumn(
                  'Đang làm',
                  'preparing',
                  state.preparingOrders,
                  context,
                  Icons.local_fire_department_rounded,
                  Colors.orange.shade800),
              // Cột 'Sẵn sàng'
              _buildOrderColumn('Sẵn sàng', 'ready', state.readyOrders, context,
                  Icons.check_circle_rounded, Colors.green.shade600),
            ],
          );
          // --- Kết thúc giao diện chính ---
        },
      ),
    );
  }

  // --- Widget xây dựng một cột Order ---
  Widget _buildOrderColumn(
      String title,
      String statusKey,
      List<ActiveOrderModel> orders,
      BuildContext context,
      IconData icon,
      Color color) {
    // Dùng DragTarget để cho phép thả Order vào cột này
    return DragTarget<ActiveOrderModel>(
      // Hàm builder để vẽ giao diện cột
      builder: (context, candidateData, rejectedData) {
        // candidateData: List các order đang được kéo LÊN TRÊN cột này
        // rejectedData: List các order bị từ chối thả vào cột này (ít dùng)
        bool isHighlighted = candidateData.isNotEmpty; // Highlight cột nếu có order đang kéo qua

        return Container(
          width: 340, // Chiều rộng cố định cho mỗi cột
          margin: const EdgeInsets.symmetric(horizontal: 8.0), // Khoảng cách giữa các cột
          // Trang trí cột: bo góc, màu nền, viền highlight
          decoration: BoxDecoration(
            color: Colors.white, // Nền trắng cho cột
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isHighlighted
                  ? color.withOpacity(0.6)
                  : Colors.grey.shade300, // Viền xám hoặc màu highlight
              width: isHighlighted ? 3 : 1, // Viền dày hơn khi highlight
            ),
            boxShadow: isHighlighted
                ? [
              // Đổ bóng nhẹ khi highlight
              BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2)
            ]
                : [
              // Đổ bóng nhẹ bình thường
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch, // Kéo dãn header/divider
            children: [
              // --- Header của cột ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 28), // Icon trạng thái
                    const SizedBox(width: 10),
                    // Tiêu đề cột (Tên + Số lượng)
                    Text('$title ',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color)),
                    Text('(${orders.length})',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: color.withOpacity(0.8))),
                    const Spacer(), // Đẩy về 2 phía
                    // Có thể thêm nút action cho cột (vd: làm tất cả món cột 'Mới')
                  ],
                ),
              ),
              const Divider(
                  height: 1, indent: 16, endIndent: 16, thickness: 1), // Đường kẻ phân cách
              // --- Danh sách các thẻ Order ---
              Expanded(
                // Xử lý trường hợp cột trống
                child: orders.isEmpty
                    ? Center(
                    child: Text('Không có order',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                            fontStyle: FontStyle.italic)))
                // ListView chứa các thẻ Order có thể kéo thả
                    : ListView.builder(
                  itemCount: orders.length,
                  padding:
                  const EdgeInsets.all(12.0), // Padding cho các thẻ bên trong
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    // Draggable: Cho phép kéo thẻ Order này đi
                    return Draggable<ActiveOrderModel>(
                      key: ValueKey(order.id), // Key để Flutter nhận diện đúng Order
                      data: order, // Dữ liệu được mang theo khi kéo
                      // Giao diện thẻ khi đang kéo (feedback)
                      feedback: SizedBox(
                          width: 316, // Chiều rộng nhỏ hơn cột một chút
                          child: Material(
                            // Bọc Material để có hiệu ứng đổ bóng khi kéo
                              elevation: 6.0,
                              borderRadius: BorderRadius.circular(12),
                              child: OrderTicket(
                                  order: order, isDragging: true))),
                      // Giao diện thẻ gốc bị mờ đi khi đang kéo
                      childWhenDragging: Opacity(
                          opacity: 0.3, child: OrderTicket(order: order)),
                      // Giao diện thẻ bình thường
                      child: OrderTicket(order: order),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      // --- Xử lý khi thả Order vào cột ---
      // Dùng onAcceptWithDetails để nhận cả dữ liệu (order được thả)
      onAcceptWithDetails: (details) {
        final droppedOrder = details.data; // Lấy ActiveOrderModel từ data
        // Chỉ gọi BLoC để cập nhật nếu trạng thái của order khác với trạng thái của cột
        if (droppedOrder.status != statusKey) {
          print('--> Bếp thả Order ${droppedOrder.id} vào cột $statusKey');
          // Gọi event UpdateOrderStatusKitchen của KitchenBloc
          context.read<KitchenBloc>().add(UpdateOrderStatusKitchen(
              orderId: droppedOrder.id, status: statusKey));
        } else {
          print(
              '--> Thả Order ${droppedOrder.id} vào cùng cột ${statusKey}, không cần cập nhật.');
        }
      },
      // (Tùy chọn) Hàm kiểm tra xem có cho phép thả vào cột này không
      onWillAcceptWithDetails: (details) {
        // Luôn cho phép thả trong trường hợp này
        return true;
        // Có thể thêm logic phức tạp hơn, vd: không cho kéo ngược từ 'Ready' về 'Preparing'
        //final draggedStatus = details.data.status;
        //if (statusKey == 'preparing' && draggedStatus == 'ready') return false;
        //return true;
      },
    );
  } // --- Kết thúc _buildOrderColumn ---

} // --- Kết thúc _KitchenScreenState ---

// === WIDGET OrderTicket (Không thay đổi nhiều, giữ nguyên từ file bạn gửi) ===
class OrderTicket extends StatelessWidget {
  final ActiveOrderModel order;
  final bool isDragging;
  const OrderTicket({super.key, required this.order, this.isDragging = false});

  // Hàm tính màu dựa trên thời gian chờ
  Color _getColorForOrder(Duration duration) {
    if (duration.inMinutes >= 15) return Colors.red.shade800;
    if (duration.inMinutes >= 7) return Colors.orange.shade800;
    return Colors.blue.shade700;
  }

  // Hàm hiển thị dialog xác nhận
  void _showConfirmationDialog(BuildContext context,
      {required String title,
        required String content,
        required VoidCallback onConfirm}) {
    // Hiện AlertDialog
    showDialog(
      context: context,
      // barrierDismissible: false, // Ngăn đóng khi bấm ra ngoài (tùy chọn)
      builder: (ctx) => AlertDialog(
        // ctx là BuildContext của dialog
        title: Text(title), // Tiêu đề dialog
        content: Text(content), // Nội dung dialog
        actions: <Widget>[
          // Các nút bấm
          // Nút Hủy
          TextButton(
            child: const Text('Hủy'),
            onPressed: () {
              Navigator.of(ctx).pop(); // Đóng dialog
            },
          ),
          // Nút Xác nhận
          FilledButton(
            // Dùng FilledButton cho nổi bật
            child: const Text('Xác nhận'),
            onPressed: () {
              onConfirm(); // Thực hiện hành động đã truyền vào
              Navigator.of(ctx).pop(); // Đóng dialog
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = DateTime.now().difference(order.createdAt);
    final color = _getColorForOrder(duration);
    // --- Biến isTakeAway được định nghĩa ở đây ---
    final bool isTakeAway =
        order.tableNumber == null || order.tableNumber!.isEmpty;
    // ------------------------------------------

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      // Cần có decoration để hiển thị (ví dụ từ code của bạn)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Header của thẻ ---
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            // Cần có decoration để hiển thị (ví dụ từ code của bạn)
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tên bàn hoặc Mang về
                Text(
                  isTakeAway ? 'MANG VỀ' : 'BÀN ${order.tableNumber}', // Sử dụng isTakeAway
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5),
                ),
                // Thời gian chờ
                Text(
                  '${duration.inMinutes} phút',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          // --- Danh sách món ăn ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
            child: Column(
              children: order.orderItems
                  .map((item) => _buildItemRow(context, item))
                  .toList(),
            ),
          ),
          // --- Nút Action Tổng (Làm tất cả / Hoàn thành) ---
          if (order.status != 'ready')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: SizedBox(
                  width: double.infinity,
                  // === SỬA LẠI: TRUYỀN isTakeAway VÀO HÀM ===
                  child: _buildOrderActionButton(order, context, isTakeAway)
                // =======================================
              ),
            ),
        ],
      ),
    );
  }

  // Widget hiển thị một dòng món ăn (Giữ nguyên)
  Widget _buildItemRow(BuildContext context, OrderItemDetail item) {
    bool isItemReady = item.status == 'ready'; // Kiểm tra món đã xong chưa
    Color textColor =
    isItemReady ? Colors.grey.shade600 : Colors.black87; // Màu chữ
    TextDecoration textDecoration =
    isItemReady ? TextDecoration.lineThrough : TextDecoration.none; // Gạch ngang

    return Padding(
      // Dùng Padding thay vì AnimatedPadding nếu không cần animation phức tạp
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Tên món và số lượng
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  // Số lượng
                  TextSpan(
                    text: '${item.quantity}x ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isItemReady
                            ? Colors.grey.shade600
                            : Theme.of(context)
                            .primaryColorDark, // Màu số lượng
                        decoration: textDecoration,
                        decorationColor: Colors.grey.shade600,
                        decorationThickness: 1.5),
                  ),
                  // Tên món
                  TextSpan(
                    text: item.menuItem.name,
                    style: TextStyle(
                        fontSize: 15, // Cỡ chữ tên món
                        color: textColor,
                        decoration: textDecoration,
                        decorationColor: Colors.grey.shade600,
                        decorationThickness: 1.5),
                  ),
                ],
              ),
              maxLines: 2, // Cho phép xuống dòng nếu tên quá dài
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Nút Action cho từng món (Làm / Xong)
          _buildItemActionButton(context, item), // Gọi hàm build nút
        ],
      ),
    );
  }

  // --- Widget xây dựng nút Action cho từng món ---
  Widget _buildItemActionButton(BuildContext context, OrderItemDetail item) {
    final bloc = context.read<KitchenBloc>(); // Lấy bloc
    const buttonHeight = 32.0; // Chiều cao nút nhỏ
    const buttonPadding =
    EdgeInsets.symmetric(horizontal: 10); // Padding nút

    switch (item.status) {
      case 'pending': // Món mới
        return SizedBox(
            height: buttonHeight,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: buttonPadding,
                side: BorderSide(color: Colors.orange.shade800), // Viền màu cam
                foregroundColor: Colors.orange.shade800, // Chữ màu cam
              ),
              onPressed: () => bloc.add(
                  UpdateOrderItemStatus(orderItemId: item.id, status: 'preparing')),
              child: const Text('Làm'),
            ));
      case 'preparing': // Món đang làm
        return SizedBox(
            height: buttonHeight,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade600, // Nền màu xanh lá
                padding: buttonPadding,
              ),
              onPressed: () => bloc.add(
                  UpdateOrderItemStatus(orderItemId: item.id, status: 'ready')),
              child: const Text('Xong'),
            ));
      case 'ready': // Món đã xong
      // Hiển thị icon check thay vì nút
        return Icon(Icons.check_circle,
            color: Colors.green.shade600, size: 24); // Icon nhỏ hơn
      default:
        return const SizedBox.shrink(); // Không hiển thị gì cho trạng thái khác
    }
  }

  // === SỬA LẠI: THÊM THAM SỐ bool isTakeAway ===
  Widget _buildOrderActionButton(
      ActiveOrderModel order, BuildContext context, bool isTakeAway) {
    // ==========================================
    final bloc = context.read<KitchenBloc>();
    final areAllItemsReady = order.orderItems
        .where((i) => i.status != 'cancelled')
        .every((item) => item.status == 'ready');

    switch (order.status) {
      case 'pending':
        return FilledButton.icon(
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: const Text('LÀM TẤT CẢ'),
          style: FilledButton.styleFrom( // Thêm style cơ bản
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.bold)
          ),
          onPressed: () => _showConfirmationDialog(
            context,
            title: 'Xác nhận',
            // === SỬA LẠI: DÙNG THAM SỐ isTakeAway ===
            content:
            'Bắt đầu làm tất cả món cho ${isTakeAway ? 'Mang về' : 'Bàn ${order.tableNumber}'}?',
            // ===================================
            onConfirm: () => bloc.add(
                UpdateOrderStatusKitchen(orderId: order.id, status: 'preparing')),
          ),
        );
      case 'preparing':
        return FilledButton.icon(
          icon: const Icon(Icons.done_all_rounded, size: 20),
          label: const Text('HOÀN THÀNH ORDER'),
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              backgroundColor:
              areAllItemsReady ? Colors.green.shade600 : Colors.grey.shade400,
              disabledBackgroundColor: Colors.grey.shade400,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
              textStyle: const TextStyle(fontWeight: FontWeight.bold)),
          onPressed: areAllItemsReady
              ? () => _showConfirmationDialog(
              context,
              title: 'Xác nhận',
              // === SỬA LẠI: DÙNG THAM SỐ isTakeAway ===
              content:
              'Order cho ${isTakeAway ? 'Mang về' : 'Bàn ${order.tableNumber}'} đã sẵn sàng?',
              // ===================================
              onConfirm: () => bloc.add(UpdateOrderStatusKitchen(
                  orderId: order.id, status: 'ready')))
              : null,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}