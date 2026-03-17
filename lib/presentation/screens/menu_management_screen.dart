import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qlnh_app/data/models/menu_item_model.dart';
import 'package:qlnh_app/data/services/api_service.dart';
import 'package:qlnh_app/presentation/widgets/menu_item_form_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <<<--- THÊM IMPORT NÀY

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => MenuManagementScreenState();
}

class MenuManagementScreenState extends State<MenuManagementScreen> {
  List<MenuItemModel>? _menuItems;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _reloadMenuItems();
  }

  Future<void> _reloadMenuItems() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }
    try {
      final items = await context.read<ApiService>().getMenuItemsForAdmin();
      if (mounted) {
        setState(() {
          _menuItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _confirmDelete(MenuItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa món "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          TextButton(
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              try {
                await context.read<ApiService>().deleteMenuItem(item.id);
                Navigator.of(ctx).pop();
                _reloadMenuItems();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thành công!'), backgroundColor: Colors.green));
              } catch (e) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: Colors.red));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAvailability(MenuItemModel item, bool value) async {
    setState(() {
      final index = _menuItems!.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _menuItems![index] = item.copyWith(isAvailable: value);
      }
    });

    try {
      await context.read<ApiService>().updateMenuItem(item.id, {'isAvailable': value});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi cập nhật: $e'), backgroundColor: Colors.red));
      setState(() {
        final index = _menuItems!.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _menuItems![index] = item.copyWith(isAvailable: !value);
        }
      });
    }
  }

  void showItemFormSheet({MenuItemModel? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => MenuItemFormSheet(
        item: item,
        onSuccess: () {
          _reloadMenuItems();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${item != null ? 'Cập nhật' : 'Thêm'} món ăn thành công!'),
            backgroundColor: Colors.green,
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SỬA LẠI: Thêm AppBar để có tiêu đề và nút quay lại
      appBar: AppBar(
        title: const Text('Quản lý Thực đơn'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showItemFormSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _menuItems == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(child: Text('Lỗi: $_error'));
    }
    if (_menuItems == null || _menuItems!.isEmpty) {
      return const Center(child: Text('Chưa có món ăn nào.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        // SỬA LẠI: Giảm giá trị để thẻ cao hơn, khắc phục lỗi overflow
        childAspectRatio: 0.7,
      ),
      itemCount: _menuItems!.length,
      itemBuilder: (context, index) {
        final item = _menuItems![index];
        return _MenuItemCard(
          item: item,
          onEdit: () => showItemFormSheet(item: item),
          onDelete: () => _confirmDelete(item),
          onToggle: (value) => _toggleAvailability(item, value),
        );
      },
    );
  }
}

// === WIDGET CARD MỚI CHO GIAO DIỆN LƯỚI ===
class _MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onToggle;

  const _MenuItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // === CẬP NHẬT: Tách riêng 2 widget placeholder ===
    Widget errorPlaceholder = Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
    Widget emptyPlaceholder = Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 40),
    );
    // ===============================================

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            // === CẬP NHẬT: Dùng CachedNetworkImage ===
            child: item.imageUrl.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: Colors.grey.shade200),
              errorWidget: (context, url, error) => errorPlaceholder,
            )
                : emptyPlaceholder,
            // =======================================
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.category,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyFormatter.format(item.price),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          } else if (value == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Sửa'),
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Xóa', style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.isAvailable ? 'Đang bán' : 'Tạm tắt',
                  style: TextStyle(
                    fontSize: 12,
                    color: item.isAvailable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: item.isAvailable,
                  onChanged: (value) => onToggle(value),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}