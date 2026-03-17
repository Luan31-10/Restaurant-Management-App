import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:qlnh_app/data/models/menu_item_model.dart';
import 'package:qlnh_app/data/models/table_model.dart';
import 'package:qlnh_app/data/services/api_service.dart';
import 'package:qlnh_app/logic/blocs/menu_items/menu_item_bloc.dart';
import 'package:qlnh_app/logic/blocs/order_cart/order_cart_bloc.dart';
import 'package:qlnh_app/logic/blocs/tables/table_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <<<--- THÊM IMPORT NÀY

class OrderCreationScreen extends StatefulWidget {
  final TableModel table;
  const OrderCreationScreen({super.key, required this.table});
  @override
  State<OrderCreationScreen> createState() => _OrderCreationScreenState();
}

class _OrderCreationScreenState extends State<OrderCreationScreen> {
  List<MenuItemModel> _bestsellers = [];
  bool _isLoadingBestsellers = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    context.read<MenuItemBloc>().add(FetchMenuItems());
    // Khởi tạo giỏ hàng trống khi vào màn hình
    context.read<OrderCartBloc>().add(ClearCart());
    _fetchBestsellers();
  }

  void _fetchBestsellers() async {
    try {
      final apiService = context.read<ApiService>();
      final items = await apiService.getBestsellers();
      if (mounted) {
        setState(() {
          _bestsellers = items;
          _isLoadingBestsellers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBestsellers = false;
        });
      }
      debugPrint('Failed to load bestsellers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<OrderCartBloc, OrderCartState>(
      listener: (context, state) {
        // Chỉ xử lý khi có sự kiện submit order
        if (state.status == OrderCartStatus.success) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Gửi order thành công!'), backgroundColor: Colors.green));
          context.read<TableBloc>().add(FetchTables()); // Cập nhật lại trạng thái bàn
          Navigator.of(context).pop();
        } else if (state.status == OrderCartStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('Lỗi: ${state.errorMessage}'), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceVariant,
        appBar: AppBar(
          title: Text('Chọn món cho ${widget.table.number}'),
          backgroundColor: theme.colorScheme.surface,
          elevation: 1,
        ),
        body: BlocBuilder<MenuItemBloc, MenuItemState>(
          builder: (context, menuState) {
            if (menuState is MenuItemLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (menuState is MenuItemLoaded) {
              final categories = menuState.categories;
              if (_selectedCategory == null && categories.isNotEmpty) {
                _selectedCategory = categories.first;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 120),
                      children: [
                        if (!_isLoadingBestsellers && _bestsellers.isNotEmpty)
                          _buildBestsellersSection(theme),

                        _buildCategoryTabs(categories, theme),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0),
                          child: Text(
                            _selectedCategory ?? 'Thực đơn',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _buildMenuItemList(
                            menuState.menuItems,
                            key: ValueKey(_selectedCategory),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            if (menuState is MenuItemError) {
              return Center(child: Text('Lỗi tải thực đơn: ${menuState.message}'));
            }
            return const Center(child: Text('Không có dữ liệu thực đơn.'));
          },
        ),
        bottomSheet: _buildCartSummary(theme),
      ),
    );
  }

  Widget _buildBestsellersSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 12.0),
          child: Row(
            children: [
              Icon(Icons.whatshot, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Món bán chạy nhất',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _bestsellers.length,
            itemBuilder: (context, index) {
              final item = _bestsellers[index];
              return _buildBestsellerCard(item, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBestsellerCard(MenuItemModel item, ThemeData theme) {
    // TẠO WIDGET PLACEHOLDER
    Widget imagePlaceholder = Container(
      height: 110,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        shadowColor: theme.shadowColor.withOpacity(0.1),
        child: InkWell(
          onTap: () => _addItemToCart(item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                // SỬA LỖI: THÊM KIỂM TRA `isNotEmpty`
                child: item.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(height: 110, width: double.infinity, color: Colors.grey.shade200),
                  errorWidget: (context, url, error) => imagePlaceholder,
                )
                    : imagePlaceholder, // Hiển thị placeholder nếu URL rỗng
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  item.name,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(List<String> categories, ThemeData theme) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? theme.primaryColor : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? theme.primaryColor : theme.dividerColor),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItemList(List<MenuItemModel> allItems, {required Key key}) {
    final items = allItems.where((item) => item.category == _selectedCategory).toList();
    if (items.isEmpty) {
      return const Center(child: Text('Chưa có món ăn trong danh mục này.'));
    }
    return Column(
      key: key,
      children: items.map((item) {
        return _buildMenuItemCard(item)
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.1, curve: Curves.easeOutCubic);
      }).toList(),
    );
  }

  // =================================================================
  // === HÀM ĐƯỢC SỬA LỖI CHÍNH LÀ HÀM NÀY ===
  // =================================================================
  Widget _buildMenuItemCard(MenuItemModel item) {
    final theme = Theme.of(context);

    // TẠO 1 WIDGET PLACEHOLDER (để dùng lại)
    Widget imagePlaceholder = Container(
      width: 90,
      height: 90,
      color: Colors.grey.shade200,
      child: const Icon(Icons.restaurant, color: Colors.grey),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: theme.shadowColor.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // SỬA LỖI: THÊM KIỂM TRA `isNotEmpty`
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage( // DÙNG CachedNetworkImage cho nhất quán
                imageUrl: item.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(width: 90, height: 90, color: Colors.grey.shade200),
                errorWidget: (context, url, error) => imagePlaceholder,
              )
                  : imagePlaceholder, // Hiển thị placeholder nếu URL rỗng
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(item.price),
                    style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<OrderCartBloc, OrderCartState>(
              builder: (context, cartState) {
                // CẬP NHẬT 1: Dùng getter `quantityOf` từ state để lấy số lượng
                final quantity = cartState.quantityOf(item);

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: quantity == 0
                      ? _buildAddButton(item)
                      : _buildQuantityControl(item, cartState), // Truyền cả cartState vào
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(MenuItemModel item) {
    return IconButton(
      key: ValueKey('add_${item.id}'),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        foregroundColor: Theme.of(context).primaryColor,
      ),
      icon: const Icon(Icons.add_rounded),
      onPressed: () => _addItemToCart(item),
    );
  }

  Widget _buildQuantityControl(MenuItemModel item, OrderCartState cartState) {
    final theme = Theme.of(context);
    // CẬP NHẬT 2: Tìm đúng CartItemModel để gửi đi trong event
    final cartItem = cartState.cartItems.firstWhere((ci) => ci.menuItem.id == item.id);
    final quantity = cartItem.quantity;

    return Container(
      key: ValueKey('quantity_${item.id}'),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: const Icon(Icons.remove_rounded),
              color: theme.primaryColor,
              onPressed: () {
                // CẬP NHẬT 3: Gửi đúng event `DecrementItemInCart` với `CartItemModel`
                context.read<OrderCartBloc>().add(DecrementItemInCart(cartItem));
              },
            ),
          ),
          Text(quantity.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.primaryColor)),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: const Icon(Icons.add_rounded),
              color: theme.primaryColor,
              onPressed: () => _addItemToCart(item),
            ),
          ),
        ],
      ),
    );
  }

  void _addItemToCart(MenuItemModel item) {
    context.read<OrderCartBloc>().add(AddItemToCart(item));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Đã thêm: ${item.name}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
  }

  Widget _buildCartSummary(ThemeData theme) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return BlocBuilder<OrderCartBloc, OrderCartState>(
      builder: (context, cartState) {
        if (cartState.cartItems.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // CẬP NHẬT 4: Dùng getter `totalItems` để hiển thị đúng tổng số lượng
                  Text('Tổng cộng (${cartState.totalItems} món):', style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
                  Text(currencyFormatter.format(cartState.totalPrice), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: cartState.cartItems.isEmpty || cartState.status == OrderCartStatus.loading ? null : () => context.read<OrderCartBloc>().add(SubmitNewOrder(tableId: widget.table.id)),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: cartState.status == OrderCartStatus.loading ? Container() : const Icon(Icons.send_rounded),
                  label: cartState.status == OrderCartStatus.loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('GỬI ORDER'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}