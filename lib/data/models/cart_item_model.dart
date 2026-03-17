import 'package:equatable/equatable.dart';
import 'package:qlnh_app/data/models/menu_item_model.dart';

class CartItemModel extends Equatable {
  final MenuItemModel menuItem;
  final int quantity;
  final String note;

  const CartItemModel({
    required this.menuItem,
    required this.quantity,
    this.note = '',
  });

  CartItemModel copyWith({
    MenuItemModel? menuItem,
    int? quantity,
    String? note, // MỚI: Thêm vào phương thức copyWith
  }) {
    return CartItemModel(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note, // MỚI: Cập nhật logic sao chép
    );
  }

  @override
  List<Object> get props => [
    menuItem,
    quantity,
    note,
  ];
}