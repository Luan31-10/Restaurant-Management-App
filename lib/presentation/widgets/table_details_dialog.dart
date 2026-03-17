import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qlnh_app/data/models/table_model.dart';
import 'package:qlnh_app/data/services/api_service.dart';
import 'package:qlnh_app/logic/blocs/order_cart/order_cart_bloc.dart';
import 'package:qlnh_app/presentation/screens/edit_order_screen.dart';
import 'package:qlnh_app/presentation/screens/payment_screen.dart';

class TableDetailsDialog extends StatelessWidget {
  final TableModel table;

  const TableDetailsDialog({super.key, required this.table});

  void _navigateToEditOrder(BuildContext context) {
    Navigator.of(context).pop(); // Đóng dialog trước khi điều hướng
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => OrderCartBloc(apiService: context.read<ApiService>()),
          child: EditOrderScreen(table: table),
        ),
      ),
    );
  }

  void _navigateToPayment(BuildContext context) {
    Navigator.of(context).pop(); // Đóng dialog trước
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentScreen(table: table)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final order = table.activeOrder;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Để dialog tự co lại theo nội dung
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header: Tên bàn và Trạng thái ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(table.number, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text(
                  'Đang có khách',
                  style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // --- Tổng tiền ---
            Text(
              currencyFormatter.format(order?.totalAmount ?? 0),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const Divider(height: 24),
            // --- Danh sách món đã gọi ---
            const Text('Chi tiết Order:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 150, // Giới hạn chiều cao của danh sách
              child: (order == null || order.orderItems.isEmpty)
                  ? const Center(child: Text('Chưa có món nào được gọi.'))
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: order.orderItems.length,
                itemBuilder: (context, index) {
                  final item = order.orderItems[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      '${item.quantity}x',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                    ),
                    title: Text(item.menuItem.name),
                    trailing: Text(currencyFormatter.format(item.price * item.quantity)),
                  );
                },
              ),
            ),
            const Divider(height: 24),
            // --- Các nút hành động ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _navigateToEditOrder(context),
                    child: const Text('Thêm / Sửa Món'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _navigateToPayment(context),
                    child: const Text('Thanh Toán'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}