part of 'edit_order_bloc.dart';

enum EditStatus { initial, loading, success, failure }

class EditOrderState extends Equatable {
  final List<CartItemModel> items;
  final EditStatus status;
  final String errorMessage;

  const EditOrderState({
    this.items = const [],
    this.status = EditStatus.initial,
    this.errorMessage = '',
  });

  double get totalPrice => items.fold(0.0, (sum, current) => sum + (current.menuItem.price * current.quantity));

  EditOrderState copyWith({
    List<CartItemModel>? items,
    EditStatus? status,
    String? errorMessage,
  }) {
    return EditOrderState(
      items: items ?? this.items,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object> get props => [items, status, errorMessage];
}