part of 'table_bloc.dart';

abstract class TableEvent extends Equatable {
  const TableEvent();
  @override
  List<Object> get props => [];
}

class FetchTables extends TableEvent {}

class UpdateOrderStatus extends TableEvent {
  final int orderId;
  final String status;
  const UpdateOrderStatus(this.orderId, this.status, {required String paymentMethod});

  @override
  List<Object> get props => [orderId, status];
}

class UpdateTableStatus extends TableEvent {
  final int tableId;
  final String status;
  const UpdateTableStatus(this.tableId, this.status);

  @override
  List<Object> get props => [tableId, status];
}
class PayOrder extends TableEvent {
  final int orderId;
  final String paymentMethod;
  const PayOrder({
    required this.orderId,
    required this.paymentMethod
  });
  @override
  List<Object> get props => [orderId];
}

// === THÊM EVENT NÀY ===
// Event này được gọi KHI nhận được tin nhắn WebSocket
class TableStatusReceived extends TableEvent {
  final TableModel updatedTable; // Thông tin bàn mới từ WebSocket
  const TableStatusReceived(this.updatedTable);

  @override
  List<Object> get props => [updatedTable];
}