import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qlnh_app/data/models/menu_item_model.dart';
import 'package:qlnh_app/data/services/api_service.dart';
import 'package:qlnh_app/logic/blocs/menu_items/menu_item_bloc.dart';
import 'package:qlnh_app/logic/blocs/order_cart/order_cart_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <<<--- 1. THÊM IMPORT NÀY

import '../../data/models/cart_item_model.dart';

class MenuForOrder extends StatelessWidget {
  const MenuForOrder({super.key});

  void _showRecommendations(BuildContext context, MenuItemModel addedItem) async {
    final apiService = context.read<ApiService>();
    final recommendations = await apiService.getRecommendations(addedItem.id);

    if (recommendations.isNotEmpty && context.mounted) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gợi ý đi kèm "${addedItem.name}":', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ...recommendations.map((item) => ListTile(
                  title: Text(item.name),
                  subtitle: Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(item.price)),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm'),
                    onPressed: () {
                      context.read<OrderCartBloc>().add(AddItemToCart(item));
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Đã thêm: ${item.name}'),
                        duration: const Duration(seconds: 1),
                      ));
                    },
                  ),
                )).toList(),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuItemBloc, MenuItemState>(
      builder: (context, menuState) {
        if (menuState is MenuItemLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (menuState is MenuItemLoaded) {
          final categorizedMenu = <String, List<MenuItemModel>>{};
          for (var item in menuState.menuItems) {
            (categorizedMenu[item.category] ??= []).add(item);
          }
          final categories = categorizedMenu.keys.toList();

          if (categories.isEmpty) {
            return const Center(child: Text('Thực đơn trống.'));
          }

          return DefaultTabController(
            length: categories.length,
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).canvasColor,
                  child: TabBar(
                    isScrollable: true,
                    tabs: categories.map((category) => Tab(text: category)).toList(),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: categories.map((category) {
                      final items = categorizedMenu[category]!;
                      // --- THAY ĐỔI LỚN: TỪ LISTVIEW SANG GRIDVIEW ---
                      return GridView.builder(
                        padding: const EdgeInsets.all(12.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2 cột
                          crossAxisSpacing: 12.0,
                          mainAxisSpacing: 12.0,
                          childAspectRatio: 0.8, // Điều chỉnh tỷ lệ để thẻ cao hơn một chút
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _MenuItemGridCard(
                            item: item,
                            onAddToCart: () {
                              context.read<OrderCartBloc>().add(AddItemToCart(item));
                              _showRecommendations(context, item);
                            },
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }
        if (menuState is MenuItemError) {
          return Center(child: Text('Lỗi tải thực đơn: ${menuState.message}'));
        }
        return const Center(child: Text('Đang tải thực đơn...'));
      },
    );
  }
}

// === WIDGET CARD MỚI CHO GIAO DIỆN LƯỚI ===
// === THAY THẾ TOÀN BỘ WIDGET NÀY ===

class _MenuItemGridCard extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback onAddToCart;

  const _MenuItemGridCard({required this.item, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    // Dùng context.watch để widget tự build lại khi giỏ hàng thay đổi
    final cartBloc = context.watch<OrderCartBloc>();
    final existingItemIndex = cartBloc.state.cartItems.indexWhere(
          (cartItem) => cartItem.menuItem.id == item.id,
    );
    final bool isSelected = existingItemIndex != -1;

    // === 2. TẠO WIDGET PLACEHOLDER TÁI SỬ DỤNG ===
    Widget imagePlaceholder = Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 40),
    );
    // ===========================================

    return GestureDetector(
      onTap: onAddToCart,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần hình ảnh
            Expanded(
              flex: 3,
              child: SizedBox(
                width: double.infinity,
                // === 3. SỬA LỖI HIỂN THỊ ẢNH TẠI ĐÂY ===
                child: item.imageUrl.isNotEmpty
                    ? CachedNetworkImage( // Dùng CachedNetworkImage
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  // Thêm placeholder khi đang tải
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                  ),
                  // Dùng placeholder chung khi có lỗi
                  errorWidget: (context, url, error) => imagePlaceholder,
                )
                    : imagePlaceholder, // Dùng placeholder chung khi URL rỗng
                // =====================================
              ),
            ),
            // Phần thông tin
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // --- GIAO DIỆN THAY ĐỔI ĐỘNG ---
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),

                      // --- SỬA LỖI TẠI ĐÂY (Giữ nguyên code fix của bạn) ---
                      // Chỉ xây dựng firstChild nếu món ăn đã được chọn (isSelected)
                      firstChild: isSelected
                          ? _buildQuantityControl(context, cartBloc.state.cartItems[existingItemIndex])
                          : const SizedBox.shrink(), // Nếu không, dùng một widget trống an toàn

                      secondChild: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          currencyFormatter.format(item.price),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      crossFadeState: isSelected ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget mới cho cụm nút tăng/giảm số lượng
  Widget _buildQuantityControl(BuildContext context, CartItemModel cartItem) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.remove_circle, size: 28, color: Colors.red),
          onPressed: () => context.read<OrderCartBloc>().add(DecrementItemInCart(cartItem)),
        ),
        Text(
          cartItem.quantity.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.add_circle, size: 28, color: Colors.green),
          onPressed: onAddToCart,
        ),
      ],
    );
  }
}