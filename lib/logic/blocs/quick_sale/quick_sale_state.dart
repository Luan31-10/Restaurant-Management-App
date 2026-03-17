part of 'quick_sale_bloc.dart';

enum QuickSaleStatus { initial, loading, success, failure }

class QuickSaleState extends Equatable {
  // Vì bạn dùng CartItemModel, state sẽ lưu List<CartItemModel>
  final List<CartItemModel> cartItems;
  final QuickSaleStatus status;

  const QuickSaleState({
    this.cartItems = const [],
    this.status = QuickSaleStatus.initial,
  });

  // GETTER SẼ TÍNH TOÁN TỰ ĐỘNG VÀ LUÔN TRẢ VỀ DOUBLE
  // Nó lấy giá trị price (đã là double) từ MenuItemModel
  double get totalPrice => cartItems.fold(
      0.0, (sum, current) => sum + (current.menuItem.price * current.quantity));

  QuickSaleState copyWith({
    List<CartItemModel>? cartItems,
    QuickSaleStatus? status,
  }) {
    // Không cần tính toán gì ở đây cả!
    return QuickSaleState(
      cartItems: cartItems ?? this.cartItems,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [cartItems, totalPrice, status];
}