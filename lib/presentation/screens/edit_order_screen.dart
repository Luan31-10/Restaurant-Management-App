import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qlnh_app/data/models/cart_item_model.dart';
import 'package:qlnh_app/data/models/table_model.dart';
import 'package:qlnh_app/logic/blocs/menu_items/menu_item_bloc.dart';
import 'package:qlnh_app/logic/blocs/order_cart/order_cart_bloc.dart';
import 'package:qlnh_app/logic/blocs/tables/table_bloc.dart';
import 'package:qlnh_app/presentation/widgets/menu_for_order.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <<<--- THÊM IMPORT NÀY

class EditOrderScreen extends StatefulWidget {
  final TableModel table;
  const EditOrderScreen({super.key, required this.table});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  @override
  void initState() {
    super.initState();
    // Tải danh sách tất cả món ăn để hiển thị trong thực đơn
    context.read<MenuItemBloc>().add(FetchMenuItems());

    // Nạp các món ăn từ order cũ vào giỏ hàng (BLoC) khi màn hình được mở
    // (Kiểm tra xem BLoC đã được khởi tạo từ màn hình Table chưa)
    // Thông thường, việc này đã được làm ở table_screen.dart trước khi push
    // Nhưng chúng ta có thể làm lại để đảm bảo
    if (widget.table.activeOrder != null && context.read<OrderCartBloc>().state.cartItems.isEmpty) {
      final initialCartItems = widget.table.activeOrder!.orderItems.map((orderItem) {
        return CartItemModel(menuItem: orderItem.menuItem, quantity: orderItem.quantity);
      }).toList();
      context.read<OrderCartBloc>().add(InitializeCart(initialCartItems));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderCartBloc, OrderCartState>(
      listener: (context, state) {
        if (state.status == OrderCartStatus.success) {
          // Khi cập nhật thành công, tải lại danh sách bàn và quay về
          context.read<TableBloc>().add(FetchTables());
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Cập nhật order thành công!'), backgroundColor: Colors.green));
        } else if (state.status == OrderCartStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('Lỗi: ${state.errorMessage}'), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sửa Order cho ${widget.table.number}'),
        ),
        // THAY ĐỔI LỚN: Chia body thành 2 phần
        body: Column(
          children: [
            // Phần 1: Các món đã có trong order
            _buildCurrentOrderItems(),
            const Divider(thickness: 8, color: Color(0xFFF0F0F8)),
            // Phần 2: Thực đơn để thêm món mới
            const Expanded(child: MenuForOrder()),
          ],
        ),
        // Nút bấm "Lưu thay đổi"
        bottomSheet: _buildCartSummary(),
      ),
    );
  }

  // WIDGET MỚI: Hiển thị danh sách các món hiện tại
  Widget _buildCurrentOrderItems() {
    // === TẠO WIDGET PLACEHOLDER GIỐNG NHƯ FILE KIA ===
    Widget imagePlaceholder = Container(
      width: 50,
      height: 50,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
    // ===============================================

    return BlocBuilder<OrderCartBloc, OrderCartState>(
      builder: (context, cartState) {
        if (cartState.cartItems.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('Chưa có món nào trong order.')),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Các món đã gọi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150, // Giới hạn chiều cao
                child: ListView.builder(
                  itemCount: cartState.cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartState.cartItems[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,

                      // === SỬA LỖI: THÊM ẢNH VÀO ĐÂY ===
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: cartItem.menuItem.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: cartItem.menuItem.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade200),
                          errorWidget: (context, url, error) =>
                          imagePlaceholder,
                        )
                            : imagePlaceholder,
                      ),
                      // ===================================

                      title: Text(cartItem.menuItem.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.redAccent),
                            onPressed: () => context
                                .read<OrderCartBloc>()
                                .add(DecrementItemInCart(cartItem)),
                          ),
                          Text(cartItem.quantity.toString(),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                color: Colors.green),
                            onPressed: () => context
                                .read<OrderCartBloc>()
                                .add(AddItemToCart(cartItem.menuItem)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget để hiển thị tổng tiền và nút lưu
  Widget _buildCartSummary() {
    final currencyFormatter =
    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return BlocBuilder<OrderCartBloc, OrderCartState>(
      // === SỬA LẠI: BUILD KHI LÀ INITIAL HOẶC LOADING ===
      // (Để nút bấm không bị ẩn khi đang load)
      buildWhen: (prev, curr) =>
      curr.status == OrderCartStatus.initial ||
          curr.status == OrderCartStatus.loading,
      builder: (context, cartState) {
        // if (cartState.status != OrderCartStatus.initial) return const SizedBox.shrink(); // Bỏ dòng này

        return Container(
          padding: const EdgeInsets.all(16)
              .copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng cộng:', style: TextStyle(fontSize: 18)),
                  Text(
                    currencyFormatter.format(cartState.totalPrice),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: cartState.status == OrderCartStatus.loading
                      ? null
                      : () {
                    if (widget.table.activeOrder != null) {
                      // Gửi event để lưu các thay đổi của order
                      context.read<OrderCartBloc>().add(
                          SubmitOrderChanges(
                              orderId: widget.table.activeOrder!.id));
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: cartState.status == OrderCartStatus.loading
                      ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3))
                      : const Text('LƯU THAY ĐỔI'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}