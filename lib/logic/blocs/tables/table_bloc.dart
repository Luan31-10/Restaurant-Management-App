import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/table_model.dart';
import '../../../data/services/api_service.dart';

part 'table_event.dart';
part 'table_state.dart';

class TableBloc extends Bloc<TableEvent, TableState> {
  final ApiService apiService;

  TableBloc({required this.apiService}) : super(TableInitial()) {
    on<FetchTables>(_onFetchTables);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<UpdateTableStatus>(_onUpdateTableStatus);
    on<PayOrder>(_onPayOrder);
    // === ĐĂNG KÝ HANDLER MỚI ===
    on<TableStatusReceived>(_onTableStatusReceived);
    // ===========================
  }

  // === HANDLER MỚI CHO WEBSOCKET ===
  void _onTableStatusReceived(TableStatusReceived event, Emitter<TableState> emit) {
    final currentState = state;
    // Chỉ cập nhật nếu state hiện tại là TableLoaded
    if (currentState is TableLoaded) {
      // Tạo một danh sách bàn mới (không sửa trực tiếp state cũ)
      final List<TableModel> updatedTables = List.from(currentState.tables);
      // Tìm vị trí của bàn cần cập nhật
      final index = updatedTables.indexWhere((table) => table.id == event.updatedTable.id);

      // Nếu tìm thấy, thay thế bàn cũ bằng bàn mới từ WebSocket
      if (index != -1) {
        updatedTables[index] = event.updatedTable;
        // Emit state mới với danh sách đã cập nhật
        // Dùng copyWith để giữ lại status và errorMessage hiện tại (nếu có)
        // và đảm bảo status là 'loaded' sau khi nhận update
        emit(currentState.copyWith(tables: updatedTables, status: TableStatus.loaded));
        print('🔄 TableBloc: Đã cập nhật bàn ${event.updatedTable.id} từ WebSocket.');
      } else {
        print('⚠️ TableBloc: Nhận được cập nhật cho bàn ${event.updatedTable.id} không có trong danh sách hiện tại.');
        // Cân nhắc: Có thể gọi FetchTables ở đây để đảm bảo đồng bộ hoàn toàn
        // add(FetchTables());
      }
    } else {
      print('ℹ️ TableBloc: Nhận được cập nhật WebSocket nhưng state không phải là TableLoaded.');
      // Có thể FetchTables nếu đang ở Initial hoặc Error
      // if (currentState is TableInitial || currentState is TableError) {
      //   add(FetchTables());
      // }
    }
  }
  // ================================

  Future<void> _onFetchTables(FetchTables event, Emitter<TableState> emit) async {
    final currentState = state;
    // Chỉ hiện loading toàn màn hình nếu chưa có dữ liệu hoặc đang ở trạng thái lỗi
    if (currentState is! TableLoaded || currentState.tables.isEmpty || currentState.status == TableStatus.error) {
      emit(TableLoading());
    } else {
      // Nếu đã có dữ liệu, chỉ đổi status để hiện loading nhỏ (background)
      emit(currentState.copyWith(status: TableStatus.loading));
    }

    try {
      final tables = await apiService.getTables();
      emit(TableLoaded(tables: tables, status: TableStatus.loaded)); // Trạng thái là loaded khi thành công
    } catch (e) {
      final errorMessage = e.toString();
      // Nếu đang ở state loaded mà fetch lỗi, giữ lại data cũ và báo lỗi
      if (currentState is TableLoaded && currentState.tables.isNotEmpty) {
        emit(currentState.copyWith(status: TableStatus.error, errorMessage: errorMessage));
      } else {
        // Nếu chưa load lần nào hoặc list rỗng mà lỗi, emit state Error riêng
        emit(TableError(errorMessage));
      }
      print('❌ TableBloc FetchTables Error: $errorMessage');
    }
  }

  Future<void> _onUpdateOrderStatus(UpdateOrderStatus event, Emitter<TableState> emit) async {
    final currentState = state;
    // Không cần emit loading ở đây vì nó diễn ra nhanh và WebSocket sẽ cập nhật

    try {
      // Chỉ cần gọi API, backend sẽ emit WebSocket
      await apiService.updateOrderStatus(event.orderId, event.status);
      // KHÔNG GỌI add(FetchTables()) NỮA
      print('✅ TableBloc: Gọi API updateOrderStatus thành công.');
    } catch (e) {
      final errorMessage = 'Lỗi cập nhật order: $e';
      // Xử lý lỗi: Giữ data cũ, đổi status thành error và gửi message
      if (currentState is TableLoaded) {
        emit(currentState.copyWith(status: TableStatus.error, errorMessage: errorMessage));
      } else {
        // Nếu state ban đầu không phải loaded, emit TableError
        emit(TableError(errorMessage));
      }
      print('❌ TableBloc UpdateOrderStatus Error: $errorMessage');
    }
  }

  Future<void> _onUpdateTableStatus(UpdateTableStatus event, Emitter<TableState> emit) async {
    final currentState = state;
    // Không cần emit loading

    try {
      // Chỉ gọi API, backend sẽ emit WebSocket
      await apiService.updateTableStatus(event.tableId, event.status);
      // KHÔNG GỌI add(FetchTables()) NỮA
      print('✅ TableBloc: Gọi API updateTableStatus thành công.');
    } catch (e) {
      final errorMessage = 'Lỗi cập nhật bàn: $e';
      if (currentState is TableLoaded) {
        emit(currentState.copyWith(status: TableStatus.error, errorMessage: errorMessage));
      } else {
        emit(TableError(errorMessage));
      }
      print('❌ TableBloc UpdateTableStatus Error: $errorMessage');
    }
  }

  Future<void> _onPayOrder(PayOrder event, Emitter<TableState> emit) async {
    final currentState = state;
    if (currentState is TableLoaded) {
      // Báo cho UI biết đang xử lý thanh toán
      emit(currentState.copyWith(status: TableStatus.paymentInProgress));
      try {
        // Gọi API, backend sẽ emit WebSocket cập nhật bàn thành 'cleaning'
        await apiService.updateOrderStatus(event.orderId, 'paid', paymentMethod: event.paymentMethod);
        // Emit trạng thái thành công để UI xử lý (vd: đóng màn hình thanh toán)
        // Dùng copyWith để giữ lại danh sách bàn hiện tại
        emit(currentState.copyWith(status: TableStatus.paymentSuccess));
        print('✅ TableBloc: Thanh toán thành công cho order ${event.orderId}.');
        // WebSocket sẽ tự cập nhật bàn, KHÔNG GỌI FetchTables
      } catch (e) {
        final errorMessage = e.toString();
        // Emit trạng thái thất bại và lỗi
        emit(currentState.copyWith(
          status: TableStatus.paymentFailure,
          errorMessage: errorMessage,
        ));
        print('❌ TableBloc PayOrder Error: $errorMessage');
      }
    } else {
      print("⚠️ Lỗi PayOrder: State không phải là TableLoaded");
      // Emit lỗi chung nếu chưa load xong bàn
      emit(const TableError("Không thể thanh toán khi chưa tải xong danh sách bàn."));
    }
  }
}