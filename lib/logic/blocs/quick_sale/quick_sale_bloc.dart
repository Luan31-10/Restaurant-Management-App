import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qlnh_app/data/models/cart_item_model.dart';
import 'package:qlnh_app/data/models/menu_item_model.dart';
import 'package:qlnh_app/data/services/api_service.dart';


part 'quick_sale_event.dart';
part 'quick_sale_state.dart';

class QuickSaleBloc extends Bloc<QuickSaleEvent, QuickSaleState> {
  final ApiService apiService;
  QuickSaleBloc({required this.apiService}) : super(const QuickSaleState()) {
    on<AddItemToQuickSale>(_onAddItem);
    on<RemoveItemFromQuickSale>(_onRemoveItem);
    on<ClearQuickSaleCart>((event, emit) => emit(const QuickSaleState()));
    on<AssignCartToTable>(_onAssignCartToTable);
    on<IncrementItemInQuickSale>(_onIncrementItem);
    on<DecrementItemInQuickSale>(_onDecrementItem);


  }

  void _onAddItem(AddItemToQuickSale event, Emitter<QuickSaleState> emit) {
    final updatedItems = List<CartItemModel>.from(state.cartItems);
    final index = updatedItems.indexWhere((i) => i.menuItem.id == event.menuItem.id);
    if (index != -1) {
      updatedItems[index] = updatedItems[index].copyWith(quantity: updatedItems[index].quantity + 1);
    } else {
      updatedItems.add(CartItemModel(menuItem: event.menuItem, quantity: 1));
    }
    emit(state.copyWith(cartItems: updatedItems, status: QuickSaleStatus.initial));
  }

  void _onRemoveItem(RemoveItemFromQuickSale event, Emitter<QuickSaleState> emit) {
    final updatedItems = List<CartItemModel>.from(state.cartItems);
    final index = updatedItems.indexWhere((i) => i.menuItem.id == event.cartItem.menuItem.id);
    if (index != -1) {
      if (updatedItems[index].quantity > 1) {
        updatedItems[index] = updatedItems[index].copyWith(quantity: updatedItems[index].quantity - 1);
      } else {
        updatedItems.removeAt(index);
      }
    }
    emit(state.copyWith(cartItems: updatedItems, status: QuickSaleStatus.initial));
  }
  void _onIncrementItem(IncrementItemInQuickSale event, Emitter<QuickSaleState> emit) {
    final updatedItems = List<CartItemModel>.from(state.cartItems);
    final index = updatedItems.indexWhere((i) => i.menuItem.id == event.cartItem.menuItem.id);
    if (index != -1) {
      updatedItems[index] = updatedItems[index].copyWith(quantity: updatedItems[index].quantity + 1);
      emit(state.copyWith(cartItems: updatedItems));
    }
  }

  void _onDecrementItem(DecrementItemInQuickSale event, Emitter<QuickSaleState> emit) {
    final updatedItems = List<CartItemModel>.from(state.cartItems);
    final index = updatedItems.indexWhere((i) => i.menuItem.id == event.cartItem.menuItem.id);
    if (index != -1) {
      if (updatedItems[index].quantity > 1) {
        updatedItems[index] = updatedItems[index].copyWith(quantity: updatedItems[index].quantity - 1);
      } else {
        updatedItems.removeAt(index);
      }
      emit(state.copyWith(cartItems: updatedItems));
    }
  }

  Future<void> _onAssignCartToTable(AssignCartToTable event, Emitter<QuickSaleState> emit) async {
    if (state.cartItems.isEmpty) return;
    emit(state.copyWith(status: QuickSaleStatus.loading));
    try {
      await apiService.createOrder(event.tableId, state.cartItems);
      emit(state.copyWith(status: QuickSaleStatus.success, cartItems: []));
    } catch (e) {
      emit(state.copyWith(status: QuickSaleStatus.failure));
    }
  }
}