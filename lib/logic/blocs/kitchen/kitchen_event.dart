part of 'kitchen_bloc.dart';

abstract class KitchenEvent extends Equatable {
  const KitchenEvent();
  @override
  List<Object> get props => [];
}

// Giữ nguyên các event cũ
class FetchKitchenOrders extends KitchenEvent {}

class UpdateOrderStatusKitchen extends KitchenEvent {
  final int orderId;
  final String status;

  const UpdateOrderStatusKitchen({required this.orderId, required this.status});
  @override
  List<Object> get props => [orderId, status];
}
class UpdateOrderItemStatus extends KitchenEvent {
  final int orderItemId;
  final String status;

  const UpdateOrderItemStatus({required this.orderItemId, required this.status});

  @override
  List<Object> get props => [orderItemId, status];
}

// === THÊM 2 EVENT MỚI CHO WEBSOCKET ===

// Nhận được order mới hoặc cập nhật từ WebSocket
class KitchenOrderReceived extends KitchenEvent {
  final ActiveOrderModel order; // Dữ liệu order đầy đủ từ WebSocket
  const KitchenOrderReceived(this.order);

  @override
  List<Object> get props => [order];
}

// Nhận được thông báo order bị hủy từ WebSocket
class KitchenOrderCancelled extends KitchenEvent {
  final ActiveOrderModel order; // Dữ liệu order bị hủy từ WebSocket (ít nhất cần ID)
  const KitchenOrderCancelled(this.order);

  @override
  List<Object> get props => [order];
}
// ===================================