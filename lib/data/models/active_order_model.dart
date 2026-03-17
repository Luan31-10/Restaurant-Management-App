// Mở file lib/data/models/active_order_model.dart và thay thế bằng code này.

import 'package:qlnh_app/data/models/menu_item_model.dart';

class ActiveOrderModel {
  final int id;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final String? tableNumber;
  final List<OrderItemDetail> orderItems;

  ActiveOrderModel({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    this.tableNumber,
    required this.orderItems,
  });

  factory ActiveOrderModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['OrderItems'] as List;
    List<OrderItemDetail> orderItems =
    itemsList.map((i) => OrderItemDetail.fromJson(i)).toList();

    return ActiveOrderModel(
      // SỬA LỖI: Chuyển đổi an toàn sang int và double
      id: int.parse(json['id'].toString()),
      status: json['status'],
      totalAmount: double.parse(json['totalAmount'].toString()),
      createdAt: DateTime.parse(json['createdAt']),
      // Giả sử tên cột đúng trong DB là 'name'
      tableNumber: json['Table']?['number'],
      orderItems: orderItems,
    );
  }
}

class OrderItemDetail {
  final int id;
  final int orderId;
  final int quantity;
  final double price;
  final String status;
  final MenuItemModel menuItem;
  final DateTime updatedAt;

  OrderItemDetail({
    required this.id,
    required this.orderId,
    required this.quantity,
    required this.price,
    required this.status,
    required this.menuItem,
    required this.updatedAt,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) {
    return OrderItemDetail(
      // SỬA LỖI: Chuyển đổi an toàn sang int và double
      id: int.parse(json['id'].toString()),
      orderId: json['orderId'],
      quantity: int.parse(json['quantity'].toString()),
      price: double.parse(json['price'].toString()),
      status: json['status'] ?? 'pending',
      menuItem: MenuItemModel.fromJson(json['MenuItem']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}