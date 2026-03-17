part of 'table_bloc.dart';

// Enum để định nghĩa các trạng thái con, đặc biệt là cho quá trình thanh toán
enum TableStatus {
  initial,
  loading, // Đang tải lần đầu hoặc đang fetch lại
  loaded,  // Tải xong, trạng thái bình thường
  error,   // Có lỗi xảy ra (khi tải hoặc cập nhật ngầm)
  paymentInProgress,
  paymentSuccess,
  paymentFailure
}

// State cha trừu tượng
abstract class TableState extends Equatable {
  const TableState();

  @override
  List<Object> get props => [];
}

// Các state con
class TableInitial extends TableState {}

class TableLoading extends TableState {} // Dùng khi tải lần đầu

// --- CẬP NHẬT LẠI HOÀN TOÀN CLASS NÀY ---
class TableLoaded extends TableState {
  final List<TableModel> tables; // Danh sách bàn
  final TableStatus status;       // Trạng thái phụ (loading ngầm, error ngầm, payment...)
  final String errorMessage;    // Thông báo lỗi (nếu status là error hoặc paymentFailure)

  const TableLoaded({
    required this.tables,
    this.status = TableStatus.loaded, // Mặc định là đã tải xong
    this.errorMessage = '',
  });

  // === THÊM HÀM COPYWITH ===
  TableLoaded copyWith({
    List<TableModel>? tables,
    TableStatus? status,
    String? errorMessage,
  }) {
    return TableLoaded(
      tables: tables ?? this.tables,
      status: status ?? this.status,
      // Cho phép xóa lỗi cũ khi cập nhật status mới
      errorMessage: errorMessage ?? (status != this.status ? '' : this.errorMessage),
    );
  }
  // ==========================


  @override
  List<Object> get props => [tables, status, errorMessage];
}
// -----------------------------------------

class TableError extends TableState {
  final String message;
  const TableError(this.message);
  @override
  List<Object> get props => [message];
}