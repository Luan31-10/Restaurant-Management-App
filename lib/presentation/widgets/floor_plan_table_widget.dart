import 'package:flutter/material.dart';
import 'package:qlnh_app/data/models/table_model.dart'; // Đảm bảo import đúng model
import 'dart:math' as math;
import 'package:intl/intl.dart'; // Cho NumberFormat

// =============== GHẾ CAO CẤP ===============
class ChairPainter extends CustomPainter {
  final Color color;
  // === THÊM CONST ===
  const ChairPainter({this.color = const Color(0xFF795548)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    // Seat
    paint.color = color.withOpacity(0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.22, size.width, size.height * 0.78),
        // === THÊM CONST ===
        const Radius.circular(3),
      ),
      paint,
    );
    // Backrest
    paint.color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.2, 0, size.width * 0.6, size.height * 0.3),
        // === THÊM CONST ===
        const Radius.circular(2),
      ),
      paint,
    );
    // Highlight
    paint.color = Colors.white.withOpacity(0.2);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.2, 0, size.width * 0.6, 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
// ===========================================

// =============== WIDGET BÀN CHUYÊN NGHIỆP ===============
class FloorPlanTableWidget extends StatefulWidget {
  final TableModel table;
  final VoidCallback onNewOrderTap;
  final VoidCallback onAddItemsTap;
  final VoidCallback onEditOrderTap;
  final VoidCallback onCleanedTap;
  final VoidCallback onPaymentTap;

  // === THÊM CONST ===
  const FloorPlanTableWidget({
    super.key,
    required this.table,
    required this.onNewOrderTap,
    required this.onAddItemsTap,
    required this.onEditOrderTap,
    required this.onCleanedTap,
    required this.onPaymentTap,
  });

  @override
  State<FloorPlanTableWidget> createState() => _FloorPlanTableWidgetState();
}

