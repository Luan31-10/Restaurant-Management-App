import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qlnh_app/data/models/cart_item_model.dart';
import 'package:qlnh_app/data/models/menu_item_model.dart';
import 'package:qlnh_app/data/services/api_service.dart';

part 'order_cart_event.dart';
part 'order_cart_state.dart';

class OrderCartBloc extends Bloc<OrderCartEvent, OrderCartState> {
  final ApiService apiService;

  OrderCartBloc({required this.apiService}) : super(const OrderCartState()) {
    // Đăng ký các trình xử lý sự kiện
    on<InitializeCart>(_onInitializeCart);
    on<AddItemToCart>(_onAddItemToCart);
    on<DecrementItemInCart>(_onDecrementItemInCart);
    on<ClearCart>(_onClearCart);
    on<SubmitNewOrder>(_onSubmitNewOrder);
    on<SubmitOrderChanges>(_onSubmitOrderChanges);

    // MỚI: Đăng ký các trình xử lý cho sự kiện nâng cao
    on<RemoveItemCompletely>(_onRemoveItemCompletely);
    on<UpdateItemNote>(_onUpdateItemNote);
    on<SetItemQuantity>(_onSetItemQuantity);
  }

  // Nạp order cũ vào giỏ hàng
  void _onInitializeCart(InitializeCart event, Emitter<OrderCartState> emit) {
    emit(state.copyWith(
      cartItems: List.from(event.initialItems),
      status: OrderCartStatus.initial,
    ));
  }

  // Thêm món
  void _onAddItemToCart(AddItemToCart event, Emitter<OrderCartState> emit) {
    final List<CartItemModel> updatedItems = List.from(state.cartItems);
    // Tìm item trong giỏ có cùng menuItemId và chưa có ghi chú
    final int index = updatedItems.indexWhere(
            (item) => item.menuItem.id == event.menuItem.id && item.note.isEmpty);

    if (index != -1) {
      // Nếu tìm thấy, tăng số lượng
      final oldItem = updatedItems[index];
      updatedItems[index] = oldItem.copyWith(quantity: oldItem.quantity + 1);
    } else {
      // Nếu không, thêm item mới vào giỏ
      updatedItems.add(CartItemModel(menuItem: event.menuItem, quantity: 1));
    }
    emit(state.copyWith(cartItems: updatedItems));
  }

  // Giảm món
  void _onDecrementItemInCart(DecrementItemInCart event, Emitter<OrderCartState> emit) {
    final List<CartItemModel> updatedItems = List.from(state.cartItems);
    // Tìm chính xác cartItem được truyền vào
    final int index = updatedItems.indexOf(event.cartItem);

    if (index != -1) {
      if (updatedItems[index].quantity > 1) {
        // Nếu số lượng > 1, giảm đi 1
        final oldItem = updatedItems[index];
        updatedItems[index] = oldItem.copyWith(quantity: oldItem.quantity - 1);
      } else {
        // Nếu số lượng là 1, xóa item
        updatedItems.removeAt(index);
      }
    }
    emit(state.copyWith(cartItems: updatedItems));
  }

  // Dọn giỏ hàng
  void _onClearCart(ClearCart event, Emitter<OrderCartState> emit) {
    emit(const OrderCartState()); // Reset về trạng thái ban đầu
  }

  // MỚI: Xóa hẳn một item
  void _onRemoveItemCompletely(RemoveItemCompletely event, Emitter<OrderCartState> emit) {
    final List<CartItemModel> updatedItems = List.from(state.cartItems);
    updatedItems.remove(event.cartItem);
    emit(state.copyWith(cartItems: updatedItems));
  }

  // MỚI: Cập nhật ghi chú
  void _onUpdateItemNote(UpdateItemNote event, Emitter<OrderCartState> emit) {
    final List<CartItemModel> updatedItems = List.from(state.cartItems);
    final int index = updatedItems.indexOf(event.cartItem);

    if (index != -1) {
      updatedItems[index] = updatedItems[index].copyWith(note: event.note);
    }
    emit(state.copyWith(cartItems: updatedItems));
  }

  // MỚI: Đặt số lượng cụ thể
  void _onSetItemQuantity(SetItemQuantity event, Emitter<OrderCartState> emit) {
    final List<CartItemModel> updatedItems = List.from(state.cartItems);
    final int index = updatedItems.indexOf(event.cartItem);

    if (index != -1) {
      if (event.quantity > 0) {
        // Nếu số lượng > 0, cập nhật
        updatedItems[index] = updatedItems[index].copyWith(quantity: event.quantity);
      } else {
        // Nếu số lượng <= 0, xóa item
        updatedItems.removeAt(index);
      }
    }
    emit(state.copyWith(cartItems: updatedItems));
  }

  // Gửi order mới
  Future<void> _onSubmitNewOrder(SubmitNewOrder event, Emitter<OrderCartState> emit) async {
    if (state.cartItems.isEmpty) return;
    emit(state.copyWith(status: OrderCartStatus.loading));
    try {
      await apiService.createOrder(event.tableId, state.cartItems);
      emit(state.copyWith(status: OrderCartStatus.success));
    } catch (e) {
      emit(state.copyWith(status: OrderCartStatus.failure, errorMessage: e.toString()));
    }
  }

  // Cập nhật order cũ
  Future<void> _onSubmitOrderChanges(SubmitOrderChanges event, Emitter<OrderCartState> emit) async {
    if (state.cartItems.isEmpty) return;
    emit(state.copyWith(status: OrderCartStatus.loading));
    try {
      await apiService.editOrder(event.orderId, state.cartItems);
      emit(state.copyWith(status: OrderCartStatus.success));
    } catch (e) {
      emit(state.copyWith(status: OrderCartStatus.failure, errorMessage: e.toString()));
    }
  }
}