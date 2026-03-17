import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qlnh_app/data/models/menu_item_model.dart';
import 'package:intl/intl.dart'; // Thêm import để định dạng tiền tệ

class MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback onAddToCart;

  const MenuItemCard({super.key, required this.item, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Widget hiển thị hình ảnh mặc định khi URL rỗng hoặc lỗi
    Widget errorPlaceholder = Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.restaurant_menu, color: Colors.grey, size: 40),
    );

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Thêm cái này để bo góc ảnh
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onAddToCart,

        // === THAY ĐỔI 1: Chuyển từ Row sang Column ===
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Căn lề trái
          children: [

            // === 2. PHẦN HÌNH ẢNH (dùng Expanded) ===
            // Bọc ảnh bằng Expanded để nó tự co giãn lấp đầy không gian
            Expanded(
              child: SizedBox(
                width: double.infinity, // Cho ảnh đầy chiều ngang
                child: item.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade200),
                  errorWidget: (context, url, error) => errorPlaceholder,
                )
                    : errorPlaceholder, // Hiển thị placeholder nếu URL rỗng
              ),
            ),

            // === 3. PHẦN TEXT (Bỏ mô tả, chỉ giữ Tên và Giá) ===
            Padding(
              // Giảm padding để có thêm không gian
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Cột chỉ chiếm chiều cao cần thiết
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2, // Cho phép 2 dòng
                    overflow: TextOverflow.ellipsis, // Hiển thị ...
                  ),
                  const SizedBox(height: 4), // Giảm khoảng cách
                  // Dùng Row để đặt Giá và Nút bấm trên cùng 1 hàng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        // Dùng currencyFormatter để định dạng tiền
                        currencyFormatter.format(item.price),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      // Nút thêm (thu nhỏ lại)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(), // Xóa padding mặc định
                        iconSize: 22, // Kích thước icon
                        icon: const Icon(Icons.add_shopping_cart),
                        color: Theme.of(context).primaryColor,
                        onPressed: onAddToCart,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}