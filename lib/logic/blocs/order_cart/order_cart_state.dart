part of 'order_cart_bloc.dart';

enum OrderCartStatus { initial, loading, success, failure }

class OrderCartState extends Equatable {
  final List<CartItemModel> cartItems;
  final OrderCartStatus status;
  final String errorMessage;

  const OrderCartState({
    this.cartItems = const [],
    this.status = OrderCartStatus.initial,
    this.errorMessage = '',
  });

  // Tính tổng tiền
  double get totalPrice => cartItems.fold(
      0.0, (sum, current) => sum + (current.menuItem.price * current.quantity));

  // MỚI: Lấy tổng số lượng tất cả các món
  int get totalItems => cartItems.fold(
      0, (sum, current) => sum + current.quantity);

  // MỚI: Lấy số lượng của một menuItem cụ thể
  int quantityOf(MenuItemModel menuItem) {
    final index = cartItems.indexWhere((item) => item.menuItem.id == menuItem.id);
    if (index != -1) {
      return cartItems[index].quantity;
    }
    return 0;
  }

  OrderCartState copyWith({
    List<CartItemModel>? cartItems,
    OrderCartStatus? status,
    String? errorMessage,
  }) {
    return OrderCartState(
      cartItems: cartItems ?? this.cartItems,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object> get props => [cartItems, status, errorMessage];
}