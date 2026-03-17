part of 'edit_order_bloc.dart';

abstract class EditOrderEvent extends Equatable {
  const EditOrderEvent();
  @override
  List<Object> get props => [];
}

// Nạp các món đã có vào state
class LoadOrder extends EditOrderEvent {
  final List<CartItemModel> items;
  const LoadOrder(this.items);
  @override
  List<Object> get props => [items];
}

// Thêm một món mới chưa có trong giỏ
class AddNewItem extends EditOrderEvent {
  final MenuItemModel menuItem;
  const AddNewItem(this.menuItem);
  @override
  List<Object> get props => [menuItem];
}

// Tăng số lượng món đã có
class IncrementItem extends EditOrderEvent {
  final CartItemModel item;
  const IncrementItem(this.item);
  @override
  List<Object> get props => [item];
}

// Giảm số lượng món đã có
class DecrementItem extends EditOrderEvent {
  final CartItemModel item;
  const DecrementItem(this.item);
  @override
  List<Object> get props => [item];
}

// Gửi thay đổi lên server
class SaveChanges extends EditOrderEvent {
  final int orderId;
  const SaveChanges(this.orderId);
  @override
  List<Object> get props => [orderId];
}