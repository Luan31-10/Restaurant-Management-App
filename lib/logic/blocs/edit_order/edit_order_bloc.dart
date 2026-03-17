import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qlnh_app/data/models/cart_item_model.dart';
import 'package:qlnh_app/data/models/menu_item_model.dart';
import 'package:qlnh_app/data/services/api_service.dart';

part 'edit_order_event.dart';
part 'edit_order_state.dart';

class EditOrderBloc extends Bloc<EditOrderEvent, EditOrderState> {
  final ApiService apiService;

  EditOrderBloc({required this.apiService}) : super(const EditOrderState()) {
    on<LoadOrder>(_onLoadOrder);
    on<AddNewItem>(_onAddNewItem);
    on<IncrementItem>(_onIncrementItem);
    on<DecrementItem>(_onDecrementItem);
    on<SaveChanges>(_onSaveChanges);
  }

  void _onLoadOrder(LoadOrder event, Emitter<EditOrderState> emit) {
    emit(state.copyWith(items: event.items));
  }

  void _onAddNewItem(AddNewItem event, Emitter<EditOrderState> emit) {
    final List<CartItemModel> updatedItems = List.from(state.items);
    final int index = updatedItems.indexWhere((item) => item.menuItem.id == event.menuItem.id);
    if (index != -1) {
      final oldItem = updatedItems[index];
      updatedItems[index] = oldItem.copyWith(quantity: oldItem.quantity + 1);
    } else {
      updatedItems.add(CartItemModel(menuItem: event.menuItem, quantity: 1));
    }
    emit(state.copyWith(items: updatedItems));
  }

  void _onIncrementItem(IncrementItem event, Emitter<EditOrderState> emit) {
    final List<CartItemModel> updatedItems = state.items.map((item) {
      return item.menuItem.id == event.item.menuItem.id
          ? item.copyWith(quantity: item.quantity + 1)
          : item;
    }).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void _onDecrementItem(DecrementItem event, Emitter<EditOrderState> emit) {
    final List<CartItemModel> updatedItems = List.from(state.items);
    final int index = updatedItems.indexWhere((item) => item.menuItem.id == event.item.menuItem.id);
    if (index != -1) {
      if (updatedItems[index].quantity > 1) {
        final oldItem = updatedItems[index];
        updatedItems[index] = oldItem.copyWith(quantity: oldItem.quantity - 1);
      } else {
        updatedItems.removeAt(index);
      }
      emit(state.copyWith(items: updatedItems));
    }
  }

  Future<void> _onSaveChanges(SaveChanges event, Emitter<EditOrderState> emit) async {
    if (state.items.isEmpty) return;
    emit(state.copyWith(status: EditStatus.loading));
    try {
      await apiService.editOrder(event.orderId, state.items);
      emit(state.copyWith(status: EditStatus.success));
    } catch (e) {
      emit(state.copyWith(status: EditStatus.failure, errorMessage: e.toString()));
    }
  }
}