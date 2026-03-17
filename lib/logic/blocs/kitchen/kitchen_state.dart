part of 'kitchen_bloc.dart';

// Lớp helper ConsolidatedItem (Giữ nguyên)
class ConsolidatedItem {
  final MenuItemModel menuItem;
  final int totalQuantity;
  final List<OrderItemDetail> orderItems;

  ConsolidatedItem({
    required this.menuItem,
    required this.totalQuantity,
    required this.orderItems,
  });
}

enum KitchenStatus { initial, loading, loaded, error }

class KitchenState extends Equatable {
  final KitchenStatus status;
  final List<ActiveOrderModel> pendingOrders;
  final List<ActiveOrderModel> preparingOrders;
  final List<ActiveOrderModel> readyOrders;
  final String errorMessage;

  const KitchenState({
    this.status = KitchenStatus.initial,
    this.pendingOrders = const [],
    this.preparingOrders = const [],
    this.readyOrders = const [],
    this.errorMessage = '',
  });

  // Getter consolidatedItems (Giữ nguyên)
  List<ConsolidatedItem> get consolidatedItems {
    // ... (code getter giữ nguyên) ...
    final Map<int, ConsolidatedItem> itemMap = {};
    final activeOrders = [...pendingOrders, ...preparingOrders];

    for (var order in activeOrders) {
      for (var item in order.orderItems) {
        if (item.status != 'ready') {
          if (itemMap.containsKey(item.menuItem.id)) {
            final existing = itemMap[item.menuItem.id]!;
            itemMap[item.menuItem.id] = ConsolidatedItem(
              menuItem: existing.menuItem,
              totalQuantity: existing.totalQuantity + item.quantity,
              orderItems: [...existing.orderItems, item],
            );
          } else {
            itemMap[item.menuItem.id] = ConsolidatedItem(
              menuItem: item.menuItem,
              totalQuantity: item.quantity,
              orderItems: [item],
            );
          }
        }
      }
    }
    return itemMap.values.toList();
  }

  // Hàm copyWith (Giữ nguyên)
  KitchenState copyWith({
    KitchenStatus? status,
    List<ActiveOrderModel>? pendingOrders,
    List<ActiveOrderModel>? preparingOrders,
    List<ActiveOrderModel>? readyOrders,
    String? errorMessage,
    // Cho phép xóa lỗi khi cập nhật thành công
    bool clearError = false,
  }) {
    return KitchenState(
      status: status ?? this.status,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      preparingOrders: preparingOrders ?? this.preparingOrders,
      readyOrders: readyOrders ?? this.readyOrders,
      errorMessage: clearError ? '' : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object> get props => [status, pendingOrders, preparingOrders, readyOrders, errorMessage];
}