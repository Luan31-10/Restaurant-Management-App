import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qlnh_app/data/models/active_order_model.dart';
import 'package:qlnh_app/data/services/api_service.dart';
import 'package:qlnh_app/data/models/menu_item_model.dart';

part 'kitchen_event.dart';
part 'kitchen_state.dart';

class KitchenBloc extends Bloc<KitchenEvent, KitchenState> {
  final ApiService apiService;

  KitchenBloc({required this.apiService}) : super(const KitchenState()) {
    on<FetchKitchenOrders>(_onFetchKitchenOrders);
    on<UpdateOrderStatusKitchen>(_onUpdateOrderStatus);
    on<UpdateOrderItemStatus>(_onUpdateOrderItemStatus);
    on<KitchenOrderReceived>(_onKitchenOrderReceived);
    on<KitchenOrderCancelled>(_onKitchenOrderCancelled);
  }

  // --- HÀM TẢI DỮ LIỆU BAN ĐẦU (Giữ nguyên) ---
  Future<void> _onFetchKitchenOrders(
      FetchKitchenOrders event, Emitter<KitchenState> emit) async {
    if (state.status == KitchenStatus.initial || state.status == KitchenStatus.error) {
      emit(state.copyWith(status: KitchenStatus.loading, clearError: true));
    }
    try {
      final orders = await apiService.getKitchenOrders();
      final pending = orders.where((o) => o.status == 'pending').toList();
      final preparing = orders.where((o) => o.status == 'preparing').toList();
      final ready = orders.where((o) => o.status == 'ready').toList(); // Lấy cả ready
      emit(state.copyWith(
        status: KitchenStatus.loaded,
        pendingOrders: pending,
        preparingOrders: preparing,
        readyOrders: ready,
      ));
    } catch (e) {
      emit(state.copyWith(status: KitchenStatus.error, errorMessage: e.toString()));
    }
  }

  // --- HÀM CẬP NHẬT TRẠNG THÁI ORDER (TỪ BẾP) ---
  // Sửa lại: BỎ GỌI add(FetchKitchenOrders())
  Future<void> _onUpdateOrderStatus(
      UpdateOrderStatusKitchen event, Emitter<KitchenState> emit) async {
    // Lưu state cũ phòng khi lỗi
    final previousState = state;
    // Có thể emit loading tạm thời nếu muốn
    // emit(state.copyWith(status: KitchenStatus.loading)); // Tùy chọn

    try {
      // Chỉ gọi API, backend sẽ emit WebSocket 'order_updated'
      await apiService.updateOrderStatus(event.orderId, event.status);
      print("✅ KitchenBloc: Gọi API updateOrderStatus thành công.");
      // === BỎ DÒNG NÀY ĐI ===
      // add(FetchKitchenOrders());
      // ====================
      // Nếu có emit loading tạm, emit lại loaded ở đây
      // emit(previousState.copyWith(status: KitchenStatus.loaded)); // Tùy chọn
    } catch (e) {
      print("❌ KitchenBloc: Lỗi khi gọi API updateOrderStatus: $e");
      // Rollback về state cũ hoặc emit lỗi
      // emit(previousState); // Rollback nếu có optimistic update
      emit(state.copyWith(status: KitchenStatus.error, errorMessage: "Lỗi cập nhật trạng thái order: ${e.toString()}"));
    }
  }

  // --- HÀM CẬP NHẬT TRẠNG THÁI MÓN ĂN (TỪ BẾP) ---
  // Sửa lại: BỎ GỌI add(FetchKitchenOrders())
  Future<void> _onUpdateOrderItemStatus(
      UpdateOrderItemStatus event,
      Emitter<KitchenState> emit,
      ) async {
    final previousState = state;
    // emit(state.copyWith(status: KitchenStatus.loading)); // Tùy chọn

    try {
      // Chỉ gọi API, backend sẽ emit WebSocket 'order_updated'
      await apiService.updateOrderItemStatus(
        orderItemId: event.orderItemId,
        status: event.status,
      );
      print("✅ KitchenBloc: Gọi API updateOrderItemStatus thành công.");
      // === BỎ DÒNG NÀY ĐI ===
      // add(FetchKitchenOrders());
      // ====================
      // emit(previousState.copyWith(status: KitchenStatus.loaded)); // Tùy chọn
    } catch (e) {
      print("❌ KitchenBloc: Lỗi khi gọi API updateOrderItemStatus: $e");
      // emit(previousState); // Rollback nếu có optimistic update
      emit(state.copyWith(status: KitchenStatus.error, errorMessage: "Lỗi cập nhật trạng thái món: ${e.toString()}"));
    }
  }


  // === HANDLER WEBSOCKET: XỬ LÝ ORDER UPDATE (Giữ nguyên) ===
  void _onKitchenOrderReceived(KitchenOrderReceived event, Emitter<KitchenState> emit) {
    print("⚡️ KitchenBloc: Nhận được order update từ WebSocket - ID: ${event.order.id}, Status: ${event.order.status}");
    final updatedOrder = event.order;
    final String newStatus = updatedOrder.status;

    List<ActiveOrderModel> currentPending = List.from(state.pendingOrders);
    List<ActiveOrderModel> currentPreparing = List.from(state.preparingOrders);
    List<ActiveOrderModel> currentReady = List.from(state.readyOrders);

    // Xóa khỏi tất cả list cũ
    currentPending.removeWhere((o) => o.id == updatedOrder.id);
    currentPreparing.removeWhere((o) => o.id == updatedOrder.id);
    currentReady.removeWhere((o) => o.id == updatedOrder.id);

    // Thêm vào list mới
    if (newStatus == 'pending') { currentPending.add(updatedOrder); currentPending.sort((a, b) => a.createdAt.compareTo(b.createdAt)); }
    else if (newStatus == 'preparing') { currentPreparing.add(updatedOrder); currentPreparing.sort((a, b) => a.createdAt.compareTo(b.createdAt)); }
    else if (newStatus == 'ready') { currentReady.add(updatedOrder); currentReady.sort((a, b) => a.createdAt.compareTo(b.createdAt)); }

    // Emit state mới
    emit(state.copyWith(
      status: KitchenStatus.loaded,
      pendingOrders: currentPending,
      preparingOrders: currentPreparing,
      readyOrders: currentReady,
      clearError: true,
    ));
  }
  // ===========================================

  // === HANDLER WEBSOCKET: XỬ LÝ ORDER CANCEL (Giữ nguyên) ===
  void _onKitchenOrderCancelled(KitchenOrderCancelled event, Emitter<KitchenState> emit) {
    print("🗑️ KitchenBloc: Nhận được order cancel từ WebSocket - ID: ${event.order.id}");
    final cancelledOrderId = event.order.id;

    List<ActiveOrderModel> currentPending = List.from(state.pendingOrders);
    List<ActiveOrderModel> currentPreparing = List.from(state.preparingOrders);
    List<ActiveOrderModel> currentReady = List.from(state.readyOrders);

    // Xóa khỏi tất cả list
    currentPending.removeWhere((o) => o.id == cancelledOrderId);
    currentPreparing.removeWhere((o) => o.id == cancelledOrderId);
    currentReady.removeWhere((o) => o.id == cancelledOrderId);

    // Emit state mới
    emit(state.copyWith(
      status: KitchenStatus.loaded,
      pendingOrders: currentPending,
      preparingOrders: currentPreparing,
      readyOrders: currentReady,
      clearError: true,
    ));
  }
  }