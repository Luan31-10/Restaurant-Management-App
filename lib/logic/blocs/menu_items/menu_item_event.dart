part of 'menu_item_bloc.dart';

abstract class MenuItemEvent extends Equatable {
  const MenuItemEvent();
  @override
  List<Object> get props => [];
}

class FetchMenuItems extends MenuItemEvent {}