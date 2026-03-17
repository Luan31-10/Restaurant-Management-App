import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qlnh_app/data/models/cart_item_model.dart';
import 'package:qlnh_app/logic/blocs/quick_sale/quick_sale_bloc.dart';
import 'package:qlnh_app/logic/blocs/tables/table_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <<<--- ĐÃ THÊM IMPORT

class CartSummaryScreen extends StatelessWidget {
  const CartSummaryScreen({super.key});

  void _showTableSelectionDialog(BuildContext context) {
    context.read<TableBloc>().add(FetchTables());
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) {
        return BlocBuilder<TableBloc, TableState>(
          builder: (context, state) {
            if (state is TableLoading) return const Center(heightFactor: 3, child: CircularProgressIndicator());
            if (state is TableLoaded) {
              final availableTables = state.tables.where((t) => t.status == 'available').toList();
              if (availableTables.isEmpty) {
                return const Center(heightFactor: 3, child: Text("Không có bàn trống nào."));
              }
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Chọn bàn trống', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: availableTables.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final table = availableTables[index];
                          return ListTile(
                            leading: const Icon(Icons.table_restaurant_outlined),
                            title: Text(table.number, style: const TextStyle(fontWeight: FontWeight.bold)),
                            onTap: () {
                              context.read<QuickSaleBloc>().add(AssignCartToTable(table.id));
                              Navigator.of(dialogContext).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
            return const Center(heightFactor: 3, child: Text("Lỗi tải danh sách bàn."));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');

    return BlocListener<QuickSaleBloc, QuickSaleState>(
      listener: (context, state) {
        if (state.status == QuickSaleStatus.success) {
          context.read<TableBloc>().add(FetchTables());
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Tạo order thành công!'), backgroundColor: Colors.green));
        } else if (state.status == QuickSaleStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Tạo order thất bại!'), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Xác nhận Giỏ hàng'),
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        body: BlocBuilder<QuickSaleBloc, QuickSaleState>(
          builder: (context, state) {
            if (state.status == QuickSaleStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.cartItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text("Giỏ hàng của bạn đang trống.", style: TextStyle(color: Colors.grey, fontSize: 18)),
                  ],
                ),
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    itemCount: state.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = state.cartItems[index];
                      return _buildCartItemCard(context, item, currencyFormatter);
                    },
                  ),
                ),
                _buildSummarySection(context, state, currencyFormatter),
              ],
            );
          },
        ),
      ),
    );
  }

  // === HÀM ĐÃ ĐƯỢC CẬP NHẬT ===
  // Widget cho mỗi món ăn trong giỏ hàng
  Widget _buildCartItemCard(BuildContext context, CartItemModel item, NumberFormat formatter) {

    // === TẠO WIDGET PLACEHOLDER ===
    Widget imagePlaceholder = Container(
        width: 70,
        height: 70,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported, color: Colors.grey)
    );
    // ==============================

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),

              // === SỬA LỖI HIỂN THỊ ẢNH TẠI ĐÂY ===
              child: item.menuItem.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: item.menuItem.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(width: 70, height: 70, color: Colors.grey.shade200),
                errorWidget: (context, url, error) => imagePlaceholder,
              )
                  : imagePlaceholder, // Hiển thị placeholder nếu URL rỗng
              // ===================================
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.menuItem.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(formatter.format(item.menuItem.price), style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14)),
                ],
              ),
            ),
            // Bộ điều khiển số lượng
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  IconButton(
                    splashRadius: 20, visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: () => context.read<QuickSaleBloc>().add(DecrementItemInQuickSale(item)),
                  ),
                  Text(item.quantity.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    splashRadius: 20, visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () => context.read<QuickSaleBloc>().add(IncrementItemInQuickSale(item)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget cho phần tổng kết và nút bấm
  Widget _buildSummarySection(BuildContext context, QuickSaleState state, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng cộng:', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54)),
              Text(formatter.format(state.totalPrice), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
              icon: const Icon(Icons.table_restaurant_outlined),
              label: const Text('GÁN VÀO BÀN & TẠO ORDER'),
              onPressed: state.cartItems.isEmpty ? null : () => _showTableSelectionDialog(context),
            ),
          ),
        ],
      ),
    );
  }
}