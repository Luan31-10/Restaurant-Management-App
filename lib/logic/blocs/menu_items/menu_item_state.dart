part of 'menu_item_bloc.dart';

abstract class MenuItemState extends Equatable {
  const MenuItemState();

  @override
  List<Object> get props => [];
}

class MenuItemInitial extends MenuItemState {}

class MenuItemLoading extends MenuItemState {}

class MenuItemLoaded extends MenuItemState {
  final List<MenuItemModel> menuItems;
  final List<String> categories; // Giao diện cần thuộc tính này

  const MenuItemLoaded({
    required this.menuItems,
    required this.categories,
  });

  @override
  List<Object> get props => [menuItems, categories];
}

class MenuItemError extends MenuItemState {
  final String message;

  // SỬA LẠI: Constructor chỉ cần nhận một tham số là message
  const MenuItemError(this.message);

  @override
  List<Object> get props => [message];
}