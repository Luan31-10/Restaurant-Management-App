part of 'order_cart_bloc.dart';

abstract class OrderCartEvent extends Equatable {
  const OrderCartEvent();
  @override
  List<Object> get props => [];
}

// === CÁC SỰ KIỆN CỐT LÕI ===

// Nạp order cũ vào giỏ hàng khi sửa order
class InitializeCart extends OrderCartEvent {
  final List<CartItemModel> initialItems;
  const InitializeCart(this.initialItems);
  @override
  List<Object> get props => [initialItems];
}

// Thêm một món vào giỏ (tăng số lượng nếu đã có)
class AddItemToCart extends OrderCartEvent {
  final MenuItemModel menuItem;
  const AddItemToCart(this.menuItem);
  @override
  List<Object> get props => [menuItem];
}

// Giảm số lượng đi 1 (xóa nếu còn 1)
class DecrementItemInCart extends OrderCartEvent {
  final CartItemModel cartItem;
  const DecrementItemInCart(this.cartItem);
  @override
  List<Object> get props => [cartItem];
}

// Dọn sạch giỏ hàng
class ClearCart extends OrderCartEvent {}

// Gửi yêu cầu tạo order mới
class SubmitNewOrder extends OrderCartEvent {
  final int tableId;
  const SubmitNewOrder({required this.tableId});
  @override
  List<Object> get props => [tableId];
}

// Gửi yêu cầu cập nhật order đã có
class SubmitOrderChanges extends OrderCartEvent {
  final int orderId;
  const SubmitOrderChanges({required this.orderId});
  @override
  List<Object> get props => [orderId];
}


// === CÁC SỰ KIỆN NÂNG CẤP ===

// MỚI: Xóa hẳn một dòng item khỏi giỏ hàng, bất kể số lượng
class RemoveItemCompletely extends OrderCartEvent {
  final CartItemModel cartItem;
  const RemoveItemCompletely(this.cartItem);
  @override
  List<Object> get props => [cartItem];
}

// MỚI: Cập nhật ghi chú cho một item
class UpdateItemNote extends OrderCartEvent {
  final CartItemModel cartItem;
  final String note;
  const UpdateItemNote({required this.cartItem, required this.note});
  @override
  List<Object> get props => [cartItem, note];
}

// MỚI: Thiết lập một số lượng cụ thể cho item
class SetItemQuantity extends OrderCartEvent {
  final CartItemModel cartItem;
  final int quantity;
  const SetItemQuantity({required this.cartItem, required this.quantity});
  @override
  List<Object> get props => [cartItem, quantity];
}