class _FloorPlanTableWidgetState extends State<FloorPlanTableWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isPressed = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300)); // <<< CONST
    final initialStatus = widget.table.status;
    if (['occupied', 'serving', 'billing'].contains(initialStatus)) {
      // Bỏ qua logic expand mặc định
    } else {
      _isExpanded = false;
    }
  }

  @override
  void didUpdateWidget(covariant FloorPlanTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newStatus = widget.table.status;
    if (!['occupied', 'serving', 'billing'].contains(newStatus) && _isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isExpanded) {
          setState(() {
            _isExpanded = false;
            _animationController.reverse();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    final status = widget.table.status;
    if (['occupied', 'serving', 'billing'].contains(status)) {
      setState(() {
        _isExpanded = !_isExpanded;
        if (_isExpanded) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    } else {
      print("Cannot expand table in status: $status");
    }
  }

  void _handleTapDown(TapDownDetails details) { setState(() => _isPressed = true); }
  void _handleTapUp(TapUpDetails details) { setState(() => _isPressed = false); }
  void _handleTapCancel() { setState(() => _isPressed = false); }

  void _handleTap() {
    setState(() => _isPressed = false);
    final status = widget.table.status;

    switch (status) {
      case 'available':
        widget.onNewOrderTap();
        break;
      case 'cleaning':
        break;
      case 'reserved':
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.table.number} đã được đặt trước.'),
          // === THÊM CONST ===
          duration: const Duration(seconds: 2),
        ));
        break;
      case 'occupied':
      case 'serving':
      case 'billing':
        _toggleExpand();
        break;
      default:
        print("Unhandled tap for table status: $status");
    }
  }

  void _showCleanTableConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // === THÊM CONST ===
          title: const Text('Xác nhận dọn bàn'),
          content: Text('Chuyển trạng thái ${widget.table.number} thành "Còn trống"?'),
          actions: <Widget>[
            TextButton(
              // === THÊM CONST ===
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              // === THÊM CONST ===
              child: const Text('Xác nhận'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onCleanedTap();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final currentStatus = widget.table.status;

    final bool canExpand = ['occupied', 'serving', 'billing'].contains(currentStatus);
    final bool isCleaning = currentStatus == 'cleaning';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (currentStatus) {
      case 'occupied':
        statusColor = colorScheme.error;
        statusText = "Đang có khách";
        statusIcon = Icons.person_outline;
        break;
      case 'serving':
        statusColor = Colors.teal.shade600;
        statusText = "Đang phục vụ";
        statusIcon = Icons.room_service_outlined;
        break;
      case 'billing':
        statusColor = Colors.blue.shade700;
        statusText = "Chờ thanh toán";
        statusIcon = Icons.receipt_long_outlined;
        break;
      case 'cleaning':
        statusColor = Colors.orange.shade700;
        statusText = "Cần dọn dẹp";
        statusIcon = Icons.cleaning_services_outlined;
        break;
      case 'reserved':
        statusColor = Colors.blueGrey.shade400;
        statusText = "Đã đặt trước";
        statusIcon = Icons.bookmark_added_outlined;
        break;
      default: // 'available'
        statusColor = Colors.brown.shade700;
        statusText = "Còn trống";
        statusIcon = Icons.check_circle_outline;
    }

    // === THÊM CONST ===
    const double tableSize = 74.0;
    const double chairSize = 19.0;
    const double radius = tableSize * 0.63;
    final totalAmount = widget.table.activeOrder?.totalAmount ?? 0.0;
    final String displayText = canExpand && totalAmount > 0
        ? '$statusText • ${currencyFormatter.format(totalAmount)}'
        : statusText;

    return Card(
      elevation: _isPressed ? 2 : (_isExpanded ? 8 : 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: AnimatedContainer(
          // === THÊM CONST ===
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _isExpanded ? statusColor.withOpacity(0.5) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 126,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Chairs
                    ...List.generate(widget.table.capacity, (index) {
                      final angle = (2 * math.pi / widget.table.capacity) * index;
                      return Transform.translate(
                        offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
                        child: Transform.rotate(
                          angle: angle,
                          child: SizedBox(
                            width: chairSize,
                            height: chairSize,
                            child: CustomPaint(
                              // === THÊM CONST ===
                              painter: ChairPainter(color: statusColor.withOpacity(0.85)),
                            ),
                          ),
                        ),
                      );
                    }),
                    // Table surface
                    Container(
                      width: tableSize,
                      height: tableSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // === THÊM CONST ===
                        gradient: RadialGradient(
                            center: const Alignment(0.3, -0.3),
                            colors: [ Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3C3C3C) : const Color(0xFFFDFDFD), Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8), ],
                            stops: const [0.0, 1.0]
                        ),
                        boxShadow: [ BoxShadow( color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.1), blurRadius: 8, offset: const Offset(0, 2), ) ], // <<< CONST
                        border: Border.all( color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF555555) : const Color(0xFFCCCCCC), width: 3, ),
                      ),
                      child: Center(
                        child: Text(
                          widget.table.number,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF333333),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    if (currentStatus != 'available')
                      Positioned(
                        top: 6, right: 6,
                        child: Container(
                          // === THÊM CONST ===
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [ BoxShadow( color: statusColor.withOpacity(0.5), blurRadius: 6, offset: const Offset(0, 1), ), ], // <<< CONST
                          ),
                          child: Icon(statusIcon, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                // === THÊM CONST ===
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: Text(
                  displayText,
                  style: textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizeTransition(
                sizeFactor: CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
                axisAlignment: -1.0,
                // === THÊM CONST ===
                child: canExpand ? _buildOccupiedDetails(context) : const SizedBox.shrink(),
              ),
              if (isCleaning)
                Padding(
                  // === THÊM CONST ===
                  padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 12),
                  child: _buildCleaningButton(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOccupiedDetails(BuildContext context) {
    final order = widget.table.activeOrder;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // === THÊM CONST ===
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF444444) : const Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          if (order != null && order.orderItems.isNotEmpty) ...[
            Text(
              "Món đã gọi:",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            // === THÊM CONST ===
            const SizedBox(height: 10),
            Column(
              children: order.orderItems.map((item) => Padding(
                // === THÊM CONST ===
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      alignment: Alignment.center,
                      child: Text(
                        "${item.quantity}x",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    // === THÊM CONST ===
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.menuItem.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : null,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ] else ...[
            Center(
              child: Text(
                "Chưa có món nào.",
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          // === THÊM CONST ===
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              // === THÊM CONST ===
              icon: const Icon(Icons.payment, size: 18),
              // === THÊM CONST ===
              label: const Text('Thanh Toán', style: TextStyle(fontSize: 14)),
              onPressed: widget.onPaymentTap,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                // === THÊM CONST ===
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          // === THÊM CONST ===
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              // === THÊM CONST ===
              icon: const Icon(Icons.edit_note, size: 18),
              // === THÊM CONST ===
              label: const Text('Sửa / Thêm Món', style: TextStyle(fontSize: 14)),
              onPressed: widget.onEditOrderTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.primary),
                foregroundColor: colorScheme.primary,
                // === THÊM CONST ===
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleaningButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: _showCleanTableConfirmationDialog,
      // === THÊM CONST ===
      icon: const Icon(Icons.done_outline_rounded, size: 22),
      // === THÊM CONST ===
      label: const Text('Đã dọn xong   ', style: TextStyle(fontSize: 13)),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.green.shade400,
        foregroundColor: Colors.white,
        // === THÊM CONST ===
        padding: const EdgeInsets.symmetric(vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}