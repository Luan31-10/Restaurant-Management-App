import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qlnh_app/data/models/active_order_model.dart';
import 'package:qlnh_app/data/models/table_model.dart';
import 'package:qlnh_app/logic/blocs/auth/auth_bloc.dart';
import 'package:qlnh_app/logic/blocs/tables/table_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <<<--- THÊM IMPORT NÀY

enum PaymentMethod { cash, card, transfer }

class PaymentScreen extends StatefulWidget {
  final TableModel table;
  // === THÊM CONST ===
  const PaymentScreen({super.key, required this.table});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ActiveOrderModel? order = widget.table.activeOrder;

    if (order == null) {
      return Scaffold(
        // === THÊM CONST ===
        appBar: AppBar(title: const Text('Lỗi Thanh Toán')),
        // === THÊM CONST ===
        body: const Center(
            child: Text('Không tìm thấy thông tin order cho bàn này.')),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background, // <<< Dùng màu nền từ theme
      appBar: AppBar(
        title: Text('Hóa đơn Bàn ${widget.table.number}'),
        // backgroundColor: theme.colorScheme.surface, // AppBar theme đã xử lý
      ),
      bottomNavigationBar: _buildBottomActions(context, order),
      body: SingleChildScrollView(
        // === THÊM CONST ===
        padding: const EdgeInsets.all(16.0),
        child: Container(
          // === THÊM CONST ===
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, // <<< Dùng màu surface từ theme
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                // === THÊM CONST ===
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildReceiptHeader(),
              // === THÊM CONST ===
              const SizedBox(height: 24),
              _buildOrderInfo(context, order),
              _buildDottedDivider(),
              _buildItemsTable(context, order),
              _buildDottedDivider(),
              _buildSummary(context, order),
              // === THÊM CONST ===
              const SizedBox(height: 24),
              _buildReceiptFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // Phần 1: Header hóa đơn
  Widget _buildReceiptHeader() {
    // === THÊM CONST ===
    return const Column(
      children: [
        Text('POS Pro Restaurant',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('39/3a Nguyen Huu Cau, My Hue, TP.HCM'),
        SizedBox(height: 16),
        Text('HÓA ĐƠN BÁN LẺ', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
      ],
    );
  }

  // Phần 2: Thông tin chung
  Widget _buildOrderInfo(BuildContext context, ActiveOrderModel order) {
    final cashierName = context.read<AuthBloc>().state.user?.name ?? 'N/A';
    final now = DateTime.now();

    return Padding(
      // === THÊM CONST ===
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          _buildInfoRow('Số HĐ:', 'HD-${order.id}'),
          // === THÊM CONST ===
          const SizedBox(height: 8),
          _buildInfoRow('Ngày:', DateFormat('dd/MM/yyyy').format(now)),
          // === THÊM CONST ===
          const SizedBox(height: 8),
          _buildInfoRow('Giờ ra:', DateFormat('HH:mm').format(now)),
          // === THÊM CONST ===
          const SizedBox(height: 8),
          _buildInfoRow('Thu ngân:', cashierName),
        ],
      ),
    );
  }

  // Phần 3: Bảng chi tiết món
  Widget _buildItemsTable(BuildContext context, ActiveOrderModel order) {
    final currencyFormatter = NumberFormat("#,##0", "vi_VN");
    return Padding(
      // === THÊM CONST ===
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          // === THÊM CONST ===
          const Row(
            children: [
              Expanded(flex: 5,
                  child: Text('Tên hàng',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 1,
                  child: Text('SL', textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 3,
                  child: Text('Đ.Giá', textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 3,
                  child: Text('T.Tiền', textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          // === THÊM CONST ===
          const Divider(height: 12),
          ...order.orderItems.map((item) {
            return Padding(
              // === THÊM CONST ===
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: Text(item.menuItem.name)),
                  Expanded(flex: 1,
                      child: Text(item.quantity.toString(),
                          textAlign: TextAlign.center)),
                  Expanded(flex: 3,
                      child: Text(currencyFormatter.format(item.price),
                          textAlign: TextAlign.right)),
                  Expanded(flex: 3,
                      child: Text(
                          currencyFormatter.format(item.price * item.quantity),
                          textAlign: TextAlign.right)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Phần 4: Tổng kết
  Widget _buildSummary(BuildContext context, ActiveOrderModel order) {
    final currencyFormatter = NumberFormat.currency(
        locale: 'vi_VN', symbol: 'đ');
    final theme = Theme.of(context);

    return Padding(
      // === THÊM CONST ===
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          _buildInfoRow(
              'Tạm tính:', currencyFormatter.format(order.totalAmount)),
          // === THÊM CONST ===
          const SizedBox(height: 8),
          // === THÊM CONST ===
          _buildInfoRow('Giảm giá:', '0đ'),
          // === THÊM CONST ===
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // === THÊM CONST ===
              Text('TỔNG CỘNG', style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold)),
              Text(
                currencyFormatter.format(order.totalAmount),
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: theme.colorScheme.primary), // <<< Dùng màu primary từ theme
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Phần 5: Footer hóa đơn
  Widget _buildReceiptFooter() {
    // === THÊM CONST ===
    return const Text('Xin cảm ơn và hẹn gặp lại!',
        style: TextStyle(fontStyle: FontStyle.italic));
  }

  // THANH ĐIỀU KHIỂN DƯỚI CÙNG
  Widget _buildBottomActions(BuildContext context, ActiveOrderModel order) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0).copyWith(bottom: MediaQuery
          .of(context)
          .padding
          .bottom + 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // <<< Dùng màu surface
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              // === THÊM CONST ===
              offset: const Offset(0, -5)),
        ],
        // === THÊM CONST ===
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _buildPaymentOption(context, label: 'Tiền mặt',
                  icon: Icons.money,
                  method: PaymentMethod.cash,
                  order: order)),
              // === THÊM CONST ===
              const SizedBox(width: 12),
              Expanded(child: _buildPaymentOption(context, label: 'Thẻ',
                  icon: Icons.credit_card,
                  method: PaymentMethod.card,
                  order: order)),
              // === THÊM CONST ===
              const SizedBox(width: 12),
              Expanded(child: _buildPaymentOption(context, label: 'QR Pay',
                  icon: Icons.qr_code_2,
                  method: PaymentMethod.transfer,
                  order: order)),
            ],
          ),
          // === THÊM CONST ===
          const SizedBox(height: 16),
          BlocBuilder<TableBloc, TableState>(
            builder: (context, state) {
              bool isLoading = state is TableLoading;
              return SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  // === THÊM CONST ===
                  icon: const Icon(Icons.check_circle_outline),
                  // === THÊM CONST ===
                  label: const Text('XÁC NHẬN THANH TOÁN'),
                  style: FilledButton.styleFrom(
                    // === THÊM CONST ===
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    // === THÊM CONST ===
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading
                      ? null
                      : () {
                    if (_selectedPaymentMethod == PaymentMethod.card) {
                      _showCardConfirmationDialog(context, order);
                    } else {
                      context.read<TableBloc>().add(
                          UpdateOrderStatus(order.id, 'paid', paymentMethod: _selectedPaymentMethod.name)); // Thêm paymentMethod
                      Navigator.of(context).popUntil((route) =>
                      route.isFirst);
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGETS HỖ TRỢ ---
  Widget _buildPaymentOption(BuildContext context,
      {required String label, required IconData icon, required PaymentMethod method, required ActiveOrderModel order}) {
    final theme = Theme.of(context);
    final isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethod = method);
        if (method == PaymentMethod.transfer) {
          _showQrCodeDialog(context, order);
        }
      },
      child: AnimatedContainer(
        // === THÊM CONST ===
        duration: const Duration(milliseconds: 250),
        // === THÊM CONST ===
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : theme // <<< Dùng primary từ theme
              .colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? theme.colorScheme.primary : Colors.transparent), // <<< Dùng primary từ theme
        ),
        child: Column(
          children: [
            Icon(icon, size: 28,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme // <<< Dùng primary từ theme
                    .onSurfaceVariant), // <<< Dùng onSurfaceVariant từ theme
            // === THÊM CONST ===
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme // <<< Dùng primary từ theme
                    .onSurfaceVariant)), // <<< Dùng onSurfaceVariant từ theme
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)), // <<< CONST
        Text(value,
            // === THÊM CONST ===
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDottedDivider() {
    return Padding(
      // === THÊM CONST ===
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final boxWidth = constraints.constrainWidth();
          // === THÊM CONST ===
          const double dashWidth = 5.0;
          const double dashHeight = 1.0;
          const double dashSpace = 3.0;
          final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              // === THÊM CONST ===
              return SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Theme.of(context).dividerColor), // <<< Dùng dividerColor từ theme
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // --- Dialog QR Code (Giữ nguyên cấu trúc, thêm const) ---
  void _showQrCodeDialog(BuildContext context, ActiveOrderModel order) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(
        locale: 'vi_VN', symbol: 'đ');

    // === THÊM CONST ===
    const bankId = "Techcombank";
    const accountNumber = "19038975516014";
    const accountName = "VO THANH LUAN";
    final amount = order.totalAmount.toInt();
    final content = "TT BAN ${widget.table.number} HD-${order.id}";
    // URL QR Code nên được encode
    final encodedContent = Uri.encodeComponent(content);
    final qrData = 'https://img.vietqr.io/image/$bankId-$accountNumber-print.png?amount=$amount&addInfo=$encodedContent&accountName=$accountName';


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // === THÊM CONST ===
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          // === THÊM CONST ===
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quét mã để thanh toán',
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold),
              ),
              // === THÊM CONST ===
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage( // <<< Dùng CachedNetworkImage
                  imageUrl: qrData,
                  width: 250,
                  height: 250,
                  placeholder: (context, url) => const SizedBox( // <<< CONST
                    width: 250,
                    height: 250,
                    // === THÊM CONST ===
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => const SizedBox( // <<< CONST
                    width: 250,
                    height: 250,
                    // === THÊM CONST ===
                    child: Center(child: Icon(Icons.error_outline, color: Colors.red)),
                  ),
                ),
              ),
              // === THÊM CONST ===
              const SizedBox(height: 24),
              _buildQrInfoRow(
                context,
                icon: Icons.account_balance,
                label: 'Ngân hàng',
                value: bankId,
              ),
              // === THÊM CONST ===
              const Divider(height: 24),
              _buildQrInfoRow(
                context,
                icon: Icons.person,
                label: 'Chủ tài khoản',
                value: accountName,
              ),
              // === THÊM CONST ===
              const Divider(height: 24),
              _buildQrInfoRow(
                context,
                icon: Icons.credit_card,
                label: 'Số tài khoản',
                value: accountNumber,
                canCopy: true,
              ),
              // === THÊM CONST ===
              const Divider(height: 24),
              _buildQrInfoRow(
                context,
                icon: Icons.price_change,
                label: 'Số tiền',
                value: currencyFormatter.format(amount),
                isAmount: true,
              ),
              // === THÊM CONST ===
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  // === THÊM CONST ===
                  child: const Text('Đã hiểu'),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // --- Widget Row thông tin QR (Thêm const) ---
  Widget _buildQrInfoRow(BuildContext context,
      {required IconData icon, required String label, required String value, bool canCopy = false, bool isAmount = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20), // <<< Dùng màu từ theme
            // === THÊM CONST ===
            const SizedBox(width: 12),
            Text(label, style: theme.textTheme.bodyLarge),
          ],
        ),
        Row(
          children: [
            Text(
              value,
              style: isAmount
                  ? theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: theme.colorScheme.primary) // <<< Dùng màu từ theme
                  : theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold),
            ),
            if (canCopy)
              IconButton(
                // === THÊM CONST ===
                icon: const Icon(Icons.copy_outlined, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    // === THÊM CONST ===
                    const SnackBar(content: Text('Đã sao chép số tài khoản!')),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  // --- Dialog xác nhận thẻ (Thêm const) ---
  void _showCardConfirmationDialog(BuildContext context, ActiveOrderModel order) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: ListTile(
            // === THÊM CONST ===
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.credit_card, color: theme.colorScheme.primary), // <<< Dùng màu từ theme
            // === THÊM CONST ===
            title: const Text(
              'Xác nhận Thanh toán Thẻ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // === THÊM CONST ===
          content: const Text('Vui lòng xác nhận bạn đã nhận được thanh toán thành công từ máy POS.'),
          actions: <Widget>[
            TextButton(
              // === THÊM CONST ===
              child: const Text('HỦY BỎ'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            FilledButton(
              // === THÊM CONST ===
              child: const Text('THÀNH CÔNG'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Thêm paymentMethod khi xác nhận thẻ
                context.read<TableBloc>().add(UpdateOrderStatus(order.id, 'paid', paymentMethod: PaymentMethod.card.name));
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  }
}