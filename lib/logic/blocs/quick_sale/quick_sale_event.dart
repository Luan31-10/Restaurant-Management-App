part of 'quick_sale_bloc.dart';

abstract class QuickSaleEvent extends Equatable {
  const QuickSaleEvent();
  @override List<Object> get props => [];
}

class AddItemToQuickSale extends QuickSaleEvent {
  final MenuItemModel menuItem;
  const AddItemToQuickSale(this.menuItem);
  @override List<Object> get props => [menuItem];
}

class RemoveItemFromQuickSale extends QuickSaleEvent {
  final CartItemModel cartItem;
  const RemoveItemFromQuickSale(this.cartItem);
  @override List<Object> get props => [cartItem];
}

class AssignCartToTable extends QuickSaleEvent {
  final int tableId;
  const AssignCartToTable(this.tableId);
  @override List<Object> get props => [tableId];
}

class IncrementItemInQuickSale extends QuickSaleEvent {
  final CartItemModel cartItem;
  const IncrementItemInQuickSale(this.cartItem);
  @override List<Object> get props => [cartItem];
}

// Event mới để giảm số lượng
class DecrementItemInQuickSale extends QuickSaleEvent {
  final CartItemModel cartItem;
  const DecrementItemInQuickSale(this.cartItem);
  @override List<Object> get props => [cartItem];
}

class ClearQuickSaleCart extends QuickSaleEvent {}