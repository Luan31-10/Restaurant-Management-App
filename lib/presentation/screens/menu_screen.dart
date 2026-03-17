import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qlnh_app/data/models/menu_item_model.dart';
import 'package:qlnh_app/logic/blocs/quick_sale/quick_sale_bloc.dart';
import 'package:qlnh_app/presentation/screens/cart_summary_screen.dart'; // Import trang giỏ hàng
import 'package:qlnh_app/presentation/widgets/menu_item_card.dart';
import '../../logic/blocs/menu_items/menu_item_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart'; // <<<--- 1. IMPORT FLUTTER ANIMATE

class MenuScreen extends StatefulWidget {
  // === THÊM CONST ===
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ValueNotifier<String> _searchQuery = ValueNotifier('');

  @override
  void dispose() {
    _searchQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // === THÊM CONST ===
        title: const Text('Thực đơn'),
        // centerTitle: true, // Bỏ dòng này nếu đã đặt mặc định trong theme
      ),
      floatingActionButton: BlocBuilder<QuickSaleBloc, QuickSaleState>(
        builder: (context, state) {
          if (state.cartItems.isEmpty) {
            // === THÊM CONST ===
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            heroTag: null,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CartSummaryScreen()));
            },
            label: Text('${state.cartItems.length} món'),
            // === THÊM CONST ===
            icon: const Icon(Icons.shopping_cart_outlined),
          );
        },
      ),
      body: BlocBuilder<MenuItemBloc, MenuItemState>(
        builder: (context, state) {
          if (state is MenuItemLoading) {
            // === THÊM CONST ===
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MenuItemLoaded) {

            final allMenuItems = state.menuItems;

            return Column(
              children: [
                // --- Thanh Tìm Kiếm ---
                Padding(
                  // === THÊM CONST ===
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    // InputDecoration bây giờ sẽ tự lấy style từ theme
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm món ăn...',
                      prefixIcon: Icon(Icons.search),
                      // fillColor: Theme.of(context).colorScheme.surfaceVariant, // Không cần nếu đã đặt trong theme
                    ),
                    onChanged: (value) => _searchQuery.value = value,
                  ),
                ),

                // --- TabBar và GridView ---
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _searchQuery,
                    builder: (context, searchQuery, _) {

                      final allCategories = allMenuItems.map((e) => e.category).toSet().toList();
                      final searchFilteredItems = allMenuItems.where((item) {
                        return searchQuery.isEmpty || item.name.toLowerCase().contains(searchQuery.toLowerCase());
                      }).toList();
                      final categorizedMenu = <String, List<MenuItemModel>>{};
                      for (var item in searchFilteredItems) {
                        (categorizedMenu[item.category] ??= []).add(item);
                      }
                      final categories = allCategories.where((c) => categorizedMenu.containsKey(c)).toList();

                      // Thêm kiểm tra nếu categories rỗng sau khi lọc
                      if (categories.isEmpty) {
                        return const Center(
                          // === THÊM CONST ===
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Không tìm thấy món ăn nào.'),
                          ),
                        );
                      }

                      return DefaultTabController(
                        length: categories.length,
                        child: Column(
                          children: [
                            TabBar(
                              isScrollable: true,
                              tabs: categories.map((category) => Tab(text: category)).toList(),
                            ),
                            Expanded(
                              child: TabBarView(
                                children: categories.map((category) {
                                  final items = categorizedMenu[category]!;
                                  return GridView.builder(
                                    // === THÊM CONST ===
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16.0,
                                      mainAxisSpacing: 16.0,
                                      childAspectRatio: 0.8,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      return MenuItemCard(
                                        item: item,
                                        onAddToCart: () {
                                          context.read<QuickSaleBloc>().add(AddItemToQuickSale(item));
                                          ScaffoldMessenger.of(context)
                                            ..hideCurrentSnackBar()
                                            ..showSnackBar(SnackBar(
                                              content: Text('Đã thêm: ${item.name}'),
                                              // === THÊM CONST ===
                                              duration: const Duration(seconds: 1),
                                            ));
                                        },
                                      )
                                      // === 2. THÊM HIỆU ỨNG ANIMATION ===
                                          .animate()
                                          .fadeIn(duration: 400.ms, delay: (100 * (index % 10)).ms)
                                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
                                      // ==============================
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          if (state is MenuItemError) {
            return Center(child: Text('Lỗi: ${state.message}'));
          }
          // === THÊM CONST ===
          return const Center(child: Text('Chạm để tải dữ liệu'));
        },
      ),
    );
  }
}